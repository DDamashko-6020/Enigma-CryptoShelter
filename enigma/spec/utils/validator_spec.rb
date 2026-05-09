# frozen_string_literal: true

RSpec.describe Enigma::Utils::Validator do
  let(:v) { described_class.new }

  describe '#not_empty' do
    it 'passes for non-empty string' do
      expect { v.not_empty('valor', 'campo') }.not_to raise_error
    end

    it 'raises InvalidKeyError for empty string' do
      expect { v.not_empty('', 'campo') }
        .to raise_error(Enigma::Errors::InvalidKeyError)
    end

    it 'raises InvalidKeyError for nil' do
      expect { v.not_empty(nil, 'campo') }
        .to raise_error(Enigma::Errors::InvalidKeyError)
    end

    it 'raises InvalidKeyError for whitespace only' do
      expect { v.not_empty('   ', 'campo') }
        .to raise_error(Enigma::Errors::InvalidKeyError)
    end
  end
end
