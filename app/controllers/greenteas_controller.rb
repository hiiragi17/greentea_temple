class GreenteasController < ApplicationController
  def index
    @greenteas = Greentea.all
  end
end
