#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tk'
require 'tkextlib/tile'

require_relative 'app/core'
require_relative 'utils/file_handler'
require_relative 'utils/validator'
require_relative 'app/ui/theme'
require_relative 'app/ui/cryptoshelter_app'

Enigma::UI::CryptoshelterApp.new.run
