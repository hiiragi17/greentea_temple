require 'rails_helper'

RSpec.describe DirectionsService do
  let(:origin) { double('origin', latitude: 34.9671, longitude: 135.7727) }
  let(:destination) { double('destination', latitude: 34.9948, longitude: 135.7850) }

  let(:ok_body) do
    {
      'status' => 'OK',
      'routes' => [
        {
          'legs' => [{ 'distance' => { 'value' => 1500 }, 'duration' => { 'value' => 1080 } }],
          'overview_polyline' => { 'points' => 'abc123encoded' }
        }
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

      it 'returns distance, duration and polyline from an OK response' do
        allow(DirectionsService).to receive(:request).and_return(ok_body)

        result = DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')
        expect(result).to eq(distance_meters: 1500, duration_seconds: 1080, polyline: 'abc123encoded')
      end

      it 'returns a nil polyline when overview_polyline is missing' do
        body = ok_body.deep_dup
        body['routes'][0].delete('overview_polyline')
        allow(DirectionsService).to receive(:request).and_return(body)

        result = DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')
        expect(result).to eq(distance_meters: 1500, duration_seconds: 1080, polyline: nil)
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

      it 'sends departure_time for transit modes (train/bus) but not for walk/car' do
        expect(DirectionsService).to receive(:request) do |uri|
          expect(uri.query).to include('departure_time=')
          ok_body
        end
        DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')

        expect(DirectionsService).to receive(:request) do |uri|
          expect(uri.query).not_to include('departure_time=')
          ok_body
        end
        DirectionsService.leg(origin: origin, destination: destination, mode: 'car')
      end

      it 'uses the current time as departure_time within service hours' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 10, 0, 0)) do
          expect(DirectionsService).to receive(:request) do |uri|
            expect(uri.query).to include("departure_time=#{Time.zone.now.to_i}")
            ok_body
          end
          DirectionsService.leg(origin: origin, destination: destination, mode: 'train')
        end
      end

      it 'rolls departure_time forward to the same-day fallback hour when queried before service hours' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 3, 0, 0)) do
          expect(DirectionsService).to receive(:request) do |uri|
            expected = Time.zone.local(2026, 1, 5, 9, 0, 0).to_i
            expect(uri.query).to include("departure_time=#{expected}")
            ok_body
          end
          DirectionsService.leg(origin: origin, destination: destination, mode: 'train')
        end
      end

      it 'rolls departure_time forward to the next-day fallback hour when queried after service hours' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 23, 30, 0)) do
          expect(DirectionsService).to receive(:request) do |uri|
            expected = Time.zone.local(2026, 1, 6, 9, 0, 0).to_i
            expect(uri.query).to include("departure_time=#{expected}")
            ok_body
          end
          DirectionsService.leg(origin: origin, destination: destination, mode: 'train')
        end
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

      it 'does not retry non-transit modes on a non-OK status' do
        expect(DirectionsService).to receive(:request).once.and_return('status' => 'ZERO_RESULTS', 'routes' => [])
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')).to be_nil
      end

      it 'logs the status and mode for every failed attempt' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 10, 0, 0)) do
          allow(DirectionsService).to receive(:request).and_return('status' => 'ZERO_RESULTS', 'routes' => [])
          expect(Rails.logger).to receive(:warn).with(/ZERO_RESULTS.*mode="bus"/).exactly(3).times
          DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')
        end
      end

      it 'retries transit modes at the next-day fallback hour when the first attempt is non-OK' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 10, 0, 0)) do
          first_departure = Time.zone.local(2026, 1, 5, 10, 0, 0).to_i
          retry_departure = Time.zone.local(2026, 1, 6, 9, 0, 0).to_i
          call_count = 0

          expect(DirectionsService).to receive(:request).twice do |uri|
            call_count += 1
            if call_count == 1
              expect(uri.query).to include("departure_time=#{first_departure}")
              { 'status' => 'ZERO_RESULTS', 'routes' => [] }
            else
              expect(uri.query).to include("departure_time=#{retry_departure}")
              ok_body
            end
          end

          result = DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')
          expect(result).to eq(distance_meters: 1500, duration_seconds: 1080, polyline: 'abc123encoded')
        end
      end

      it 'falls back to a relaxed (unrestricted) transit query without a time re-retry when both times are the same' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 23, 30, 0)) do
          call_count = 0

          expect(DirectionsService).to receive(:request).twice do |uri|
            call_count += 1
            if call_count == 1
              expect(uri.query).to include('transit_mode=bus')
              { 'status' => 'ZERO_RESULTS', 'routes' => [] }
            else
              expect(uri.query).not_to include('transit_mode=')
              ok_body
            end
          end

          result = DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')
          expect(result).to eq(distance_meters: 1500, duration_seconds: 1080, polyline: 'abc123encoded')
        end
      end

      it 'falls back to a relaxed (unrestricted) transit query when both the time retry and the mode-restricted retry are ZERO_RESULTS' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 10, 0, 0)) do
          call_count = 0

          expect(DirectionsService).to receive(:request).exactly(3).times do |uri|
            call_count += 1
            if call_count == 3
              expect(uri.query).not_to include('transit_mode=')
              ok_body
            else
              expect(uri.query).to include('transit_mode=rail')
              { 'status' => 'ZERO_RESULTS', 'routes' => [] }
            end
          end

          result = DirectionsService.leg(origin: origin, destination: destination, mode: 'train')
          expect(result).to eq(distance_meters: 1500, duration_seconds: 1080, polyline: 'abc123encoded')
        end
      end

      it 'returns nil when even the relaxed transit fallback is ZERO_RESULTS' do
        Timecop.freeze(Time.zone.local(2026, 1, 5, 10, 0, 0)) do
          expect(DirectionsService).to receive(:request).exactly(3).times
                                                          .and_return('status' => 'ZERO_RESULTS', 'routes' => [])
          expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')).to be_nil
        end
      end

      it 'does not retry transit modes when the request itself fails (network failure)' do
        expect(DirectionsService).to receive(:request).once.and_return(nil)
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')).to be_nil
      end

      it 'does not retry transit modes for a permanent API status such as REQUEST_DENIED' do
        expect(DirectionsService).to receive(:request).once.and_return('status' => 'REQUEST_DENIED', 'routes' => [])
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'bus')).to be_nil
      end

      it 'returns nil when the request itself fails' do
        allow(DirectionsService).to receive(:request).and_return(nil)
        expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')).to be_nil
      end

      it 'returns nil (does not raise) on transient network failures' do
        [Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError, Net::ReadTimeout].each do |error|
          allow(Net::HTTP).to receive(:start).and_raise(error)
          expect {
            expect(DirectionsService.leg(origin: origin, destination: destination, mode: 'walk')).to be_nil
          }.not_to raise_error
        end
      end

      it 'returns nil when coordinates are missing' do
        no_coords = double('spot', latitude: nil, longitude: nil)
        expect(DirectionsService).not_to receive(:request)
        expect(DirectionsService.leg(origin: no_coords, destination: destination, mode: 'walk')).to be_nil
      end
    end
  end
end
