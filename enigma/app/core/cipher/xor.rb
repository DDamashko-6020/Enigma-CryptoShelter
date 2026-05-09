# frozen_string_literal: true

#
# app/core/cipher/xor.rb
# Responsibility: XOR cipher — educational algorithm, NOT secure.
#   Key is repeated cyclically over plaintext bytes.
#   Encrypt and decrypt are the same operation (XOR is symmetric).
#   Output: Base64(xor_result). No authentication tag.
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
      class Xor < Base
        private

        attr_reader :key

        public

        # @param key [String] encryption key (any length, repeated cyclically)
        # @raise [Errors::InvalidKeyError] if key is empty
        def initialize(key)
          raise Errors::InvalidKeyError, 'Key cannot be empty' if key.nil? || key.empty?

          @key = key
        end

        # @return [Integer] key.bytesize
        def key_size
          @key.bytesize
        end

        # @return [String] 'XOR'
        def algorithm_name
          'XOR'
        end

        # XOR-encrypt plaintext.
        # Same operation as decrypt (XOR is symmetric).
        #
        # @param data [String] plaintext
        # @return [String] Base64(xor_bytes)
        def encrypt(data)
          xored = xor_bytes(data)
          Base64.strict_encode64(xored)
        end

        # XOR-decrypt ciphertext.
        # Same operation as encrypt (XOR is symmetric).
        #
        # @param encoded [String] Base64 output from #encrypt
        # @return [String] plaintext
        # @raise [Errors::CorruptedDataError] on malformed input
        def decrypt(encoded)
          raw = Base64.strict_decode64(encoded)
          xor_bytes(raw)
        rescue ArgumentError => e
          raise Errors::CorruptedDataError, "Invalid Base64: #{e.message}"
        end

        private

        # Core XOR operation: each byte of data XOR'd with cycling key byte.
        #
        # @param data [String] binary string
        # @return [String] xor-transformed binary string
        def xor_bytes(data)
          key_bytes = @key.bytes
          key_len = key_bytes.length
          data.bytes.each_with_index.map do |byte, i|
            byte ^ key_bytes[i % key_len]
          end.pack('C*')
        end
      end
    end
  end
end
