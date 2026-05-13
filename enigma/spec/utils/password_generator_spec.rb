# frozen_string_literal: true

RSpec.describe Enigma::Utils::PasswordGenerator do
  describe '.generate' do
    it 'returns a string' do
      expect(described_class.generate).to be_a(String)
    end

    it 'defaults to 20 characters' do
      expect(described_class.generate.length).to eq(20)
    end

    it 'respects custom length' do
      expect(described_class.generate(length: 8).length).to eq(8)
    end

    it 'includes uppercase, digits, and symbols by default' do
      pw = described_class.generate
      expect(pw).to match(/[A-Z]/)
      expect(pw).to match(/[0-9]/)
      expect(pw).to match(/[^A-Za-z0-9]/)
    end

    it 'excludes symbols when symbols: false' do
      pw = described_class.generate(symbols: false)
      expect(pw).not_to match(/[^A-Za-z0-9]/)
    end

    it 'generates unique passwords' do
      pws = Array.new(10) { described_class.generate }
      expect(pws.uniq.size).to be > 1
    end
  end

  describe '.strength' do
    it 'returns :weak for short password' do
      expect(described_class.strength('Ab1')).to eq(:weak)
    end

    it 'returns :strong for long complex password' do
      expect(described_class.strength('Correct-Horse-Battery-Staple99!')).to eq(:strong)
    end

    it 'returns :medium for moderate password' do
      expect(described_class.strength('Password1')).to eq(:medium)
    end
  end
end
