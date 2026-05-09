# frozen_string_literal: true

RSpec.describe Enigma::Core::Cipher::LayeredCipher do
  let(:key1) { "\x01" * 32 }
  let(:key2) { "\x02" * 32 }
  let(:aes) { Enigma::Core::Cipher::AesGcm.new(key1) }
  let(:chacha) { Enigma::Core::Cipher::Chacha20.new(key2) }
  subject(:cipher) { described_class.new(aes, chacha) }

  it 'round-trips plaintext through all layers' do
    plain = 'Hello LayeredCipher!'
    expect(cipher.decrypt(cipher.encrypt(plain))).to eq(plain)
  end

  it 'handles binary data' do
    binary = (0..255).to_a.pack('C*')
    expect(cipher.decrypt(cipher.encrypt(binary))).to eq(binary)
  end

  it 'raises AuthTagError on wrong key in any layer' do
    encrypted = cipher.encrypt('secret')
    wrong_aes = Enigma::Core::Cipher::AesGcm.new("\xff" * 32)
    wrong = described_class.new(wrong_aes, chacha)
    expect { wrong.decrypt(encrypted) }.to raise_error(Enigma::Errors::AuthTagError)
  end

  it 'reports combined algorithm_name' do
    expect(cipher.algorithm_name).to eq('AES-256-GCM + ChaCha20-Poly1305')
  end

  it 'reports combined key_size' do
    expect(cipher.key_size).to eq(64)
  end

  it 'works with a single layer' do
    single = described_class.new(aes)
    expect(single.decrypt(single.encrypt('test'))).to eq('test')
  end

  it 'raises InvalidKeyError with no layers' do
    expect { described_class.new }.to raise_error(Enigma::Errors::InvalidKeyError)
  end
end
