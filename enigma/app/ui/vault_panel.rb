# frozen_string_literal: true

require 'tk'
require 'tkextlib/tile'
require 'securerandom'

module Enigma
  module UI
    class VaultPanel
      COLORS = Enigma::Theme::COLORS
      FONT = Enigma::Theme::FONT

      def initialize(parent)
        @frame = TkFrame.new(parent) { background COLORS[:bg] }
        @vault_open = false
        @manager = nil
        @selected_id = nil
        @key_deriving = false
        build_layout
      end

      def hide
        @frame.pack_forget
      end

      def show
        @frame.pack(side: :top, fill: :both, expand: true)
      end

      private

      def build_layout
        top_bar = TkFrame.new(@frame) { background COLORS[:bg] }
        top_bar.pack(fill: :x, padx: 20, pady: [16, 0])

        search_frame = TkFrame.new(top_bar) { background COLORS[:input] }
        search_frame.pack(side: :left, fill: :x, expand: true)
        @search_entry = TkEntry.new(search_frame) do
          background COLORS[:input]
          foreground COLORS[:text_secondary]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:accent]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        @search_entry.pack(fill: :x, ipady: 6, padx: 4, pady: 4)
        placeholder(@search_entry, "\u{1F50D} SEARCH VAULT...")
        @search_entry.bind('KeyRelease') { on_search }

        @vault_status = TkLabel.new(top_bar) do
          font TkFont.new("#{FONT} 9 bold")
          background COLORS[:bg]
        end
        @vault_status.pack(side: :right, padx: [16, 0])
        update_vault_status

        main = TkFrame.new(@frame) { background COLORS[:bg] }
        main.pack(fill: :both, expand: true, pady: [12, 0])

        left = TkFrame.new(main) do
          background COLORS[:bg]
          width 320
        end
        left.pack(side: :left, fill: :both, anchor: 'nw')
        left.pack_propagate(false)
        TkFrame.new(left) do
          background COLORS[:border_inactive]
          width 1
        end.pack(side: :right, fill: :y)

        right = TkFrame.new(main) { background COLORS[:panel] }
        right.pack(side: :left, fill: :both, expand: true)

        build_sidebar(left)
        build_detail_panel(right)
      end

      def build_sidebar(parent)
        header = TkFrame.new(parent) { background COLORS[:bg] }
        header.pack(fill: :x, padx: 12, pady: [12, 8])
        TkLabel.new(header) do
          text '  CREDENTIALS'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(side: :left)

        @unlock_btn = TkLabel.new(header) do
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:accent]
          background COLORS[:bg]
          cursor 'hand2'
        end
        @unlock_btn.pack(side: :right)
        @unlock_btn.bind('Button-1') { on_toggle_lock }
        update_lock_button

        list_frame = TkFrame.new(parent) { background COLORS[:bg] }
        list_frame.pack(fill: :both, expand: true, padx: 8)

        @tree = Tk::Tile::Treeview.new(list_frame) do
          height 0
          selectmode 'browse'
          columns %w[site username]
        end
        @tree.columnconfigure('#0', width: 0, minwidth: 0, stretch: false)
        @tree.columnconfigure('site', width: 180, minwidth: 120)
        @tree.columnconfigure('username', width: 120, minwidth: 80)

        scroll = Tk::Tile::Scrollbar.new(list_frame) { orient 'vertical' }
        @tree.configure('yscrollcommand' => proc { |*args| scroll.set(*args) })
        scroll.command(proc { |*args| @tree.yview(*args) })

        @tree.pack(side: :left, fill: :both, expand: true)
        scroll.pack(side: :right, fill: :y)
        @tree.bind('ButtonRelease-1') { on_item_selected }
        @tree.bind('ButtonRelease-3') { on_item_selected }
      end

      def build_detail_panel(parent)
        pad = { padx: 24, pady: [20, 0] }
        TkLabel.new(parent) do
          text 'CREDENTIAL DETAILS'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(pad)

        detail_card = TkFrame.new(parent) { background COLORS[:input] }
        detail_card.pack(pad.merge(fill: :x))

        @detail_labels = {}
        %w[Service Username Password Notes].each do |f|
          row = TkFrame.new(detail_card) { background COLORS[:input] }
          row.pack(fill: :x, pady: [6, 0], padx: 12)
          TkLabel.new(row) do
            text "  #{f.upcase}:"
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:text_secondary]
            background COLORS[:input]
          end.pack(side: :left, anchor: 'n')
          lbl = TkLabel.new(row) do
            text '  --'
            font TkFont.new("#{FONT} 11")
            foreground COLORS[:text]
            background COLORS[:input]
            wraplength 380
            justify 'left'
          end
          lbl.pack(side: :left, fill: :x, expand: true)
          @detail_labels[f.downcase] = lbl
        end

        row_pad = { padx: 24, pady: [12, 0] }
        action_row = TkFrame.new(parent) { background COLORS[:panel] }
        action_row.pack(row_pad.merge(fill: :x))

        me = self
        [['COPY', :on_copy], ['EDIT', :on_edit], ['DELETE', :on_delete], ['+ ADD', :on_add]].each do |label, method|
          btn = TkLabel.new(action_row) do
            text "  #{label}  "
            font TkFont.new("#{FONT} 9 bold")
            foreground COLORS[:accent]
            background COLORS[:panel]
            cursor 'hand2'
            relief 'solid'
            highlightthickness 1
            highlightcolor COLORS[:accent]
            highlightbackground COLORS[:border_inactive]
          end
          btn.pack(side: :left, padx: [0, 12])
          btn.bind('Button-1', proc { me.send(method) })
        end

        TkFrame.new(parent) do
          background COLORS[:border_inactive]
          height 1
        end
               .pack(row_pad.merge(fill: :x, pady: [24, 0]))

        TkLabel.new(parent) do
          text '  METADATA'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(pad)

        meta_card = TkFrame.new(parent) { background COLORS[:input] }
        meta_card.pack(pad.merge(fill: :x))
        row = TkFrame.new(meta_card) { background COLORS[:input] }
        row.pack(fill: :x, pady: [4, 0], padx: 12)
        TkLabel.new(row) do
          text '  Created:'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:input]
        end.pack(side: :left)
        lbl = TkLabel.new(row) do
          text '  --'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text_secondary]
          background COLORS[:input]
        end
        lbl.pack(side: :left)
        @detail_labels['created'] = lbl
      end

      def on_toggle_lock
        if @vault_open
          lock_vault
        else
          prompt_unlock_or_create
        end
      end

      def prompt_unlock_or_create
        storage = Core::Vault::Storage.new

        if storage.exists?
          show_unlock_dialog
        else
          show_create_vault_dialog
        end
      end

      def show_create_vault_dialog
        dialog = build_dialog('Create Master Password', 420, 340)

        TkLabel.new(dialog.body) do
          text '  CREATE YOUR MASTER PASSWORD'
          font TkFont.new("#{FONT} 11 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [16, 4])

        TkLabel.new(dialog.body) do
          text '  This password protects all your stored credentials.'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20)

        TkLabel.new(dialog.body) do
          text '  It cannot be recovered if lost.'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:red]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [0, 12])

        TkLabel.new(dialog.body) do
          text '  Master password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20)
        pw = styled_entry(dialog.body, show: '*')
        pw.pack(fill: :x, padx: 20, ipady: 4)

        TkLabel.new(dialog.body) do
          text '  Confirm password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [8, 0])
        confirm = styled_entry(dialog.body, show: '*')
        confirm.pack(fill: :x, padx: 20, ipady: 4)

        error_label = TkLabel.new(dialog.body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:panel]
        end
        error_label.pack(anchor: 'w', padx: 20, pady: [4, 0])

        TkLabel.new(dialog.body) do
          text "  Minimum 8 characters. Store it safely \u{2014} no recovery."
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [8, 8])

        btn_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        btn_frame.pack(fill: :x, padx: 20, pady: [4, 16])

        TkButton.new(btn_frame) do
          text '  CREATE VAULT  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            p1 = pw.get
            p2 = confirm.get
            if p1.length < 8
              error_label.configure('text' => '  Password must be at least 8 characters.')
            elsif p1 != p2
              error_label.configure('text' => '  Passwords do not match.')
            else
              dialog.close
              create_vault(p1)
            end
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  CANCEL  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { dialog.close }
        end.pack(side: :left)
      end

      def show_unlock_dialog
        dialog = build_dialog('Unlock Vault', 380, 200)

        TkLabel.new(dialog.body) do
          text '  Enter master password to unlock vault:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [16, 8])

        pw = styled_entry(dialog.body, show: '*')
        pw.pack(fill: :x, padx: 20, ipady: 4)
        pw.focus

        error_label = TkLabel.new(dialog.body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:panel]
        end
        error_label.pack(anchor: 'w', padx: 20, pady: [4, 0])

        btn_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        btn_frame.pack(fill: :x, padx: 20, pady: [12, 16])

        TkButton.new(btn_frame) do
          text '  UNLOCK  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            password = pw.get
            if password.empty?
              error_label.configure('text' => '  Enter a password.')
            else
              dialog.close
              unlock_vault(password)
            end
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  CANCEL  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { dialog.close }
        end.pack(side: :left)
      end

      def unlock_vault(password)
        show_unlocking_state(true)
        Thread.new do
          TkAfter.new(0, 1) do
            @vault_status.configure('text' => "  \u{25CF}  VERIFYING...", 'foreground' => COLORS[:accent])
          end

          storage = Core::Vault::Storage.new
          km = Core::KeyMaster.instance
          salt, encrypted = storage.load
          vault_key = km.derive_vault_key(password, salt)
          cipher = Core::Cipher::AesGcm.new(vault_key)
          json = cipher.decrypt(encrypted)
          data = JSON.parse(json)
          (data['credentials'] || []).map { |h| Core::Vault::Credential.from_h(h) }

          @manager = Core::Vault::Manager.new(storage, km, password)
          @manager.unlock

          TkAfter.new(0, 1) do
            @vault_open = true
            update_vault_status
            update_lock_button
            refresh_list
            show_unlocking_state(false)
          end
        rescue Core::Errors::AuthTagError
          TkAfter.new(0, 1) do
            show_unlocking_state(false)
            Tk.messageBox(
              'type' => 'ok', 'icon' => 'error',
              'title' => 'Error', 'message' => 'Incorrect master password or corrupted vault.'
            )
          end
        rescue StandardError => e
          TkAfter.new(0, 1) do
            show_unlocking_state(false)
            Tk.messageBox(
              'type' => 'ok', 'icon' => 'error',
              'title' => 'Error', 'message' => e.message
            )
          end
        end
      end

      def create_vault(password)
        show_unlocking_state(true)
        Thread.new do
          TkAfter.new(0, 1) do
            @vault_status.configure('text' => "  \u{25CF}  CREATING VAULT...", 'foreground' => COLORS[:accent])
          end

          km = Core::KeyMaster.instance
          salt = km.generate_salt
          vault_key = km.derive_vault_key(password, salt)
          cipher = Core::Cipher::AesGcm.new(vault_key)
          empty_payload = cipher.encrypt(JSON.generate({ 'credentials' => [] }))
          storage = Core::Vault::Storage.new
          storage.create_new!(salt, empty_payload)

          @manager = Core::Vault::Manager.new(storage, km, password)
          @manager.unlock

          TkAfter.new(0, 1) do
            @vault_open = true
            update_vault_status
            update_lock_button
            refresh_list
            show_unlocking_state(false)
          end
        rescue StandardError => e
          TkAfter.new(0, 1) do
            show_unlocking_state(false)
            Tk.messageBox(
              'type' => 'ok', 'icon' => 'error',
              'title' => 'Error', 'message' => "Failed to create vault: #{e.message}"
            )
          end
        end
      end

      def lock_vault
        @manager&.lock
        @manager = nil
        @vault_open = false
        @selected_id = nil
        @tree.delete(*@tree.children(''))
        clear_details
        update_vault_status
        update_lock_button
      end

      def update_vault_status
        if @vault_open
          @vault_status.configure('text' => "  \u{25CF}  VAULT OPEN", 'foreground' => COLORS[:green])
        else
          @vault_status.configure('text' => "  \u{25CF}  VAULT LOCKED", 'foreground' => COLORS[:red])
        end
      end

      def update_lock_button
        @unlock_btn.configure('text' => @vault_open ? '  LOCK' : '  UNLOCK')
      end

      def show_unlocking_state(active)
        if active
          @unlock_btn.configure('state' => 'disabled')
        else
          @unlock_btn.configure('state' => 'normal')
        end
      end

      def refresh_list
        @tree.delete(*@tree.children(''))
        return unless @manager

        @manager.all.each do |cred|
          @tree.insert('', 'end', id: cred.id, values: [cred.site, cred.username])
        end
      end

      def on_search
        return unless @manager

        q = @search_entry.get
        placeholder_text = "\u{1F50D} SEARCH VAULT..."
        return if q == placeholder_text

        @tree.delete(*@tree.children(''))
        results = q.empty? ? @manager.all : @manager.find(q)
        results.each do |cred|
          @tree.insert('', 'end', id: cred.id, values: [cred.site, cred.username])
        end
      end

      def on_item_selected
        sel = @tree.selection
        return if sel.empty? || !@manager

        cred = @manager.find_by_id(sel[0])
        return unless cred

        @selected_id = cred.id
        @detail_labels['service'].configure('text' => "  #{cred.site}")
        @detail_labels['username'].configure('text' => "  #{cred.username}")
        @detail_labels['password'].configure('text' => "  #{'*' * cred.password.length}")
        @detail_labels['password'].instance_variable_set(:@password, cred.password)
        @detail_labels['notes'].configure('text' => "  #{cred.notes}")
        @detail_labels['created'].configure('text' => "  #{cred.created_at}")
      end

      def clear_details
        %w[service username password notes created].each do |k|
          @detail_labels[k]&.configure('text' => '  --')
        end
      end

      def on_copy
        return unless @manager && @selected_id

        cred = @manager.find_by_id(@selected_id)
        return unless cred

        TkClipboard.clear
        TkClipboard.add cred.password
      end

      def on_edit
        return unless @manager && @selected_id

        cred = @manager.find_by_id(@selected_id)
        return unless cred

        dialog = build_dialog('Edit Credential', 480, 340)
        entries = {}
        %w[Service Username Password Notes].each do |f|
          row = TkFrame.new(dialog.body) { background COLORS[:panel] }
          row.pack(fill: :x, pady: 4, padx: 16)
          TkLabel.new(row) do
            text "  #{f}:"
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:text_secondary]
            background COLORS[:panel]
          end.pack(side: :left)
          entry = styled_entry(row)
          entry.insert(0, cred.send(f.downcase))
          entry.pack(side: :left, fill: :x, expand: true, padx: [8, 0])
          entries[f.downcase] = entry
        end

        btn_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        btn_frame.pack(fill: :x, padx: 16, pady: [8, 16])

        TkButton.new(btn_frame) do
          text '  SAVE  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            dialog.close
            attrs = {}
            attrs[:site] = entries['service'].get if entries['service'].get != cred.site
            attrs[:username] = entries['username'].get if entries['username'].get != cred.username
            attrs[:password] = entries['password'].get if entries['password'].get != cred.password
            attrs[:notes] = entries['notes'].get if entries['notes'].get != cred.notes
            @manager.update(@selected_id, attrs) unless attrs.empty?
            refresh_list
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  CANCEL  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { dialog.close }
        end.pack(side: :left)
      end

      def on_delete
        return unless @manager && @selected_id

        cred = @manager.find_by_id(@selected_id)
        return unless cred

        confirmed = Tk.messageBox(
          'type' => 'yesno',
          'icon' => 'warning',
          'title' => 'Confirm Deletion',
          'message' => "Delete credential '#{cred.site}'?\nThis action cannot be undone."
        )
        return unless confirmed == 'yes'

        @manager.delete(@selected_id)
        @selected_id = Core::Vault::NullCredential.new.id
        refresh_list
        clear_details
      rescue Core::Errors::CredentialNotFoundError => e
        Tk.messageBox(
          'type' => 'ok', 'icon' => 'error',
          'title' => 'Error', 'message' => e.message
        )
      end

      def on_add
        return unless @manager

        dialog = build_dialog('Add Credential', 480, 360)
        entries = {}
        %w[Service Username Password Notes].each do |f|
          row = TkFrame.new(dialog.body) { background COLORS[:panel] }
          row.pack(fill: :x, pady: 4, padx: 16)
          TkLabel.new(row) do
            text "  #{f}:"
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:text_secondary]
            background COLORS[:panel]
          end.pack(side: :left)
          entry = styled_entry(row)
          entry.pack(side: :left, fill: :x, expand: true, padx: [8, 0])
          entries[f.downcase] = entry
        end

        gen_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        gen_frame.pack(fill: :x, padx: 16, pady: [0, 8])

        TkLabel.new(gen_frame) do
          text '  Generate:'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(side: :left)

        TkButton.new(gen_frame) do
          text "  \u{26A1} GENERATE PASSWORD  "
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            generated = Utils::PasswordGenerator.generate(length: 20, symbols: true)
            entries['password'].delete(0, 'end')
            entries['password'].insert(0, generated)
            entries['password'].configure('show' => '')
          }
        end.pack(side: :left, padx: [8, 0])

        btn_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        btn_frame.pack(fill: :x, padx: 16, pady: [4, 16])

        TkButton.new(btn_frame) do
          text '  ADD  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            dialog.close
            cred = Core::Vault::Credential.new(
              site: entries['service'].get,
              username: entries['username'].get,
              password: entries['password'].get,
              notes: entries['notes'].get
            )
            @manager.add(credential: cred)
            refresh_list
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  CANCEL  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { dialog.close }
        end.pack(side: :left)
      end

      def build_dialog(title, width, height)
        dlg = TkToplevel.new(@frame) do
          title title
          geometry "#{width}x#{height}+#{@frame.winfo_rootx + 80}+#{@frame.winfo_rooty + 80}"
          background COLORS[:panel]
        end
        dlg.transient(@frame)
        dlg.grab_set
        dlg.focus

        body = TkFrame.new(dlg) { background COLORS[:panel] }
        body.pack(fill: :both, expand: true)

        res = OpenStruct.new
        res.body = body
        res.dlg = dlg
        res.close = proc {
          dlg.grab_release
          dlg.destroy
        }

        dlg.protocol('WM_DELETE_WINDOW', res.close)

        res
      end

      def styled_entry(parent, show: nil)
        opts = {
          'background' => COLORS[:input],
          'foreground' => COLORS[:text],
          'font' => TkFont.new("#{FONT} 11"),
          'insertbackground' => COLORS[:accent],
          'relief' => 'flat',
          'highlightthickness' => 1,
          'highlightcolor' => COLORS[:accent],
          'highlightbackground' => COLORS[:border_inactive]
        }
        opts['show'] = show if show
        TkEntry.new(parent, opts)
      end

      def placeholder(entry, text)
        entry.insert(0, text)
        entry.bind('FocusIn') do
          if entry.get == text
            entry.delete(0, 'end')
            entry.configure('foreground' => COLORS[:text])
          end
        end
        entry.bind('FocusOut') do
          if entry.get.empty?
            entry.insert(0, text)
            entry.configure('foreground' => COLORS[:text_secondary])
          end
        end
      end
    end
  end
end
