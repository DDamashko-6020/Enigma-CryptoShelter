#!/usr/bin/env ruby
require 'tk'
require 'tkextlib/tile'

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'enigma'
require 'enigma/ui/cryptoshelter_app'

Enigma::UI::CryptoshelterApp.new.run
