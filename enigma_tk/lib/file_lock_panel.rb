require 'tk'
require 'tkextlib/tile'

class FileLockPanel
  COLORS = Theme::COLORS
  FONT = Theme::FONT

  def initialize(parent, app)
    @app = app
    @key_visible = false

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
    pad = { padx: 40, pady: [30, 0] }

    TkLabel.new(@frame) do
      text 'FILE LOCK'
      font TkFont.new("#{FONT} 12 bold")
      foreground COLORS[:accent]
      background COLORS[:bg]
    end.pack(pad.merge(anchor: 'w'))

    TkLabel.new(@frame) do
      text 'Encrypt or decrypt files using symmetric-key cryptography'
      font TkFont.new("#{FONT} 9")
      foreground COLORS[:text_secondary]
      background COLORS[:bg]
    end.pack(pad.merge(anchor: 'w', pady: [4, 0]))

    cfg_card = TkFrame.new(@frame) { background COLORS[:panel] }
    cfg_card.pack(pad.merge(fill: :x, pady: [20, 0]))

    TkLabel.new(cfg_card) do
      text '  CONFIGURATION'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:accent]
      background COLORS[:panel]
    end.pack(anchor: 'w', pady: [16, 0], padx: 20)

    build_file_row(cfg_card)
    build_key_row(cfg_card)
    build_algo_row(cfg_card)
    build_action_row(cfg_card)

    status_card = TkFrame.new(@frame) { background COLORS[:panel] }
    status_card.pack(pad.merge(fill: :x, pady: [20, 0]))

    TkLabel.new(status_card) do
      text '  STATUS'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:accent]
      background COLORS[:panel]
    end.pack(anchor: 'w', pady: [16, 0], padx: 20)

    status_items = TkFrame.new(status_card) { background COLORS[:panel] }
    status_items.pack(fill: :x, padx: 20, pady: [12, 16])

    TkLabel.new(status_items) do
      text "  \u{25CF}  SESSION ENCRYPTED"
      font TkFont.new("#{FONT} 9")
      foreground COLORS[:green]
      background COLORS[:panel]
    end.pack(anchor: 'w', pady: [0, 4])

    @file_status_label = TkLabel.new(status_items) do
      text "  \u{25CB}  FILE LOCKED: none"
      font TkFont.new("#{FONT} 9")
      foreground COLORS[:text]
      background COLORS[:panel]
    end
    @file_status_label.pack(anchor: 'w', pady: [0, 4])

    @lock_status_label = TkLabel.new(status_items) do
      text "  \u{25CB}  LAST OPERATION: --"
      font TkFont.new("#{FONT} 9")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
    end
    @lock_status_label.pack(anchor: 'w')
  end

  def build_file_row(parent)
    row = TkFrame.new(parent) { background COLORS[:panel] }
    row.pack(fill: :x, padx: 20, pady: [16, 0])

    TkLabel.new(row) do
      text 'FILE'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
    end.pack(side: :left)

    @file_path = TkEntry.new(row) do
      background COLORS[:input]
      foreground COLORS[:text]
      font TkFont.new("#{FONT} 11")
      insertbackground COLORS[:accent]
      relief 'flat'
      highlightthickness 1
      highlightcolor COLORS[:accent]
      highlightbackground COLORS[:border_inactive]
    end
    @file_path.pack(side: :left, fill: :x, expand: true, padx: [12, 8], ipady: 4)

    browse_btn = TkLabel.new(row) do
      text '  BROWSE  '
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:accent]
      background COLORS[:panel]
      cursor 'hand2'
      relief 'solid'
      highlightthickness 1
      highlightcolor COLORS[:accent]
      highlightbackground COLORS[:border_inactive]
    end
    browse_btn.pack(side: :left)
    browse_btn.bind('Button-1') { on_browse }
  end

  def build_key_row(parent)
    row = TkFrame.new(parent) { background COLORS[:panel] }
    row.pack(fill: :x, padx: 20, pady: [12, 0])

    TkLabel.new(row) do
      text 'KEY'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
    end.pack(side: :left)

    @key_entry = TkEntry.new(row) do
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
    @key_entry.pack(side: :left, fill: :x, expand: true, padx: [16, 8], ipady: 4)

    eye_btn = TkLabel.new(row) do
      text "\u{1F441}"
      font TkFont.new("#{FONT} 11")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
      cursor 'hand2'
    end
    eye_btn.pack(side: :left)
    eye_btn.bind('Button-1') { toggle_key_visibility }
  end

  def build_algo_row(parent)
    row = TkFrame.new(parent) { background COLORS[:panel] }
    row.pack(fill: :x, padx: 20, pady: [12, 0])

    TkLabel.new(row) do
      text 'ALGORITHM'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:text_secondary]
      background COLORS[:panel]
    end.pack(side: :left)

    @algo_combo = Tk::Tile::Combobox.new(row) do
      values ['AES-256-GCM', 'ChaCha20-Poly1305', 'XOR']
      state 'readonly'
      width 28
    end
    @algo_combo.current = 0
    @algo_combo.pack(side: :left, padx: [8, 0])
  end

  def build_action_row(parent)
    row = TkFrame.new(parent) { background COLORS[:panel] }
    row.pack(fill: :x, padx: 20, pady: [20, 20])

    me = self
    lock_btn = TkButton.new(row) do
      text '  LOCK  '
      font TkFont.new("#{FONT} 11 bold")
      foreground COLORS[:bg]
      background COLORS[:accent]
      relief 'flat'
      height 2
      command proc { me.on_lock }
    end
    lock_btn.pack(side: :left, padx: [0, 16])

    unlock_btn = TkButton.new(row) do
      text '  UNLOCK  '
      font TkFont.new("#{FONT} 11 bold")
      foreground COLORS[:accent]
      background COLORS[:bg]
      relief 'flat'
      highlightthickness 1
      highlightcolor COLORS[:accent]
      highlightbackground COLORS[:accent]
      height 2
      command proc { me.on_unlock }
    end
    unlock_btn.pack(side: :left)
  end

  def toggle_key_visibility
    @key_visible = !@key_visible
    @key_entry.configure('show' => @key_visible ? '' : '*')
  end

  def on_browse
    file = Tk.getOpenFile
    @file_path.delete(0, 'end')
    @file_path.insert(0, file) if file && !file.empty?
  end

  def on_lock
    @file_status_label.configure('text' => "  \u{25CF}  FILE LOCKED: #{file_basename}")
    @lock_status_label.configure('text' => "  \u{25CF}  LAST OPERATION: ENCRYPT (#{Time.now.strftime('%H:%M:%S')})")
    @file_status_label.configure('foreground' => COLORS[:accent])
  end

  def on_unlock
    @file_status_label.configure('text' => "  \u{25CB}  FILE LOCKED: none")
    @lock_status_label.configure('text' => "  \u{25CF}  LAST OPERATION: DECRYPT (#{Time.now.strftime('%H:%M:%S')})")
    @file_status_label.configure('foreground' => COLORS[:text])
  end

  def file_basename
    path = @file_path.get
    return 'none' if path.nil? || path.empty?
    File.basename(path)
  rescue
    'unknown'
  end
end
