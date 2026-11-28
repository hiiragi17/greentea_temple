class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, with: :render404
  rescue_from ActionController::RoutingError, with: :render404
  rescue_from Exception, with: :render500

  def render404
    render template: 'errors/404', status: :not_found
  end

  def render500(_exception = nil)
    render template: 'errors/500', status: :internal_server_error
  end

  add_flash_types :success, :error, :info
end
