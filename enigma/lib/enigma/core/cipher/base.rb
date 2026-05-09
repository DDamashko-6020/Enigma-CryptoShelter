module Enigma
  module Core
    module Cipher
      class Base
        def encrypt(_data)
          raise NotImplementedError, "#{self.class} must implement #encrypt"
        end

        def decrypt(_data)
          raise NotImplementedError, "#{self.class} must implement #decrypt"
        end

        def encrypt_file(input_path, output_path)
          data = Enigma::Utils::FileHandler.new.read(input_path)
          encrypted = encrypt(data)
          Enigma::Utils::FileHandler.new.write(output_path, encrypted)
        end

        def decrypt_file(input_path, output_path)
          data = Enigma::Utils::FileHandler.new.read(input_path)
          decrypted = decrypt(data)
          Enigma::Utils::FileHandler.new.write(output_path, decrypted)
        end

        def name
          self.class.name.split('::').last.downcase
        end
      end
    end
  end
end
