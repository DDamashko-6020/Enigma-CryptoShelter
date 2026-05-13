# frozen_string_literal: true

RSpec.describe Enigma::Core::KeyMaster do
  subject(:km) { described_class.instance }
  let(:salt) { SecureRandom.random_bytes(32) }

  describe '#derive_vault_key' do
    it 'returns 32 bytes' do
      expect(km.derive_vault_key('password', salt).bytesize).to eq(32)
    end

    it 'is deterministic for same password and salt' do
      k1 = km.derive_vault_key('test', salt)
      k2 = km.derive_vault_key('test', salt)
      expect(k1).to eq(k2)
    end

    it 'differs for different passwords' do
      k1 = km.derive_vault_key('pass1', salt)
      k2 = km.derive_vault_key('pass2', salt)
      expect(k1).not_to eq(k2)
    end
  end

  describe '#derive_filelock_key' do
    it 'returns 32 bytes' do
      expect(km.derive_filelock_key('password', salt).bytesize).to eq(32)
    end

    it 'differs from vault_key with same password' do
      vault = km.derive_vault_key('password', salt)
      filelock = km.derive_filelock_key('password', salt)
      expect(vault).not_to eq(filelock)
    end
  end

  describe '#generate_salt' do
    it 'returns 32 bytes' do
      expect(km.generate_salt.bytesize).to eq(32)
    end

    it 'produces unique salts' do
      salts = Array.new(10) { km.generate_salt }
      expect(salts.uniq.size).to eq(10)
    end
  end
end
