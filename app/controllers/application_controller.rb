# Copyright (c) 2015 - The MITRE Corporation
# For license information, see the LICENSE.txt file
#
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
