# frozen_string_literal: true

require 'tk'
require 'tkextlib/tile'
require 'fileutils'

module Enigma
  module UI
    class FileLockPanel
      COLORS = Enigma::Theme::COLORS
      FONT = Enigma::Theme::FONT
      ORANGE = '#FF6B00'
      GREEN_OK = '#00CC66'

      def initialize(parent)
        @frame = TkFrame.new(parent) { background COLORS[:bg] }
        @key_visible = false
        @share_key_visible = false
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
        pad = { padx: 40, pady: [30, 0] }

        TkLabel.new(@frame) do
          text 'FILE LOCK'
          font TkFont.new("#{FONT} 12 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(pad.merge(anchor: 'w'))

        TkLabel.new(@frame) do
          text 'Double-layer AES-256-GCM + ChaCha20-Poly1305 file encryption'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(pad.merge(anchor: 'w', pady: [4, 0]))

        cfg_card = TkFrame.new(@frame) { background COLORS[:panel] }
        cfg_card.pack(pad.merge(fill: :x, pady: [20, 0]))

        TkLabel.new(cfg_card) do
          text '  CONFIGURATION'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(anchor: 'w', pady: [16, 0], padx: 20)

        build_file_row(cfg_card)
        build_master_key_row(cfg_card)
        build_share_key_row(cfg_card)
        build_action_row(cfg_card)

        status_card = TkFrame.new(@frame) { background COLORS[:panel] }
        status_card.pack(pad.merge(fill: :x, pady: [20, 0]))

        TkLabel.new(status_card) do
          text '  STATUS'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(anchor: 'w', pady: [16, 0], padx: 20)

        si = TkFrame.new(status_card) { background COLORS[:panel] }
        si.pack(fill: :x, padx: 20, pady: [12, 16])
        @session_status = TkLabel.new(si) do
          text "  \u{25CF}  LOCAL SESSION ENCRYPTED"
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:green]
          background COLORS[:panel]
        end
        @session_status.pack(anchor: 'w', pady: [0, 4])
        @file_status = TkLabel.new(si) do
          text "  \u{25CB}  FILE LOCKED: none"
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text]
          background COLORS[:panel]
        end
        @file_status.pack(anchor: 'w', pady: [0, 4])
        @last_op = TkLabel.new(si) do
          text "  \u{25CB}  LAST OPERATION: --"
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end
        @last_op.pack(anchor: 'w')
      end

      def build_file_row(parent)
        row = TkFrame.new(parent) { background COLORS[:panel] }
        row.pack(fill: :x, padx: 20, pady: [16, 0])
        TkLabel.new(row) do
          text 'FILE'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(side: :left)
        @file_path = TkEntry.new(row) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:accent]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        @file_path.pack(side: :left, fill: :x, expand: true, padx: [12, 8], ipady: 4)
        browse = TkLabel.new(row) do
          text '  BROWSE  '
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
          cursor 'hand2'
          relief 'solid'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        browse.pack(side: :left)
        browse.bind('Button-1') { on_browse }
      end

      def build_master_key_row(parent)
        row = TkFrame.new(parent) { background COLORS[:panel] }
        row.pack(fill: :x, padx: 20, pady: [12, 0])
        TkLabel.new(row) do
          text 'MASTER KEY'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(side: :left)
        @master_key_entry = TkEntry.new(row) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:accent]
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        @master_key_entry.pack(side: :left, fill: :x, expand: true, padx: [16, 8], ipady: 4)
        eye = TkLabel.new(row) do
          text "\u{1F441}"
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
          cursor 'hand2'
        end
        eye.pack(side: :left)
        eye.bind('Button-1') { toggle_master_key }
      end

      def build_share_key_row(parent)
        row = TkFrame.new(parent) { background COLORS[:panel] }
        row.pack(fill: :x, padx: 20, pady: [12, 0])
        TkLabel.new(row) do
          text 'SHARE KEY '
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(side: :left)
        @share_key_entry = TkEntry.new(row) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:accent]
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        @share_key_entry.pack(side: :left, fill: :x, expand: true, padx: [16, 8], ipady: 4)
        eye = TkLabel.new(row) do
          text "\u{1F441}"
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
          cursor 'hand2'
        end
        eye.pack(side: :left)
        eye.bind('Button-1') { toggle_share_key }
      end

      def build_action_row(parent)
        row = TkFrame.new(parent) { background COLORS[:panel] }
        row.pack(fill: :x, padx: 20, pady: [20, 20])
        me = self

        @encrypt_btn = TkButton.new(row) do
          text '  \u{1F512} LOCK FILE \u2192 .ultra  '
          font TkFont.new("#{FONT} 11 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          height 2
          command proc { me.on_lock_file }
        end
        @encrypt_btn.pack(side: :left, padx: [0, 16])

        @decrypt_btn = TkButton.new(row) do
          text '  \u{1F513} UNLOCK .ultra  '
          font TkFont.new("#{FONT} 11 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          height 2
          command proc { me.on_unlock_file }
        end
        @decrypt_btn.pack(side: :left)
      end

      def toggle_master_key
        @key_visible = !@key_visible
        @master_key_entry.configure('show' => @key_visible ? '' : '*')
      end

      def toggle_share_key
        @share_key_visible = !@share_key_visible
        @share_key_entry.configure('show' => @share_key_visible ? '' : '*')
      end

      def on_browse
        file = Tk.getOpenFile
        return if file.nil? || file.empty?

        @file_path.delete(0, 'end')
        @file_path.insert(0, file)
      end

      def on_lock_file
        path = @file_path.get
        if path.nil? || path.empty?
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'Select a file first')
          return
        end
        unless File.exist?(path)
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'File not found')
          return
        end

        master_pass = @master_key_entry.get
        share_key = @share_key_entry.get
        if master_pass.empty?
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'Enter your master key')
          return
        end
        if share_key.empty?
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'Enter a share key')
          return
        end

        show_processing(true, encrypting: true)

        Thread.new do
          storage = Core::Vault::Storage.new
          unless storage.exists?
            TkAfter.new(0, 1) do
              show_processing(false)
              Tk.messageBox('type' => 'ok', 'icon' => 'error',
                            'title' => 'Error',
                            'message' => 'No vault found. Create a vault in the Vault tab first.')
            end
            next
          end

          salt, = storage.load
          filelock_key = Core::KeyMaster.instance.derive_filelock_key(master_pass, salt)
          output = Core::FileLock::Locker.new(filelock_key, share_key).lock(path)

          TkAfter.new(0, 1) do
            show_processing(false)
            @file_status.configure(
              'text' => "  \u{25CF}  FILE LOCKED: #{File.basename(output)}",
              'foreground' => COLORS[:accent]
            )
            @last_op.configure(
              'text' => "  \u{25CF}  LAST OPERATION: ENCRYPT (#{Time.now.strftime('%H:%M:%S')})"
            )
          end
        rescue StandardError => e
          TkAfter.new(0, 1) do
            show_processing(false)
            Tk.messageBox('type' => 'ok', 'icon' => 'error',
                          'title' => 'Error', 'message' => "Encryption failed: #{e.message}")
          end
        end
      end

      def on_unlock_file
        path = @file_path.get
        if path.nil? || path.empty?
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'Select a .ultra file first')
          return
        end
        unless File.exist?(path)
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'File not found')
          return
        end
        unless path.end_with?('.ultra')
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'File must have .ultra extension')
          return
        end

        master_pass = @master_key_entry.get
        share_key = @share_key_entry.get
        if master_pass.empty?
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'Enter your master key')
          return
        end
        if share_key.empty?
          Tk.messageBox('type' => 'ok', 'icon' => 'warning',
                        'title' => 'Error', 'message' => 'Enter the share key')
          return
        end

        show_processing(true, encrypting: false)

        Thread.new do
          storage = Core::Vault::Storage.new
          unless storage.exists?
            TkAfter.new(0, 1) do
              show_processing(false)
              Tk.messageBox('type' => 'ok', 'icon' => 'error',
                            'title' => 'Error',
                            'message' => 'No vault found. Create a vault in the Vault tab first.')
            end
            next
          end

          salt, = storage.load
          filelock_key = Core::KeyMaster.instance.derive_filelock_key(master_pass, salt)
          Core::FileLock::Unlocker.new(filelock_key, share_key).unlock(path)

          TkAfter.new(0, 1) do
            show_processing(false)
            @file_status.configure(
              'text' => "  \u{25CB}  FILE LOCKED: none",
              'foreground' => COLORS[:text]
            )
            @last_op.configure(
              'text' => "  \u{25CF}  LAST OPERATION: DECRYPT (#{Time.now.strftime('%H:%M:%S')})"
            )
          end
        rescue Core::Errors::AuthTagError
          TkAfter.new(0, 1) do
            show_processing(false)
            Tk.messageBox('type' => 'ok', 'icon' => 'error',
                          'title' => 'Error',
                          'message' => 'Wrong master password or share key. Decryption failed.')
          end
        rescue StandardError => e
          TkAfter.new(0, 1) do
            show_processing(false)
            Tk.messageBox('type' => 'ok', 'icon' => 'error',
                          'title' => 'Error', 'message' => "Decryption failed: #{e.message}")
          end
        end
      end

      def show_processing(active, encrypting: true)
        if active
          @encrypt_btn.configure('state' => 'disabled',
                                 'text' => "  \u{23F3} #{encrypting ? 'ENCRYPTING' : 'DECRYPTING'}...  ")
          @decrypt_btn.configure('state' => 'disabled')
          @session_status.configure('text' => "  \u{25CF}  #{encrypting ? 'ENCRYPTING' : 'DECRYPTING'}...",
                                    'foreground' => ORANGE)
        else
          @encrypt_btn.configure('state' => 'normal',
                                 'text' => '  \u{1F512} LOCK FILE \u2192 .ultra  ')
          @decrypt_btn.configure('state' => 'normal')
          @session_status.configure('text' => "  \u{25CF}  LOCAL SESSION ENCRYPTED",
                                    'foreground' => GREEN_OK)
        end
      end
    end
  end
end
