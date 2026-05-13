# frozen_string_literal: true

#
# app/core/vault/manager.rb
# Responsibility: State machine for vault credentials (locked/unlocked).
#

require_relative '../errors/vault_error'
require_relative 'storage'
require_relative 'credential'

module Enigma
  module Core
    module Vault
      # Pattern: State
      class Manager
        LOCKED   = :locked
        UNLOCKED = :unlocked

        def initialize(storage)
          @storage     = storage
          @credentials = []
          @state       = LOCKED
        end

        def unlock
          @credentials = @storage.load
          @state       = UNLOCKED
        rescue Errors::AuthTagError
          @state = LOCKED
          raise
        end

        def lock
          @credentials = []
          @state       = LOCKED
        end

        def unlocked?
          @state == UNLOCKED
        end

        def add(site:, username:, password:, notes: '')
          require_unlocked!
          cred = Credential.new(site: site, username: username,
                                password: password, notes: notes)
          @credentials << cred
          persist!
          cred
        end

        def all
          require_unlocked!
          @credentials.dup
        end

        def find(query)
          require_unlocked!
          q = query.to_s.downcase
          @credentials.select do |c|
            c.site.downcase.include?(q) || c.username.downcase.include?(q)
          end
        end

        def update(id, **fields)
          require_unlocked!
          idx = find_index!(id)
          old = @credentials[idx]
          updated = Credential.new(
            id: old.id, created_at: old.created_at,
            updated_at: Time.now.iso8601,
            site:     fields.fetch(:site, old.site),
            username: fields.fetch(:username, old.username),
            password: fields.fetch(:password, old.password),
            notes:    fields.fetch(:notes, old.notes)
          )
          @credentials[idx] = updated
          persist!
          updated
        end

        def delete(id)
          require_unlocked!
          find_index!(id)
          @credentials.reject! { |c| c.id == id }
          persist!
        end

        def count
          @credentials.size
        end

        private

        def require_unlocked!
          raise Errors::VaultLockedError unless unlocked?
        end

        def find_index!(id)
          idx = @credentials.index { |c| c.id == id }
          raise Errors::CredentialNotFoundError, id if idx.nil?

          idx
        end

        def persist!
          @storage.save(@credentials)
        end
      end
    end
  end
end
