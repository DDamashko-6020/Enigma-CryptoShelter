module Enigma
  module Core
    module Vault
      class Manager
        def initialize(storage, auto_load: true)
          @storage = storage
          @credentials = auto_load ? @storage.load : []
        end

        def all
          @credentials.dup
        end

        def find(id)
          @credentials.find { |c| c.id == id }
        end

        def search(query)
          q = query.downcase
          @credentials.select do |c|
            c.service.downcase.include?(q) ||
              c.username.downcase.include?(q) ||
              c.notes.downcase.include?(q)
          end
        end

        def add(credential)
          @credentials << credential
          persist!
          credential
        end

        def update(id, attributes)
          cred = find(id)
          raise VaultError, "Credential not found: #{id}" unless cred

          attributes.each do |key, value|
            cred.send(:"#{key}=", value) if cred.respond_to?(:"#{key}=")
          end
          cred.updated_at = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
          persist!
          cred
        end

        def delete(id)
          cred = find(id)
          raise VaultError, "Credential not found: #{id}" unless cred

          @credentials.delete(cred)
          persist!
          cred
        end

        def count
          @credentials.size
        end

        def clear!
          @credentials.clear
        end

        def locked?
          false
        end

        private

        def persist!
          @storage.save(@credentials)
        end
      end
    end
  end
end
