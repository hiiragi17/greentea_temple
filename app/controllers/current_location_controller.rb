class CurrentLocationController < ApplicationController
  def search
    gon.greenteas = Greentea.all
    gon.temples = Temple.all
  end
  
  def result; end
end
