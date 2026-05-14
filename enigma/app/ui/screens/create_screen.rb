# frozen_string_literal: true
# encoding: utf-8

#
# app/ui/screens/create_screen.rb
# Responsibility: First-run vault creation screen with security questions.
#

require 'tk'

module Enigma
  module UI
    class CreateScreen
      COLORS = MainWindow::COLORS
      FONT   = MainWindow::FONT

      SECURITY_QUESTIONS = [
        "¿Cuál es el nombre de tu mascota?",
        "¿Cuál es tu ciudad favorita?",
        "¿Cuál es el nombre de tu primer profesor?",
        "¿Cuál es tu comida favorita?",
        "¿Cuál es el año de nacimiento de tu madre?",
        "¿Cuál es tu libro favorito?",
        "¿Cuál es tu película favorita?",
        "¿Cuál es el nombre de tu mejor amigo de la infancia?",
        "¿Cuál es tu deporte favorito?",
        "¿Cuál es el modelo de tu primer auto?",
        "¿Cuál es el nombre de tu escuela primaria?",
        "¿Cuál es tu color favorito?",
        "¿Cuál es el nombre de soltera de tu madre?",
        "¿Cuál es tu estación del año favorita?",
        "¿Cuál es tu artista o banda favorita?",
        "¿Cuál es tu destino de viaje soñado?",
        "¿Cuál es el segundo apellido de tu padre?",
        "¿Cuál es tu número de la suerte?"
      ].freeze

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
          text "🔒  ENIGMA CRYPTOSHELTER"
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
          text '  PREGUNTAS DE SEGURIDAD (elige o escribe la tuya)'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:orange]
          background COLORS[:bg_main]
        end
        q_label.pack(anchor: 'w', padx: 40, pady: [0, 8])

        @q_entries = []
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
            background COLORS[:bg_input]
            foreground COLORS[:fg_primary]
            font TkFont.new("#{FONT} 10")
          end
          q_combo.pack(fill: :x, padx: 16, pady: [4, 0])
          @q_vars << q_var
          @q_entries << q_combo

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

        questions = []
        @q_vars.each_with_index do |qv, i|
          q = qv.value.strip
          a = @a_entries[i].value.strip
          if q.empty? || a.empty?
            @error_label.configure('text' => "  Completa pregunta #{i + 1} y su respuesta")
            return
          end
          questions << { 'q' => q, 'h' => OpenSSL::Digest::SHA256.hexdigest(a.downcase) }
        end

        @create_btn.configure('state' => 'disabled', 'text' => '  Creando...  ')
        @error_label.configure('text' => '')
        Tk.update

        Core::Auth::AuthConfig.new.create!(pw, questions)
        session = Core::Facades::VaultFacade.create(pw)
        @on_success.call(session)
      rescue StandardError => e
        warn "[CreateScreen] #{e.class}: #{e.message}"
        @error_label.configure('text' => "  Error: #{e.message}")
        @create_btn.configure('state' => 'normal', 'text' => '  CREAR VAULT  ')
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
