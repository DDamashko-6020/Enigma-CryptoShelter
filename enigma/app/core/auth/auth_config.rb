# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'openssl'
require 'securerandom'
require_relative '../key_master'

module Enigma
  module Core
    module Auth
      class AuthConfig
        AUTH_DIR      = File.expand_path('~/.enigma_cryptoshelter').freeze
        AUTH_FILENAME = 'auth.dat'
        AUTH_PATH     = File.join(AUTH_DIR, AUTH_FILENAME).freeze
        DIR_MODE      = 0o700
        FILE_MODE     = 0o600

        MAGIC      = "ENIGMA_AUTH\x01".b.freeze
        MAGIC_SIZE = MAGIC.bytesize
        SALT_SIZE  = 32
        HASH_SIZE  = 32

        def exists?
          File.exist?(AUTH_PATH)
        end

        def create!(master_password, questions)
          salt = SecureRandom.random_bytes(SALT_SIZE)
          verify_hash = derive_verify_hash(master_password, salt)

          payload = JSON.generate('questions' => questions)
          FileUtils.mkdir_p(AUTH_DIR, mode: DIR_MODE)
          File.binwrite(AUTH_PATH, MAGIC + salt + verify_hash + payload)
          File.chmod(FILE_MODE, AUTH_PATH)
        end

        def verify(master_password)
          return nil unless exists?

          raw = read_auth_file or return nil

          salt = raw[MAGIC_SIZE, SALT_SIZE]
          stored_hash = raw[MAGIC_SIZE + SALT_SIZE, HASH_SIZE]
          return nil unless stored_hash == derive_verify_hash(master_password, salt)

          { salt: salt, questions: load_questions_with_hashes }
        rescue StandardError
          nil
        end

        def load_questions_text
          questions = load_questions_with_hashes
          questions&.map { |q| q['q'] }
        end

        def load_questions_with_hashes
          raw = read_auth_file or return nil
          data = parse_auth_json(raw)
          (data['questions'] || []).map { |q| { 'q' => q['q'], 'h' => q['h'] } }
        rescue StandardError
          nil
        end

        def reset_master_password(new_password)
          raw = File.binread(AUTH_PATH)
          return false unless raw.start_with?(MAGIC)

          json_str = raw[(MAGIC_SIZE + SALT_SIZE + HASH_SIZE)..]

          new_salt = SecureRandom.random_bytes(SALT_SIZE)
          new_hash = derive_verify_hash(new_password, new_salt)

          FileUtils.mkdir_p(AUTH_DIR, mode: DIR_MODE)
          File.binwrite(AUTH_PATH, MAGIC + new_salt + new_hash + json_str)
          File.chmod(FILE_MODE, AUTH_PATH)
          true
        rescue StandardError
          false
        end

        private

        def read_auth_file
          return nil unless exists?

          raw = File.binread(AUTH_PATH)
          return nil unless raw.start_with?(MAGIC)

          raw
        end

        def parse_auth_json(raw)
          json_str = raw[(MAGIC_SIZE + SALT_SIZE + HASH_SIZE)..]
          JSON.parse(json_str)
        end

        def derive_verify_hash(password, salt)
          km = Core::KeyMaster.instance
          key = km.derive_vault_key(password, salt)
          OpenSSL::Digest::SHA256.digest(key)
        end
      end
    end
  end
end
