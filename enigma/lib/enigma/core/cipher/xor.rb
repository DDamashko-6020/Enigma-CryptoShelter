module Enigma
  module Core
    module Cipher
      class XOR < Base
        def initialize(key)
          raise ArgumentError, 'Key cannot be empty' if key.nil? || key.empty?
          @key = key
        end

        def encrypt(data)
          data.bytes.zip(@key.bytes.cycle).map { |b, k| (b ^ k).chr }.join
        end

        def decrypt(data)
          encrypt(data)
        end
      end
    end
  end
end
