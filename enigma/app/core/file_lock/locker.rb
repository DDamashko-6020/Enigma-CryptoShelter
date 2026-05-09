# frozen_string_literal: true

require 'digest'
require_relative '../cipher/aes_gcm'
require_relative '../cipher/chacha20'
require_relative '../cipher/layered_cipher'

module Enigma
  module Core
    module FileLock
      class Locker
        def initialize(filelock_key, share_key)
          share_key_derived = Digest::SHA256.digest(share_key)

          @cipher = Cipher::LayeredCipher.new(
            Cipher::AesGcm.new(filelock_key),
            Cipher::Chacha20.new(share_key_derived)
          )
        end

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
