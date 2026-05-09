# frozen_string_literal: true

RSpec.describe Enigma::Core::KeyMaster do
  subject(:km) { described_class.instance }

  describe '#vault_key' do
    it 'returns 32 bytes' do
      expect(km.vault_key('password').bytesize).to eq(32)
    end

    it 'is deterministic for same password' do
      expect(km.vault_key('test')).to eq(km.vault_key('test'))
    end

    it 'differs for different passwords' do
      expect(km.vault_key('a')).not_to eq(km.vault_key('b'))
    end
  end

  describe '#filelock_key' do
    it 'returns 32 bytes' do
      expect(km.filelock_key('password').bytesize).to eq(32)
    end

    it 'differs from vault_key with same password' do
      expect(km.vault_key('pw')).not_to eq(km.filelock_key('pw'))
    end
  end
end
