require 'gtk3'

module Enigma
  module UI
    class FileLockPanel < Gtk::Box
      def initialize
        super(:vertical, 8)

        @cipher = nil
        build_ui
      end

      private

      def build_ui
        title = Gtk::Label.new
        title.markup = '<b>File Lock / Unlock</b>'
        pack_start(title, expand: false)

        key_box = Gtk::Box.new(:horizontal, 8)
        key_label = Gtk::Label.new('Password:')
        @key_entry = Gtk::Entry.new
        @key_entry.visibility = false
        key_box.pack_start(key_label, expand: false)
        key_box.pack_start(@key_entry, expand: true)
        pack_start(key_box, expand: false)

        file_box = Gtk::Box.new(:horizontal, 8)
        @file_path = Gtk::Entry.new
        @file_path.placeholder_text = 'File path...'
        browse_btn = Gtk::Button.new(label: 'Browse')
        browse_btn.signal_connect(:clicked) { browse_file }
        file_box.pack_start(@file_path, expand: true)
        file_box.pack_start(browse_btn, expand: false)
        pack_start(file_box, expand: false)

        button_box = Gtk::Box.new(:horizontal, 8)
        lock_btn = Gtk::Button.new(label: 'Lock (Encrypt)')
        lock_btn.signal_connect(:clicked) { do_lock }
        unlock_btn = Gtk::Button.new(label: 'Unlock (Decrypt)')
        unlock_btn.signal_connect(:clicked) { do_unlock }
        button_box.pack_start(lock_btn, expand: true)
        button_box.pack_start(unlock_btn, expand: true)
        pack_start(button_box, expand: false)

        @status_label = Gtk::Label.new('')
        pack_start(@status_label, expand: false)
      end

      def browse_file
        dialog = Gtk::FileChooserDialog.new(
          title: 'Select File',
          parent: nil,
          action: :open,
          buttons: [
            [Gtk::Stock::OPEN, :accept],
            [Gtk::Stock::CANCEL, :cancel]
          ]
        )
        if dialog.run == :accept
          @file_path.text = dialog.filename
        end
        dialog.destroy
      end

      def setup_cipher
        key = @key_entry.text
        raise 'Password cannot be empty' if key.empty?

        km = Enigma::Core::KeyMaster.new
        key_bytes = km.derive_key(key, 'enigma_file_salt')
        @cipher = Enigma::Core::Cipher::AESGCM.new(key_bytes)
      end

      def do_lock
        setup_cipher
        path = @file_path.text
        raise 'Select a file' if path.empty?

        locker = Enigma::Core::FileLock::Locker.new(@cipher)
        output = locker.lock(path)
        @status_label.text = "Locked: #{output}"
      rescue StandardError => e
        show_error(e.message)
      end

      def do_unlock
        setup_cipher
        path = @file_path.text
        raise 'Select a file' if path.empty?

        unlocker = Enigma::Core::FileLock::Unlocker.new(@cipher)
        output = unlocker.unlock(path)
        @status_label.text = "Unlocked: #{output}"
      rescue StandardError => e
        show_error(e.message)
      end

      def show_error(message)
        md = Gtk::MessageDialog.new(
          parent: nil, flags: :modal, type: :error,
          buttons: :close, message: message
        )
        md.run
        md.destroy
      end
    end
  end
end
