RSpec.describe Enigma::Core::Vault::Storage do
  let(:password) { 'test-password' }
  let(:tmp_path) { File.join('/tmp', "enigma_vault_test_#{Time.now.to_i}_#{rand(9999)}.dat") }
  subject(:storage) { described_class.new(tmp_path, password) }

  after(:each) { File.delete(tmp_path) if File.exist?(tmp_path) }

  describe '#load' do
    it 'returns empty array when file does not exist' do
      File.delete(tmp_path) if File.exist?(tmp_path)
      expect(storage.load).to eq([])
    end

    it 'raises VaultError on corrupted data' do
      File.binwrite(tmp_path, 'garbage')
      expect { storage.load }.to raise_error(Enigma::Core::VaultError, /corrupted/)
    end

    it 'raises VaultError on wrong password' do
      cred = Enigma::Core::Vault::Credential.new(
        service: 'Test', username: 'u', password: 'p'
      )
      storage.save([cred])
      wrong_storage = described_class.new(tmp_path, 'wrong-password')
      expect { wrong_storage.load }.to raise_error(Enigma::Core::VaultError, /password/)
    end
  end

  describe '#save and #load round-trip' do
    it 'persists and retrieves credentials' do
      cred = Enigma::Core::Vault::Credential.new(
        service: 'Test', username: 'u', password: 'p', notes: 'n'
      )
      storage.save([cred])
      loaded = storage.load
      expect(loaded.size).to eq(1)
      expect(loaded.first.service).to eq('Test')
      expect(loaded.first.username).to eq('u')
    end

    it 'persists multiple credentials' do
      creds = [
        Enigma::Core::Vault::Credential.new(service: 'A', username: 'u1', password: 'p1'),
        Enigma::Core::Vault::Credential.new(service: 'B', username: 'u2', password: 'p2')
      ]
      storage.save(creds)
      loaded = storage.load
      expect(loaded.size).to eq(2)
      expect(loaded.map(&:service)).to contain_exactly('A', 'B')
    end

    it 'overwrites existing file on save' do
      cred1 = Enigma::Core::Vault::Credential.new(service: 'S1', username: 'u', password: 'p')
      cred2 = Enigma::Core::Vault::Credential.new(service: 'S2', username: 'u', password: 'p')
      storage.save([cred1])
      storage.save([cred2])
      expect(storage.load.size).to eq(1)
      expect(storage.load.first.service).to eq('S2')
    end

    it 'uses consistent salt across save and load' do
      cred = Enigma::Core::Vault::Credential.new(service: 'X', username: 'u', password: 'p')
      storage.save([cred])
      data = File.binread(tmp_path)
      salt1 = data[0...32]
      storage.save([cred])
      data = File.binread(tmp_path)
      salt2 = data[0...32]
      expect(salt1).to eq(salt2)
    end

    it 'produces different ciphertexts on each save due to random IV' do
      cred = Enigma::Core::Vault::Credential.new(service: 'X', username: 'u', password: 'p')
      storage.save([cred])
      data1 = File.binread(tmp_path)
      cred2 = Enigma::Core::Vault::Credential.new(service: 'X', username: 'u', password: 'p')
      storage2 = described_class.new(tmp_path, password)
      storage2.save([cred2])
      data2 = File.binread(tmp_path)
      expect(data1).not_to eq(data2)
    end
  end

  describe '#exist?' do
    it 'returns false when file does not exist' do
      File.delete(tmp_path) if File.exist?(tmp_path)
      expect(storage.exist?).to be(false)
    end

    it 'returns true after save' do
      storage.save([])
      expect(storage.exist?).to be(true)
    end
  end
end
