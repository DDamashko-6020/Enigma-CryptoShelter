# frozen_string_literal: true

#
# app/core/cipher/layered_cipher.rb
# Responsibility: Compose multiple ciphers into a single encrypt/decrypt pipeline.
#   Encrypt applies each cipher in order. Decrypt applies them in reverse.
#   Behaves exactly like any Cipher::Base — polymorphic with single ciphers.
#
# OOP pillar — POLYMORPHISM: LayeredCipher is-a Cipher::Base, usable anywhere
#   a single cipher is expected.
# OOP pillar — COMPOSITION: layers are injected, not hardcoded.
# Pattern: Composite
#

require_relative 'base'

module Enigma
  module Core
    module Cipher
      class LayeredCipher < Base
        # @param ciphers [Array<Cipher::Base>] ordered list of cipher layers
        def initialize(*ciphers)
          raise Errors::InvalidKeyError, 'At least one cipher required' if ciphers.empty?

          @ciphers = ciphers
        end

        # Apply each cipher layer in sequence to encrypt.
        #
        # @param data [String] plaintext
        # @return [String] ciphertext (output of the last layer)
        def encrypt(data)
          @ciphers.reduce(data) { |d, cipher| cipher.encrypt(d) }
        end

        # Apply each cipher layer in reverse sequence to decrypt.
        #
        # @param encoded [String] ciphertext from #encrypt
        # @return [String] plaintext
        def decrypt(encoded)
          @ciphers.reverse.reduce(encoded) { |d, cipher| cipher.decrypt(d) }
        end

        # @return [String] concatenated algorithm names (e.g. 'AES-256-GCM + ChaCha20-Poly1305')
        def algorithm_name
          @ciphers.map(&:algorithm_name).join(' + ')
        end

        # @return [Integer] sum of all layer key sizes
        def key_size
          @ciphers.sum(&:key_size)
        end
      end
    end
  end
end
