require 'tk'
require 'tkextlib/tile'

require 'cipher_lab_panel'
require 'vault_panel'
require 'file_lock_panel'

class CryptoshelterApp
  COLORS = {
    bg: '#0D0D0D',
    panel: '#1A1A1A',
    input: '#111111',
    accent: '#FF6B00',
    accent_hover: '#CC4400',
    text: '#E0E0E0',
    text_secondary: '#666666',
    border_active: '#FF6B00',
    border_inactive: '#2A2A2A',
    green: '#00CC66',
    red: '#CC2200'
  }.freeze

  FONT = 'Courier'
  FONT_SIZE = 11

  def initialize
    @root = TkRoot.new
    @root.title 'ENIGMA CRYPTOSHELTER'
    @root.geometry('1200x800+50+50')
    @root.resizable(false, false)
    @root.background COLORS[:bg]

    @current_tab = 'cipher'

    build_top_nav
    build_content_area
    build_status_bar
  end

  def run
    Tk.mainloop
  end

  private

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
      font TkFont.new('Courier 12 bold')
      foreground COLORS[:accent]
      background COLORS[:bg]
    end.pack(side: :left)

    center = TkFrame.new(nav) { background COLORS[:bg] }
    center.pack(side: :left, expand: true)

    @tab_buttons = {}
    @tab_underlines = {}
    %w[Cipher\ Lab Vault File\ Lock].each do |tab_name|
      key = tab_name.downcase.gsub(/\s/, '_')
      tab_key = key

      f = TkFrame.new(center) { background COLORS[:bg] }
      f.pack(side: :left, padx: 15, pady: [8, 0])

      btn = TkLabel.new(f) do
        text tab_name
        font TkFont.new('Courier 11')
        foreground tab_key == @current_tab ? COLORS[:text] : COLORS[:text_secondary]
        background COLORS[:bg]
        cursor 'hand2'
      end
      btn.pack

      underline = TkFrame.new(f) do
        background tab_key == @current_tab ? COLORS[:accent] : COLORS[:bg]
        height 2
      end
      underline.pack(fill: :x, pady: [4, 0])

      @tab_buttons[tab_key] = btn
      @tab_underlines[tab_key] = underline

      btn.bind('Button-1') { switch_tab(tab_key) }
    end

    right = TkFrame.new(nav) { background COLORS[:bg] }
    right.pack(side: :right, padx: [0, 20], pady: 10)

    TkLabel.new(right) do
      text "\u{1F512}"
      font TkFont.new('Courier 12')
      foreground COLORS[:accent]
      background COLORS[:bg]
    end.pack(side: :right)
  end

  def build_content_area
    @content = TkFrame.new(@root) do
      background COLORS[:bg]
    end
    @content.pack(side: :top, fill: :both, expand: true)

    @panels = {}
    @panels['cipher_lab'] = CipherLabPanel.new(@content, self)
    @panels['vault'] = VaultPanel.new(@content, self)
    @panels['file_lock'] = FileLockPanel.new(@content, self)

    @panels.each { |_, p| p.hide }
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
    TkFrame.new(bar) { background COLORS[:bg]; height 30 }.pack(fill: :x)

    left = TkFrame.new(bar) { background COLORS[:bg]; height 30 }
    left.pack(side: :left, fill: :y, padx: [20, 0])

    TkLabel.new(left) do
      text "\u{25CF} OFFLINE MODE | AES-256 ACTIVE"
      font TkFont.new('Courier 9')
      foreground COLORS[:green]
      background COLORS[:bg]
    end.pack(side: :left, fill: :y)

    right = TkFrame.new(bar) { background COLORS[:bg]; height 30 }
    right.pack(side: :right, fill: :y, padx: [0, 20])

    TkLabel.new(right) do
      text 'System Logs'
      font TkFont.new('Courier 9')
      foreground COLORS[:text_secondary]
      background COLORS[:bg]
      cursor 'hand2'
    end.pack(side: :left, fill: :y)

    TkLabel.new(right) do
      text ' | '
      font TkFont.new('Courier 9')
      foreground COLORS[:text_secondary]
      background COLORS[:bg]
    end.pack(side: :left, fill: :y)

    TkLabel.new(right) do
      text 'Network Status'
      font TkFont.new('Courier 9')
      foreground COLORS[:text_secondary]
      background COLORS[:bg]
      cursor 'hand2'
    end.pack(side: :left, fill: :y)
  end

  def switch_tab(tab_key)
    @current_tab = tab_key

    @tab_underlines.each do |key, underline|
      underline.configure('background' => key == tab_key ? COLORS[:accent] : COLORS[:bg])
    end
    @tab_buttons.each do |key, btn|
      btn.configure('foreground' => key == tab_key ? COLORS[:text] : COLORS[:text_secondary])
    end

    @panels.each { |_, p| p.hide }
    @panels[tab_key].show
  end
end
