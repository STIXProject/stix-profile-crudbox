require 'nokogiri'
require 'yaml'

namespace :profile_mgmt do

    desc "Update the baseline profile information"
    task :update_baseline do

        profile_hash = {}
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
        constructs = []
        xsd = File.open(file)
        ndoc = Nokogiri::XML(xsd)
        for elem in ndoc.xpath("//xs:complexType")
            elem_hash = {"name" => elem['name'], "use" => SchemaProfiler::USAGE_PROHIBITED}
            constructs.push(elem_hash)
            attrs = elem.xpath(".//xs:attribute")
            fields = elem.xpath(".//xs:sequence//xs:element")
            if not attrs.to_a.empty?
                elem_hash["attributes"] = []
                for attrb in attrs
                    ref = attrb['ref']
                    name = attrb['name']
                    type = attrb['type']
                    if ref
                        elem_hash["attributes"].push({"name" => ref, "type" => ref, "use" => SchemaProfiler::USAGE_PROHIBITED})
                    else
                        elem_hash["attributes"].push({"name" => name, "type" => type, "use" => SchemaProfiler::USAGE_PROHIBITED})
                    end
                end
            end
            if not fields.to_a.empty?
                elem_hash["elements"] = []
                for attrb in fields
                    ref = attrb['ref']
                    name = attrb['name']
                    type = attrb['type']
                    if ref
                        elem_hash["elements"].push({"name" => ref, "type" => ref, "use" => SchemaProfiler::USAGE_PROHIBITED})
                    else
                        elem_hash["elements"].push({"name" => name, "type" => type, "use" => SchemaProfiler::USAGE_PROHIBITED})
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
