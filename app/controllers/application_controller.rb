class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :refinery_user?
end
