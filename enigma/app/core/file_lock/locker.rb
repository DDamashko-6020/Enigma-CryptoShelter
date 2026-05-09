# frozen_string_literal: true

#
# app/core/file_lock/locker.rb
# Responsibility: Double-layer file encryption producing .ultra files.
#   Layer 1: AES-256-GCM with filelock_key (derived from master password)
#   Layer 2: ChaCha20-Poly1305 with share_key (user-provided second key)
#   Output: .ultra file (original_filename + '.ultra')
#
# Security: two independent AEAD layers using different algorithms and keys.
#   Breaking either layer requires breaking a separate cipher.
#
# Pattern: Composite — delegates layered encryption to LayeredCipher.
#

require 'digest'
require_relative '../cipher/aes_gcm'
require_relative '../cipher/chacha20'
require_relative '../cipher/layered_cipher'
require_relative '../key_master'

module Enigma
  module Core
    module FileLock
      class Locker
        # @param master_password [String] user's master password
        # @param share_key [String] user-provided second key (any length, SHA-256 derived)
        def initialize(master_password, share_key)
          km = KeyMaster.instance
          filelock_key = km.filelock_key(master_password)
          share_key_derived = Digest::SHA256.digest(share_key)

          @cipher = Cipher::LayeredCipher.new(
            Cipher::AesGcm.new(filelock_key),
            Cipher::Chacha20.new(share_key_derived)
          )
        end

        # Encrypt a file with double-layer protection.
        #
        # @param input_path [String] path to the original file
        # @param output_path [String] path for .ultra output (default: input + '.ultra')
        # @return [String] the output path
        def lock(input_path, output_path = nil)
          output_path ||= "#{input_path}.ultra"
          plain = File.binread(input_path)
          encrypted = @cipher.encrypt(plain)
          File.binwrite(output_path, encrypted)
          output_path
        end
      end
    end
  end
end
