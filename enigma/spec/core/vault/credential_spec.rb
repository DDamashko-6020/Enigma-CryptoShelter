# frozen_string_literal: true

RSpec.describe Enigma::Core::Vault::Credential do
  subject(:cred) { described_class.new(site: 'GitHub', username: 'user', password: 'secret', notes: 'personal') }

  describe 'initialization' do
    it 'sets attributes' do
      expect(cred.site).to eq('GitHub')
      expect(cred.username).to eq('user')
      expect(cred.password).to eq('secret')
      expect(cred.notes).to eq('personal')
    end

    it 'generates UUID as id' do
      expect(cred.id).to match(/^[0-9a-f-]{36}$/)
    end

    it 'generates ISO8601 created_at' do
      expect(cred.created_at).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'defaults notes to empty string' do
      c = described_class.new(site: 'X', username: 'u', password: 'p')
      expect(c.notes).to eq('')
    end

    it 'uses provided id' do
      c = described_class.new(site: 'X', username: 'u', password: 'p', id: 'custom-id')
      expect(c.id).to eq('custom-id')
    end
  end

  describe 'validation' do
    it 'raises on empty site' do
      expect { described_class.new(site: '', username: 'u', password: 'p') }
        .to raise_error(Enigma::Errors::VaultError)
    end

    it 'raises on empty username' do
      expect { described_class.new(site: 'S', username: '', password: 'p') }
        .to raise_error(Enigma::Errors::VaultError)
    end

    it 'raises on empty password' do
      expect { described_class.new(site: 'S', username: 'u', password: '') }
        .to raise_error(Enigma::Errors::VaultError)
    end
  end

  describe 'two instances have different ids' do
    let(:c1) { described_class.new(site: 'A', username: 'u', password: 'p') }
    let(:c2) { described_class.new(site: 'B', username: 'u', password: 'p') }

    it { expect(c1.id).not_to eq(c2.id) }
  end

  describe '#to_h / #from_h round-trip' do
    it 'preserves all fields' do
      restored = described_class.from_h(cred.to_h)
      expect(restored.id).to eq(cred.id)
      expect(restored.site).to eq(cred.site)
      expect(restored.username).to eq(cred.username)
      expect(restored.password).to eq(cred.password)
      expect(restored.notes).to eq(cred.notes)
      expect(restored.created_at).to eq(cred.created_at)
    end

    it 'handles string keys' do
      hash = cred.to_h.transform_keys(&:to_s)
      restored = described_class.from_h(hash)
      expect(restored.id).to eq(cred.id)
    end
  end
end
