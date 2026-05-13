# frozen_string_literal: true

#
# app/core/facades/file_lock_facade.rb
# Responsibility: Facade between UI and file_lock core.
#

module Enigma
  module Core
    module Facades
      class FileLockFacade
        def initialize
          @storage = Vault::Storage.new(Vault::Storage::VAULT_PATH, nil)
        end

        def vault_exists?
          @storage.exists?
        end

        def lock(file_path, filelock_key, share_key)
          FileLock::Locker.new(filelock_key, share_key).lock(file_path)
        end

        def unlock(ultra_path, filelock_key, share_key)
          FileLock::Unlocker.new(filelock_key, share_key).unlock(ultra_path)
        end
      end
    end
  end
end
