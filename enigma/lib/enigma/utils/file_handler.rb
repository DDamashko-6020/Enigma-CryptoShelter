require 'fileutils'

module Enigma
  module Utils
    class FileHandler
      FILE_PERMISSIONS = 0600

      def read(path)
        raise Errno::ENOENT, "File not found: #{path}" unless File.exist?(path)
        File.binread(path)
      end

      def write(path, data)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.binwrite(path, data)
        File.chmod(FILE_PERMISSIONS, path)
      end

      def delete(path)
        File.delete(path) if File.exist?(path)
      end

      def exist?(path)
        File.exist?(path)
      end

      def size(path)
        File.size(path)
      end
    end
  end
end
