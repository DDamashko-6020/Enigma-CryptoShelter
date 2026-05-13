# frozen_string_literal: true

RSpec.describe Enigma::Core::Vault::Storage do
  subject(:storage) { described_class.new(tmp_path, cipher) }

  let(:tmp_path) { File.join('/tmp', "enigma_vault_test_#{Time.now.to_i}_#{rand(9999)}.vault") }
  let(:password) { 'test-password' }
  let(:salt) { SecureRandom.random_bytes(32) }
  let(:vault_key) { Enigma::Core::KeyMaster.instance.derive_vault_key(password, salt) }
  let(:cipher) { Enigma::Core::Cipher::AesGcm.new(vault_key) }

  before { FileUtils.rm_f(tmp_path) }
  after(:each) { FileUtils.rm_f(tmp_path) if File.exist?(tmp_path) }

  describe '#exists?' do
    it 'returns false when file missing' do
      expect(storage.exists?).to be false
    end

    it 'returns true after create_new!' do
      storage.create_new!(salt)
      expect(storage.exists?).to be true
    end
  end

  describe '#create_new!' do
    it 'creates an empty vault file' do
      storage.create_new!(salt)
      expect(File.exist?(tmp_path)).to be true
    end

    it 'sets restrictive permissions' do
      storage.create_new!(salt)
      mode = File.stat(tmp_path).mode & 0o777
      expect(mode).to eq(0o600)
    end
  end

  describe '#load' do
    it 'returns empty array for new vault' do
      storage.create_new!(salt)
      expect(storage.load).to eq([])
    end

    it 'raises CorruptedDataError for invalid file format' do
      File.binwrite(tmp_path, "\x00\x00\x00")
      expect { storage.load }.to raise_error(Enigma::Errors::CorruptedDataError)
    end
  end

  describe '#save / #load round-trip' do
    it 'persists and retrieves credentials' do
      storage.create_new!(salt)
      cred = Enigma::Core::Vault::Credential.new(site: 'S', username: 'u', password: 'p')
      storage.save([cred])
      loaded = storage.load
      expect(loaded.size).to eq(1)
      expect(loaded.first.site).to eq('S')
    end

    it 'overwrites existing data' do
      storage.create_new!(salt)
      c1 = Enigma::Core::Vault::Credential.new(site: 'A', username: 'u', password: 'p')
      c2 = Enigma::Core::Vault::Credential.new(site: 'B', username: 'v', password: 'q')
      storage.save([c1])
      storage.save([c2])
      expect(storage.load.size).to eq(1)
    end
  end

  describe '.vault_exists?' do
    it 'returns false when vault file missing' do
      stub_const("#{described_class}::VAULT_PATH", tmp_path)
      expect(described_class.vault_exists?).to be false
    end

    it 'returns true after vault creation' do
      stub_const("#{described_class}::VAULT_PATH", tmp_path)
      storage.create_new!(salt)
      expect(described_class.vault_exists?).to be true
    end
  end

  describe '.read_salt' do
    it 'reads salt from vault file' do
      storage.create_new!(salt)
      read = described_class.read_salt(tmp_path)
      expect(read).to eq(salt)
    end

    it 'raises CorruptedDataError for short file' do
      File.binwrite(tmp_path, 'x')
      expect { described_class.read_salt(tmp_path) }
        .to raise_error(Enigma::Errors::CorruptedDataError)
    end
  end
end
