class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from Exception, with: :render_500

  def render_404
    render template: "errors/404", status: :not_found
  end

  def render_500(exception = nil)
    render template: "errors/500", status: :internal_server_error
  end

  before_action :require_login

  add_flash_types :success, :error, :info

  private

  def not_authenticated
    redirect_to root_path
  end
end
