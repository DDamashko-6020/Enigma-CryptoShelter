module Enigma
  module Core
    module FileLock
      class Locker
        def initialize(cipher)
          @cipher = cipher
        end

        def lock(input_path, output_path = nil)
          output_path ||= input_path + '.enc'
          @cipher.encrypt_file(input_path, output_path)
          output_path
        end
      end
    end
  end
end
