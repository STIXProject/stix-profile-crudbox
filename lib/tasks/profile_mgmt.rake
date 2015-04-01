require 'nokogiri'
require 'yaml'
require 'stix_schema_spy'

StixSchemaSpy::Schema.preload!

namespace :profile_mgmt do

    desc ""
    task :print_schemas do
        profile = {} # ActiveSupport::OrderedHash.new
        profile['name'] = 'Baseline Profile'
        profile['version'] = ''
        profile['groups'] = {}
        StixSchemaSpy::Schema.all.each do |schema|
            if profile['version'].empty?
                profile['version'] = schema.stix_version
            end
            if not schema.title.nil?
                profile['groups'][schema.title] = {'project' => schema.project.to_s, 'constructs' => {}}
                process_schema(profile, schema)
            end
        end
        base_prof = File.open(Rails.root.join("test_profile_#{profile['version']}.yaml"), "w")
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
                'attributes' => [],
                 'fields' => []}
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
                this_field['name'] = fieldname
                this_field['type'] = field.type!.full_name
                this_field['use'] = SchemaProfiler::USAGE_MUST_NOT # default to must not/prohibited
                this_type[is_attr ? "attributes" : "fields"].append(this_field)
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

    desc "Update the baseline profile information"
    task :update_baseline do

        profile_hash = {}
        profile_hash["Profile Name"] = "Baseline Profile"
        profile_hash["STIX Version"] = "1.1.1"
        @schemas = Dir.glob(Rails.root.join("schemas/*.xsd"))
        for file in @schemas
            process_xsd(profile_hash, file, 0, "STIX - " + File.basename(file, ".xsd").gsub("_", " ").titleize)
        end
        for file in Dir.glob(Rails.root.join("schemas/cybox/*.xsd"))
            process_xsd(profile_hash, file, 0, "CybOX - " + File.basename(file, ".xsd").gsub("_", " ").titleize)
        end
        object_hash = {}
        profile_hash["CybOX - Objects"] = object_hash
        for file in Dir.glob(Rails.root.join("schemas/cybox/objects/*.xsd"))
            title = File.basename(file, ".xsd").gsub("_", " ").titleize
            process_xsd(object_hash, file, 1, title)
        end
        base_prof = File.open(Rails.root.join("base_profile.yaml"), "w")
        base_prof.write(YAML.dump(profile_hash))
        base_prof.close
    end

    def process_xsd(profile_hash, file, level, title)
        xsd_hash = { }
        constructs = { }
        xsd = File.open(file)
        ndoc = Nokogiri::XML(xsd)
        for elem in ndoc.xpath("//xs:complexType")
            const_hash = {}
            constructs[elem['name']] = const_hash
            attrs = elem.xpath(".//xs:attribute")
            fields = elem.xpath(".//xs:sequence//xs:element")
            if not attrs.to_a.empty?
                attr_hash = {}
                const_hash["attributes"] = attr_hash
                for attrb in attrs
                    ref = attrb['ref']
                    name = attrb['name']
                    type = attrb['type']
                    if ref
                        attr_hash[ref] = {"type" => ref, "use" => SchemaProfiler::USAGE_PROHIBITED}
                    else
                        attr_hash[name] = {"type" => type, "use" => SchemaProfiler::USAGE_PROHIBITED}
                    end
                end
            end
            if not fields.to_a.empty?
                elem_hash = {}
                const_hash["elements"] = elem_hash
                for attrb in fields
                    ref = attrb['ref']
                    name = attrb['name']
                    type = attrb['type']
                    if ref
                        elem_hash[ref] = {"type" => ref, "use" => SchemaProfiler::USAGE_PROHIBITED}
                    else
                        elem_hash[name] = {"type" => type, "use" => SchemaProfiler::USAGE_PROHIBITED}
                    end
                end
            end
        end
        if not constructs.to_a.empty?
            xsd_hash["constructs"] = constructs
        end
        xsd.close
        profile_hash[title] = xsd_hash
    end
end
