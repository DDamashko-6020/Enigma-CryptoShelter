# frozen_string_literal: true

#
# app/ui/screens/unlock_screen.rb
# Responsibility: Returning-user vault unlock screen with loading state.
#

require 'tk'

module Enigma
  module UI
    class UnlockScreen
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
        @root.geometry('420x320+200+150')
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
          text 'Ingresa tu clave maestra'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_main]
        end
        subtitle.pack(pady: [0, 20])

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
        pw_row.pack(fill: :x, padx: 16, pady: [4, 16])

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

        toggle_btn = TkLabel.new(pw_row) do
          text '  \u{1F441}  '
          font TkFont.new("#{FONT} 11")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_input]
          cursor 'hand2'
        end
        toggle_btn.pack(side: :left)
        toggle_btn.bind('Button-1') { toggle_password }

        @error_label = TkLabel.new(@frame) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red_err]
          background COLORS[:bg_main]
        end
        @error_label.pack(anchor: 'w', padx: 40, pady: [4, 0])

        btn_frame = TkFrame.new(@frame) { background COLORS[:bg_main] }
        btn_frame.pack(pady: [16, 0])

        @unlock_btn = TkButton.new(btn_frame) do
          text '  ABRIR VAULT  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg_main]
          background COLORS[:orange]
          relief 'flat'
        end
        @unlock_btn.pack(fill: :x, padx: 40, ipady: 6)

        screen = self
        @unlock_btn.command(proc { screen.send(:on_unlock) })

        @pw_entry.bind('Return') { on_unlock }
      end

      def on_unlock
        pw = @pw_entry.value
        if pw.empty?
          @error_label.configure('text' => '  Ingresa tu clave maestra')
          return
        end

        @unlock_btn.configure('state' => 'disabled', 'text' => '  Verificando...  ')
        @error_label.configure('text' => '')
        Tk.update

        queue = Queue.new
        Thread.new do
          begin
            session = Core::Facades::VaultFacade.open(pw)
            queue << [:ok, session]
          rescue Errors::AuthTagError
            queue << [:auth_error]
          rescue StandardError => e
            queue << [:error, e.message]
          end
        end

        poll_unlock(queue)
      end

      def poll_unlock(queue)
        TkAfter.new(100, 1) do
          result = begin
            queue.pop(nonblock: true)
          rescue ThreadError
            nil
          end

          if result.nil?
            poll_unlock(queue)
            return
          end

          case result[0]
          when :ok
            @on_success.call(result[1])
          when :auth_error
            @unlock_btn.configure('state' => 'normal', 'text' => '  ABRIR VAULT  ')
            @error_label.configure('text' => '  Clave incorrecta')
          when :error
            @unlock_btn.configure('state' => 'normal', 'text' => '  ABRIR VAULT  ')
            @error_label.configure('text' => "  Error: #{result[1]}")
          end
        end
      end

      def toggle_password
        current = @pw_entry.cget('show')
        @pw_entry.configure('show' => current == '*' ? '' : '*')
      end
    end
  end
end
