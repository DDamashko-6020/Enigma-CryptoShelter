module Enigma
  module Core
    module Cipher
      class Caesar < Base
        def initialize(shift)
          @shift = shift
        end

        def encrypt(data)
          data.bytes.map { |b| shift_byte(b, @shift) }.pack('C*')
        end

        def decrypt(data)
          data.bytes.map { |b| shift_byte(b, -@shift) }.pack('C*')
        end

        private

        def shift_byte(byte, shift)
          case byte
          when 65..90
            ((byte - 65 + shift) % 26 + 65)
          when 97..122
            ((byte - 97 + shift) % 26 + 97)
          else
            byte
          end
        end
      end
    end
  end
end
