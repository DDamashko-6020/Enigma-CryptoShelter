# frozen_string_literal: true

#
# app/core/key_master.rb
# Responsibility: Derive deterministic 32-byte keys from a master password
#   using SHA-256 with purpose-specific salts.
#
#   NEVER stores the master password in any instance variable.
#   Each call to vault_key or filelock_key derives fresh and returns immediately.
#
# Security notes:
#   - vault key ≠ filelock key (different salt per purpose)
#   - SHA-256 output is exactly 32 bytes, perfect for AES-256 / ChaCha20
#   - Master password never touches disk
#
# Pattern: Singleton — one KeyMaster instance per process.
#   Stateless: no instance variables, no mutable configuration.
#   Thread-safe: instance is created at class load time.
#

require 'digest'
require 'singleton'

module Enigma
  module Core
    class KeyMaster
      include Singleton

      VAULT_SALT = 'enigma_vault_v1'
      FILELOCK_SALT = 'enigma_filelock_v1'

      # Derive the vault encryption key.
      #
      # @param master_password [String] user-chosen master password
      # @return [String] 32-byte key (raw binary)
      def vault_key(master_password)
        Digest::SHA256.digest(master_password + VAULT_SALT)
      end

      # Derive the file lock encryption key.
      #
      # @param master_password [String] user-chosen master password
      # @return [String] 32-byte key (raw binary)
      def filelock_key(master_password)
        Digest::SHA256.digest(master_password + FILELOCK_SALT)
      end
    end
  end
end
