# frozen_string_literal: true

#
# app/utils/validator.rb
# Responsibility: Shared validation helpers used across core modules.
#   No business logic — pure validation utilities.
#

require_relative '../core/errors'

module Enigma
  module Utils
    class Validator
      # @param value [Object] value to check
      # @param name [String] field name for error message
      # @return [void]
      # @raise [Errors::InvalidKeyError] if value is nil or empty
      def not_empty(value, name)
        raise Enigma::Errors::InvalidKeyError, "#{name} cannot be empty" if value.nil? || value.to_s.empty?
      end
    end
  end
end
