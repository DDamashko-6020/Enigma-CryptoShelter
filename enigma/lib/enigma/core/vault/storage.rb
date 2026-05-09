require 'json'
require 'openssl'

module Enigma
  module Core
    module Vault
      class Storage
        def initialize(path, password)
          @path = path
          @password = password
          @salt = nil
          @key_master = Enigma::Core::KeyMaster.new
          @file_handler = Enigma::Utils::FileHandler.new
        end

        def save(credentials)
          data = JSON.pretty_generate(credentials.map(&:to_h))
          ensure_salt
          key = @key_master.derive_key(@password, @salt)
          cipher = Enigma::Core::Cipher::AESGCM.new(key)
          encrypted = cipher.encrypt(data)
          @file_handler.write(@path, @salt + encrypted)
        end

        def load
          return [] unless @file_handler.exist?(@path)

          raw = @file_handler.read(@path)
          if raw.bytesize < Enigma::Core::KeyMaster::SALT_SIZE
            raise Enigma::Core::VaultError, 'Vault file corrupted'
          end

          @salt = raw[0...Enigma::Core::KeyMaster::SALT_SIZE]
          encrypted = raw[Enigma::Core::KeyMaster::SALT_SIZE..-1]
          key = @key_master.derive_key(@password, @salt)
          cipher = Enigma::Core::Cipher::AESGCM.new(key)
          data = cipher.decrypt(encrypted)
          JSON.parse(data).map { |h| Credential.from_h(h) }
        rescue OpenSSL::Cipher::CipherError
          raise Enigma::Core::VaultError, 'Wrong master password or corrupted vault'
        rescue JSON::ParserError, TypeError, NoMethodError
          raise Enigma::Core::VaultError, 'Vault file corrupted'
        end

        def exist?
          @file_handler.exist?(@path)
        end

        private

        def ensure_salt
          return if @salt

          if @file_handler.exist?(@path)
            raw = @file_handler.read(@path)
            if raw && raw.bytesize >= Enigma::Core::KeyMaster::SALT_SIZE
              @salt = raw[0...Enigma::Core::KeyMaster::SALT_SIZE]
            end
          end

          @salt ||= @key_master.generate_salt
        end
      end
    end
  end
end
