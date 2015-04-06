require "yaml"
require "safe_yaml/load"

module ProfileHelper

    def attributize(str)
        # lowercase, replace spaces, remove periods
        str.downcase().gsub(" ", "-").gsub(".", "")
    end

    def new_diff(prof1, prof2)
        @diff = {'groups' => {}}

        internal_diff(prof1, prof2, @diff)
        internal_diff(prof2, prof1, @diff)

        @diff['groups'].each do |groupName, groupInfo|
            if groupInfo.empty?
                @diff['groups'].delete(groupName)
            end
        end
    end

    def internal_diff(prof1, prof2, diffs)
        prof1['groups'].each do |groupName, groupInfo|
            if prof2['groups'].has_key?(groupName) # current group is in other profile
                internal_diff_constructs(groupName, prof1, prof2, diffs)
            else # current group missing from other profile
                cGroup = {"#{prof1['name']}" => SchemaProfiler::ITEM_PRESENT,
                          "#{prof2['name']}" => SchemaProfiler::ITEM_MISSING}
                diffs['groups'][groupName] = cGroup
            end
        end
    end

    def internal_diff_constructs(groupName, prof1, prof2, diffs)
        cGroup = diffs['groups'].has_key?(groupName) ? diffs['groups'][groupName] : {}
        diffs['groups'][groupName] = cGroup
        groupInfo1 = prof1['groups'][groupName]
        groupInfo2 = prof2['groups'][groupName]
        groupInfo1['constructs'].each do |constructName, constructInfo|
            cConstr = cGroup.has_key?(constructName) ? cGroup[constructName] : {}
            if groupInfo2['constructs'].has_key?(constructName) # current construct is in other profile
                constr = internal_diff_construct(groupName, constructName, prof1, prof2, diffs)
                if not constr.empty?
                    cGroup[constructName] = constr
                end
            else # current construct missing from other profile
                puts "UHOH"
                cGroup[constructName] = {"#{prof1['name']}" => SchemaProfiler::ITEM_PRESENT,
                           "#{prof2['name']}" => SchemaProfiler::ITEM_MISSING}
            end
        end
    end

    def internal_diff_construct(groupName, constructName, prof1, prof2, diffs)
        cConstr = diffs['groups'][groupName].has_key?(constructName) ? diffs['groups'][groupName][constructName] : {}
        constructInfo1 = prof1['groups'][groupName]['constructs'][constructName]
        constructInfo2 = prof2['groups'][groupName]['constructs'][constructName]

        if constructInfo1.has_key?('attributes')
            constr1Attrs = constructInfo1['attributes']
            constr1Attrs.each do |attrName, attrInfo|
                if not constructInfo2.has_key?('attributes') # construct from prof2 has no attributes
                    cConstr[attrName] = {"#{prof1['name']}" => attrInfo['use'],
                                   "#{prof2['name']}" => SchemaProfiler::ITEM_MISSING}
                elsif not constructInfo2['attributes'].has_key?(attrName) # construct from prof2 doesnt have THIS attribute
                    cConstr[attrName] = {"#{prof1['name']}" => attrInfo['use'],
                                   "#{prof2['name']}" => SchemaProfiler::ITEM_MISSING}
                elsif constructInfo2['attributes'][attrName]['use'] != attrInfo['use']
                    cConstr[attrName] = {"#{prof1['name']}" => attrInfo['use'],
                                   "#{prof2['name']}" => constructInfo2['attributes'][attrName]['use']}
                end
            end
        end

        if constructInfo1.has_key?('fields')
            constr1Attrs = constructInfo1['fields']
            constr1Attrs.each do |fieldName, fieldInfo|
                if not constructInfo2.has_key?('fields') # construct from prof2 has no attributes
                    cConstr[fieldName] = {"#{prof1['name']}" => fieldInfo['use'],
                                   "#{prof2['name']}" => SchemaProfiler::ITEM_MISSING}
                elsif not constructInfo2['fields'].has_key?(fieldName) # construct from prof2 doesnt have THIS attribute
                    cConstr[fieldName] = {"#{prof1['name']}" => fieldInfo['use'],
                                   "#{prof2['name']}" => SchemaProfiler::ITEM_MISSING}
                elsif constructInfo2['fields'][fieldName]['use'] != fieldInfo['use']
                    cConstr[fieldName] = {"#{prof1['name']}" => fieldInfo['use'],
                                   "#{prof2['name']}" => constructInfo2['fields'][fieldName]['use']}
                end
            end
        end
        return cConstr
    end

    def profile_to_excel(pyaml)
        p = Axlsx::Package.new
        wb = p.workbook
        wb.styles do |s|
            title_cell = s.add_style :fg_color => "00", :sz => 20, :border => { :style => :thick, :color => "5182bb", :edges => [:bottom] }
            header_cell = s.add_style :fg_color => "00", :sz => 14, :border => { :style => :thick, :color => "5182bb", :edges => [:bottom] }
            pyaml['groups'].each do |groupName, groupHash|
                if groupName.length >= 31
                    smallkey = groupName[0...28] + "..."
                else
                    smallkey = groupName
                end
                wb.add_worksheet(:name => smallkey) do |sheet|
                    sheet.add_row [groupName, "", ""], :style => [title_cell, title_cell, title_cell]
                    sheet.merge_cells("A1:C1")
                    sheet.add_row []
                    sheet.add_row ["Field", "Type", "Occurrence     "], :style => [header_cell, header_cell, header_cell]
                    excel_constructs(sheet, groupHash, s)
                end
            end
        end
        return p
    end

    def excel_constructs(sheet, value, xl_styles)
        construct_header = xl_styles.add_style :bg_color => "00", :fg_color => "FF", :sz => 14
        col_styles = {
            'must' =>  (xl_styles.add_style :bg_color => "96b4d6", :fg_color => "18375b", :sz => 12),
            'should' => (xl_styles.add_style :bg_color => "c7eecf", :fg_color => "09600b", :sz => 12),
            'may' => (xl_styles.add_style :bg_color => "f9bf87", :fg_color => "bf6915", :sz => 12),
            'should not' => (xl_styles.add_style :bg_color => "feeaa0", :fg_color => "bd6b15", :sz => 12),
            'must not' => (xl_styles.add_style :bg_color => "fec7ce", :fg_color => "9a0511", :sz => 12)
        }
        sheet.add_row []
        value['constructs'].each do |key, construct|
            row = sheet.add_row [key, "", ""], :style => [construct_header]
            row_idx = sheet.rows.index(row)
            sheet.merge_cells(row.cells[(0..2)])
            if construct['attributes']
                excel_fields(sheet, construct['attributes'], col_styles, true)
            end
            if construct['fields']
                excel_fields(sheet, construct['fields'], col_styles)
            end
            sheet.add_row []
        end
    end

    def excel_fields(sheet, fields, styles, attributes = false)
        fields.each do |key, field|
            if attributes
                key = "@" + key
            end
            if field.has_key?("type") and not field['type'].nil?
                curr_style = styles[field['use'].downcase()]
                sheet.add_row [key, field["type"], field['use']], :style => [curr_style, curr_style, curr_style]
            else
                sheet.add_row [key, "", field['use']]
            end
        end
    end
end
