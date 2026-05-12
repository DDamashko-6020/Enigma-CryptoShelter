#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tk'
require 'tkextlib/tile'
require 'ostruct'

# Parche para compatibilidad con frozen_string_literal en Tk 0.6.0 + Ruby 3.x
class TclTkIp
  alias _toUTF8_original _toUTF8
  def _toUTF8(str, enc = nil)
    str = str.dup if str.frozen?
    _toUTF8_original(str, enc)
  end
end

require_relative 'app/core'
require_relative 'utils/file_handler'
require_relative 'utils/validator'
require_relative 'utils/password_generator'
require_relative 'app/ui/theme'
require_relative 'app/ui/cryptoshelter_app'

Enigma::UI::CryptoshelterApp.new.run
