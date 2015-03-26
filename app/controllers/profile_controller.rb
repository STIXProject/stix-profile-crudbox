require 'axlsx'
require "yaml"
require "safe_yaml/load"

class ProfileController < ApplicationController
    include ProfileHelper

    def create
        @baseline = SafeYAML.load_file(Rails.root.join("base_profile_1.1.1.yaml"))
    end

    def do_compare
        begin
            if request.POST['prof1_baseline']
                prof1 = SafeYAML.load_file(Rails.root.join("base_profile_1.1.1.yaml"))
                @prof1_name = "Base Profile"
            elsif request.POST['prof1']
                prof1 = SafeYAML.load(request.POST['prof1'].tempfile)
                @prof1_name = request.POST['prof1'].original_filename
            else
                raise Exception
            end
        rescue Exception
            @prof1error = true
        end
        begin
            if request.POST['prof2_baseline']
                prof2 = SafeYAML.load_file(Rails.root.join("base_profile_1.1.1.yaml"))
                @prof2_name = "Base Profile"
            elsif request.POST['prof2']
                prof2 = SafeYAML.load(request.POST['prof2'].tempfile)
                @prof2_name = request.POST['prof2'].original_filename
            else
                raise Exception
            end
        rescue Exception
            @prof2error = true
        end
        if not @prof1error and not @prof2error
            begin
                diff_profiles(prof1, prof2)
            rescue => e
                @differror = true
                raise e
            end
        end
        @comparing = true
        render "compare_results"
    end

    def open_profile
        @profile = SafeYAML.load(request.POST['profile'].tempfile)
        @editing = true
        render "edit"
    end


    def upload
        uploaded = JSON.parse(request.POST['profile'])
        @@new_file = uploaded.to_yaml
        head :created
    end

    def download
        send_data(@@new_file, type: 'application/x-yaml', disposition: 'attachment', filename: 'new_profile.yaml')
    end

    def download_excel
        theyaml = SafeYAML.load(@@new_file)
        send_data(profile_to_excel(theyaml).to_stream.read, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', disposition: 'attachment', filename: 'stix_profile.xlsx')
    end

    def created
    end

    def view
    end

    def start_edit
    end

    def edit
    end

    def index
    end

    def compare
    end
end
