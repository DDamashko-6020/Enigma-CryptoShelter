module Enigma
  module Core
    module FileLock
      class Unlocker
        def initialize(cipher)
          @cipher = cipher
        end

        def unlock(input_path, output_path = nil)
          output_path ||= input_path.sub(/\.enc$/, '.dec')
          @cipher.decrypt_file(input_path, output_path)
          output_path
        end
      end
    end
  end
end
