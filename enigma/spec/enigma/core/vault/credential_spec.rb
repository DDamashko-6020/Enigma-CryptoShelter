RSpec.describe Enigma::Core::Vault::Credential do
  subject(:credential) do
    described_class.new(
      service: 'GitHub',
      username: 'user',
      password: 'secret123',
      notes: 'personal account'
    )
  end

  describe '#initialize' do
    it 'sets service, username, password, and notes' do
      expect(credential.service).to eq('GitHub')
      expect(credential.username).to eq('user')
      expect(credential.password).to eq('secret123')
      expect(credential.notes).to eq('personal account')
    end

    it 'generates a UUID as id when not provided' do
      expect(credential.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'uses provided id when given' do
      cred = described_class.new(service: 'X', username: 'y', password: 'z', id: 'custom-id')
      expect(cred.id).to eq('custom-id')
    end

    it 'sets created_at and updated_at as ISO8601 strings' do
      expect(credential.created_at).to be_a(String)
      expect(credential.updated_at).to eq(credential.created_at)
    end

    it 'defaults notes to empty string' do
      cred = described_class.new(service: 'X', username: 'y', password: 'z')
      expect(cred.notes).to eq('')
    end
  end

  describe '#to_h' do
    it 'returns a hash with all attributes' do
      hash = credential.to_h
      expect(hash[:service]).to eq('GitHub')
      expect(hash[:username]).to eq('user')
      expect(hash[:password]).to eq('secret123')
      expect(hash[:notes]).to eq('personal account')
      expect(hash[:id]).to eq(credential.id)
    end
  end

  describe '#to_json' do
    it 'serializes to JSON' do
      json = credential.to_json
      parsed = JSON.parse(json)
      expect(parsed['service']).to eq('GitHub')
      expect(parsed['username']).to eq('user')
    end
  end

  describe '.from_h' do
    it 'reconstructs a credential from a hash' do
      hash = credential.to_h.transform_keys(&:to_s)
      restored = described_class.from_h(hash)
      expect(restored.service).to eq('GitHub')
      expect(restored.username).to eq('user')
      expect(restored.id).to eq(credential.id)
    end
  end
end
