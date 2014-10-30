require 'nokogiri'
require 'yaml'

namespace :profile_mgmt do

    desc "Update the baseline profile information"
    task :update_baseline do

        base_prof = File.open(Rails.root.join("base_profile.yaml"), "w")
        @schemas = Dir.glob(Rails.root.join("schemas/*.xsd"))
        for file in @schemas
            process_xsd(base_prof, file, 0, "STIX - " + File.basename(file, ".xsd").gsub("_", " ").titleize)
        end

        for file in Dir.glob(Rails.root.join("schemas/cybox/*.xsd"))
            process_xsd(base_prof, file, 0, "CybOX - " + File.basename(file, ".xsd").gsub("_", " ").titleize)
        end

        base_prof.write("CybOX Objects:\n")
        for file in Dir.glob(Rails.root.join("schemas/cybox/objects/*.xsd"))
            process_xsd(base_prof, file, 1, "CybOX - " + File.basename(file, ".xsd").gsub("_", " ").titleize)
        end
        base_prof.close
    end

    def process_xsd(base_prof, file, level, title)
        output_item(base_prof, level, title)
        xsd = File.open(file)
        ndoc = Nokogiri::XML(xsd)
        for elem in ndoc.xpath("//xs:complexType")
            output_item(base_prof, level + 1, "- " + elem['name'])
            attrs = elem.xpath(".//xs:attribute")
            if not attrs.to_a.empty?
                output_item(base_prof, level + 2, "attributes")
                for attrb in attrs
                    output_child_item(base_prof, level + 3, attrb['name'], attrb['type'], attrb['ref'])
                end
            end
            fields = elem.xpath(".//xs:sequence//xs:element")
            if not fields.to_a.empty?
                output_item(base_prof, level + 2, "fields")
                for attrb in fields
                    output_child_item(base_prof, level + 3, attrb['name'], attrb['type'], attrb['ref'])
                end
            end
        end
        xsd.close
    end

    def output_item(outfile, level, catname)
        outfile.write("\t" * level + catname + ":\n")
    end

    def output_child_item(outfile, level, name, type, ref)
        if ref
            outfile.write("\t" * level + "- name:\t" + ref + "\n")
            outfile.write("\t" * level + "  type:\t" + ref + "\n")
            outfile.write("\t" * level + "  use:\t0\n\n")
        else
            outfile.write("\t" * level + "- name:\t" + (name.to_s == '' ? "UNKNOWN" : name) + "\n")
            outfile.write("\t" * level + "  type:\t" + (type.to_s == '' ? "UNKNOWN" : type) + "\n")
            outfile.write("\t" * level + "  use:\t0\n\n")
        end
    end
end
