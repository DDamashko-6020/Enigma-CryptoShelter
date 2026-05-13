# frozen_string_literal: true

#
# app/ui/screens/create_screen.rb
# Responsibility: First-run vault creation screen.
#

require 'tk'

module Enigma
  module UI
    class CreateScreen
      COLORS = MainWindow::COLORS
      FONT   = MainWindow::FONT

      def initialize(root, on_success)
        @root       = root
        @on_success = on_success
        build
      end

      def hide
        @frame.pack_forget
      end

      private

      def build
        @root.geometry('480x420+200+150')
        @root.resizable(false, false)

        @frame = TkFrame.new(@root) { background COLORS[:bg_main] }
        @frame.pack(expand: true)

        title = TkLabel.new(@frame) do
          text "\u{1F512}  ENIGMA CRYPTOSHELTER"
          font TkFont.new("#{FONT} 14 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_main]
        end
        title.pack(pady: [0, 4])

        subtitle = TkLabel.new(@frame) do
          text 'Crear clave maestra'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_main]
        end
        subtitle.pack(pady: [0, 20])

        build_password_fields
        build_strength_bar
        build_error_label
        build_create_button
      end

      def build_password_fields
        pw_card = TkFrame.new(@frame) { background COLORS[:bg_panel] }
        pw_card.pack(fill: :x, padx: 40)

        pw_label = TkLabel.new(pw_card) do
          text '  Clave maestra'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_panel]
        end
        pw_label.pack(anchor: 'w', padx: 16, pady: [16, 0])

        pw_row = TkFrame.new(pw_card) { background COLORS[:bg_panel] }
        pw_row.pack(fill: :x, padx: 16, pady: [4, 0])

        @pw_entry = TkEntry.new(pw_row) do
          background COLORS[:bg_input]
          foreground COLORS[:fg_primary]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:orange]
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:orange]
          highlightbackground COLORS[:border]
        end
        @pw_entry.pack(side: :left, fill: :x, expand: true, ipady: 4)
        @pw_entry.focus

        toggle_pw = TkLabel.new(pw_row) do
          text '  \u{1F441}  '
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_input]
          cursor 'hand2'
        end
        toggle_pw.pack(side: :left)
        toggle_pw.bind('Button-1') { toggle_password }

        confirm_label = TkLabel.new(pw_card) do
          text '  Confirmar clave maestra'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_panel]
        end
        confirm_label.pack(anchor: 'w', padx: 16, pady: [12, 0])

        confirm_row = TkFrame.new(pw_card) { background COLORS[:bg_panel] }
        confirm_row.pack(fill: :x, padx: 16, pady: [4, 16])

        @confirm_entry = TkEntry.new(confirm_row) do
          background COLORS[:bg_input]
          foreground COLORS[:fg_primary]
          font TkFont.new("#{FONT} 11")
          insertbackground COLORS[:orange]
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:orange]
          highlightbackground COLORS[:border]
        end
        @confirm_entry.pack(side: :left, fill: :x, expand: true, ipady: 4)

        toggle_confirm = TkLabel.new(confirm_row) do
          text '  \u{1F441}  '
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_input]
          cursor 'hand2'
        end
        toggle_confirm.pack(side: :left)
        toggle_confirm.bind('Button-1') { toggle_confirm_visibility }
      end

      def build_strength_bar
        @strength_label = TkLabel.new(@frame) do
          text ''
          font TkFont.new("#{FONT} 9")
          background COLORS[:bg_main]
        end
        @strength_label.pack(anchor: 'w', padx: 40, pady: [4, 0])

        @pw_entry.bind('KeyRelease') { update_strength }
      end

      def build_error_label
        @error_label = TkLabel.new(@frame) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red_err]
          background COLORS[:bg_main]
        end
        @error_label.pack(anchor: 'w', padx: 40, pady: [4, 0])
      end

      def build_create_button
        btn_frame = TkFrame.new(@frame) { background COLORS[:bg_main] }
        btn_frame.pack(pady: [16, 0])

        screen = self
        TkButton.new(btn_frame) do
          text '  CREAR VAULT  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg_main]
          background COLORS[:orange]
          relief 'flat'
          command proc { screen.send(:on_create) }
        end.pack(fill: :x, padx: 40, ipady: 6)
      end

      def on_create
        pw      = @pw_entry.value
        confirm = @confirm_entry.value

        if pw.length < 8
          @error_label.configure('text' => '  M\u00ednimo 8 caracteres')
          return
        end

        if pw != confirm
          @error_label.configure('text' => '  Las claves no coinciden')
          return
        end

        begin
          session = Core::Facades::VaultFacade.create(pw)
          @on_success.call(session)
        rescue StandardError => e
          @error_label.configure('text' => "  Error: #{e.message}")
        end
      end

      def toggle_password
        current = @pw_entry.cget('show')
        @pw_entry.configure('show' => current == '*' ? '' : '*')
      end

      def toggle_confirm_visibility
        current = @confirm_entry.cget('show')
        @confirm_entry.configure('show' => current == '*' ? '' : '*')
      end

      def update_strength
        level = Utils::PasswordGenerator.strength(@pw_entry.value)
        color = case level
                when :weak then COLORS[:red_err]
                when :medium then COLORS[:orange]
                else COLORS[:green_ok]
                end
        label = { weak: 'D\u00e9bil', medium: 'Media', strong: 'Fuerte' }[level]
        @strength_label.configure(
          'text' => "  #{label}",
          'foreground' => color
        )
      end
    end
  end
end
