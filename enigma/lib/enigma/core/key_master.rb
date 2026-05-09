require 'securerandom'
require 'openssl'

module Enigma
  module Core
    class KeyMaster
      DEFAULT_ITERATIONS = 100_000
      SALT_SIZE = 32
      KEY_SIZE = 32

      def initialize(iterations: DEFAULT_ITERATIONS)
        @iterations = iterations
      end

      def generate_key(length = KEY_SIZE)
        SecureRandom.random_bytes(length)
      end

      def generate_salt(size = SALT_SIZE)
        SecureRandom.random_bytes(size)
      end

      def derive_key(password, salt, length = KEY_SIZE)
        OpenSSL::PKCS5.pbkdf2_hmac(
          password,
          salt,
          @iterations,
          length,
          OpenSSL::Digest::SHA256.new
        )
      end

      def generate_nonce(length = 12)
        SecureRandom.random_bytes(length)
      end
    end
  end
end
