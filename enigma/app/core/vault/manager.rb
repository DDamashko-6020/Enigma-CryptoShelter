# frozen_string_literal: true

require 'json'
require_relative '../errors'
require_relative '../key_master'
require_relative '../cipher/aes_gcm'
require_relative 'storage'
require_relative 'credential'

module Enigma
  module Core
    module Vault
      class Manager
        attr_reader :unlocked

        def initialize(storage, key_master, master_password)
          @storage = storage
          @key_master = key_master
          @master_password = master_password.dup
          @credentials = []
          @unlocked = false
        end

        def self.open(master_password)
          km = KeyMaster.instance
          storage = Storage.new
          manager = new(storage, km, master_password)
          manager.unlock
          manager
        end

        def unlock
          if @storage.exists?
            salt, encrypted = @storage.load
            key = @key_master.derive_vault_key(@master_password, salt)
            @cipher = Cipher::AesGcm.new(key)
            json = @cipher.decrypt(encrypted)
            data = JSON.parse(json)
            @credentials = (data['credentials'] || []).map { |h| Credential.from_h(h) }
          else
            salt = @key_master.generate_salt
            key = @key_master.derive_vault_key(@master_password, salt)
            @cipher = Cipher::AesGcm.new(key)
            empty_encrypted = @cipher.encrypt(JSON.generate({ 'credentials' => [] }))
            @storage.create_new!(salt, empty_encrypted)
            @credentials = []
          end

          @master_password.replace('')
          @salt = salt
          @unlocked = true
        end

        def lock
          @credentials.clear
          @cipher = nil
          @salt = nil
          @unlocked = false
        end

        def all
          raise_locked unless @unlocked
          @credentials.dup
        end

        def find(query)
          raise_locked unless @unlocked

          q = query.downcase
          @credentials.select do |c|
            c.site.downcase.include?(q) || c.username.downcase.include?(q) || c.notes.downcase.include?(q)
          end
        end

        def find_by_id(id)
          raise_locked unless @unlocked
          @credentials.find { |c| c.id == id }
        end

        alias search find

        def add(site: nil, username: nil, password: nil, notes: nil, credential: nil)
          raise_locked unless @unlocked

          cred = credential || Credential.new(site: site, username: username, password: password, notes: notes || '')
          @credentials << cred
          persist!
          cred
        end

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

        def delete(id)
          raise_locked unless @unlocked

          cred = @credentials.find { |c| c.id == id }
          raise Errors::CredentialNotFoundError, id unless cred

          @credentials.delete(cred)
          persist!
        end

        def count
          @credentials.size
        end

        def clear!
          @credentials.clear
        end

        private

        def persist!
          data = JSON.generate({ 'credentials' => @credentials.map(&:to_h) })
          encrypted = @cipher.encrypt(data)
          @storage.save(@salt, encrypted)
        end

        def raise_locked
          raise Errors::VaultLockedError, 'Vault is locked. Call unlock first.'
        end
      end
    end
  end
end
