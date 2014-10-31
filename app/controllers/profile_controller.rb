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

    def upload
        uploaded = JSON.parse(request.POST['profile'])
        @@new_file = uploaded.to_yaml
        head :created
    end

    def download
        send_data(@@new_file, type: 'application/x-yaml', disposition: 'attachment', filename: 'newprofile.yaml')
    end

    def created
    end
end
