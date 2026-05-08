module Enigma
  module Errors

    # Error base del vault — nunca se lanza directamente.
    class VaultError < StandardError
      def initialize(msg = "Error del vault")
        super
      end
    end

    # Se intentó operar con el vault bloqueado.
    # Se lanza desde Manager cuando unlocked? == false.
    class VaultLockedError < VaultError
      def initialize(msg = "El vault está bloqueado")
        super
      end
    end

    # No existe el archivo .vault en disco.
    # Se lanza desde Storage#load cuando el archivo no existe.
    class VaultNotFoundError < VaultError
      def initialize(msg = "No existe un vault en este dispositivo")
        super
      end
    end

    # Una credencial con ese id no existe en el vault.
    # Se lanza desde Manager#update y Manager#delete.
    class CredentialNotFoundError < VaultError
      def initialize(id)
        super("Credencial no encontrada: #{id}")
      end
    end

  end
end