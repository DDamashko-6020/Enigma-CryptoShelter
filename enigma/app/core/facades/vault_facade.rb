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
          salt = KeyMaster.instance.generate_salt
          keys = KeyMaster.instance.derive_session_keys(master_password, salt)

          cipher  = Cipher::AesGcm.new(keys[:vault_key])
          storage = Vault::Storage.new(Vault::Storage::VAULT_PATH, cipher)
          storage.create_new!(salt)
          manager = Vault::Manager.new(storage)
          manager.unlock

          keys.merge(manager: manager)
        end

        def self.open(master_password)
          salt = Vault::Storage.read_salt(Vault::Storage::VAULT_PATH)
          keys = KeyMaster.instance.derive_session_keys(master_password, salt)

          cipher  = Cipher::AesGcm.new(keys[:vault_key])
          storage = Vault::Storage.new(Vault::Storage::VAULT_PATH, cipher)
          manager = Vault::Manager.new(storage)
          manager.unlock

          keys.merge(manager: manager)
        rescue Errors::AuthTagError
          raise Errors::AuthTagError, 'Clave maestra incorrecta'
        end
      end
    end
  end
end
