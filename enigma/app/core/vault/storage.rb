# frozen_string_literal: true

#
# app/core/vault/storage.rb
# Responsibility: File I/O for vault — magic, salt, encrypted JSON.
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

        MAGIC = "ENIGMA\x01".b.freeze

        def self.vault_exists?
          File.exist?(VAULT_PATH)
        end

        def self.read_salt(path = VAULT_PATH)
          raw = File.binread(path)
          raise Errors::CorruptedDataError unless raw.start_with?(MAGIC)

          raw[MAGIC.bytesize, 32]
        end

        SALT_LENGTH = 32

        def initialize(path, cipher)
          @path   = path
          @cipher = cipher
          @salt   = nil
        end

        def exists?
          File.exist?(@path)
        end

        def create_new!(salt)
          @salt = salt
          FileUtils.mkdir_p(VAULT_DIR, mode: DIR_MODE)
          payload = @cipher.encrypt(JSON.generate({ credentials: [] }))
          File.binwrite(@path, MAGIC + @salt + payload)
          File.chmod(FILE_MODE, @path)
        end

        def load
          raw = File.binread(@path)
          raise Errors::CorruptedDataError unless raw.start_with?(MAGIC)

          @salt = raw[MAGIC.bytesize, SALT_LENGTH]
          encrypted = raw[(MAGIC.bytesize + SALT_LENGTH)..]
          json = @cipher.decrypt(encrypted)
          JSON.parse(json)['credentials'].map { |h| Credential.from_h(h) }
        rescue OpenSSL::Cipher::CipherError => e
          raise Errors::AuthTagError, e.message
        end

        def save(credentials)
          ensure_salt_loaded!
          json = JSON.generate({ credentials: credentials.map(&:to_h) })
          File.binwrite(@path, MAGIC + @salt + @cipher.encrypt(json))
          File.chmod(FILE_MODE, @path)
        end

        private

        def ensure_salt_loaded!
          return if @salt

          raw   = File.binread(@path)
          @salt = raw[MAGIC.bytesize, SALT_LENGTH]
        end
      end
    end
  end
end
