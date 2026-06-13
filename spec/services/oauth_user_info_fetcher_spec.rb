require 'rails_helper'

RSpec.describe OauthUserInfoFetcher do
  # Net::HTTPResponse を模した軽量ダブル。実 HTTP は飛ばさない。
  def http_response(code, body)
    instance_double(Net::HTTPResponse, code: code.to_s, body: body)
  end

  describe '.fetch (dispatch)' do
    it 'routes "google" to the Google fetcher' do
      fetcher = instance_double(described_class::Google, call: { provider: 'google' })
      expect(described_class::Google).to receive(:new).with(access_token: 'tok').and_return(fetcher)

      expect(described_class.fetch('google', access_token: 'tok')).to eq(provider: 'google')
    end

    it 'routes "line" to the Line fetcher' do
      fetcher = instance_double(described_class::Line, call: { provider: 'line' })
      expect(described_class::Line).to receive(:new).with(access_token: 'tok').and_return(fetcher)

      expect(described_class.fetch('line', access_token: 'tok')).to eq(provider: 'line')
    end

    it 'accepts a symbol provider' do
      fetcher = instance_double(described_class::Google, call: { provider: 'google' })
      allow(described_class::Google).to receive(:new).and_return(fetcher)

      expect(described_class.fetch(:google, access_token: 'tok')).to eq(provider: 'google')
    end

    it 'raises UnsupportedProviderError for an unknown provider' do
      expect { described_class.fetch('twitter', access_token: 'tok') }
        .to raise_error(described_class::UnsupportedProviderError, /twitter/)
    end
  end

  describe described_class::Google do
    subject(:result) { described_class.new(access_token: 'valid-token').call }

    context 'with a successful response' do
      before do
        allow(Net::HTTP).to receive(:start).and_return(
          http_response(200, { sub: 'g-123', name: 'Aoi', email: 'aoi@example.com' }.to_json)
        )
      end

      it 'returns the normalized user info' do
        expect(result).to eq(provider: 'google', uid: 'g-123', name: 'Aoi')
      end

      it 'falls back to email when name is missing' do
        allow(Net::HTTP).to receive(:start).and_return(
          http_response(200, { sub: 'g-123', email: 'aoi@example.com' }.to_json)
        )
        expect(result[:name]).to eq('aoi@example.com')
      end
    end

    it 'raises FetchError when the access token is blank' do
      expect { described_class.new(access_token: '').call }
        .to raise_error(OauthUserInfoFetcher::FetchError, /access_token is required/)
    end

    it 'raises FetchError on a non-200 response' do
      allow(Net::HTTP).to receive(:start).and_return(http_response(401, 'unauthorized'))
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /Google API error: 401/)
    end

    it 'raises FetchError when sub (uid) is missing' do
      allow(Net::HTTP).to receive(:start).and_return(http_response(200, { name: 'Aoi' }.to_json))
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /missing sub/)
    end

    it 'raises FetchError on invalid JSON' do
      allow(Net::HTTP).to receive(:start).and_return(http_response(200, 'not-json'))
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /Invalid Google response/)
    end

    it 'raises FetchError on a network timeout' do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /Google request failed/)
    end
  end

  describe described_class::Line do
    subject(:result) { described_class.new(access_token: 'valid-token').call }

    context 'with a successful response' do
      before do
        allow(Net::HTTP).to receive(:start).and_return(
          http_response(200, { userId: 'L-999', displayName: 'Sora' }.to_json)
        )
      end

      it 'returns the normalized user info' do
        expect(result).to eq(provider: 'line', uid: 'L-999', name: 'Sora')
      end
    end

    it 'raises FetchError when the access token is blank' do
      expect { described_class.new(access_token: nil).call }
        .to raise_error(OauthUserInfoFetcher::FetchError, /access_token is required/)
    end

    it 'raises FetchError on a non-200 response' do
      allow(Net::HTTP).to receive(:start).and_return(http_response(403, 'forbidden'))
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /LINE API error: 403/)
    end

    it 'raises FetchError on invalid JSON' do
      allow(Net::HTTP).to receive(:start).and_return(http_response(200, 'not-json'))
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /Invalid LINE response/)
    end

    it 'raises FetchError on a network failure' do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError)
      expect { result }.to raise_error(OauthUserInfoFetcher::FetchError, /LINE request failed/)
    end
  end
end
