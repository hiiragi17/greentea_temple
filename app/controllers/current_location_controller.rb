class CurrentLocationController < ApplicationController
  MAP_SPOT_FIELDS = %i[id name latitude longitude].freeze

  skip_before_action :require_login, only: %i[search result]

  def search
    @greenteas = Greentea.where.not(latitude: nil, longitude: nil).as_json(only: MAP_SPOT_FIELDS)
    @temples = Temple.where.not(latitude: nil, longitude: nil).as_json(only: MAP_SPOT_FIELDS)
  end

  def result; end
end
