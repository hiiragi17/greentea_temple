class CurrentLocationController < ApplicationController
  def search
    gon.greenteas = Greentea.all

  end
  
  def result; end
end
