# frozen_string_literal: true

#
# app/ui/screens/create_screen.rb
# Responsibility: First-run vault creation with security questions.
# Stores security data in vault header.
# Uses Queue + TkAfter polling (Thread-safe).
#

require 'tk'

module Enigma
  module UI
    class CreateScreen
      COLORS = MainWindow::COLORS
      FONT   = MainWindow::FONT

      SECURITY_QUESTIONS = Core::Vault::Storage::SECURITY_QUESTIONS

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
        @root.geometry('520x620+200+100')
        @root.resizable(false, false)

        @frame = TkFrame.new(@root) { background COLORS[:bg_main] }
        @frame.pack(expand: true, fill: :both)

        canvas = TkFrame.new(@frame) { background COLORS[:bg_main] }
        canvas.pack(expand: true, pady: [20, 0])

        title = TkLabel.new(canvas) do
          text '🔒  ENIGMA CRYPTOSHELTER'
          font TkFont.new("#{FONT} 14 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_main]
        end
        title.pack(pady: [0, 4])

        subtitle = TkLabel.new(canvas) do
          text 'Crear clave maestra y preguntas de seguridad'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_main]
        end
        subtitle.pack(pady: [0, 16])

        build_password_fields(canvas)
        build_strength_bar(canvas)
        build_security_questions(canvas)
        build_error_label(canvas)
        build_create_button(canvas)
      end

      def build_password_fields(parent)
        pw_card = TkFrame.new(parent) { background COLORS[:bg_panel] }
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
          text '  👁  '
          font TkFont.new(family: MainWindow::FONT_EMOJI, size: 11)
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
          text '  👁  '
          font TkFont.new(family: MainWindow::FONT_EMOJI, size: 11)
          foreground COLORS[:fg_secondary]
          background COLORS[:bg_input]
          cursor 'hand2'
        end
        toggle_confirm.pack(side: :left)
        toggle_confirm.bind('Button-1') { toggle_confirm_visibility }
      end

      def build_strength_bar(parent)
        @strength_label = TkLabel.new(parent) do
          text ''
          font TkFont.new("#{FONT} 9")
          background COLORS[:bg_main]
        end
        @strength_label.pack(anchor: 'w', padx: 40, pady: [4, 0])

        @pw_entry.bind('KeyRelease') { update_strength }
      end

      def build_security_questions(parent)
        sep = TkFrame.new(parent) do
          background COLORS[:border]
          height 1
        end
        sep.pack(fill: :x, padx: 40, pady: [12, 12])

        q_label = TkLabel.new(parent) do
          text '  PREGUNTAS DE SEGURIDAD (elige 2)'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_main]
        end
        q_label.pack(anchor: 'w', padx: 40, pady: [0, 8])

        @q_vars    = []
        @a_entries = []

        2.times do |i|
          card = TkFrame.new(parent) { background COLORS[:bg_panel] }
          card.pack(fill: :x, padx: 40, pady: [0, 8])

          q_header = TkLabel.new(card) do
            text "  Pregunta #{i + 1}"
            font TkFont.new("#{FONT} 9 bold")
            foreground COLORS[:orange]
            background COLORS[:bg_panel]
          end
          q_header.pack(anchor: 'w', padx: 16, pady: [12, 0])

          q_var = TkVariable.new
          q_var.value = SECURITY_QUESTIONS[i]
          q_combo = Tk::Tile::Combobox.new(card) do
            values SECURITY_QUESTIONS
            textvariable q_var
            state 'readonly'
            background COLORS[:bg_input]
            foreground COLORS[:fg_primary]
            font TkFont.new("#{FONT} 10")
          end
          q_combo.pack(fill: :x, padx: 16, pady: [4, 0])
          @q_vars << q_var

          a_label = TkLabel.new(card) do
            text '  Respuesta'
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:fg_secondary]
            background COLORS[:bg_panel]
          end
          a_label.pack(anchor: 'w', padx: 16, pady: [8, 0])

          a_row = TkFrame.new(card) { background COLORS[:bg_panel] }
          a_row.pack(fill: :x, padx: 16, pady: [2, 12])

          a_entry = TkEntry.new(a_row) do
            background COLORS[:bg_input]
            foreground COLORS[:fg_primary]
            font TkFont.new("#{FONT} 10")
            relief 'flat'
            highlightthickness 1
            highlightcolor COLORS[:orange]
            highlightbackground COLORS[:border]
          end
          a_entry.pack(side: :left, fill: :x, expand: true, ipady: 2)
          @a_entries << a_entry
        end
      end

      def build_error_label(parent)
        @error_label = TkLabel.new(parent) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red_err]
          background COLORS[:bg_main]
        end
        @error_label.pack(anchor: 'w', padx: 40, pady: [4, 0])
      end

      def build_create_button(parent)
        btn_frame = TkFrame.new(parent) { background COLORS[:bg_main] }
        btn_frame.pack(pady: [8, 20])

        @create_btn = TkButton.new(btn_frame) do
          text '  CREAR VAULT  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg_main]
          background COLORS[:orange]
          relief 'flat'
        end
        @create_btn.pack(fill: :x, padx: 40, ipady: 6)

        screen = self
        @create_btn.command(proc { screen.send(:on_create) })
      end

      def on_create
        pw      = @pw_entry.value
        confirm = @confirm_entry.value

        if pw.length < 8
          @error_label.configure('text' => '  Mínimo 8 caracteres')
          return
        end

        if pw != confirm
          @error_label.configure('text' => '  Las claves no coinciden')
          return
        end

        answers = []
        questions_data = []
        valid = true
        @q_vars.each_with_index do |qv, i|
          q_text = qv.value.strip.force_encoding('UTF-8')
          a_text = @a_entries[i].value.strip.force_encoding('UTF-8')
          if q_text.empty? || a_text.empty?
            @error_label.configure('text' => "  Completa pregunta #{i + 1} y su respuesta")
            valid = false
            break
          end
          idx = SECURITY_QUESTIONS.index(q_text)
          unless idx
            @error_label.configure('text' => "  Pregunta #{i + 1} no válida")
            valid = false
            break
          end
          questions_data << { index: idx, answer: a_text }
          answers << a_text
        end
        return unless valid

        @create_btn.configure('state' => 'disabled', 'text' => '  Creando...  ')
        @error_label.configure('text' => '')
        Tk.update

        queue = Queue.new

        Thread.new do
          security_data = {
            questions: questions_data.map { |q| { index: q[:index], answer: q[:answer] } },
            answers: answers
          }
          session = Core::Facades::VaultFacade.create(pw, security_data: security_data)
          queue << [:ok, session]
        rescue StandardError => e
          warn "[CreateScreen] #{e.class}: #{e.message}"
          queue << [:error, e.message]
        end

        poll_create(queue)
      end

      def poll_create(queue)
        TkAfter.new(50, 1) do
          result = begin; queue.pop(true); rescue ThreadError; nil; end

          if result.nil?
            poll_create(queue)
            return
          end

          case result[0]
          when :ok
            @on_success.call(result[1])
          when :error
            @error_label.configure('text' => "  Error: #{result[1]}")
            @create_btn.configure('state' => 'normal', 'text' => '  CREAR VAULT  ')
          end
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
        label = { weak: 'Débil', medium: 'Media', strong: 'Fuerte' }[level]
        @strength_label.configure(
          'text' => "  #{label}",
          'foreground' => color
        )
      end
    end
  end
end
