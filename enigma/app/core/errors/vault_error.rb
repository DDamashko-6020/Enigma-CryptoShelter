# frozen_string_literal: true

#
# app/core/errors/vault_error.rb
# Responsibility: VaultError hierarchy — all vault/storage exceptions.
#

module Enigma
  module Errors
    class VaultError < StandardError
      def initialize(msg = 'Error del vault')
        super(msg)
      end
    end

    class VaultLockedError < VaultError
      def initialize(msg = 'El vault est\u{e1} bloqueado')
        super(msg)
      end
    end

    class VaultNotFoundError < VaultError
      def initialize(msg = 'No existe un vault en este dispositivo')
        super(msg)
      end
    end

    class CredentialNotFoundError < VaultError
      def initialize(id)
        super("Credencial no encontrada: #{id}")
      end
    end
  end
end
