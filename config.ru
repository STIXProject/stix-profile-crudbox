# Copyright (c) 2015 - The MITRE Corporation
# For license information, see the LICENSE.txt file

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application
