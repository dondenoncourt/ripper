class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def check_ajax_secret_key!
    raise ArgumentError, "unauthorized access" if params[:ajax_key] != ENV['ajax_secret_key']
  end
end
