# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../errors'
require_relative 'credential'

module Enigma
  module Core
    module Vault
      class Storage
        VAULT_DIR      = File.expand_path('~/.enigma_cryptoshelter').freeze
        VAULT_FILENAME = 'vault.dat'
        VAULT_PATH     = File.join(VAULT_DIR, VAULT_FILENAME).freeze
        DIR_MODE       = 0o700
        FILE_MODE      = 0o600

        MAGIC      = "ENIGMA\x01".b.freeze
        MAGIC_SIZE = MAGIC.bytesize
        SALT_SIZE  = 32

        def exists?
          File.exist?(VAULT_PATH)
        end

        def create_new!(salt, encrypted_payload)
          raise Errors::VaultNotFoundError, 'Vault already exists' if exists?

          FileUtils.mkdir_p(VAULT_DIR, mode: DIR_MODE)
          File.binwrite(VAULT_PATH, build_file(salt, encrypted_payload))
          File.chmod(FILE_MODE, VAULT_PATH)
        end

        def load
          raise Errors::VaultNotFoundError, "Vault not found: #{VAULT_PATH}" unless exists?

          raw = File.binread(VAULT_PATH)
          salt, payload = parse_file(raw)
          [salt, payload]
        end

        def save(salt, encrypted_payload)
          FileUtils.mkdir_p(VAULT_DIR, mode: DIR_MODE)
          File.binwrite(VAULT_PATH, build_file(salt, encrypted_payload))
          File.chmod(FILE_MODE, VAULT_PATH)
        end

        def build_file(salt, encrypted_payload)
          MAGIC + salt + encrypted_payload
        end

        def parse_file(raw_bytes)
          raise Errors::CorruptedDataError, 'Invalid vault file' unless raw_bytes.start_with?(MAGIC)

          salt    = raw_bytes[MAGIC_SIZE, SALT_SIZE]
          payload = raw_bytes[(MAGIC_SIZE + SALT_SIZE)..]
          [salt, payload]
        end
      end
    end
  end
end
