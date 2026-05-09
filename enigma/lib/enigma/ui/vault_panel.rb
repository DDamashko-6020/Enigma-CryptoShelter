require 'gtk3'

module Enigma
  module UI
    class VaultPanel < Gtk::Box
      def initialize
        super(:vertical, 8)

        @vault_path = File.join(Dir.home, '.enigma_vault')
        @vault_manager = nil
        @clipboard_timer = nil

        @stack = Gtk::Stack.new
        @stack.transition_type = :crossfade

        build_lock_page
        build_vault_page

        pack_start(@stack, expand: true)
        @stack.visible_child_name = 'lock'
      end

      private

      def build_lock_page
        page = Gtk::Box.new(:vertical, 12)
        page.set_valign(:center)
        page.set_halign(:center)

        title = Gtk::Label.new
        title.markup = '<b>Vault Locked</b>'
        page.pack_start(title, expand: false)

        desc = Gtk::Label.new('Enter your master password to access the vault')
        page.pack_start(desc, expand: false)

        unlock_btn = Gtk::Button.new(label: 'Unlock Vault')
        unlock_btn.signal_connect(:clicked) do
          if File.exist?(@vault_path)
            show_unlock_dialog
          else
            show_create_dialog
          end
        end
        page.pack_start(unlock_btn, expand: false)

        @stack.add_named(page, 'lock')
      end

      def build_vault_page
        page = Gtk::Box.new(:vertical, 8)

        title = Gtk::Label.new
        title.markup = '<b>Credential Vault</b>'
        page.pack_start(title, expand: false)

        toolbar = Gtk::Box.new(:horizontal, 6)
        add_btn = Gtk::Button.new(label: 'Add')
        add_btn.signal_connect(:clicked) { show_add_dialog }
        refresh_btn = Gtk::Button.new(label: 'Refresh')
        refresh_btn.signal_connect(:clicked) { refresh_list }
        lock_btn = Gtk::Button.new(label: 'Lock')
        lock_btn.signal_connect(:clicked) { lock_vault }
        toolbar.pack_start(add_btn, expand: false)
        toolbar.pack_start(refresh_btn, expand: false)
        toolbar.pack_start(lock_btn, expand: false)
        page.pack_start(toolbar, expand: false)

        search_box = Gtk::Box.new(:horizontal, 6)
        search_label = Gtk::Label.new('Search:')
        @search_entry = Gtk::Entry.new
        @search_entry.signal_connect('activate') { do_search }
        search_btn = Gtk::Button.new(label: 'Go')
        search_btn.signal_connect(:clicked) { do_search }
        search_box.pack_start(search_label, expand: false)
        search_box.pack_start(@search_entry, expand: true)
        search_box.pack_start(search_btn, expand: false)
        page.pack_start(search_box, expand: false)

        @list_store = Gtk::ListStore.new(String, String, String, String)
        @tree_view = Gtk::TreeView.new(@list_store)
        @tree_view.append_column(Gtk::TreeViewColumn.new('Service',
          Gtk::CellRendererText.new, text: 0))
        @tree_view.append_column(Gtk::TreeViewColumn.new('Username',
          Gtk::CellRendererText.new, text: 1))
        @tree_view.append_column(Gtk::TreeViewColumn.new('Password',
          Gtk::CellRendererText.new, text: 2))
        @tree_view.selection.signal_connect('changed') { on_selection_changed }

        scroll = Gtk::ScrolledWindow.new
        scroll.set_policy(:automatic, :automatic)
        scroll.add(@tree_view)
        page.pack_start(scroll, expand: true)

        @detail_label = Gtk::Label.new('')
        @detail_label.wrap = true
        @detail_label.xalign = 0
        page.pack_start(@detail_label, expand: false)

        action_box = Gtk::Box.new(:horizontal, 6)
        delete_btn = Gtk::Button.new(label: 'Delete')
        delete_btn.signal_connect(:clicked) { do_delete }
        copy_btn = Gtk::Button.new(label: 'Copy Password')
        copy_btn.signal_connect(:clicked) { do_copy_password }
        action_box.pack_start(delete_btn, expand: true)
        action_box.pack_start(copy_btn, expand: true)
        page.pack_start(action_box, expand: false)

        @stack.add_named(page, 'vault')
      end

      def show_unlock_dialog
        dialog = Gtk::Dialog.new(
          title: 'Unlock Vault',
          parent: self.toplevel,
          flags: :modal,
          buttons: [
            [Gtk::Stock::CANCEL, :cancel],
            ['Unlock', :accept]
          ]
        )
        dialog.set_default_size(350, 150)

        box = dialog.child
        box.pack_start(Gtk::Label.new('Enter your master password:'), expand: false)

        entry = Gtk::Entry.new
        entry.visibility = false
        entry.activates_default = true
        box.pack_start(entry, expand: false)

        dialog.default_response = :accept
        dialog.show_all

        if dialog.run == :accept
          password = entry.text
          dialog.destroy
          unlock_vault(password)
        else
          dialog.destroy
        end
      end

      def show_create_dialog
        dialog = Gtk::Dialog.new(
          title: 'Create Master Password',
          parent: self.toplevel,
          flags: :modal,
          buttons: [
            [Gtk::Stock::CANCEL, :cancel],
            ['Create', :accept]
          ]
        )
        dialog.set_default_size(350, 200)

        box = dialog.child
        box.pack_start(Gtk::Label.new('Choose a master password for the vault:'), expand: false)

        pw_row = Gtk::Box.new(:horizontal, 6)
        pw_row.pack_start(Gtk::Label.new('Password:'), expand: false)
        pw_entry = Gtk::Entry.new
        pw_entry.visibility = false
        pw_row.pack_start(pw_entry, expand: true)
        box.pack_start(pw_row, expand: false)

        confirm_row = Gtk::Box.new(:horizontal, 6)
        confirm_row.pack_start(Gtk::Label.new('Confirm:'), expand: false)
        confirm_entry = Gtk::Entry.new
        confirm_entry.visibility = false
        confirm_row.pack_start(confirm_entry, expand: true)
        box.pack_start(confirm_row, expand: false)

        dialog.default_response = :accept
        dialog.show_all

        result = dialog.run
        password = pw_entry.text
        confirm = confirm_entry.text
        dialog.destroy

        return unless result == :accept

        if password.empty?
          show_error_dialog('Password cannot be empty')
          show_create_dialog
          return
        end

        if password != confirm
          show_error_dialog('Passwords do not match')
          show_create_dialog
          return
        end

        unlock_vault(password)
      end

      def unlock_vault(password)
        exists = File.exist?(@vault_path)

        storage = Enigma::Core::Vault::Storage.new(@vault_path, password)

        if exists
          @vault_manager = Enigma::Core::Vault::Manager.new(storage)
        else
          storage.save([])
          @vault_manager = Enigma::Core::Vault::Manager.new(storage)
        end

        @stack.visible_child_name = 'vault'
        refresh_list
      rescue Enigma::Core::VaultError
        show_error_dialog('Wrong master password. Please try again.')
        show_unlock_dialog
      end

      def lock_vault
        @vault_manager.clear! if @vault_manager
        @clipboard_timer&.remove
        clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
        clipboard.text = ''
        @vault_manager = nil
        @list_store.clear
        @detail_label.text = ''
        @stack.visible_child_name = 'lock'
      end

      def show_error_dialog(message)
        dialog = Gtk::MessageDialog.new(
          parent: self.toplevel,
          flags: :modal,
          type: :error,
          buttons: :ok,
          message: message
        )
        dialog.run
        dialog.destroy
      end

      def refresh_list
        @list_store.clear
        @vault_manager.all.each do |cred|
          @list_store.append do |row|
            row[0] = cred.service
            row[1] = cred.username
            row[2] = '*' * cred.password.length
            row[3] = cred.id
          end
        end
      end

      def do_search
        query = @search_entry.text
        results = query.empty? ? @vault_manager.all : @vault_manager.search(query)
        @list_store.clear
        results.each do |cred|
          @list_store.append do |row|
            row[0] = cred.service
            row[1] = cred.username
            row[2] = '*' * cred.password.length
            row[3] = cred.id
          end
        end
      end

      def on_selection_changed
        cred = find_selected_credential
        return unless cred

        @detail_label.text = "Service: #{cred.service}\n" \
                             "Username: #{cred.username}\n" \
                             "Notes: #{cred.notes}\n" \
                             "Created: #{cred.created_at}"
      end

      def find_selected_credential
        iter = @tree_view.selection.selected
        return nil unless iter
        @vault_manager.find(iter[3])
      end

      def show_add_dialog
        dialog = Gtk::Dialog.new(
          title: 'Add Credential',
          parent: self.toplevel,
          flags: :modal,
          buttons: [
            [Gtk::Stock::CANCEL, :cancel],
            [Gtk::Stock::OK, :accept]
          ]
        )
        dialog.set_default_size(400, 200)

        box = dialog.child
        entries = {}
        %w[Service Username Password Notes].each do |field|
          row = Gtk::Box.new(:horizontal, 6)
          row.pack_start(Gtk::Label.new("#{field}:"), expand: false)
          entry = Gtk::Entry.new
          entry.visibility = false if field == 'Password'
          entries[field.downcase] = entry
          row.pack_start(entry, expand: true)
          box.pack_start(row, expand: false)
        end

        dialog.show_all
        if dialog.run == :accept
          cred = Enigma::Core::Vault::Credential.new(
            service: entries['service'].text,
            username: entries['username'].text,
            password: entries['password'].text,
            notes: entries['notes'].text
          )
          @vault_manager.add(cred)
          refresh_list
        end
        dialog.destroy
      end

      def do_delete
        cred = find_selected_credential
        return unless cred

        @vault_manager.delete(cred.id)
        refresh_list
        @detail_label.text = ''
      end

      def do_copy_password
        cred = find_selected_credential
        return unless cred

        clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
        clipboard.text = cred.password

        @clipboard_timer&.remove
        @clipboard_timer = GLib::Timeout.add(30_000) do
          clipboard.text = ''
          false
        end
      end
    end
  end
end
