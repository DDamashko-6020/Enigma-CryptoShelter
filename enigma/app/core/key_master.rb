# frozen_string_literal: true

#
# app/core/key_master.rb
# Single-pass key derivation following KeePass architecture.
# ONE PBKDF2 call → master_key → HKDF expansion → purpose keys.
# master_key never stored or returned.
#
# Pattern: Singleton
# Pattern: Factory Method (derive_* methods)
#

require 'openssl'
require 'securerandom'
require 'singleton'

module Enigma
  module Core
    class KeyMaster
      include Singleton

      ITERATIONS  = ENV.fetch('ENIGMA_PBKDF2_ITER', '600000').to_i
      KEY_LENGTH  = 32
      SALT_LENGTH = 32
      DIGEST      = 'SHA256'

      VAULT_INFO    = 'enigma_vault_v1'
      FILELOCK_INFO = 'enigma_filelock_v1'

      def derive_session_keys(master_password, salt)
        master_key = pbkdf2(master_password, salt)

        result = {
          vault_key: hkdf_expand(master_key, VAULT_INFO),
          filelock_key: hkdf_expand(master_key, FILELOCK_INFO)
        }

        master_key.replace("\x00" * KEY_LENGTH)
        nil

        result
      end

      def generate_salt
        SecureRandom.random_bytes(SALT_LENGTH)
      end

      private

      def pbkdf2(password, salt)
        OpenSSL::PKCS5.pbkdf2_hmac(
          password, salt, ITERATIONS, KEY_LENGTH, DIGEST
        )
      end

      def hkdf_expand(master_key, info)
        OpenSSL::HMAC.digest(DIGEST, master_key, "#{info}\u0001")[0, KEY_LENGTH]
      end
    end
  end
end
