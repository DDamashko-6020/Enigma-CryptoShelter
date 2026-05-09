# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'singleton'

module Enigma
  module Core
    class KeyMaster
      include Singleton

      ITERATIONS  = 600_000
      KEY_LENGTH  = 32
      DIGEST      = 'SHA256'
      SALT_LENGTH = 32

      def derive_vault_key(master_password, salt)
        pbkdf2(master_password, "#{salt}vault")
      end

      def derive_filelock_key(master_password, salt)
        pbkdf2(master_password, "#{salt}filelock")
      end

      def generate_salt
        SecureRandom.random_bytes(SALT_LENGTH)
      end

      private

      def pbkdf2(password, salt)
        OpenSSL::PKCS5.pbkdf2_hmac(
          password,
          salt,
          ITERATIONS,
          KEY_LENGTH,
          DIGEST
        )
      end
    end
  end
end
