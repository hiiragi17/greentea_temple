require 'rails_helper'

RSpec.describe DirectionsService do
  let(:origin) { double('origin', latitude: 34.9671, longitude: 135.7727) }
  let(:destination) { double('destination', latitude: 34.9948, longitude: 135.7850) }

  let(:ok_body) do
    {
      'status' => 'OK',
      'routes' => [
        { 'legs' => [{ 'distance' => { 'value' => 1500 }, 'duration' => { 'value' => 1080 } }] }
      ]
    }
  end

  describe '.leg' do
    context 'when no API key is configured' do
      before { allow(DirectionsService).to receive(:api_key).and_return(nil) }

      it 'returns nil without making a request' do
        expect(DirectionsService).not_to receive(:request)
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')).to be_nil
      end
    end

    context 'when an API key is configured' do
      before { allow(DirectionsService).to receive(:api_key).and_return('test-key') }

      it 'returns distance and duration from an OK response' do
        allow(DirectionsService).to receive(:request).and_return(ok_body)

        result = DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')
        expect(result).to eq(distance_meters: 1500, duration_seconds: 1080)
      end

      it 'maps walk to mode=walking' do
        expect(DirectionsService).to receive(:request) do |uri|
          expect(uri.query).to include('mode=walking')
          ok_body
        end
        DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')
      end

      it 'maps train to transit + rail' do
        expect(DirectionsService).to receive(:request) do |uri|
          expect(uri.query).to include('mode=transit')
          expect(uri.query).to include('transit_mode=rail')
          ok_body
        end
        DirectionsService.leg(origin: origin, destination: destination, mode: 'train')
      end

      it 'maps bus to transit + bus' do
        expect(DirectionsService).to receive(:request) do |uri|
          expect(uri.query).to include('mode=transit')
          expect(uri.query).to include('transit_mode=bus')
          ok_body
        end
        DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')
      end

      it 'defaults an unset transport to walking' do
        expect(DirectionsService).to receive(:request) do |uri|
          expect(uri.query).to include('mode=walking')
          ok_body
        end
        DirectionsService.leg(origin: origin, destination: destination, mode: nil)
      end

      it 'returns nil when the API status is not OK' do
        allow(DirectionsService).to receive(:request).and_return('status' => 'ZERO_RESULTS', 'routes' => [])
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')).to be_nil
      end

      it 'returns nil when the request itself fails' do
        allow(DirectionsService).to receive(:request).and_return(nil)
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')).to be_nil
      end

      it 'returns nil when coordinates are missing' do
        no_coords = double('spot', latitude: nil, longitude: nil)
        expect(DirectionsService).not_to receive(:request)
        expect(DirectionsService.leg(origin: no_coords, destination: destination, mode: 'walk')).to be_nil
      end
    end
  end
end
