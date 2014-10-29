require 'nokogiri'

namespace :profile_mgmt do

    desc "Update the baseline profile information"
    task :update_baseline do
        @schemas = Dir.glob(Rails.root.join("schemas/**/*.xsd"))
        for file in @schemas
            xsd = File.open(file)
            ndoc = Nokogiri::XML(xsd)
            puts ndoc.root.name
            xsd.close
        end
    end
end
