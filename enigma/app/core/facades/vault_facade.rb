# frozen_string_literal: true

#
# app/core/facades/vault_facade.rb
# Responsibility: Facade between UI and vault core (create/open).
#

require 'json'

module Enigma
  module Core
    module Facades
      class VaultFacade
        def self.create(master_password)
          salt         = KeyMaster.instance.generate_salt
          vault_key    = KeyMaster.instance.derive_vault_key(master_password, salt)
          filelock_key = KeyMaster.instance.derive_filelock_key(master_password, salt)
          cipher       = Cipher::AesGcm.new(vault_key)
          storage      = Vault::Storage.new(Vault::Storage::VAULT_PATH, cipher)
          storage.create_new!(salt)
          manager = Vault::Manager.new(storage)
          manager.unlock
          { vault_key: vault_key, filelock_key: filelock_key, manager: manager }
        end

        def self.open(master_password)
          salt         = Vault::Storage.read_salt(Vault::Storage::VAULT_PATH)
          vault_key    = KeyMaster.instance.derive_vault_key(master_password, salt)
          filelock_key = KeyMaster.instance.derive_filelock_key(master_password, salt)
          cipher       = Cipher::AesGcm.new(vault_key)
          storage      = Vault::Storage.new(Vault::Storage::VAULT_PATH, cipher)
          manager      = Vault::Manager.new(storage)
          manager.unlock
          { vault_key: vault_key, filelock_key: filelock_key, manager: manager }
        rescue Errors::AuthTagError
          raise Errors::AuthTagError, 'Clave maestra incorrecta'
        end
      end
    end
  end
end
