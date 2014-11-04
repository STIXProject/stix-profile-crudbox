require "yaml"
require "safe_yaml/load"

module ProfileHelper

    def profile_to_excel(pyaml)
        p = Axlsx::Package.new
        wb = p.workbook
        pyaml.each do |key, value|
            if key.length >= 31
                smallkey = key[0...28] + "..."
            else
                smallkey = key
            end
            wb.add_worksheet(:name => smallkey) do |sheet|
                sheet.add_row [key]
                sheet.merge_cells("A1:G1")
                if value["constructs"].nil?
                    excel_cybox_objects(sheet, value)
                else
                    excel_constructs(sheet, value)
                end
            end
        end
        return p
    end

    def excel_cybox_objects(sheet, objects)
        sheet.add_row ["GROUPS"]
        objects.each do |key, object|
            sheet.add_row ["", key]
            excel_constructs(sheet, object)
            sheet.add_row []
        end
    end

    def excel_constructs(sheet, value)
        sheet.add_row []
        sheet.add_row []
        value['constructs'].each do |key, construct|
            sheet.add_row [key]
            if construct['attributes']
                sheet.add_row ["attributes"]
                excel_fields(sheet, construct['attributes'])
            end
            if construct['elements']
                sheet.add_row ["elements"]
                excel_fields(sheet, construct['elements'])
            end
            sheet.add_row []
        end
    end

    def excel_fields(sheet, fields)
        fields.each do |key, field|
            if field.has_key?("type") and not field['type'].nil?
                sheet.add_row [key, "Type: " + field["type"], field['use']]
            else
                sheet.add_row [key, "Type: <NONE>", field['use']]
            end
        end
    end

    def diff_profiles(prof1, prof2)
        @diff_forward = profile_diff(prof1, prof2)
        @diff_backward = profile_diff(prof2, prof1, true)
        @diff = {}
        @diff_forward.each do |key, value|
            @diff[key] = value
        end
        @diff_backward.each do |key, value|
            if not @diff.has_key?(key)
                @diff[key] = value
            end
        end
    end

    def profile_diff(p1, p2, backwards = false, diff = {}, path = [])
        left_label = backwards ? "p2" : "p1"
        right_label = backwards ? "p1" : "p2"
        p1.each do |key, value|
            p2val = p2.nil? ? nil : p2[key]
            if p2val.nil?
                diff[path.join("::")] = {left_label => "Present", right_label => "Missing"}
            end
            if key == "constructs"
                constructs_diff(value, p2val, diff, path.dup.push(key), left_label, right_label)
            else
                profile_diff(value, p2val, backwards, diff, path.dup.push(key))
            end
        end
        return diff
    end

    def constructs_diff(p1, p2, different, path, left_label, right_label)
        p1.each do |key, value| # for each construct
            p2val = p2.nil? ? nil : p2[key]
            if p2val.nil? # construct is missing from other profile
                different[path.dup.push(key).join("::")] = {left_label => "Present", right_label => "Missing"}
            else # construct exists
                if value.has_key?("attributes") # and has attrs
                    attr_diff(value["attributes"], p2val["attributes"], different, path.dup.push(key).push("attributes"), left_label, right_label) # so diff attrs
                end
                if value.has_key?("elements") # and has fields
                    field_diff(value["elements"], p2val["elements"], different, path.dup.push(key).push("elements"), left_label, right_label) # and diff fields
                end
            end
        end
    end

    def attr_diff(p1, p2, different, path, left_label, right_label)
        p1.each do |key, attrb|
            p2val = p2.nil? ? nil : p2[key]
            if p2val.nil?
                different[path.join("::") + "::@" + key] = {left_label => attrb["use"], right_label => "Missing"}
            elsif attrb["use"] != p2val["use"]
                different[path.join("::") + "::@" + key] = {left_label => attrb["use"], right_label => p2val["use"]}
            end
        end
    end

    def field_diff(p1, p2, different, path, left_label, right_label)
        p1.each do |key, attrb|
            p2val = p2.nil? ? nil : p2[key]
            if p2val.nil?
                different[path.join("::") + "::" + key] = {left_label => attrb["use"], right_label => "Missing"}
            elsif attrb["use"] != p2val["use"]
                different[path.join("::") + "::" + key] = {left_label => attrb["use"], right_label => p2val["use"]}
            end
        end
    end
end
