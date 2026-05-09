require 'gtk3'

module Enigma
  module UI
    class MainWindow < Gtk::Window
      def initialize
        super

        set_title "Enigma #{Enigma::VERSION}"
        set_default_size 900, 600
        signal_connect(:destroy) { Gtk.main_quit }

        @notebook = Gtk::Notebook.new
        @notebook.append_page(CipherPanel.new, Gtk::Label.new('Cipher'))
        @notebook.append_page(FileLockPanel.new, Gtk::Label.new('File Lock'))
        @notebook.append_page(VaultPanel.new, Gtk::Label.new('Vault'))

        add(@notebook)
      end

      def run
        show_all
        Gtk.main
      end
    end
  end
end
