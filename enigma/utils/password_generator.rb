# frozen_string_literal: true

require 'securerandom'

module Enigma
  module Utils
    class PasswordGenerator
      LOWERCASE = ('a'..'z').to_a.freeze
      UPPERCASE = ('A'..'Z').to_a.freeze
      DIGITS    = ('0'..'9').to_a.freeze
      SYMBOLS   = %w[! @ # $ % ^ & * ( ) - _ = + [ ] { } | ; : , . ?].freeze
      ALL       = (LOWERCASE + UPPERCASE + DIGITS + SYMBOLS).freeze

      def self.generate(length: 20, symbols: true)
        charset = symbols ? ALL : (LOWERCASE + UPPERCASE + DIGITS)
        Array.new(length) { charset[SecureRandom.random_number(charset.size)] }
             .then { |chars| ensure_complexity(chars, symbols) }
             .shuffle
             .join
      end

      def self.ensure_complexity(chars, symbols)
        chars[0] = UPPERCASE.sample(random: SecureRandom)
        chars[1] = DIGITS.sample(random: SecureRandom)
        chars[2] = SYMBOLS.sample(random: SecureRandom) if symbols
        chars
      end
      private_class_method :ensure_complexity
    end
  end
end
