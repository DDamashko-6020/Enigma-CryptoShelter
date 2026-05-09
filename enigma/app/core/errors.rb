# frozen_string_literal: true

#
# app/core/errors.rb
# Responsibility: Define the complete error hierarchy for Enigma CryptoShelter.
#   CipherError and VaultError are the two root base classes.
#   All domain exceptions inherit from these, never from StandardError directly.
#

module Enigma
  module Errors
    # --- Base cipher error ---
    class CipherError < StandardError
    end

    # Raised when AEAD authentication tag verification fails.
    # Indicates wrong key OR file tampering.
    class AuthTagError < CipherError
    end

    # Raised when a key is empty, wrong format, or too short.
    class InvalidKeyError < CipherError
    end

    # Raised when ciphertext is malformed and cannot be decoded.
    class CorruptedDataError < CipherError
    end

    # --- Base vault error ---
    class VaultError < StandardError
    end

    # Raised when attempting an operation on a locked vault.
    class VaultLockedError < VaultError
    end

    # Raised when the .vault file does not exist on disk.
    class VaultNotFoundError < VaultError
    end

    # Raised when a credential ID is not found in the vault.
    class CredentialNotFoundError < VaultError
      attr_reader :id

      def initialize(id)
        @id = id
        super("Credential not found: #{id}")
      end
    end
  end
end
