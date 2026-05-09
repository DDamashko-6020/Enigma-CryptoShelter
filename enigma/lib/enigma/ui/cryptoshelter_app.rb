require 'tk'
require 'tkextlib/tile'

require_relative 'cipher_lab_panel'
require_relative 'vault_panel'
require_relative 'file_lock_panel'

module Enigma
  module UI
    class CryptoshelterApp
      COLORS = Enigma::Theme::COLORS
      FONT = Enigma::Theme::FONT

      VAULT_PATH = File.join(Dir.home, '.enigma_vault.dat').freeze

      def initialize
        @root = TkRoot.new
        @root.title 'ENIGMA CRYPTOSHELTER'
        @root.geometry('1200x800+50+50')
        @root.resizable(false, false)
        @root.background COLORS[:bg]

        @current_tab = 'cipher_lab'

        first_run_setup unless File.exist?(VAULT_PATH)

        build_top_nav
        build_content_area
        build_status_bar
      end

      def run
        Tk.mainloop
      end

      private

      def build_top_nav
        nav = TkFrame.new(@root) { background COLORS[:bg]; highlightthickness 0 }
        nav.pack(side: :top, fill: :x)
        TkFrame.new(@root) { background COLORS[:accent]; height 1 }.pack(side: :top, fill: :x)

        left = TkFrame.new(nav) { background COLORS[:bg] }
        left.pack(side: :left, fill: :y, padx: [20, 0], pady: 10)
        TkLabel.new(left) do
          text 'ENIGMA CRYPTOSHELTER'
          font TkFont.new("#{FONT} 12 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(side: :left)

        center = TkFrame.new(nav) { background COLORS[:bg] }
        center.pack(side: :left, expand: true)

        @tab_buttons = {}
        @tab_underlines = {}
        %w[Cipher\ Lab Vault File\ Lock].each do |tab_name|
          key = tab_name.downcase.gsub(/\s+/, '_')
          f = TkFrame.new(center) { background COLORS[:bg] }
          f.pack(side: :left, padx: 15, pady: [8, 0])

          btn = TkLabel.new(f) do
            text tab_name
            font TkFont.new("#{FONT} 11")
            foreground key == @current_tab ? COLORS[:text] : COLORS[:text_secondary]
            background COLORS[:bg]
            cursor 'hand2'
          end
          btn.pack

          underline = TkFrame.new(f) do
            background key == @current_tab ? COLORS[:accent] : COLORS[:bg]
            height 2
          end
          underline.pack(fill: :x, pady: [4, 0])

          @tab_buttons[key] = btn
          @tab_underlines[key] = underline
          btn.bind('Button-1') { |_| switch_tab(key) }
        end

        right = TkFrame.new(nav) { background COLORS[:bg] }
        right.pack(side: :right, padx: [0, 20], pady: 10)
        TkLabel.new(right) do
          text "\u{1F512}"
          font TkFont.new("#{FONT} 12")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(side: :right)
      end

      def build_content_area
        @content = TkFrame.new(@root) { background COLORS[:bg] }
        @content.pack(side: :top, fill: :both, expand: true)

        @panels = {}
        @panels['cipher_lab'] = CipherLabPanel.new(@content)
        @panels['vault'] = VaultPanel.new(@content)
        @panels['file_lock'] = FileLockPanel.new(@content)

        @panels.each_value(&:hide)
        @panels['cipher_lab'].show
      end

      def build_status_bar
        TkFrame.new(@root) { background COLORS[:accent]; height 1 }.pack(side: :bottom, fill: :x)
        bar = TkFrame.new(@root) { background COLORS[:bg]; height 30 }
        bar.pack(side: :bottom, fill: :x)

        left = TkFrame.new(bar) { background COLORS[:bg] }
        left.pack(side: :left, fill: :y, padx: [20, 0])
        TkLabel.new(left) do
          text "\u{25CF} OFFLINE MODE | AES-256 ACTIVE"
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:green]
          background COLORS[:bg]
        end.pack(side: :left, fill: :y)

        right = TkFrame.new(bar) { background COLORS[:bg] }
        right.pack(side: :right, fill: :y, padx: [0, 20])
        TkLabel.new(right) do
          text 'System Logs'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
          cursor 'hand2'
        end.pack(side: :left)
        TkLabel.new(right) do
          text ' | '
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(side: :left)
        TkLabel.new(right) do
          text 'Network Status'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
          cursor 'hand2'
        end.pack(side: :left)
      end

      def first_run_setup
        dialog = TkDialog.new(
          'title' => 'Welcome to Enigma CryptoShelter',
          'parent' => @root,
          'buttons' => ['Create Vault', 'Exit']
        )

        body = TkFrame.new(dialog)
        TkLabel.new(body) do
          text '  CREATE YOUR MASTER PASSWORD'
          font TkFont.new("#{FONT} 11 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [16, 4])

        TkLabel.new(body) do
          text '  This password protects all your stored credentials.'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20)

        TkLabel.new(body) do
          text '  It cannot be recovered if lost.'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:red]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [0, 12])

        TkLabel.new(body) do
          text '  Master password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20)
        pw = TkEntry.new(body) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 12")
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        pw.pack(fill: :x, padx: 20, ipady: 4)

        TkLabel.new(body) do
          text '  Confirm password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [8, 0])
        confirm = TkEntry.new(body) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 12")
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
        end
        confirm.pack(fill: :x, padx: 20, ipady: 4)

        @first_run_error = TkLabel.new(body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:panel]
        end
        @first_run_error.pack(anchor: 'w', padx: 20, pady: [4, 0])

        TkLabel.new(body) do
          text "  Min 4 characters. Store it safely \u{2014} no recovery option."
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [8, 16])

        dialog.child = body
        body.pack(fill: :both, expand: true, padx: 0, pady: 0)
        dialog.wait_destroy

        if dialog.value == 0
          p1 = pw.get
          p2 = confirm.get
          if p1.length < 4
            Tk.messageBox('type' => 'ok', 'icon' => 'error',
                           'title' => 'Error', 'message' => 'Password must be at least 4 characters.')
            first_run_setup
            return
          end
          if p1 != p2
            Tk.messageBox('type' => 'ok', 'icon' => 'error',
                           'title' => 'Error', 'message' => 'Passwords do not match.')
            first_run_setup
            return
          end
          create_vault(p1)
        else
          exit
        end
      end

      def create_vault(password)
        key_master = Enigma::Core::KeyMaster.instance
        vault_key = key_master.vault_key(password)
        cipher = Enigma::Core::Cipher::AesGcm.new(vault_key)
        storage = Enigma::Core::Vault::Storage.new(VAULT_PATH, cipher)
        storage.save([])
      end

      def switch_tab(key)
        @current_tab = key
        @tab_underlines.each do |k, underline|
          underline.configure('background' => k == key ? COLORS[:accent] : COLORS[:bg])
        end
        @tab_buttons.each do |k, btn|
          btn.configure('foreground' => k == key ? COLORS[:text] : COLORS[:text_secondary])
        end
        @panels.each_value(&:hide)
        @panels[key].show
      end
    end
  end
end
