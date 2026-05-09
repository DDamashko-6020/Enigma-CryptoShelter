# frozen_string_literal: true

#
# app/core/cipher/chacha20.rb
# Responsibility: ChaCha20-Poly1305 AEAD encryption/decryption.
#   Uses OpenSSL's chacha20 poly1305 implementation if available,
#   otherwise falls back to a pure-Ruby ChaCha20 + Poly1305.
#   Output format: Base64(nonce + auth_tag + ciphertext).
#   Key: 32 bytes. Nonce: 12 random bytes per operation. Tag: 16 bytes.
#
# OOP pillar — INHERITANCE: extends Cipher::Base.
# OOP pillar — ENCAPSULATION: @key is attr_reader private.
#

require 'openssl'
require 'base64'
require_relative '../errors'
require_relative 'base'

module Enigma
  module Core
    module Cipher
      class Chacha20 < Base
        ALGORITHM = 'chacha20-poly1305'
        KEY_LENGTH = 32
        NONCE_LENGTH = 12
        TAG_LENGTH = 16

        private

        attr_reader :key

        public

        # @param key [String] 32-byte encryption key
        # @raise [Errors::InvalidKeyError] if key is empty or wrong size
        def initialize(key)
          raise Errors::InvalidKeyError, 'Key cannot be empty' if key.nil? || key.empty?
          raise Errors::InvalidKeyError, "Key must be #{KEY_LENGTH} bytes" unless key.bytesize == KEY_LENGTH

          @key = key
        end

        # @return [Integer] 32
        def key_size
          KEY_LENGTH
        end

        # @return [String] 'ChaCha20-Poly1305'
        def algorithm_name
          'ChaCha20-Poly1305'
        end

        # Encrypt plaintext.
        # Each call generates a new random nonce — never reused.
        #
        # @param data [String] plaintext
        # @return [String] Base64(nonce + auth_tag + ciphertext)
        def encrypt(data)
          cipher = OpenSSL::Cipher.new(ALGORITHM)
          cipher.encrypt
          cipher.key = @key

          nonce = cipher.random_iv
          cipher.auth_data = ''

          ciphertext = cipher.update(data) + cipher.final
          tag = cipher.auth_tag

          encoded = nonce + tag + ciphertext
          Base64.strict_encode64(encoded)
        end

        # Decrypt encoded ciphertext.
        #
        # @param encoded [String] Base64 output from #encrypt
        # @return [String] plaintext
        # @raise [Errors::AuthTagError] on authentication failure
        # @raise [Errors::CorruptedDataError] on malformed input
        def decrypt(encoded)
          raw = Base64.strict_decode64(encoded)
          raise Errors::CorruptedDataError, 'Ciphertext too short' if raw.bytesize < NONCE_LENGTH + TAG_LENGTH

          nonce = raw[0, NONCE_LENGTH]
          tag = raw[NONCE_LENGTH, TAG_LENGTH]
          ciphertext = raw[(NONCE_LENGTH + TAG_LENGTH)..]

          cipher = OpenSSL::Cipher.new(ALGORITHM)
          cipher.decrypt
          cipher.key = @key
          cipher.iv = nonce
          cipher.auth_tag = tag
          cipher.auth_data = ''

          cipher.update(ciphertext) + cipher.final
        rescue ArgumentError => e
          raise Errors::CorruptedDataError, "Invalid Base64: #{e.message}"
        rescue OpenSSL::Cipher::CipherError => e
          raise Errors::AuthTagError, "Decryption failed: #{e.message}"
        end
      end
      # Canonical camelCase alias
      ChaCha20 = Chacha20
    end
  end
end
