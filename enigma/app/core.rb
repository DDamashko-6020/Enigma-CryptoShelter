# frozen_string_literal: true

#
# app/core.rb
# Responsibility: Central require orchestrator for all core modules.
#   Single entry point: 'require_relative 'core' loads every core file.
#   Load order follows dependency graph (no circular requires).
#

# --- Errors (level 0, no dependencies) ---
require_relative 'core/errors'

# --- Ciphers (level 1, depend on errors) ---
require_relative 'core/cipher/base'
require_relative 'core/cipher/aes_gcm'
require_relative 'core/cipher/chacha20'
require_relative 'core/cipher/xor'
require_relative 'core/cipher/caesar'
require_relative 'core/cipher/layered_cipher'
require_relative 'core/cipher/factory'

# --- Key Master (level 2, depends on Digest) ---
require_relative 'core/key_master'

# --- Vault (level 3, depends on ciphers + key_master) ---
require_relative 'core/vault/credential'
require_relative 'core/vault/null_credential'
require_relative 'core/vault/storage'
require_relative 'core/vault/manager'

# --- File Lock (level 4, depends on ciphers + key_master) ---
require_relative 'core/file_lock/locker'
require_relative 'core/file_lock/unlocker'
