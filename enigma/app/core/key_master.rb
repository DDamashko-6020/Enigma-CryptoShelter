# frozen_string_literal: true

#
# app/core/key_master.rb
# Responsibility: PBKDF2 key derivation (Singleton).
#

require 'openssl'
require 'securerandom'
require 'singleton'

module Enigma
  module Core
    # Pattern: Singleton
    class KeyMaster
      include Singleton

      ITERATIONS    = 600_000
      KEY_LENGTH    = 32
      SALT_LENGTH   = 32
      DIGEST        = 'SHA256'
      VAULT_SALT    = 'enigma_vault_v1'
      FILELOCK_SALT = 'enigma_filelock_v1'

      # @param password [String] master password
      # @param salt [String] binary salt
      # @return [String] 32-byte vault key
      def derive_vault_key(password, salt)
        pbkdf2(password, salt + VAULT_SALT)
      end

      # @param password [String] master password
      # @param salt [String] binary salt
      # @return [String] 32-byte filelock key
      def derive_filelock_key(password, salt)
        pbkdf2(password, salt + FILELOCK_SALT)
      end

      # @return [String] 32 random bytes
      def generate_salt
        SecureRandom.random_bytes(SALT_LENGTH)
      end

      private

      def pbkdf2(password, salt)
        OpenSSL::PKCS5.pbkdf2_hmac(
          password, salt, ITERATIONS, KEY_LENGTH, DIGEST
        )
      end
    end
  end
end
