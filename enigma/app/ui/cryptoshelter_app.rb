# frozen_string_literal: true

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

      def initialize
        @root = TkRoot.new
        @root.title 'ENIGMA CRYPTOSHELTER'
        @root.geometry('1200x800+50+50')
        @root.resizable(false, false)
        @root.background COLORS[:bg]

        @current_tab = 'cipher_lab'

        build_top_nav
        build_content_area
        build_status_bar
      end

      def run
        Tk.mainloop
      end

      private

      def build_top_nav
        nav = TkFrame.new(@root) do
          background COLORS[:bg]
          highlightthickness 0
        end
        nav.pack(side: :top, fill: :x)
        TkFrame.new(@root) do
          background COLORS[:accent]
          height 1
        end.pack(side: :top, fill: :x)

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
        ['Cipher Lab', 'Vault', 'File Lock'].each do |tab_name|
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
        TkFrame.new(@root) do
          background COLORS[:accent]
          height 1
        end.pack(side: :bottom, fill: :x)
        bar = TkFrame.new(@root) do
          background COLORS[:bg]
          height 30
        end
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
