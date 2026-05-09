# frozen_string_literal: true

RSpec.describe Enigma::Core::KeyMaster do
  subject(:km) { described_class.instance }
  let(:salt) { SecureRandom.random_bytes(32) }

  describe '#derive_vault_key' do
    it 'returns 32 bytes' do
      expect(km.derive_vault_key('password', salt).bytesize).to eq(32)
    end

    it 'is deterministic for same password and salt' do
      expect(km.derive_vault_key('test', salt)).to eq(km.derive_vault_key('test', salt))
    end

    it 'differs for different passwords' do
      expect(km.derive_vault_key('a', salt)).not_to eq(km.derive_vault_key('b', salt))
    end
  end

  describe '#derive_filelock_key' do
    it 'returns 32 bytes' do
      expect(km.derive_filelock_key('password', salt).bytesize).to eq(32)
    end

    it 'differs from vault_key with same password' do
      expect(km.derive_vault_key('pw', salt)).not_to eq(km.derive_filelock_key('pw', salt))
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
