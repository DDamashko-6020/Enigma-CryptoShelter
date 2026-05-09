# frozen_string_literal: true

RSpec.describe Enigma::Core::Vault::Credential do
  describe 'Value Object semantics' do
    it 'compares by id' do
      c1 = described_class.new(site: 'S', username: 'u', password: 'p', id: 'same-id')
      c2 = described_class.new(site: 'X', username: 'y', password: 'z', id: 'same-id')
      expect(c1).to eq(c2)
    end

    it 'distinguishes different ids' do
      c1 = described_class.new(site: 'S', username: 'u', password: 'p')
      c2 = described_class.new(site: 'S', username: 'u', password: 'p')
      expect(c1).not_to eq(c2)
    end

    it 'has null? false' do
      cred = described_class.new(site: 'S', username: 'u', password: 'p')
      expect(cred.null?).to be false
    end
  end
end
