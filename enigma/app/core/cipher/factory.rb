# frozen_string_literal: true

#
# app/core/cipher/factory.rb
# Responsibility: Factory Method for creating cipher instances by algorithm name.
#   Centralizes all cipher instantiation — add a new cipher here, not in 5 files.
#
# OOP pillar — ABSTRACTION: callers depend on Cipher::Base, not on concrete classes.
# Pattern: Factory Method
#

require 'digest'
require_relative '../errors'
require_relative 'aes_gcm'
require_relative 'chacha20'
require_relative 'xor'
require_relative 'caesar'

module Enigma
  module Core
    module Cipher
      class Factory
        REGISTRY = {
          'AES-256-GCM' => AesGcm,
          'ChaCha20-Poly1305' => Chacha20,
          'XOR' => Xor,
          "C\u00e9sar" => Caesar
        }.freeze

        REGISTRY_LOWER = REGISTRY.transform_keys(&:downcase).freeze

        # Algorithms whose key must be exactly 32 bytes (derived via SHA-256).
        KEYS_DERIVED = %w[AES-256-GCM ChaCha20-Poly1305].freeze
        KEYS_DERIVED_LOWER = KEYS_DERIVED.map(&:downcase).freeze

        # Build a cipher instance from algorithm name and key material.
        # For AES-256-GCM and ChaCha20-Poly1305, derives 32-byte key via SHA-256.
        # For XOR and Caesar, uses the raw string directly.
        #
        # @param algorithm [String] algorithm name (case-insensitive)
        # @param key_material [String] user-provided key material (any length)
        # @return [Cipher::Base] ready-to-use cipher instance
        # @raise [Errors::InvalidKeyError] if algorithm is unknown
        def self.build(algorithm, key_material)
          normalized = algorithm.to_s.downcase
          klass = REGISTRY_LOWER[normalized]
          raise Errors::InvalidKeyError, "Unknown algorithm: #{algorithm}" unless klass

          key = if KEYS_DERIVED_LOWER.include?(normalized)
                  Digest::SHA256.digest(key_material.to_s)
                else
                  key_material.to_s
                end

          klass.new(key)
        end

        # List all available algorithm names (as displayed to the user).
        #
        # @return [Array<String>]
        def self.algorithms
          REGISTRY.keys
        end
      end
    end
  end
end
