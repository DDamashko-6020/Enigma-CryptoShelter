#!/usr/bin/env ruby
require 'tk'
require 'tkextlib/tile'

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'cryptoshelter_app'

CryptoshelterApp.new.run
