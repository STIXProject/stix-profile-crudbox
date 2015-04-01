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
end
