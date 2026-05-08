module Enigma
  module Errors

    #-----------------------------------------------------
    # Error base de cifrado — nunca se lanza directamente,
    # se usan las subclases de abajo.
    #-----------------------------------------------------
    
    class CipherError < StandardError
      def initialize(msg = "Error de cifrado")
        super
      end
    end

    #------------------------------------------------------------
    # El auth_tag no coincide — el archivo fue manipulado
    # o la clave es incorrecta. Se lanza desde AesGcm y Chacha20.
    #------------------------------------------------------------
    
    class AuthTagError < CipherError
      def initialize(msg = "Auth tag inválido — archivo manipulado o clave incorrecta")
        super
      end
    end


    #----------------------------------------------------------------------------
    # La clave tiene formato inválido (vacía, muy corta, no numérica para César).
    # ---------------------------------------------------------------------------
    
    class InvalidKeyError < CipherError
      def initialize(msg = "Clave inválida")
        super
      end
    end


    #-------------------------------------------------------------
    # El texto cifrado está corrupto o tiene formato inesperado.
    # ------------------------------------------------------------
    
    class CorruptedDataError < CipherError
      def initialize(msg = "Datos corruptos o formato inválido")
        super
      end
    end

  end
end

