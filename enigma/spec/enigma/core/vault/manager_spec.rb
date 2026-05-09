RSpec.describe Enigma::Core::Vault::Manager do
  let(:password) { 'test-password' }
  let(:tmp_path) { File.join('/tmp', "enigma_vault_test_#{Time.now.to_i}_#{rand(9999)}.dat") }
  let(:storage) { Enigma::Core::Vault::Storage.new(tmp_path, password) }
  subject(:manager) { described_class.new(storage) }

  let(:credential) do
    Enigma::Core::Vault::Credential.new(
      service: 'GitHub', username: 'user', password: 'secret', notes: 'personal'
    )
  end

  after(:each) { File.delete(tmp_path) if File.exist?(tmp_path) }

  describe '#all' do
    it 'returns empty array initially' do
      expect(manager.all).to eq([])
    end

    it 'returns a duplicate array' do
      manager.add(credential)
      all_creds = manager.all
      all_creds.clear
      expect(manager.all.size).to eq(1)
    end
  end

  describe '#add' do
    it 'adds a credential and returns it' do
      result = manager.add(credential)
      expect(result).to eq(credential)
      expect(manager.count).to eq(1)
    end

    it 'persists to storage' do
      manager.add(credential)
      new_manager = described_class.new(storage)
      expect(new_manager.count).to eq(1)
    end
  end

  describe '#find' do
    it 'finds a credential by id' do
      manager.add(credential)
      found = manager.find(credential.id)
      expect(found).to eq(credential)
    end

    it 'returns nil for unknown id' do
      expect(manager.find('nonexistent')).to be_nil
    end
  end

  describe '#search' do
    before do
      manager.add(credential)
      manager.add(Enigma::Core::Vault::Credential.new(
        service: 'GitLab', username: 'dev', password: 'pass1', notes: 'work'
      ))
      manager.add(Enigma::Core::Vault::Credential.new(
        service: 'AWS', username: 'root', password: 'pass2', notes: 'cloud'
      ))
    end

    it 'finds by service' do
      results = manager.search('git')
      expect(results.size).to eq(2)
      expect(results.map(&:service)).to contain_exactly('GitHub', 'GitLab')
    end

    it 'finds by username' do
      results = manager.search('dev')
      expect(results.size).to eq(1)
      expect(results.first.service).to eq('GitLab')
    end

    it 'finds by notes' do
      results = manager.search('cloud')
      expect(results.size).to eq(1)
      expect(results.first.service).to eq('AWS')
    end

    it 'returns empty array for no match' do
      expect(manager.search('zzzz')).to eq([])
    end

    it 'is case insensitive' do
      expect(manager.search('GITHUB').size).to eq(1)
    end
  end

  describe '#update' do
    it 'updates attributes' do
      manager.add(credential)
      manager.update(credential.id, { username: 'newuser', notes: 'updated' })
      expect(credential.username).to eq('newuser')
      expect(credential.notes).to eq('updated')
    end

    it 'updates updated_at timestamp' do
      manager.add(credential)
      old_time = credential.updated_at
      sleep 1
      manager.update(credential.id, { username: 'x' })
      expect(credential.updated_at).not_to eq(old_time)
    end

    it 'raises VaultError for unknown id' do
      expect { manager.update('bad', {}) }
        .to raise_error(Enigma::Core::VaultError, /not found/)
    end

    it 'ignores unknown attributes' do
      manager.add(credential)
      manager.update(credential.id, { nonexistent: 'value' })
      expect(manager.count).to eq(1)
    end
  end

  describe '#delete' do
    it 'removes a credential' do
      manager.add(credential)
      manager.delete(credential.id)
      expect(manager.count).to eq(0)
    end

    it 'returns the deleted credential' do
      manager.add(credential)
      deleted = manager.delete(credential.id)
      expect(deleted).to eq(credential)
    end

    it 'persists deletion' do
      manager.add(credential)
      manager.delete(credential.id)
      new_manager = described_class.new(storage)
      expect(new_manager.count).to eq(0)
    end

    it 'raises VaultError for unknown id' do
      expect { manager.delete('bad') }
        .to raise_error(Enigma::Core::VaultError, /not found/)
    end
  end

  describe '#count' do
    it 'returns 0 initially' do
      expect(manager.count).to eq(0)
    end

    it 'returns the number of credentials' do
      manager.add(credential)
      manager.add(Enigma::Core::Vault::Credential.new(
        service: 'S2', username: 'u', password: 'p'
      ))
      expect(manager.count).to eq(2)
    end
  end

  describe '#clear!' do
    it 'clears all credentials from memory' do
      manager.add(credential)
      manager.clear!
      expect(manager.count).to eq(0)
    end
  end
end
