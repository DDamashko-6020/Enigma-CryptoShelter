require 'gtk3'

module Enigma
  module UI
    class CipherPanel < Gtk::Box
      def initialize
        super(:vertical, 8)

        @available_ciphers = {
          'Caesar'  => ->(key) { Enigma::Core::Cipher::Caesar.new(key.to_i) },
          'XOR'     => ->(key) { Enigma::Core::Cipher::XOR.new(key) },
          'AES-GCM' => ->(key) {
            km = Enigma::Core::KeyMaster.new
            Enigma::Core::Cipher::AESGCM.new(km.derive_key(key, 'enigma_salt'))
          }
        }

        build_ui
      end

      private

      def build_ui
        title = Gtk::Label.new
        title.markup = '<b>Text Cipher</b>'
        pack_start(title, expand: false)

        @cipher_combo = Gtk::ComboBoxText.new
        @available_ciphers.each_key { |name| @cipher_combo.append_text(name) }
        @cipher_combo.active = 0
        pack_start(@cipher_combo, expand: false)

        @key_entry = Gtk::Entry.new
        @key_entry.placeholder_text = 'Key / Shift'
        pack_start(@key_entry, expand: false)

        @input_view = Gtk::TextView.new
        @input_view.buffer.text = ''
        input_scroll = Gtk::ScrolledWindow.new
        input_scroll.set_policy(:automatic, :automatic)
        input_scroll.add(@input_view)
        pack_start(input_scroll, expand: true)

        button_box = Gtk::Box.new(:horizontal, 8)
        encrypt_btn = Gtk::Button.new(label: 'Encrypt')
        encrypt_btn.signal_connect(:clicked) { do_encrypt }
        decrypt_btn = Gtk::Button.new(label: 'Decrypt')
        decrypt_btn.signal_connect(:clicked) { do_decrypt }
        button_box.pack_start(encrypt_btn, expand: true)
        button_box.pack_start(decrypt_btn, expand: true)
        pack_start(button_box, expand: false)

        @output_view = Gtk::TextView.new
        @output_view.editable = false
        output_scroll = Gtk::ScrolledWindow.new
        output_scroll.set_policy(:automatic, :automatic)
        output_scroll.add(@output_view)
        pack_start(output_scroll, expand: true)
      end

      def do_encrypt
        process(:encrypt)
      end

      def do_decrypt
        process(:decrypt)
      end

      def process(mode)
        cipher_name = @cipher_combo.active_text
        key = @key_entry.text
        input = @input_view.buffer.text

        if key.empty?
          show_error('Key is required')
          return
        end

        if input.empty?
          show_error('Input text is required')
          return
        end

        cipher_factory = @available_ciphers[cipher_name]
        cipher = cipher_factory.call(key)
        result = mode == :encrypt ? cipher.encrypt(input) : cipher.decrypt(input)
        @output_view.buffer.text = result
      rescue StandardError => e
        show_error(e.message)
      end

      def show_error(message)
        md = Gtk::MessageDialog.new(
          parent: nil,
          flags: :modal,
          type: :error,
          buttons: :close,
          message: message
        )
        md.run
        md.destroy
      end
    end
  end
end
