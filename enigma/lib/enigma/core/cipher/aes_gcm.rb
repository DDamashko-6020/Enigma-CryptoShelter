require 'openssl'

module Enigma
  module Core
    module Cipher
      class AESGCM < Base
        def initialize(key)
          raise ArgumentError, 'Key must be 16, 24, or 32 bytes' unless [16, 24, 32].include?(key.bytesize)
          @key = key
        end

        def encrypt(data)
          cipher = OpenSSL::Cipher.new('aes-256-gcm')
          cipher.encrypt
          cipher.key = @key

          iv = cipher.random_iv
          cipher.auth_data = ''

          encrypted = cipher.update(data) + cipher.final
          tag = cipher.auth_tag

          iv + tag + encrypted
        end

        def decrypt(data)
          iv = data[0..11]
          tag = data[12..27]
          encrypted = data[28..]

          cipher = OpenSSL::Cipher.new('aes-256-gcm')
          cipher.decrypt
          cipher.key = @key
          cipher.iv = iv
          cipher.auth_tag = tag
          cipher.auth_data = ''

          cipher.update(encrypted) + cipher.final
        end
      end
    end
  end
end
