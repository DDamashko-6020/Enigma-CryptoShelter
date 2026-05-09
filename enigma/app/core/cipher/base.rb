# frozen_string_literal: true

#
# app/core/cipher/base.rb
# Responsibility: Abstract base class for all cipher algorithms.
#   Defines the contract (encrypt / decrypt / algorithm_name / key_size)
#   that every cipher subclass must implement.
#
# OOP pillar — ABSTRACTION: defines the interface, hides implementation.
# OOP pillar — INHERITANCE: all ciphers inherit from this class.
#

require_relative '../errors'

module Enigma
  module Core
    module Cipher
      class Base
        # @return [Integer] the expected key length in bytes
        def key_size
          raise NotImplementedError, "#{self.class} must implement #key_size"
        end

        # @return [String] human-readable algorithm identifier
        def algorithm_name
          raise NotImplementedError, "#{self.class} must implement #algorithm_name"
        end

        # Encrypt plaintext and return encoded ciphertext.
        #
        # @param data [String] plaintext to encrypt
        # @return [String] Base64-encoded ciphertext (includes IV + tag for AEAD)
        def encrypt(data)
          raise NotImplementedError, "#{self.class} must implement #encrypt"
        end

        # Decrypt encoded ciphertext back to plaintext.
        #
        # @param encoded [String] Base64-encoded ciphertext (output of #encrypt)
        # @return [String] decrypted plaintext
        def decrypt(encoded)
          raise NotImplementedError, "#{self.class} must implement #decrypt"
        end
      end
    end
  end
end
