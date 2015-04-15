# Copyright (c) 2015 - The MITRE Corporation
# For license information, see the LICENSE.txt file
#
# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]
