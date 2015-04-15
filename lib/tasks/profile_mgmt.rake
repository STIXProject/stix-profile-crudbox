# Copyright (c) 2015 - The MITRE Corporation
# For license information, see the LICENSE.txt file
require 'nokogiri'
require 'yaml'
require 'stix_schema_spy'

StixSchemaSpy::Schema.preload!

namespace :profile_mgmt do

    desc ""
    task :print_schemas do
        profile = {}
        profile['name'] = "Baseline Profile"
        profile['stix_version'] = ''
        profile['version'] = 1
        profile['status'] = "Approved"
        profile['contact'] = "stix@mitre.org"
        profile['distribution'] = "public"
        profile['description'] = "Baseline profile for STIX 1.1.1, for use in generating clean profiles and clean comparisons."
        profile['groups'] = {}
        StixSchemaSpy::Schema.all.each do |schema|
            if profile['stix_version'].empty?
                profile['stix_version'] = schema.stix_version
            end
            if not schema.title.nil?
                profile['groups'][schema.title] = {'project' => schema.project.to_s, 'constructs' => {}}
                process_schema(profile, schema)
            end
        end
        base_prof = File.open(Rails.root.join("test_profile_#{profile['stix_version']}.yaml"), "w")
        base_prof.write(YAML.dump(profile))
        base_prof.close
    end

    def process_schema(profile_hash, schema)
        schema_title = schema.title
        schema.types.sort_by { |type| type[0].downcase }.each do |type| # for each type
            if type[1].enumeration? || type[0].include?("Enum") # let's ignore Enums for now
                next
            end
            this_type = {
                'use' => SchemaProfiler::USAGE_MUST_NOT,
                'is_vocab' => false,
                'attributes' => {},
                 'fields' => {}}
            if not type[1].vocab?.nil?
                this_type['is_vocab'] = true
                this_type.delete('attributes')
                this_type.delete('fields')
                profile_hash['groups'][schema_title]['constructs'][type[0]] = this_type
                next
            end

            type[1].fields.each do |field|
                this_field = {}
                is_attr = field.name.start_with?("@")
                fieldname = is_attr ? field.name[1..-1] : field.name
                this_field['type'] = field.type!.full_name
                this_field['use'] = SchemaProfiler::USAGE_MUST_NOT # default to must not/prohibited
                this_type[is_attr ? "attributes" : "fields"][fieldname] = this_field
            end
            if this_type['attributes'].empty?
                this_type.delete('attributes')
            end
            if this_type['fields'].empty?
                this_type.delete('fields')
            end
            profile_hash['groups'][schema_title]['constructs'][type[0]] = this_type
        end
    end
end
