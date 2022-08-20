class TemplesController < ApplicationController
  def index
    @temples = Temple.all
  end
end
