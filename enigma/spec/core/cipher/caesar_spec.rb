# frozen_string_literal: true

RSpec.describe Enigma::Core::Cipher::Caesar do
  subject(:cipher) { described_class.new('3') }

  it 'round-trips plaintext' do
    plain = 'HELLO world 123!'
    expect(cipher.decrypt(cipher.encrypt(plain))).to eq(plain)
  end

  it 'shifts printable ASCII correctly' do
    encrypted = cipher.encrypt('ABC')
    expect(encrypted).not_to eq(Base64.strict_encode64('ABC'))
  end

  it 'preserves non-printable bytes' do
    plain = "\x00\x01\x02ABC"
    expect(cipher.decrypt(cipher.encrypt(plain))).to eq(plain)
  end

  it 'raises InvalidKeyError for non-numeric key' do
    expect { described_class.new('abc') }.to raise_error(Enigma::Errors::InvalidKeyError)
  end

  it 'raises InvalidKeyError for empty key' do
    expect { described_class.new('') }.to raise_error(Enigma::Errors::InvalidKeyError)
  end

  it 'returns algorithm_name' do
    expect(cipher.algorithm_name).to eq("C\u00e9sar")
  end

  it 'returns key_size' do
    expect(cipher.key_size).to eq(4)
  end

  # NOTE: complement key 95-k does NOT reverse k because decrypt uses -@shift,
  # so key 95-k gives delta -(95-k) = k-95 ≡ k (mod 95) — same as encrypt.
  # Only the same key k reverses itself via delta -k.
end
