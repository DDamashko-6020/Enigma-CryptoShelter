# frozen_string_literal: true

#
# app/core/vault/null_credential.rb
# Responsibility: Null Object for Credential — safe default when no credential is selected.
#   Responds to all Credential public methods with empty/placeholder values.
#   Eliminates nil-check conditionals in UI rendering.
#
# OOP pillar — POLYMORPHISM: NullCredential quacks like Credential.
# Pattern: Null Object
#

module Enigma
  module Core
    module Vault
      class NullCredential
        # @return [nil] no id
        def id
          nil
        end

        # @return [String] empty placeholder
        def site
          ''
        end

        # @return [String] empty placeholder
        def username
          ''
        end

        # @return [String] empty placeholder
        def password
          ''
        end

        # @return [String] empty placeholder
        def notes
          ''
        end

        # @return [String] empty placeholder
        def created_at
          ''
        end

        # @return [Hash] empty hash
        def to_h
          {}
        end

        # @return [true] identifies this as a null object
        def null?
          true
        end
      end
    end
  end
end
