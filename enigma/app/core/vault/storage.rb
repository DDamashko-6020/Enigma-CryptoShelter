# frozen_string_literal: true

#
# app/core/vault/storage.rb
# Responsibility: Persistence layer for the credential vault.
#   Serializes credentials to JSON, encrypts with AES-256-GCM, writes to disk.
#   Vault file format: Base64(iv + auth_tag + JSON ciphertext).
#
# Security: the vault file is authenticated encryption.
#   Wrong key → AuthTagError on load. No silent failures.
#

require 'json'
require_relative '../errors'
require_relative 'credential'

module Enigma
  module Core
    module Vault
      class Storage
        # @param path [String] filesystem path to the .vault file
        # @param aes_cipher [Cipher::AesGcm] instance for encrypt/decrypt
        def initialize(path, aes_cipher)
          @path = path
          @cipher = aes_cipher
        end

        # @return [Boolean] whether the vault file exists on disk
        def exists?
          File.exist?(@path)
        end

        # Create a new empty vault file.
        # Raises VaultNotFoundError if file already exists (safety guard).
        #
        # @raise [Errors::VaultNotFoundError] if vault already exists
        def create_new!
          raise Errors::VaultNotFoundError, 'Vault already exists' if exists?

          save([])
        end

        # Load and decrypt all credentials from the vault file.
        #
        # @return [Array<Credential>] decrypted credentials
        # @raise [Errors::VaultNotFoundError] if file is missing
        # @raise [Errors::AuthTagError] if decryption key is wrong
        def load
          raise Errors::VaultNotFoundError, "Vault not found: #{@path}" unless exists?

          raw = File.binread(@path)
          json = @cipher.decrypt(raw)
          data = JSON.parse(json)
          credentials = data['credentials'] || []
          credentials.map { |h| Credential.from_h(h) }
        end

        # Encrypt and write credentials to the vault file.
        #
        # @param credentials [Array<Credential>]
        def save(credentials)
          data = JSON.generate({ 'credentials' => credentials.map(&:to_h) })
          encrypted = @cipher.encrypt(data)
          File.binwrite(@path, encrypted)
        end
      end
    end
  end
end
