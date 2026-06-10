class CurrentLocationController < ApplicationController
  MAP_SPOT_FIELDS = %i[id name latitude longitude].freeze

  skip_before_action :require_login, only: %i[search result]

  def search
    @greenteas = Greentea.all.as_json(only: MAP_SPOT_FIELDS)
    @temples = Temple.all.as_json(only: MAP_SPOT_FIELDS)
  end

  def result; end
end
