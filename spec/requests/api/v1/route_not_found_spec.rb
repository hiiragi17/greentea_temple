require 'rails_helper'

RSpec.describe 'Api::V1 route not found', type: :request do
  it 'returns 404 JSON for unmatched API paths' do
    get '/api/v1/this_endpoint_does_not_exist'

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body).to eq('error' => 'Not Found')
  end
end
