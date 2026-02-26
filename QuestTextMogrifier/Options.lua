local L = LibStub("AceLocale-3.0"):GetLocale("QuestTextMogrifierLocale")

function QuestTextMogrifier:GenerateDefaultDB()

	local defaults = {
		profile = {
			textReplacements = {
				['**'] = {
					textSearch = "",
					textReplace = "",
					onlyAdjacentToPunctuation = false
				}
			}
		}
	}

	return defaults

end



function QuestTextMogrifier:GenerateOptions()

		
	local thisQTTable = {
		type = "group",
		name = L["QTM_NEW"],
		inline = true,
		args = {
			textSearch = {
				type = "input",
				order = 1,
				name = L["QTM_SEARCH"],
				desc = L["QTM_SEARCH_DESC"],
				get = "GetFindText",
				set = "SetFindText"
			},
			textReplace = {
				type = "input",
				order = 2,
				name = L["QTM_REPLACE"],
				desc = L["QTM_REPLACE_DESC"],
				get = "GetReplaceText",
				set = "SetReplaceText"
			},
			--[[onlyAdjacentToPunctuation = {
				type = "toggle",
				name = "",
				order = 3,
				get = "GetAdjacentToPunctuation",
				set = "SetAdjacentToPunctuation"
			},]]
			btnRTDelete = {
				type = "execute",
				name = L["QTM_DELETE"],
				desc = L["QTM_DELETE_DESC"],
				width = 0.5,
				order = 4,
				func = function()
					
				end,
				
			},
		}
	
	}

	QuestTextMogrifier.optionsData = {
		type = "group",
		name = L["QTM_ADDONNAME"],
		handler = QuestTextMogrifier,
		childGroups = "tab",
		args = {
			desc = {
				type = "description",
				fontSize = "small",
				order = 1,
				width = "full",
				name = L["QTM_DESCRIPTION"]
			},
			qTSettings = {
				type = "group",
				name = L["QTM_TEXTREPLACEMENTS"],
				desc = L["QTM_TEXTREPLACEMENTS_DESC"],
				order = 10,
				args = {
				
				}
			}
		
		}
	}
	
	for i = 1,100,1 do
	
		local thisTable = CopyTable(thisQTTable)
		
		thisTable.name = tostring(i)
		thisTable.order = i + 1000
		
		thisTable.hidden = function()
			if (i == 1) or ((self.db.profile.textReplacements[i] and self.db.profile.textReplacements[i].textSearch ~= "") or (self.db.profile.textReplacements[i] and self.db.profile.textReplacements[i].textReplace ~= "")) then
				return false
			else
				return (not self.db.profile.textReplacements[i-1]) or (self.db.profile.textReplacements[i-1].textSearch == "" and self.db.profile.textReplacements[i-1].textReplace == "") 
			end
		end
		
		thisTable.args.btnRTDelete.func = function() 
			self.db.profile.textReplacements[i] = nil
			self:OrganiseReplacementsTable()
		end
		
		thisTable.args.btnRTDelete.hidden = function()
			return (not self.db.profile.textReplacements[i]) or (self.db.profile.textReplacements[i].textSearch == "" and self.db.profile.textReplacements[i].textReplace == "")
		end
			
		QuestTextMogrifier.optionsData.args.qTSettings.args[tostring(i)] = thisTable
	end
	
	--QuestTextMogrifier:OrganiseReplacementsTable()
	

end



function QuestTextMogrifier:OrganiseReplacementsTable()
	local xx = 1
	local thisCleanTable = {}
	
	for k,v in pairs(self.db.profile.textReplacements) do
		thisCleanTable[xx] = CopyTable(v)
		xx = xx + 1
	end
	
	self.db.profile.textReplacements = CopyTable(thisCleanTable)
end


function QuestTextMogrifier:GetFindText(info)
	return self.db.profile.textReplacements[tonumber(info[#info-1])] and self.db.profile.textReplacements[tonumber(info[#info-1])].textSearch or ""
end


function QuestTextMogrifier:SetFindText(info, value)
	self.db.profile.textReplacements[tonumber(info[#info-1])].textSearch = value:sub(1,1):upper()..value:sub(2)
	self:OrganiseReplacementsTable()
end


function QuestTextMogrifier:GetReplaceText(info)
	return self.db.profile.textReplacements[tonumber(info[#info-1])] and self.db.profile.textReplacements[tonumber(info[#info-1])].textReplace or ""
end


function QuestTextMogrifier:SetReplaceText(info, value)
	self.db.profile.textReplacements[tonumber(info[#info-1])].textReplace = value:sub(1,1):upper()..value:sub(2)
	self:OrganiseReplacementsTable()
end


function QuestTextMogrifier:GetAdjacentToPunctuation(info)
	return self.db.profile.textReplacements[tonumber(info[#info-1])] and self.db.profile.textReplacements[tonumber(info[#info-1])].onlyAdjacentToPunctuation or false
end


function QuestTextMogrifier:SetAdjacentToPunctuation(info, value)
	self.db.profile.textReplacements[tonumber(info[#info-1])].onlyAdjacentToPunctuation = value
	self:OrganiseReplacementsTable()
end