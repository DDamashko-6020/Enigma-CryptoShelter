# frozen_string_literal: true

#
# app/core/vault/manager.rb
# Responsibility: Stateful CRUD manager for the credential vault.
#   States: LOCKED → UNLOCKED. All CRUD operations raise VaultLockedError
#   when locked. Unlock derives the cipher key and loads data.
#
# OOP pillar — ENCAPSULATION: credentials array is private,
#   returned as defensive copies.
#

require_relative '../errors'
require_relative '../key_master'
require_relative '../cipher/aes_gcm'
require_relative 'storage'
require_relative 'credential'

module Enigma
  module Core
    module Vault
      class Manager
        # @return [Boolean] vault unlock state
        attr_reader :unlocked

        # @param storage [Storage] persistence layer
        # @param key_master [KeyMaster] for deriving the vault key
        # @param master_password [String] user's master password
        def initialize(storage, key_master, master_password)
          @storage = storage
          @key_master = key_master
          @master_password = master_password.dup
          @credentials = []
          @unlocked = false
        end

        # Facade factory: build a Manager from a vault path and password.
        # Handles key derivation, cipher creation, storage wiring, and unlock.
        #
        # Pattern: Factory Method — encapsulates complex construction.
        #
        # @param vault_path [String] path to the .vault file
        # @param master_password [String] user's master password
        # @return [Manager] unlocked and ready to use
        # @raise [Errors::AuthTagError] if password is wrong
        def self.open(vault_path, master_password)
          km = KeyMaster.instance
          vault_key = km.vault_key(master_password)
          cipher = Cipher::AesGcm.new(vault_key)
          storage = Storage.new(vault_path, cipher)
          manager = new(storage, km, master_password)
          manager.unlock
          manager
        end

        # Unlock the vault: derive key, create cipher, load data.
        # Master password is zeroed after key derivation (memory safety).
        #
        # @raise [Errors::AuthTagError] if password is wrong
        # @raise [Errors::VaultNotFoundError] if .vault file missing
        def unlock
          key = @key_master.vault_key(@master_password)
          cipher = Cipher::AesGcm.new(key)
          @master_password.replace('')

          if @storage.exists?
            @credentials = @storage.load
          else
            @storage.create_new!
            @credentials = []
          end

          @unlocked = true
        end

        # Lock the vault: clear credentials from memory.
        def lock
          @credentials.clear
          @unlocked = false
        end

        # def unlocked? — use attr_reader :unlocked

        # @return [Array<Credential>] defensive copy of all credentials
        def all
          raise_locked unless @unlocked
          @credentials.dup
        end

        # Find credentials by partial, case-insensitive match on site, username, OR notes.
        #
        # @param query [String] search term
        # @return [Array<Credential>] matching credentials
        def find(query)
          raise_locked unless @unlocked

          q = query.downcase
          @credentials.select do |c|
            c.site.downcase.include?(q) || c.username.downcase.include?(q) || c.notes.downcase.include?(q)
          end
        end

        # Find a single credential by its UUID.
        #
        # @param id [String] credential UUID
        # @return [Credential, nil]
        def find_by_id(id)
          raise_locked unless @unlocked
          @credentials.find { |c| c.id == id }
        end

        # Alias for find (backward compatibility).
        alias search find

        # Add a new credential, persist, and return it.
        #
        # @overload add(site:, username:, password:, notes: '')
        # @overload add(credential)
        # @return [Credential] newly created credential
        def add(site: nil, username: nil, password: nil, notes: nil, credential: nil)
          raise_locked unless @unlocked

          if credential
            cred = credential
          else
            cred = Credential.new(site: site, username: username, password: password, notes: notes || '')
          end
          @credentials << cred
          persist!
          cred
        end

        # Update an existing credential by ID.
        # Creates a new Credential preserving id and created_at.
        #
        # @param id [String] credential UUID
        # @param fields [Hash] fields to update (site, username, password, notes)
        # @return [Credential] updated credential
        # @raise [Errors::CredentialNotFoundError] if id not found
        def update(id, **fields)
          raise_locked unless @unlocked

          idx = @credentials.index { |c| c.id == id }
          raise Errors::CredentialNotFoundError, id unless idx

          old = @credentials[idx]
          updated = Credential.new(
            site: fields[:site] || old.site,
            username: fields[:username] || old.username,
            password: fields[:password] || old.password,
            notes: fields.key?(:notes) ? fields[:notes] : old.notes,
            id: old.id,
            created_at: old.created_at
          )
          @credentials[idx] = updated
          persist!
          updated
        end

        # Delete a credential by ID.
        #
        # @param id [String] credential UUID
        # @raise [Errors::CredentialNotFoundError] if id not found
        def delete(id)
          raise_locked unless @unlocked

          cred = @credentials.find { |c| c.id == id }
          raise Errors::CredentialNotFoundError, id unless cred

          @credentials.delete(cred)
          persist!
        end

        # @return [Integer] number of stored credentials
        def count
          @credentials.size
        end

        # Clear all credentials without locking.
        def clear!
          @credentials.clear
        end

        private

        # Persist current credentials to storage.
        def persist!
          @storage.save(@credentials)
        end

        # @raise [Errors::VaultLockedError]
        def raise_locked
          raise Errors::VaultLockedError, 'Vault is locked. Call unlock first.'
        end
      end
    end
  end
end
