# frozen_string_literal: true
# encoding: utf-8

#
# app/ui/screens/recovery_screen.rb
# Responsibility: Password recovery via security questions.
#

require 'tk'
require 'fileutils'

module Enigma
  module UI
    class RecoveryScreen
      COLORS = MainWindow::COLORS
      FONT   = MainWindow::FONT

      STEP_QUESTIONS = 0
      STEP_RESET     = 1

      def initialize(root, on_recovered, on_back = nil)
        @root         = root
        @on_recovered = on_recovered
        @on_back      = on_back
        @auth         = Core::Auth::AuthConfig.new
        @step         = STEP_QUESTIONS
        build_questions
      end

      def hide
        @frame.pack_forget
      end

      private

      def build_questions
        @root.geometry('480x400+200+150')
        @root.resizable(false, false)

        @frame = TkFrame.new(@root) { background COLORS[:bg_main] }
        @frame.pack(expand: true)

        title = TkLabel.new(@frame) do
          text "🔓  RECUPERAR ACCESO"
          font TkFont.new("#{FONT} 14 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_main]
        end
        title.pack(pady: [20, 4])

        subtitle = TkLabel.new(@frame) do
          text 'Responde las preguntas de seguridad'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_main]
        end
        subtitle.pack(pady: [0, 16])

        questions = @auth.load_questions_text || []
        if questions.empty?
          @error_label = TkLabel.new(@frame) do
            text '  No hay preguntas configuradas'
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:red_err]
            background COLORS[:bg_main]
          end
          @error_label.pack
          return
        end

        @answer_entries = []

        questions.each_with_index do |q, i|
          card = TkFrame.new(@frame) { background COLORS[:bg_panel] }
          card.pack(fill: :x, padx: 40, pady: [0, 10])

          q_label = TkLabel.new(card) do
            text "  #{i + 1}. #{q}"
            font TkFont.new("#{FONT} 9 bold")
            foreground COLORS[:orange]
            background COLORS[:bg_panel]
            wraplength 380
            justify 'left'
          end
          q_label.pack(anchor: 'w', padx: 16, pady: [12, 4])

          entry = TkEntry.new(card) do
            background COLORS[:bg_input]
            foreground COLORS[:fg_primary]
            font TkFont.new("#{FONT} 11")
            relief 'flat'
            highlightthickness 1
            highlightcolor COLORS[:orange]
            highlightbackground COLORS[:border]
          end
          entry.pack(fill: :x, padx: 16, pady: [0, 12], ipady: 4)
          @answer_entries << entry
        end

        @error_label = TkLabel.new(@frame) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red_err]
          background COLORS[:bg_main]
        end
        @error_label.pack(anchor: 'w', padx: 40, pady: [4, 0])

        btn_frame = TkFrame.new(@frame) { background COLORS[:bg_main] }
        btn_frame.pack(pady: [8, 20])

        @verify_btn = TkButton.new(btn_frame) do
          text '  VERIFICAR RESPUESTAS  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg_main]
          background COLORS[:orange]
          relief 'flat'
        end
        @verify_btn.pack(fill: :x, padx: 40, ipady: 6)

        screen = self
        @verify_btn.command(proc { screen.send(:on_verify) })

        if @on_back
          back_link = TkLabel.new(@frame) do
            text '  ← Volver a la pantalla de inicio'
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:fg_secondary]
            background COLORS[:bg_main]
            cursor 'hand2'
          end
          back_link.pack(pady: [4, 4])
          back_link.bind('Button-1') { @frame.pack_forget; @on_back.call }
        end
      end

      def on_verify
        answers = @answer_entries.map { |e| e.value }

        if answers.any?(&:empty?)
          @error_label.configure('text' => '  Responde todas las preguntas')
          return
        end

        unless @auth.verify_answers(answers)
          @error_label.configure('text' => '  Respuestas incorrectas')
          return
        end

        @frame.pack_forget
        build_reset_form
      end

      def build_reset_form
        @root.geometry('480x320+200+150')

        @frame = TkFrame.new(@root) { background COLORS[:bg_main] }
        @frame.pack(expand: true)

        title = TkLabel.new(@frame) do
          text "✅  RESPUESTAS CORRECTAS"
          font TkFont.new("#{FONT} 14 bold")
          foreground COLORS[:green_ok]
          background COLORS[:bg_main]
        end
        title.pack(pady: [20, 16])

        card = TkFrame.new(@frame) { background COLORS[:bg_panel] }
        card.pack(fill: :x, padx: 40)

        pw_label = TkLabel.new(card) do
          text '  Nueva clave maestra'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_panel]
        end
        pw_label.pack(anchor: 'w', padx: 16, pady: [16, 0])

        @new_pw = TkEntry.new(card) do
          background COLORS[:bg_input]
          foreground COLORS[:fg_primary]
          font TkFont.new("#{FONT} 11")
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:orange]
          highlightbackground COLORS[:border]
        end
        @new_pw.pack(fill: :x, padx: 16, pady: [4, 0], ipady: 4)

        conf_label = TkLabel.new(card) do
          text '  Confirmar nueva clave'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_panel]
        end
        conf_label.pack(anchor: 'w', padx: 16, pady: [12, 0])

        @new_confirm = TkEntry.new(card) do
          background COLORS[:bg_input]
          foreground COLORS[:fg_primary]
          font TkFont.new("#{FONT} 11")
          show '*'
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:orange]
          highlightbackground COLORS[:border]
        end
        @new_confirm.pack(fill: :x, padx: 16, pady: [4, 16], ipady: 4)

        @reset_error = TkLabel.new(@frame) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red_err]
          background COLORS[:bg_main]
        end
        @reset_error.pack(anchor: 'w', padx: 40, pady: [4, 0])

        btn_frame = TkFrame.new(@frame) { background COLORS[:bg_main] }
        btn_frame.pack(pady: [12, 20])

        reset_btn = TkButton.new(btn_frame) do
          text '  RESTABLECER Y REINICIAR  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg_main]
          background COLORS[:orange]
          relief 'flat'
        end
        reset_btn.pack(fill: :x, padx: 40, ipady: 6)

        screen = self
        reset_btn.command(proc { screen.send(:on_reset) })

        if @on_back
          back_link = TkLabel.new(@frame) do
            text '  ← Volver'
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:fg_secondary]
            background COLORS[:bg_main]
            cursor 'hand2'
          end
          back_link.pack(pady: [4, 4])
          back_link.bind('Button-1') { @frame.pack_forget; @on_back.call }
        end
      end

      def on_reset
        pw = @new_pw.value
        confirm = @new_confirm.value

        if pw.length < 8
          @reset_error.configure('text' => '  Mínimo 8 caracteres')
          return
        end

        if pw != confirm
          @reset_error.configure('text' => '  Las claves no coinciden')
          return
        end

        @reset_error.configure('text' => '  Restableciendo...', 'foreground' => COLORS[:orange])
        Tk.update

        vault_path = Core::Vault::Storage::VAULT_PATH
        FileUtils.rm_f(vault_path) if File.exist?(vault_path)

        auth_path = Core::Auth::AuthConfig::AUTH_PATH
        FileUtils.rm_f(auth_path) if File.exist?(auth_path)

        @on_recovered.call
      rescue StandardError => e
        @reset_error.configure('text' => "  Error: #{e.message}", 'foreground' => COLORS[:red_err])
      end
    end
  end
end
