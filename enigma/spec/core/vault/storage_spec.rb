# frozen_string_literal: true

RSpec.describe Enigma::Core::Vault::Storage do
  subject(:storage) { described_class.new }
  let(:salt) { SecureRandom.random_bytes(32) }
  let(:payload) { SecureRandom.random_bytes(64) }
  let(:tmp_path) { described_class::VAULT_PATH }

  before do
    stub_const("#{described_class}::VAULT_PATH", tmp_path)
    FileUtils.rm_f(tmp_path)
  end

  after(:each) { FileUtils.rm_f(tmp_path) }

  describe '#exists?' do
    it 'returns false when file missing' do
      expect(storage.exists?).to be false
    end

    it 'returns true after create_new!' do
      storage.create_new!(salt, payload)
      expect(storage.exists?).to be true
    end
  end

  describe '#create_new!' do
    it 'creates an empty vault file' do
      storage.create_new!(salt, payload)
      expect(File.exist?(tmp_path)).to be true
    end

    it 'raises VaultNotFoundError if already exists' do
      storage.create_new!(salt, payload)
      expect { storage.create_new!(salt, payload) }.to raise_error(Enigma::Errors::VaultNotFoundError)
    end
  end

  describe '#build_file / #parse_file round-trip' do
    it 'builds and parses correctly' do
      file_data = storage.build_file(salt, payload)
      parsed_salt, parsed_payload = storage.parse_file(file_data)
      expect(parsed_salt).to eq(salt)
      expect(parsed_payload).to eq(payload)
    end

    it 'raises CorruptedDataError for invalid magic' do
      expect { storage.parse_file("\x00" * 7 + salt + payload) }
        .to raise_error(Enigma::Errors::CorruptedDataError)
    end
  end

  describe '#save / #load round-trip' do
    it 'persists and retrieves data' do
      storage.create_new!(salt, payload)
      loaded_salt, loaded_payload = storage.load
      expect(loaded_salt).to eq(salt)
      expect(loaded_payload).to eq(payload)
    end

    it 'overwrites existing data' do
      storage.create_new!(salt, payload)
      new_payload = SecureRandom.random_bytes(64)
      storage.save(salt, new_payload)
      _, loaded = storage.load
      expect(loaded).to eq(new_payload)
    end
  end

  describe '#load errors' do
    it 'raises VaultNotFoundError when file missing' do
      expect { storage.load }.to raise_error(Enigma::Errors::VaultNotFoundError)
    end

    it 'raises CorruptedDataError for invalid file format' do
      File.binwrite(tmp_path, "\x00\x00\x00")
      expect { storage.load }.to raise_error(Enigma::Errors::CorruptedDataError)
    end
  end

  it 'sets restrictive permissions on created files' do
    storage.create_new!(salt, payload)
    mode = File.stat(tmp_path).mode & 0o777
    expect(mode).to eq(0o600)
  end
end
