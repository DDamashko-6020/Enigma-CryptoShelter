require 'securerandom'
require 'json'

module Enigma
  module Core
    module Vault
      class Credential
        attr_accessor :id, :service, :username, :password, :notes, :created_at, :updated_at

        def initialize(service:, username:, password:, notes: '', id: nil)
          @id = id || SecureRandom.uuid
          @service = service
          @username = username
          @password = password
          @notes = notes
          @created_at = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
          @updated_at = @created_at
        end

        def to_h
          {
            id: @id,
            service: @service,
            username: @username,
            password: @password,
            notes: @notes,
            created_at: @created_at,
            updated_at: @updated_at
          }
        end

        def to_json(*args)
          to_h.to_json(*args)
        end

        def self.from_h(hash)
          cred = new(
            service: hash['service'],
            username: hash['username'],
            password: hash['password'],
            notes: hash['notes'] || '',
            id: hash['id']
          )
          cred.created_at = hash['created_at']
          cred.updated_at = hash['updated_at']
          cred
        end
      end
    end
  end
end
