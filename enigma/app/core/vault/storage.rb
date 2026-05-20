# frozen_string_literal: true

#
# app/core/vault/storage.rb
# Responsibility: File I/O for vault — magic, salt, security data, AES-GCM payload.
# Supports:
#   v1 (MAGIC "ENIGMA\x01"):  salt(32) + encrypted payload  →  old vaults
#   v2 (MAGIC "ENIGMA\x02"):  salt(32) + security(96) + recovery(60) + payload  →  new vaults
#

require 'json'
require 'fileutils'
require 'openssl'

module Enigma
  module Core
    module Vault
      class Storage
        VAULT_DIR  = File.expand_path('~/.enigma_cryptoshelter').freeze
        VAULT_PATH = File.join(VAULT_DIR, 'vault.dat').freeze
        DIR_MODE   = 0o700
        FILE_MODE  = 0o600

        MAGIC    = "ENIGMA\x01".b.freeze  # v1 — old format
        MAGIC_V2 = "ENIGMA\x02".b.freeze  # v2 — new format with security header
        MAGIC_SIZE = MAGIC.bytesize

        SALT_LENGTH = 32

        NUM_QUESTIONS    = 3
        SECURITY_PER_Q   = 32  # 1 byte index + 31 byte hash
        SECURITY_SIZE    = NUM_QUESTIONS * SECURITY_PER_Q  # 96

        IV_BYTES         = 12
        TAG_BYTES        = 16
        RECOVERY_KEYSIZE = 32  # only vault_key stored for recovery
        RECOVERY_SIZE    = IV_BYTES + TAG_BYTES + RECOVERY_KEYSIZE  # 60

        HEADER_SIZE_V1 = MAGIC_SIZE + SALT_LENGTH                         # 39
        HEADER_SIZE_V2 = MAGIC_SIZE + SALT_LENGTH + SECURITY_SIZE +
                         RECOVERY_SIZE                                    # 195

        UNUSED_INDEX = 0xFF

        SECURITY_QUESTIONS = [
          "¿Cuál es el nombre de tu mascota?",
          "¿Cuál es tu ciudad favorita?",
          "¿Cuál es el nombre de tu primer profesor?",
          "¿Cuál es tu comida favorita?",
          "¿Cuál es el año de nacimiento de tu madre?",
          "¿Cuál es tu libro favorito?",
          "¿Cuál es tu película favorita?",
          "¿Cuál es el nombre de tu mejor amigo de la infancia?",
          "¿Cuál es tu deporte favorito?",
          "¿Cuál es el modelo de tu primer auto?",
          "¿Cuál es el nombre de tu escuela primaria?",
          "¿Cuál es tu color favorito?",
          "¿Cuál es el nombre de soltera de tu madre?",
          "¿Cuál es tu estación del año favorita?",
          "¿Cuál es tu artista o banda favorita?",
          "¿Cuál es tu destino de viaje soñado?",
          "¿Cuál es el segundo apellido de tu padre?",
          "¿Cuál es tu número de la suerte?"
        ].freeze

        def self.vault_exists?
          File.exist?(VAULT_PATH)
        end

        @salt_cache = nil

        def self.read_salt(path = VAULT_PATH)
          return @salt_cache if @salt_cache

          raw = File.binread(path)
          raise Errors::CorruptedDataError unless raw.start_with?(MAGIC) ||
                                                  raw.start_with?(MAGIC_V2)

          @salt_cache = raw[MAGIC_SIZE, SALT_LENGTH]
        end

        def self.clear_salt_cache!
          @salt_cache = nil
        end

        def self.v2_format?(path = VAULT_PATH)
          File.binread(path).start_with?(MAGIC_V2)
        rescue StandardError
          false
        end

        def self.read_security_data(path = VAULT_PATH)
          raw = File.binread(path)
          return [] unless v2_format?(path)

          security_raw = raw[MAGIC_SIZE + SALT_LENGTH, SECURITY_SIZE]
          questions = []
          NUM_QUESTIONS.times do |i|
            offset = i * SECURITY_PER_Q
            idx = security_raw[offset].ord
            next if idx == UNUSED_INDEX

            questions << {
              question_index: idx,
              answer_hash:    security_raw[offset + 1, 31]
            }
          end
          questions
        end

        def self.read_question_texts(path = VAULT_PATH)
          data = read_security_data(path)
          if data.empty?
            return try_read_questions_from_authdat
          end

          data.map do |q|
            idx = q[:question_index]
            if idx.between?(0, SECURITY_QUESTIONS.length - 1)
              SECURITY_QUESTIONS[idx]
            else
              "Pregunta personalizada"
            end
          end
        end

        def self.verify_answers(entered_answers, path = VAULT_PATH)
          if v2_format?(path)
            stored = read_security_data(path)
            return false if stored.size != entered_answers.size

            stored.each_with_index.all? do |q, i|
              entered_hash = Digest::SHA256.digest(
                entered_answers[i].to_s.strip.downcase
              )[0, 31]
              constant_time_compare(entered_hash, q[:answer_hash])
            end
          else
            try_verify_via_authdat(entered_answers)
          end
        end

        def self.read_recovery_data(_password, answers, path = VAULT_PATH)
          return try_recover_via_authdat(answers) unless v2_format?(path)

          raw = File.binread(path)
          return nil unless raw.bytesize >= HEADER_SIZE_V2

          recovery_raw = raw[MAGIC_SIZE + SALT_LENGTH + SECURITY_SIZE,
                             RECOVERY_SIZE]
          iv  = recovery_raw[0, IV_BYTES]
          tag = recovery_raw[IV_BYTES, TAG_BYTES]
          enc = recovery_raw[IV_BYTES + TAG_BYTES, RECOVERY_KEYSIZE]

          answer_key = recovery_key_from_answers(answers)

          cipher = OpenSSL::Cipher.new('aes-256-gcm')
          cipher.decrypt
          cipher.key = answer_key
          cipher.iv = iv
          cipher.auth_tag = tag
          vault_key = cipher.update(enc) + cipher.final

          { vault_key: vault_key }
        rescue OpenSSL::Cipher::CipherError, ArgumentError, TypeError
          nil
        end

        def initialize(path, cipher)
          @path   = path
          @cipher = cipher
          @salt   = nil
          @v2     = false
        end

        def exists?
          File.exist?(@path)
        end

        def create_new!(salt, questions_and_answers = nil)
          self.class.clear_salt_cache!
          @salt = salt
          @v2   = true
          FileUtils.mkdir_p(VAULT_DIR, mode: DIR_MODE)

          if questions_and_answers
            security_data = build_security_data(
              questions_and_answers[:questions])
            recovery_blob = build_recovery_data(
              questions_and_answers[:vault_key],
              questions_and_answers[:answers])
          else
            security_data = "\x00" * SECURITY_SIZE
            recovery_blob = "\x00" * RECOVERY_SIZE
          end

          payload = @cipher.encrypt(JSON.generate({ credentials: [] }))
          File.binwrite(@path, MAGIC_V2 + @salt + security_data +
                        recovery_blob + payload)
          File.chmod(FILE_MODE, @path)
        end

        def load
          raw = File.binread(@path)

          if raw.start_with?(MAGIC_V2)
            @v2  = true
            @salt = raw[MAGIC_SIZE, SALT_LENGTH]
            encrypted = raw[HEADER_SIZE_V2..]
          elsif raw.start_with?(MAGIC)
            @v2  = false
            @salt = raw[MAGIC_SIZE, SALT_LENGTH]
            encrypted = raw[HEADER_SIZE_V1..]
          else
            raise Errors::CorruptedDataError
          end

          json = @cipher.decrypt(encrypted)
          JSON.parse(json)['credentials'].map { |h| Credential.from_h(h) }
        rescue OpenSSL::Cipher::CipherError => e
          raise Errors::AuthTagError, e.message
        end

        def save(credentials)
          ensure_salt_loaded!
          json = JSON.generate({ credentials: credentials.map(&:to_h) })
          payload = @cipher.encrypt(json)

          if @v2
            raw  = File.binread(@path)
            header = raw[0, HEADER_SIZE_V2]
          else
            # Migrate old vault → new format on first save
            @v2 = true
            header = MAGIC_V2 + @salt + ("\x00" * SECURITY_SIZE) +
                     ("\x00" * RECOVERY_SIZE)
          end

          File.binwrite(@path, header + payload)
          File.chmod(FILE_MODE, @path)
        end

        class << self
          def reencrypt!(current_cipher, new_password,
                         questions_and_answers = nil, path = VAULT_PATH)
            storage = new(path, current_cipher)
            credentials = storage.load

            tmp_path = path + '.tmp'

            new_salt = KeyMaster.instance.generate_salt
            new_keys = KeyMaster.instance.derive_session_keys(
              new_password, new_salt)
            new_cipher = Cipher::AesGcm.new(new_keys[:vault_key])

            tmp_storage = new(tmp_path, new_cipher)

            if questions_and_answers
              qa = questions_and_answers
              qa[:vault_key] = new_keys[:vault_key]
              tmp_storage.create_new!(new_salt, qa)
            else
              tmp_storage.create_new!(new_salt)
            end
            tmp_storage.save(credentials)

            File.rename(tmp_path, path)
            File.chmod(FILE_MODE, path)
            clear_salt_cache!

            new_keys
          rescue OpenSSL::Cipher::CipherError => e
            raise Errors::AuthTagError, e.message
          ensure
            File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
          end
        end

        private

        def ensure_salt_loaded!
          return if @salt

          raw   = File.binread(@path)
          if raw.start_with?(MAGIC_V2) || raw.start_with?(MAGIC)
            @salt = raw[MAGIC_SIZE, SALT_LENGTH]
          else
            raise Errors::CorruptedDataError
          end
        end

        def build_security_data(questions)
          padded = Array.new(NUM_QUESTIONS) { |i|
            if i < questions.length
              q = questions[i]
              idx = [q[:index] || q['index'] || UNUSED_INDEX].pack('C')
              hash = Digest::SHA256.digest(
                q[:answer].to_s.strip.downcase
              )[0, 31]
              idx + hash
            else
              [UNUSED_INDEX].pack('C') + "\x00" * 31
            end
          }
          padded.join
        end

        def build_recovery_data(vault_key, answers)
          answer_key = self.class.send(:recovery_key_from_answers, answers)

          cipher = OpenSSL::Cipher.new('aes-256-gcm')
          cipher.encrypt
          cipher.key = answer_key
          iv = cipher.random_iv
          encrypted = cipher.update(vault_key) + cipher.final
          tag = cipher.auth_tag(TAG_BYTES)

          iv + tag + encrypted
        end

        def self.recovery_key_from_answers(answers)
          OpenSSL::Digest::SHA256.digest(
            answers.map { |a| a.to_s.strip.downcase }.join
          )
        end

        def self.constant_time_compare(a, b)
          return false unless a.bytesize == b.bytesize

          result = 0
          a.bytes.zip(b.bytes) { |x, y| result |= x ^ y }
          result.zero?
        end

        # ── backward-compat fallbacks to auth.dat ──

        def self.try_read_questions_from_authdat
          return [] unless File.exist?(Auth::AuthConfig::AUTH_PATH)

          Auth::AuthConfig.new.load_questions_text || []
        rescue StandardError
          []
        end

        def self.try_verify_via_authdat(answers)
          return false unless File.exist?(Auth::AuthConfig::AUTH_PATH)

          Auth::AuthConfig.new.verify_answers(answers)
        rescue StandardError
          false
        end

        def self.try_recover_via_authdat(answers)
          Auth::AuthConfig.new.recover(answers)
        rescue StandardError
          nil
        end

        private_class_method :recovery_key_from_answers, :constant_time_compare,
                             :try_read_questions_from_authdat,
                             :try_verify_via_authdat, :try_recover_via_authdat
      end
    end
  end
end
