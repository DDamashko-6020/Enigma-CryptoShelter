require 'tk'
require 'tkextlib/tile'

module Enigma
  module UI
    class VaultPanel
  COLORS = Enigma::Theme::COLORS
  FONT = Enigma::Theme::FONT
  VAULT_PATH = File.join(Dir.home, '.enigma_vault.dat').freeze

      def initialize(parent)
        @frame = TkFrame.new(parent) { background COLORS[:bg] }
        @vault_open = false
        @manager = nil
        @selected_id = nil
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

        left = TkFrame.new(main) { background COLORS[:bg]; width 320 }
        left.pack(side: :left, fill: :both, anchor: 'nw')
        left.pack_propagate(false)
        TkFrame.new(left) { background COLORS[:border_inactive]; width 1 }.pack(side: :right, fill: :y)

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
          columns ['site', 'username']
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

        TkFrame.new(parent) { background COLORS[:border_inactive]; height 1 }
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
          text "  Created:"
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
          prompt_unlock
        end
      end

      def prompt_unlock
        first_time = !File.exist?(VAULT_PATH)

        dialog = TkDialog.new(
          'title' => first_time ? 'Create Master Password' : 'Unlock Vault',
          'parent' => @frame,
          'buttons' => [first_time ? 'Create' : 'Unlock', 'Cancel']
        )

        body = TkFrame.new(dialog)
        TkLabel.new(body) do
          text first_time ? 'Choose a master password:' : 'Enter master password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(pady: 8)

        pw = TkEntry.new(body) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 11")
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        pw.pack(fill: :x, padx: 16)

        confirm = nil
        if first_time
          TkLabel.new(body) do
            text 'Confirm password:'
            font TkFont.new("#{FONT} 10")
            foreground COLORS[:text]
            background COLORS[:panel]
          end.pack(pady: [8, 0])
          confirm = TkEntry.new(body) do
            background COLORS[:input]
            foreground COLORS[:text]
            font TkFont.new("#{FONT} 11")
            show '*'
            relief 'flat'
            highlightthickness 1
            highlightcolor COLORS[:accent]
            highlightbackground COLORS[:border_inactive]
          end
          confirm.pack(fill: :x, padx: 16)
        end

        dialog.child = body
        dialog.value = nil

        body.pack(fill: :both, expand: true, padx: 20, pady: 10)
        dialog.wait_destroy

        return unless dialog.value == 0

        password = pw.get
        return if password.empty?

        if first_time
          return unless confirm && password == confirm.get
        end

        unlock_vault(password)
      end

      def unlock_vault(password)
        key_master = Enigma::Core::KeyMaster.instance
        vault_key = key_master.vault_key(password)
        cipher = Enigma::Core::Cipher::AesGcm.new(vault_key)
        storage = Enigma::Core::Vault::Storage.new(VAULT_PATH, cipher)
        @manager = Enigma::Core::Vault::Manager.new(storage, key_master, password)
        @manager.unlock
        @vault_open = true
        update_vault_status
        update_lock_button
        refresh_list
      rescue Enigma::Errors::AuthTagError, Enigma::Errors::VaultNotFoundError
        Tk.messageBox('type' => 'ok', 'icon' => 'error',
                       'title' => 'Error', 'message' => 'Wrong password or corrupted vault')
      end

      def lock_vault
        @manager&.clear!
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

        dialog = TkDialog.new('title' => 'Edit Credential', 'parent' => @frame,
                               'buttons' => ['Save', 'Cancel'])
        body = TkFrame.new(dialog)
        entries = {}
        %w[Service Username Password Notes].each do |f|
          row = TkFrame.new(body) { background COLORS[:panel] }
          row.pack(fill: :x, pady: 4, padx: 16)
          TkLabel.new(row) do
            text "  #{f}:"
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:text_secondary]
            background COLORS[:panel]
          end.pack(side: :left)
          entry = TkEntry.new(row) do
            background COLORS[:input]
            foreground COLORS[:text]
            font TkFont.new("#{FONT} 11")
            relief 'flat'
            highlightthickness 1
            highlightcolor COLORS[:accent]
            highlightbackground COLORS[:border_inactive]
          end
          entry.insert(0, cred.send(f.downcase))
          entry.pack(side: :left, fill: :x, expand: true, padx: [8, 0])
          entries[f.downcase] = entry
        end
        dialog.child = body
        body.pack(padx: 20, pady: 10)
        dialog.wait_destroy

        if dialog.value == 0
          attrs = {}
          attrs[:site] = entries['service'].get if entries['service'].get != cred.site
          attrs[:username] = entries['username'].get if entries['username'].get != cred.username
          attrs[:password] = entries['password'].get if entries['password'].get != cred.password
          attrs[:notes] = entries['notes'].get if entries['notes'].get != cred.notes
          @manager.update(@selected_id, attrs) unless attrs.empty?
          refresh_list
        end
      end

      def on_delete
        return unless @manager && @selected_id

        @manager.delete(@selected_id)
        @selected_id = nil
        clear_details
        refresh_list
      end

      def on_add
        return unless @manager

        dialog = TkDialog.new('title' => 'Add Credential', 'parent' => @frame,
                               'buttons' => ['Add', 'Cancel'])
        body = TkFrame.new(dialog)
        entries = {}
        %w[Service Username Password Notes].each do |f|
          row = TkFrame.new(body) { background COLORS[:panel] }
          row.pack(fill: :x, pady: 4, padx: 16)
          TkLabel.new(row) do
            text "  #{f}:"
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:text_secondary]
            background COLORS[:panel]
          end.pack(side: :left)
          entry = TkEntry.new(row) do
            background COLORS[:input]
            foreground COLORS[:text]
            font TkFont.new("#{FONT} 11")
            relief 'flat'
            highlightthickness 1
            highlightcolor COLORS[:accent]
            highlightbackground COLORS[:border_inactive]
          end
          entry.pack(side: :left, fill: :x, expand: true, padx: [8, 0])
          entries[f.downcase] = entry
        end
        dialog.child = body
        body.pack(padx: 20, pady: 10)
        dialog.wait_destroy

        if dialog.value == 0
          cred = Enigma::Core::Vault::Credential.new(
            site: entries['service'].get,
            username: entries['username'].get,
            password: entries['password'].get,
            notes: entries['notes'].get
          )
          @manager.add(credential: cred)
          refresh_list
        end
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
