require "yaml"
require "safe_yaml/load"

class ProfileController < ApplicationController
    def index
    end

    def create
        @baseline = SafeYAML.load_file(Rails.root.join("base_profile.yaml"))
    end

    def compare
    end

    def view
    end

    def edit
    end
end
