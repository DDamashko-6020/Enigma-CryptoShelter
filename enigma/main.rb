$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'enigma'
require 'enigma/ui'

Enigma::UI::MainWindow.new.run
