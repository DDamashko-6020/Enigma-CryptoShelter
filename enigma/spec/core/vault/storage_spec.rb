# frozen_string_literal: true

RSpec.describe Enigma::Core::Vault::Storage do
  let(:key) { "\x01" * 32 }
  let(:cipher) { Enigma::Core::Cipher::AesGcm.new(key) }
  let(:tmp_path) { File.join('/tmp', "enigma_vault_test_#{Time.now.to_i}_#{rand(9999)}.vault") }
  subject(:storage) { described_class.new(tmp_path, cipher) }

  after(:each) { File.delete(tmp_path) if File.exist?(tmp_path) }

  describe '#exists?' do
    it 'returns false when file missing' do
      expect(storage.exists?).to be false
    end

    it 'returns true after create_new!' do
      storage.create_new!
      expect(storage.exists?).to be true
    end
  end

  describe '#create_new!' do
    it 'creates an empty vault file' do
      storage.create_new!
      expect(File.exist?(tmp_path)).to be true
    end

    it 'raises VaultNotFoundError if already exists' do
      storage.create_new!
      expect { storage.create_new! }.to raise_error(Enigma::Errors::VaultNotFoundError)
    end
  end

  describe '#save / #load round-trip' do
    it 'persists and retrieves credentials' do
      cred = Enigma::Core::Vault::Credential.new(site: 'Test', username: 'u', password: 'p')
      storage.save([cred])
      loaded = storage.load
      expect(loaded.size).to eq(1)
      expect(loaded.first.site).to eq('Test')
    end

    it 'handles multiple credentials' do
      creds = [
        Enigma::Core::Vault::Credential.new(site: 'A', username: 'u1', password: 'p1'),
        Enigma::Core::Vault::Credential.new(site: 'B', username: 'u2', password: 'p2')
      ]
      storage.save(creds)
      expect(storage.load.size).to eq(2)
    end

    it 'overwrites existing data' do
      storage.save([Enigma::Core::Vault::Credential.new(site: 'S1', username: 'u', password: 'p')])
      storage.save([Enigma::Core::Vault::Credential.new(site: 'S2', username: 'u', password: 'p')])
      expect(storage.load.first.site).to eq('S2')
    end
  end

  describe '#load errors' do
    it 'raises VaultNotFoundError when file missing' do
      expect { storage.load }.to raise_error(Enigma::Errors::VaultNotFoundError)
    end

    it 'raises AuthTagError when decryption fails' do
      storage.save([Enigma::Core::Vault::Credential.new(site: 'S', username: 'u', password: 'p')])
      wrong = described_class.new(tmp_path, Enigma::Core::Cipher::AesGcm.new("\x02" * 32))
      expect { wrong.load }.to raise_error(Enigma::Errors::AuthTagError)
    end
  end
end
