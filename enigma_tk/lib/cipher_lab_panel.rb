require 'tk'
require 'tkextlib/tile'

class CipherLabPanel
  COLORS = CryptoshelterApp::COLORS
  FONT = CryptoshelterApp::FONT

  def initialize(parent, app)
    @app = app
    @frame = TkFrame.new(parent) do
      background COLORS[:bg]
    end
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
      values ['AES-256-GCM', 'ChaCha20-Poly1305', 'XOR', "C\u00e9sar"]
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
    eye_btn = TkLabel.new(key_row) do
      text "\u{1F441}"
      font TkFont.new("#{FONT} 11")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
      cursor 'hand2'
    end
    eye_btn.pack(side: :left, padx: [6, 0])
    eye_btn.bind('Button-1') { toggle_key_visibility }

    TkLabel.new(parent) do
      text 'Enter secure key...'
      font TkFont.new("#{FONT} 9")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
    end.pack(pad.merge(pady: [2, 0]))

    btn_pad = { padx: 16, pady: [20, 0], fill: :x }

    encrypt_btn = TkButton.new(parent) do
      text 'ENCRYPT'
      font TkFont.new("#{FONT} 11 bold")
      foreground COLORS[:bg]
      background COLORS[:accent]
      relief 'flat'
      height 2
      command method(:on_encrypt)
    end
    encrypt_btn.pack(btn_pad)

    decrypt_btn = TkButton.new(parent) do
      text 'DECRYPT'
      font TkFont.new("#{FONT} 11 bold")
      foreground COLORS[:accent]
      background COLORS[:bg]
      relief 'flat'
      highlightthickness 1
      highlightcolor COLORS[:accent]
      highlightbackground COLORS[:accent]
      height 2
      command method(:on_decrypt)
    end
    decrypt_btn.pack(btn_pad.merge(pady: [8, 0]))

    status_card = TkFrame.new(parent) do
      background COLORS[:input]
    end
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

    plain_scroll = TkScrollbar.new(plain_frame) do
      foreground COLORS[:accent]
      background COLORS[:input]
    end
    plain_scroll.pack(side: :right, fill: :y)
    @plain_text.yscrollbar(plain_scroll)
    plain_scroll.command(proc { |*args| @plain_text.yview(*args) })

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

    cipher_scroll = TkScrollbar.new(cipher_frame) do
      foreground COLORS[:accent]
      background COLORS[:input]
    end
    cipher_scroll.pack(side: :right, fill: :y)
    @cipher_text.yscrollbar(cipher_scroll)
    cipher_scroll.command(proc { |*args| @cipher_text.yview(*args) })
  end

  def toggle_key_visibility
    @key_visible = !@key_visible
    @key_entry.configure('show' => @key_visible ? '' : '*')
  end

  def update_char_count
    text = @plain_text.get('1.0', 'end-1c')
    chars = text.length
    lines = [text.count("\n") + 1, 1].max
    @char_label.configure('text' => "CHAR: #{chars} | LINES: #{lines}")
  end

  def copy_ciphertext
    text = @cipher_text.get('1.0', 'end-1c')
    return if text.empty?

    TkClipboard.clear
    TkClipboard.add text
  end

  def on_encrypt
  end

  def on_decrypt
  end
end
