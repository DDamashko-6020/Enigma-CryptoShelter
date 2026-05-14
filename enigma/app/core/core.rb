# frozen_string_literal: true

#
# app/core/core.rb
# Responsibility: Central require orchestrator for all core modules.
#

# --- Errors (no dependencies) ---
require_relative 'errors/cipher_error'
require_relative 'errors/vault_error'

# --- Ciphers (depend on cipher_error) ---
require_relative 'cipher/base'
require_relative 'cipher/aes_gcm'
require_relative 'cipher/chacha20'
require_relative 'cipher/xor'
require_relative 'cipher/caesar'
require_relative 'cipher/factory'

# --- KeyMaster (depends on OpenSSL stdlib) ---
require_relative 'key_master'

# --- Vault (depends on ciphers + errors) ---
require_relative 'vault/null_credential'
require_relative 'vault/credential'
require_relative 'vault/storage'
require_relative 'vault/manager'

# --- File Lock (depends on ciphers) ---
require_relative 'file_lock/locker'
require_relative 'file_lock/unlocker'

# --- Auth (security questions, password recovery) ---
require_relative 'auth/auth_config'

# --- Facades (bridges core → UI) ---
require_relative 'facades/vault_facade'
require_relative 'facades/cipher_facade'
require_relative 'facades/file_lock_facade'
