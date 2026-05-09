# frozen_string_literal: true

#
# app/core/file_lock/unlocker.rb
# Responsibility: Reverse the double-layer .ultra decryption.
#   Layer 2 reverse: ChaCha20-Poly1305 with share_key
#   Layer 1 reverse: AES-256-GCM with filelock_key
#   Output: original file content (strips .ultra extension from path)
#
# Raises AuthTagError if either layer's authentication fails.
#
# Pattern: Composite — delegates layered decryption to LayeredCipher.
#

require 'digest'
require_relative '../cipher/aes_gcm'
require_relative '../cipher/chacha20'
require_relative '../cipher/layered_cipher'
require_relative '../key_master'

module Enigma
  module Core
    module FileLock
      class Unlocker
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

        # Decrypt a .ultra file restoring the original content.
        #
        # @param ultra_path [String] path to the .ultra file
        # @param output_path [String] path for decrypted output (default: strips .ultra)
        # @return [String] the output path
        # @raise [Errors::AuthTagError] if any decryption layer fails
        def unlock(ultra_path, output_path = nil)
          output_path ||= ultra_path.sub(/\.ultra$/, '')
          encrypted = File.binread(ultra_path)
          plain = @cipher.decrypt(encrypted)
          File.binwrite(output_path, plain)
          output_path
        end
      end
    end
  end
end
