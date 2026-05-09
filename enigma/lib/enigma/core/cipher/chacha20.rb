require 'openssl'

module Enigma
  module Core
    module Cipher
      class ChaCha20 < Base
        def initialize(key)
          raise ArgumentError, 'Key must be 32 bytes' unless key.bytesize == 32
          @key = key
        end

        def encrypt(data)
          cipher = OpenSSL::Cipher.new('chacha20')
          cipher.encrypt
          cipher.key = @key
          cipher.update(data) + cipher.final
        end

        def decrypt(data)
          cipher = OpenSSL::Cipher.new('chacha20')
          cipher.decrypt
          cipher.key = @key
          cipher.update(data) + cipher.final
        end
      end
    end
  end
end
