# frozen_string_literal: true

#
# app/core/cipher/caesar.rb
# Responsibility: Caesar cipher — educational algorithm, NOT secure.
#   Operates on ASCII printable range 32..126 (95 characters).
#   Shift is circular: (code - 32 + shift) % 95 + 32.
#   Key is a numeric string parsed as Integer (e.g. '3').
#
# OOP pillar — INHERITANCE: extends Cipher::Base.
# OOP pillar — POLYMORPHISM: responds to encrypt/decrypt same as AesGcm.
#

require 'base64'
require_relative '../errors'
require_relative 'base'

module Enigma
  module Core
    module Cipher
      class Caesar < Base
        PRINTABLE_MIN = 32
        PRINTABLE_MAX = 126
        PRINTABLE_RANGE = PRINTABLE_MAX - PRINTABLE_MIN + 1 # 95

        private

        attr_reader :shift

        public

        # @param key [String] numeric shift value (e.g. '3')
        # @raise [Errors::InvalidKeyError] if key is not a valid integer string
        def initialize(key)
          raise Errors::InvalidKeyError, 'Key cannot be empty' if key.nil? || key.to_s.empty?

          @shift = Integer(key.to_s)
        rescue ArgumentError
          raise Errors::InvalidKeyError, "Key must be a numeric string, got '#{key}'"
        end

        # @return [Integer] 4 (byte size of integer representation)
        def key_size
          4
        end

        # @return [String] 'César'
        def algorithm_name
          "C\u00e9sar"
        end

        # Encrypt plaintext by shifting each printable character forward.
        #
        # @param data [String] plaintext
        # @return [String] Base64(shifted_bytes)
        def encrypt(data)
          shifted = data.bytes.map { |b| shift_byte(b, @shift) }.pack('C*')
          Base64.strict_encode64(shifted)
        end

        # Decrypt ciphertext by shifting each printable character backward.
        #
        # @param encoded [String] Base64 output from #encrypt
        # @return [String] plaintext
        # @raise [Errors::CorruptedDataError] on malformed input
        def decrypt(encoded)
          raw = Base64.strict_decode64(encoded)
          raw.bytes.map { |b| shift_byte(b, -@shift) }.pack('C*')
        rescue ArgumentError => e
          raise Errors::CorruptedDataError, "Invalid Base64: #{e.message}"
        end

        private

        # Circular shift a byte within the printable ASCII range.
        # Non-printable bytes (< 32) are passed through unchanged.
        #
        # @param byte [Integer] byte value
        # @param delta [Integer] shift amount
        # @return [Integer] shifted byte
        def shift_byte(byte, delta)
          return byte if byte < PRINTABLE_MIN

          ((byte - PRINTABLE_MIN + delta) % PRINTABLE_RANGE) + PRINTABLE_MIN
        end
      end
    end
  end
end
