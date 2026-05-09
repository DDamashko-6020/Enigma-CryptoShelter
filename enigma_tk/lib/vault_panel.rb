require 'tk'
require 'tkextlib/tile'

class VaultPanel
  COLORS = CryptoshelterApp::COLORS
  FONT = CryptoshelterApp::FONT

  def initialize(parent, app)
    @app = app
    @vault_open = false
    @selected_index = nil
    @credentials = []

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
    top_bar = TkFrame.new(@frame) { background COLORS[:bg] }
    top_bar.pack(fill: :x, padx: 20, pady: [16, 0])

    search_frame = TkFrame.new(top_bar) do
      background COLORS[:input]
    end
    search_frame.pack(side: :left, fill: :x, expand: true)

    @search_entry = TkEntry.new(search_frame) do
      background COLORS[:input]
      foreground COLORS[:text_secondary]
      font TkFont.new("#{FONT} 11")
      insertbackground COLORS[:accent]
      relief 'flat'
      highlightthickness 1
      highlightcolor COLORS[:accent]
      highlightbackground COLORS[:border_inactive]
    end
    @search_entry.pack(fill: :x, ipady: 6, padx: 4, pady: 4)
    set_placeholder(@search_entry, "\u{1F50D} SEARCH VAULT...")

    @vault_status_label = TkLabel.new(top_bar) do
      text "  \u{25CF}  VAULT LOCKED"
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:red]
      background COLORS[:bg]
    end
    @vault_status_label.pack(side: :right, padx: [16, 0])

    main = TkFrame.new(@frame) { background COLORS[:bg] }
    main.pack(fill: :both, expand: true, pady: [12, 0])

    left = TkFrame.new(main) do
      background COLORS[:bg]
      width 320
    end
    left.pack(side: :left, fill: :both, anchor: 'nw')
    left.pack_propagate(false)

    TkFrame.new(left) do
      background COLORS[:border_inactive]
      width 1
    end.pack(side: :right, fill: :y)

    right = TkFrame.new(main) { background COLORS[:panel] }
    right.pack(side: :left, fill: :both, expand: true)

    build_sidebar(left)
    build_detail_panel(right)
  end

  def build_sidebar(parent)
    header = TkFrame.new(parent) { background COLORS[:bg] }
    header.pack(fill: :x, padx: 12, pady: [12, 8])

    TkLabel.new(header) do
      text '  CREDENTIALS'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:accent]
      background COLORS[:bg]
    end.pack(side: :left)

    @unlock_btn = TkLabel.new(header) do
      text "  #{@vault_open ? 'LOCK' : 'UNLOCK'}"
      font TkFont.new("#{FONT} 9")
      foreground COLORS[:accent]
      background COLORS[:bg]
      cursor 'hand2'
    end
    @unlock_btn.pack(side: :right)
    @unlock_btn.bind('Button-1') { toggle_vault_lock }

    list_frame = TkFrame.new(parent) { background COLORS[:bg] }
    list_frame.pack(fill: :both, expand: true, padx: 8)

    @listbox = Tk::Tile::Treeview.new(list_frame) do
      height 0
      selectmode 'browse'
    end
    @listbox.configure('columns' => ['site', 'username'])
    @listbox.heading('#0', text: '')
    @listbox.column('#0', width: 0, minwidth: 0, stretch: false)
    @listbox.heading('site', text: 'SITE')
    @listbox.column('site', width: 180, minwidth: 120)
    @listbox.heading('username', text: 'USER')
    @listbox.column('username', width: 120, minwidth: 80)

    @listbox.configure(
      'background' => COLORS[:bg],
      'foreground' => COLORS[:text],
      'fieldbackground' => COLORS[:bg],
      'font' => TkFont.new("#{FONT} 10"),
      'borderwidth' => 0,
      'highlightthickness' => 0
    )

    scroll = Tk::Tile::Scrollbar.new(list_frame) do
      orient 'vertical'
      command proc { |*args| @listbox.yview(*args) }
    end
    @listbox.configure('yscrollcommand' => proc { |*args| scroll.set(*args) })

    @listbox.pack(side: :left, fill: :both, expand: true)
    scroll.pack(side: :right, fill: :y)

    @listbox.bind('<<TreeviewSelect>>') { on_item_selected }

    @credential_items = []
    add_demo_items
  end

  def build_detail_panel(parent)
    pad = { padx: 24, pady: [20, 0] }
    row_pad = { padx: 24, pady: [12, 0] }

    TkLabel.new(parent) do
      text 'CREDENTIAL DETAILS'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:accent]
      background COLORS[:panel]
    end.pack(pad)

    detail_card = TkFrame.new(parent) { background COLORS[:input] }
    detail_card.pack(pad.merge(fill: :x))

    fields = %w[Service Username Password Notes]
    @detail_labels = {}
    fields.each do |f|
      row = TkFrame.new(detail_card) { background COLORS[:input] }
      row.pack(fill: :x, pady: [6, 0], padx: 12)

      TkLabel.new(row) do
        text "  #{f.upcase}:"
        font TkFont.new("#{FONT} 9")
        foreground COLORS[:text_secondary]
        background COLORS[:input]
      end.pack(side: :left, anchor: 'n')

      value = TkLabel.new(row) do
        text '  --'
        font TkFont.new("#{FONT} 11")
        foreground COLORS[:text]
        background COLORS[:input]
        wraplength 380
        justify 'left'
      end
      value.pack(side: :left, fill: :x, expand: true)
      @detail_labels[f.downcase] = value
    end

    action_row = TkFrame.new(parent) { background COLORS[:panel] }
    action_row.pack(row_pad.merge(fill: :x))

    actions = [
      ['COPY', method(:on_copy_password)],
      ['EDIT', method(:on_edit_credential)],
      ['DELETE', method(:on_delete_credential)]
    ]
    actions.each do |label, cmd|
      btn = TkLabel.new(action_row) do
        text "  #{label}  "
        font TkFont.new("#{FONT} 9 bold")
        foreground COLORS[:accent]
        background COLORS[:panel]
        cursor 'hand2'
        relief 'solid'
        highlightthickness 1
        highlightcolor COLORS[:accent]
        highlightbackground COLORS[:border_inactive]
      end
      btn.pack(side: :left, padx: [0, 12])
      btn.bind('Button-1', &cmd)
    end

    divider = TkFrame.new(parent) do
      background COLORS[:border_inactive]
      height 1
    end
    divider.pack(row_pad.merge(fill: :x, pady: [24, 0]))

    TkLabel.new(parent) do
      text '  METADATA'
      font TkFont.new("#{FONT} 9 bold")
      foreground COLORS[:accent]
      background COLORS[:panel]
    end.pack(pad)

    meta_card = TkFrame.new(parent) { background COLORS[:input] }
    meta_card.pack(pad.merge(fill: :x))

    %w[Created Updated ID].each do |f|
      row = TkFrame.new(meta_card) { background COLORS[:input] }
      row.pack(fill: :x, pady: [4, 0], padx: 12)

      TkLabel.new(row) do
        text "  #{f}:"
        font TkFont.new("#{FONT} 9")
        foreground COLORS[:text_secondary]
        background COLORS[:input]
      end.pack(side: :left)

      value = TkLabel.new(row) do
        text '  --'
        font TkFont.new("#{FONT} 10")
        foreground COLORS[:text_secondary]
        background COLORS[:input]
      end
      value.pack(side: :left)
      @detail_labels[f.downcase] = value
    end
  end

  def toggle_vault_lock
    @vault_open = !@vault_open
    if @vault_open
      @vault_status_label.configure('text' => "  \u{25CF}  VAULT OPEN", 'foreground' => COLORS[:green])
      @unlock_btn.configure('text' => '  LOCK')
    else
      @vault_status_label.configure('text' => "  \u{25CF}  VAULT LOCKED", 'foreground' => COLORS[:red])
      @unlock_btn.configure('text' => '  UNLOCK')
      clear_details
      @selected_index = nil
    end
  end

  def add_demo_items
    demo = [
      { site: 'GitHub', username: 'dev_user' },
      { site: 'AWS Console', username: 'admin@corp.com' },
      { site: 'GitLab', username: 'dev_user' },
      { site: 'Cloudflare', username: 'admin@corp.com' },
      { site: 'DigitalOcean', username: 'root' }
    ]
    demo.each { |d| add_credential(d[:site], d[:username]) }
  end

  def add_credential(site, username)
    id = @listbox.insert('', 'end', values: [site, username])
    @credential_items << { id: id, site: site, username: username, password: '••••••••', notes: '' }
  end

  def on_item_selected
    sel = @listbox.selection
    if sel && !sel.empty?
      values = @listbox.item(sel[0], 'values')
      idx = @credential_items.index { |c| c[:site] == values[0] && c[:username] == values[1] }
      if idx
        @selected_index = idx
        show_details(idx)
      end
    end
  end

  def show_details(idx)
    cred = @credential_items[idx]
    return unless cred

    label_map = {
      'service' => cred[:site],
      'username' => cred[:username],
      'password' => cred[:password],
      'notes' => cred[:notes] || '--',
      'created' => '2026-01-15 10:30 UTC',
      'updated' => '2026-03-22 14:15 UTC',
      'id' => 'c4a7e9f2-...'
    }
    label_map.each { |k, v| @detail_labels[k]&.configure('text' => "  #{v}") }
  end

  def clear_details
    %w[service username password notes created updated id].each do |k|
      @detail_labels[k]&.configure('text' => '  --')
    end
  end

  def on_copy_password
  end

  def on_edit_credential
  end

  def on_delete_credential
  end

  def set_placeholder(entry, text)
    entry.insert(0, text)
    entry.bind('FocusIn') do
      if entry.get == text
        entry.delete(0, 'end')
        entry.configure('foreground' => COLORS[:text])
      end
    end
    entry.bind('FocusOut') do
      if entry.get.empty?
        entry.insert(0, text)
        entry.configure('foreground' => COLORS[:text_secondary])
      end
    end
  end
end
