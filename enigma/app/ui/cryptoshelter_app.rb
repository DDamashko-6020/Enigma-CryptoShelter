# frozen_string_literal: true

require 'tk'
require 'tkextlib/tile'
require 'openssl'

require_relative 'cipher_lab_panel'
require_relative 'vault_panel'
require_relative 'file_lock_panel'
require_relative '../core/auth/auth_config'

module Enigma
  module UI
    class CryptoshelterApp
      COLORS = Enigma::Theme::COLORS
      FONT = Enigma::Theme::FONT

      SECURITY_QUESTIONS = [
        'What is the name of your first pet?',
        'What city were you born in?',
        "What is your mother's maiden name?",
        'What was the name of your first school?',
        'What is your favorite book?',
        'What year did you graduate high school?',
        'What is the name of your childhood best friend?',
        'What is the model of your first car?'
      ].freeze

      def initialize
        @root = TkRoot.new
        @root.title 'ENIGMA CRYPTOSHELTER'
        @root.background COLORS[:bg]
        @master_password = nil
      end

      def run
        if Core::Auth::AuthConfig.new.exists?
          show_login
        else
          show_register
        end
        Tk.mainloop
      end

      private

      def show_login
        @root.geometry('420x320+200+150')
        @root.resizable(false, false)

        center = TkFrame.new(@root) { background COLORS[:bg] }
        center.pack(expand: true)

        TkLabel.new(center) do
          text "\u{1F512}  ENIGMA CRYPTOSHELTER"
          font TkFont.new("#{FONT} 14 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(pady: [0, 4])

        TkLabel.new(center) do
          text 'Enter master password to access your vault'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(pady: [0, 16])

        pw_entry = styled_entry(center, show: '*')
        pw_entry.pack(fill: :x, ipady: 6, padx: 40)
        pw_entry.focus

        error_label = TkLabel.new(center) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:bg]
        end
        error_label.pack(anchor: 'w', padx: 40, pady: [4, 0])

        btn_frame = TkFrame.new(center) { background COLORS[:bg] }
        btn_frame.pack(pady: [12, 0])

        TkButton.new(btn_frame) do
          text '  UNLOCK  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            pw = pw_entry.get
            if pw.empty?
              error_label.configure('text' => '  Enter your master password.')
              next
            end
            if Core::Auth::AuthConfig.new.verify(pw)
              @master_password = pw
              @root.geometry('1200x800+50+50')
              @root.resizable(false, false)
              center.pack_forget
              build_main_app
            else
              error_label.configure('text' => '  Incorrect master password.')
            end
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  QUIT  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { exit }
        end.pack(side: :left)

        forgot_btn = TkLabel.new(center) do
          text '  Forgot password?  '
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
          cursor 'hand2'
        end
        forgot_btn.pack(pady: [12, 0])
        forgot_btn.bind('Button-1') { on_forgot_password }

        pw_entry.bind('Return') do
          pw = pw_entry.get
          if Core::Auth::AuthConfig.new.verify(pw)
            @master_password = pw
            @root.geometry('1200x800+50+50')
            @root.resizable(false, false)
            center.pack_forget
            build_main_app
          else
            error_label.configure('text' => '  Incorrect master password.')
          end
        end
      end

      def show_register
        @root.geometry('520x620+200+100')
        @root.resizable(false, false)

        title_frame = TkFrame.new(@root) { background COLORS[:bg] }
        title_frame.pack(fill: :x, padx: 30, pady: [24, 0])

        TkLabel.new(title_frame) do
          text "\u{1F512}  ENIGMA CRYPTOSHELTER"
          font TkFont.new("#{FONT} 14 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack

        TkLabel.new(title_frame) do
          text 'First-time setup \u{2014} create your master password'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(pady: [4, 0])

        @register_sep = TkFrame.new(@root) do
          background COLORS[:border_inactive]
          height 1
        end
        @register_sep.pack(fill: :x, padx: 30, pady: [16, 0])

        body = TkFrame.new(@root) { background COLORS[:bg] }
        body.pack(fill: :both, expand: true, padx: 30, pady: [12, 0])

        TkLabel.new(body) do
          text '  MASTER PASSWORD'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(anchor: 'w', pady: [8, 4])

        row1 = TkFrame.new(body) { background COLORS[:bg] }
        row1.pack(fill: :x, pady: 2)
        TkLabel.new(row1) do
          text '  Password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:bg]
        end.pack(side: :left)
        pw_entry = styled_entry(row1, show: '*')
        pw_entry.pack(side: :right, fill: :x, expand: true)

        row2 = TkFrame.new(body) { background COLORS[:bg] }
        row2.pack(fill: :x, pady: 2)
        TkLabel.new(row2) do
          text '  Confirm:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:bg]
        end.pack(side: :left)
        confirm_entry = styled_entry(row2, show: '*')
        confirm_entry.pack(side: :right, fill: :x, expand: true)

        pw_error = TkLabel.new(body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:bg]
        end
        pw_error.pack(anchor: 'w', pady: [2, 0])

        TkFrame.new(body) do
          background COLORS[:border_inactive]
          height 1
        end.pack(fill: :x, pady: [8, 0])

        TkLabel.new(body) do
          text '  SECURITY QUESTIONS'
          font TkFont.new("#{FONT} 9 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
        end.pack(anchor: 'w', pady: [12, 4])

        TkLabel.new(body) do
          text '  Used to recover access if you forget your master password.'
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:text_secondary]
          background COLORS[:bg]
        end.pack(anchor: 'w')

        question_fields = []
        3.times do
          q_frame = TkFrame.new(body) { background COLORS[:bg] }
          q_frame.pack(fill: :x, pady: [6, 0])

          combo = Tk::Tile::Combobox.new(q_frame) do
            values SECURITY_QUESTIONS
            state 'readonly'
            font TkFont.new("#{FONT} 10")
            foreground COLORS[:text]
            background COLORS[:input]
          end
          combo.pack(fill: :x, ipady: 2)

          a_frame = TkFrame.new(q_frame) { background COLORS[:bg] }
          a_frame.pack(fill: :x, pady: [2, 0])
          TkLabel.new(a_frame) do
            text '  Answer:'
            font TkFont.new("#{FONT} 9")
            foreground COLORS[:text_secondary]
            background COLORS[:bg]
          end.pack(side: :left)
          ans_entry = styled_entry(a_frame)
          ans_entry.pack(side: :right, fill: :x, expand: true)

          question_fields << { combo: combo, answer: ans_entry }
        end

        error_label = TkLabel.new(body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:bg]
        end
        error_label.pack(anchor: 'w', pady: [4, 0])

        btn_frame = TkFrame.new(@root) { background COLORS[:bg] }
        btn_frame.pack(fill: :x, padx: 30, pady: [12, 20])

        TkButton.new(btn_frame) do
          text '  CREATE MASTER PASSWORD  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            pw = pw_entry.get
            confirm = confirm_entry.get
            if pw.length < 8
              error_label.configure('text' => '  Password must be at least 8 characters.')
              next
            end
            if pw != confirm
              error_label.configure('text' => '  Passwords do not match.')
              next
            end
            questions = []
            question_fields.each_with_index do |field, i|
              q = field[:combo].get
              a = field[:answer].get.strip.downcase
              if q.empty? || a.empty?
                error_label.configure('text' => "  Please fill in question #{i + 1} and its answer.")
                next
              end
              questions << { 'q' => q, 'h' => OpenSSL::Digest::SHA256.hexdigest(a) }
            end
            Core::Auth::AuthConfig.new.create!(pw, questions)
            @master_password = pw
            @root.geometry('1200x800+50+50')
            @root.resizable(false, false)
            title_frame.pack_forget
            @register_sep.pack_forget
            body.pack_forget
            btn_frame.pack_forget
            build_main_app
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  QUIT  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { exit }
        end.pack(side: :left)
      end

      def on_forgot_password
        auth = Core::Auth::AuthConfig.new
        questions = auth.load_questions_text
        unless questions && questions.length == 3
          Tk.messageBox('type' => 'ok', 'icon' => 'error',
                        'title' => 'Error', 'message' => 'Could not load security questions.')
          return
        end

        dialog = build_dialog('Recover Access', 480, 340)
        answers = []

        questions.each_with_index do |q, i|
          q_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
          q_frame.pack(fill: :x, padx: 20, pady: [0, 8])
          TkLabel.new(q_frame) do
            text "  #{i + 1}. #{q}"
            font TkFont.new("#{FONT} 9 bold")
            foreground COLORS[:accent]
            background COLORS[:panel]
          end.pack(anchor: 'w')
          entry = styled_entry(q_frame)
          entry.pack(fill: :x, ipady: 2)
          answers << entry
        end

        error_lbl = TkLabel.new(dialog.body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:panel]
        end
        error_lbl.pack(anchor: 'w', padx: 20, pady: [2, 0])

        btn_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        btn_frame.pack(fill: :x, padx: 20, pady: [8, 16])

        stored = auth.load_questions_with_hashes || []
        TkButton.new(btn_frame) do
          text '  VERIFY  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            hashed = answers.map { |e| OpenSSL::Digest::SHA256.hexdigest(e.get.strip.downcase) }
            if stored.empty? || hashed == stored.map { |q| q['h'] }
              dialog.close
              show_reset_password
            else
              error_lbl.configure('text' => '  One or more answers are incorrect.')
            end
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  CANCEL  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { dialog.close }
        end.pack(side: :left)
      end

      def show_reset_password
        dialog = build_dialog('Reset Master Password', 400, 220)

        TkLabel.new(dialog.body) do
          text '  Create a new master password:'
          font TkFont.new("#{FONT} 10")
          foreground COLORS[:text]
          background COLORS[:panel]
        end.pack(anchor: 'w', padx: 20, pady: [16, 8])

        pw = styled_entry(dialog.body, show: '*')
        pw.pack(fill: :x, padx: 20, ipady: 4)

        confirm = styled_entry(dialog.body, show: '*')
        confirm.pack(fill: :x, padx: 20, ipady: 4, pady: [8, 0])

        error_lbl = TkLabel.new(dialog.body) do
          text ''
          font TkFont.new("#{FONT} 9")
          foreground COLORS[:red]
          background COLORS[:panel]
        end
        error_lbl.pack(anchor: 'w', padx: 20, pady: [2, 0])

        btn_frame = TkFrame.new(dialog.body) { background COLORS[:panel] }
        btn_frame.pack(fill: :x, padx: 20, pady: [8, 16])

        TkButton.new(btn_frame) do
          text '  RESET  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:bg]
          background COLORS[:accent]
          relief 'flat'
          command proc {
            p1 = pw.get
            p2 = confirm.get
            if p1.length < 8
              error_lbl.configure('text' => '  Minimum 8 characters.')
            elsif p1 != p2
              error_lbl.configure('text' => '  Passwords do not match.')
            elsif Core::Auth::AuthConfig.new.reset_master_password(p1)
              dialog.close
              Tk.messageBox('type' => 'ok', 'icon' => 'info',
                            'title' => 'Success',
                            'message' => 'Password reset successfully. You can now log in with your new password.')
            else
              error_lbl.configure('text' => '  Failed to reset password.')
            end
          }
        end.pack(side: :left, padx: [0, 12])

        TkButton.new(btn_frame) do
          text '  CANCEL  '
          font TkFont.new("#{FONT} 10 bold")
          foreground COLORS[:accent]
          background COLORS[:bg]
          relief 'flat'
          highlightthickness 1
          highlightcolor COLORS[:accent]
          highlightbackground COLORS[:accent]
          command proc { dialog.close }
        end.pack(side: :left)
      end

      def build_main_app
        @current_tab = 'cipher_lab'
        build_top_nav
        build_content_area
        build_status_bar
      end

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

      def build_dialog(title, width, height)
        dlg = TkToplevel.new(@root) do
          title title
          geometry "#{width}x#{height}+#{@root.winfo_rootx + 80}+#{@root.winfo_rooty + 80}"
          background COLORS[:panel]
        end
        dlg.transient(@root)
        dlg.grab_set
        dlg.focus

        body = TkFrame.new(dlg) { background COLORS[:panel] }
        body.pack(fill: :both, expand: true)

        res = OpenStruct.new
        res.body = body
        res.dlg = dlg
        res.close = proc {
          dlg.grab_release
          dlg.destroy
        }

        dlg.protocol('WM_DELETE_WINDOW', res.close)
        res
      end

      def styled_entry(parent, show: nil)
        opts = {
          'background' => COLORS[:input],
          'foreground' => COLORS[:text],
          'font' => TkFont.new("#{FONT} 11"),
          'insertbackground' => COLORS[:accent],
          'relief' => 'flat',
          'highlightthickness' => 1,
          'highlightcolor' => COLORS[:accent],
          'highlightbackground' => COLORS[:border_inactive]
        }
        opts['show'] = show if show
        TkEntry.new(parent, opts)
      end
    end
  end
end
