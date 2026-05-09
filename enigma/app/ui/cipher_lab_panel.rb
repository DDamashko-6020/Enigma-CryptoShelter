# frozen_string_literal: true

require 'tk'
require 'tkextlib/tile'
require 'digest'
require 'openssl'

module Enigma
  module UI
    class CipherLabPanel
      COLORS = Enigma::Theme::COLORS
      FONT = Enigma::Theme::FONT

      def initialize(parent)
        @frame = TkFrame.new(parent) { background COLORS[:bg] }
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
        main = TkFrame.new(@frame) { background COLORS[:bg] }
        main.pack(fill: :both, expand: true)

        left = TkFrame.new(main) do
          background COLORS[:panel]
          width 320
        end
        left.pack(side: :left, fill: :y, anchor: 'nw')
        left.pack_propagate(false)
        TkFrame.new(left) do
          background COLORS[:border_inactive]
          width 1
        end.pack(side: :right, fill: :y)

        right = TkFrame.new(main) { background COLORS[:bg] }
        right.pack(side: :left, fill: :both, expand: true)

        build_left_panel(left)
        build_right_panel(right)
      end

      def build_left_panel(parent)
        pad = { padx: 16, pady: [20, 0] }

        TkLabel.new(parent) do
          text 'CONFIGURATION'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:panel]
        end.pack(pad)

        TkLabel.new(parent) do
          text 'ALGORITHM'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(pad)

        algo_frame = TkFrame.new(parent) { background COLORS[:panel] }
        algo_frame.pack(pad.merge(fill: :x))
        @algorithm = Tk::Tile::Combobox.new(algo_frame) do
          values %w[AES-256-GCM ChaCha20-Poly1305 XOR César]
          state 'readonly'
          width 30
        end
        @algorithm.current = 0
        @algorithm.pack(fill: :x)

        TkLabel.new(parent) do
          text 'ENCRYPTION KEY'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(pad.merge(pady: [16, 0]))

        key_row = TkFrame.new(parent) { background COLORS[:panel] }
        key_row.pack(pad.merge(fill: :x))
        @key_entry = TkEntry.new(key_row) do
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
        @key_entry.pack(side: :left, fill: :x, expand: true)
        @key_visible = false
        eye = TkLabel.new(key_row) do
          text "\u{1F441}"
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
          cursor 'hand2'
        end
        eye.pack(side: :left, padx: [6, 0])
        eye.bind('Button-1') { toggle_key_visibility }

        TkLabel.new(parent) do
          text 'Enter secure key...'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:panel]
        end.pack(pad.merge(pady: [2, 0]))

        btn_pad = { padx: 16, pady: [20, 0], fill: :x }
        me = self

        TkButton.new(parent) do
          text 'ENCRYPT'
          font TkFont.new("#{FONT} 11 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          height 2
          command proc { me.on_encrypt }
        end.pack(btn_pad)

        TkButton.new(parent) do
          text 'DECRYPT'
          font TkFont.new("#{FONT} 11 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          height 2
          command proc { me.on_decrypt }
        end.pack(btn_pad.merge(pady: [8, 0]))

        status_card = TkFrame.new(parent) { background COLORS[:input] }
        status_card.pack(pad.merge(pady: [20, 16], fill: :x))
        TkLabel.new(status_card) do
          text "  \u{25CF}  SESSION ENCRYPTED"
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text]
          background COLORS[:input]
        end.pack(anchor: 'w', pady: [8, 2])
        TkLabel.new(status_card) do
          text "  \u{25CF}  HARDWARE ACCELERATION ACTIVE"
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:accent]
          background COLORS[:input]
        end.pack(anchor: 'w', pady: [2, 8])
      end

      def build_right_panel(parent)
        pad = { padx: 20, pady: [16, 0] }

        plain_row = TkFrame.new(parent) { background COLORS[:bg] }
        plain_row.pack(pad.merge(fill: :x))
        TkLabel.new(plain_row) do
          text 'PLAINTEXT'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(side: :left)
        @char_label = TkLabel.new(plain_row) do
          text 'CHAR: 0 | LINES: 0'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end
        @char_label.pack(side: :right)

        plain_frame = TkFrame.new(parent) { background COLORS[:bg] }
        plain_frame.pack(pad.merge(fill: :both, expand: true))
        @plain_text = TkText.new(plain_frame) do
          background COLORS[:input]
          foreground COLORS[:text]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:accent]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
          selectbackground COLORS[:accent]
          selectforeground COLORS[:bg]
          wrap 'word'
        end
        @plain_text.pack(side: :left, fill: :both, expand: true)
        ps = TkScrollbar.new(plain_frame)
        ps.pack(side: :right, fill: :y)
        @plain_text.yscrollbar(ps)
        ps.command(proc { |*args| @plain_text.yview(*args) })
        @plain_text.bind('KeyRelease') { update_char_count }

        cipher_row = TkFrame.new(parent) { background COLORS[:bg] }
        cipher_row.pack(pad.merge(pady: [8, 0], fill: :x))
        TkLabel.new(cipher_row) do
          text 'CIPHERTEXT'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(side: :left)
        copy_btn = TkLabel.new(cipher_row) do
          text "  \u{29CB}"
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:accent]
          background COLORS[:bg]
          cursor 'hand2'
        end
        copy_btn.pack(side: :right)
        copy_btn.bind('Button-1') { copy_ciphertext }

        cipher_frame = TkFrame.new(parent) { background COLORS[:bg] }
        cipher_frame.pack(pad.merge(pady: [0, 16], fill: :both, expand: true))
        @cipher_text = TkText.new(cipher_frame) do
          background COLORS[:bg]
          foreground COLORS[:accent]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:accent]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:border_inactive]
          state 'disabled'
          wrap 'word'
        end
        @cipher_text.pack(side: :left, fill: :both, expand: true)
        cs = TkScrollbar.new(cipher_frame)
        cs.pack(side: :right, fill: :y)
        @cipher_text.yscrollbar(cs)
        cs.command(proc { |*args| @cipher_text.yview(*args) })
      end

      def toggle_key_visibility
        @key_visible = !@key_visible
        @key_entry.configure('show' => @key_visible ? '' : '*')
      end

      def update_char_count
        text = @plain_text.get('1.0', 'end-1c')
        @char_label.configure('text' => "CHAR: #{text.length} | LINES: #{[text.count("\n") + 1, 1].max}")
      end

      def copy_ciphertext
        text = @cipher_text.get('1.0', 'end-1c')
        return if text.empty?

        TkClipboard.clear
        TkClipboard.add text
      end

      def on_encrypt
        plain = @plain_text.get('1.0', 'end-1c')
        return if plain.empty?

        algo = @algorithm.get
        key_str = @key_entry.get

        cipher = build_cipher(algo, key_str)
        return unless cipher

        encrypted = cipher.encrypt(plain)
        hex = encrypted.unpack1('H*')
        set_ciphertext(hex)
      rescue StandardError => e
        set_ciphertext("ERROR: #{e.message}")
      end

      def on_decrypt
        hex = @cipher_text.get('1.0', 'end-1c')
        return if hex.empty? || hex.start_with?('ERROR')

        algo = @algorithm.get
        key_str = @key_entry.get

        cipher = build_cipher(algo, key_str)
        return unless cipher

        data = [hex].pack('H*')
        decrypted = cipher.decrypt(data)
        @plain_text.delete('1.0', 'end')
        @plain_text.insert('1.0', decrypted)
        update_char_count
      rescue StandardError => e
        set_ciphertext("DECRYPT ERROR: #{e.message}")
      end

      def build_cipher(algo, key_str)
        case algo
        when 'AES-256-GCM'
          key = Digest::SHA256.digest(key_str)
          Enigma::Core::Cipher::AesGcm.new(key)
        when 'ChaCha20-Poly1305'
          key = Digest::SHA256.digest(key_str)
          Enigma::Core::Cipher::ChaCha20.new(key)
        when 'XOR'
          Enigma::Core::Cipher::Xor.new(key_str)
        when "C\u00e9sar"
          key = key_str.empty? ? '3' : key_str
          Enigma::Core::Cipher::Caesar.new(key)
        end
      end

      def set_ciphertext(text)
        @cipher_text.configure('state' => 'normal')
        @cipher_text.delete('1.0', 'end')
        @cipher_text.insert('1.0', text)
        @cipher_text.configure('state' => 'disabled')
      end
    end
  end
end
