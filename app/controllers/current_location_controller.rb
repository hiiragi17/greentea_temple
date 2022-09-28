class CurrentLocationController < ApplicationController
  skip_before_action :require_login, only: %i[search result]

  def search
    gon.greenteas = Greentea.all
    gon.temples = Temple.all
  end

  def result; end
end
