# frozen_string_literal: true

#
# app/utils/file_handler.rb
# Responsibility: Low-level binary file I/O operations.
#   Always uses File.binread / File.binwrite for binary safety.
#   Sets restrictive permissions (0600) on written files.
#

require 'fileutils'

module Enigma
  module Utils
    class FileHandler
      FILE_PERMISSIONS = 0o600

      # @param path [String] file path
      # @return [String] binary content
      # @raise [Errno::ENOENT] if file not found
      def read(path)
        raise Errno::ENOENT, "File not found: #{path}" unless File.exist?(path)

        File.binread(path)
      end

      # Write binary data with restrictive permissions.
      #
      # @param path [String] output path
      # @param data [String] binary data
      def write(path, data)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.binwrite(path, data)
        File.chmod(FILE_PERMISSIONS, path)
      end

      # @param path [String] file path
      def delete(path)
        File.delete(path) if File.exist?(path)
      end

      # @param path [String] file path
      # @return [Boolean]
      def exist?(path)
        File.exist?(path)
      end
    end
  end
end
