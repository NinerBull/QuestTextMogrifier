QuestTextMogrifier = LibStub("AceAddon-3.0"):NewAddon("QuestTextMogrifier", "AceEvent-3.0", "AceConsole-3.0")
QuestTextMogrifier.AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("QuestTextMogrifierLocale")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")


function QuestTextMogrifier:OnInitialize()

	self.db = LibStub("AceDB-3.0"):New("QuestTextMogrifierDB", QuestTextMogrifier:GenerateDefaultDB(), true)
	
	self:GenerateOptions()
	
	self.optionsData.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	
	AC:RegisterOptionsTable("QuestTextMogrifier_Options", self.optionsData)
	
	self.optionsFrame = ACD:AddToBlizOptions("QuestTextMogrifier_Options", L["QTM_ADDONNAME"])

end

function QuestTextMogrifier:OnEnable()

	self:RegisterChatCommand("qtm", "SlashCommand")
	self:RegisterChatCommand("questtextmogrifier", "SlashCommand")
	
	self:RegisterEvent("ITEM_TEXT_READY")
	
	-- Get Gossip Text
	QuestTextMogrifier.C_GossipInfoGetTextHook = C_GossipInfo.GetText
	C_GossipInfo.GetText = function (...)
		local thisGossipText = QuestTextMogrifier:C_GossipInfoGetTextHook()
		return QuestTextMogrifier:DoTextRename(thisGossipText)
	end
	

	-- Get Greeting Text
	QuestTextMogrifier.GetGreetingTextHook = GetGreetingText
	GetGreetingText = function (...)
		local thisGreetingText = QuestTextMogrifier:GetGreetingTextHook()
		return QuestTextMogrifier:DoTextRename(thisGreetingText)
	end


	-- Get Quest Text
	QuestTextMogrifier.GetQuestTextHook = GetQuestText
	GetQuestText = function (...)
		local thisQuestText = QuestTextMogrifier:GetQuestTextHook()
		return QuestTextMogrifier:DoTextRename(thisQuestText)
	end


	-- Get Quest Progress Text
	QuestTextMogrifier.GetProgressTextHook = GetProgressText
	GetProgressText = function (...)
		local thisProgressText = QuestTextMogrifier:GetProgressTextHook()
		return QuestTextMogrifier:DoTextRename(thisProgressText)
	end



	-- Get Quest Reward Text
	QuestTextMogrifier.GetRewardTextHook = GetRewardText
	GetRewardText = function (...)
		local thisRewardText = QuestTextMogrifier:GetRewardTextHook()
		return QuestTextMogrifier:DoTextRename(thisRewardText)
	end
	
	
	
	hooksecurefunc(SubtitlesFrame, "AddSubtitle", function(...)
		if not QuestTextMogrifier:ShouldNotEditText() then
			SubtitlesFrame.Subtitle1:SetText(QuestTextMogrifier:DoTextRename(SubtitlesFrame.Subtitle1:GetText()))
		end
	end)
	
	
	
	local function ChatFilterFunc(self, thisEvent, thisMessage, thisNPC, ...)

		if (QuestTextMogrifier:ShouldNotEditText(true)) then
			return false, thisMessage, thisNPC, ...
		end
		
		if (canaccessvalue and not canaccessvalue(thisMessage)) then
			return false, thisMessage, thisNPC, ...
		end
	
		local thisNewMessage = QuestTextMogrifier:DoTextRename(thisMessage)
		if (TRP3_API.configuration.getValue(TRPRPNAMEINQUESTS.CONFIG.TEXTMODNPCSPEECH) == true) then
			if (thisEvent == "CHAT_MSG_MONSTER_SAY" or thisEvent == "CHAT_MSG_MONSTER_YELL" or thisEvent ==  "CHAT_MSG_MONSTER_PARTY") then
				pcall(function () 
					QuestTextMogrifier:ModSpeechBubbles()
				end) 
				
			end
		end
		
		
		return false, thisNewMessage, thisNPC, ...
	
	end
	
	
	
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", ChatFilterFunc) -- NPC /s Chat
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", ChatFilterFunc) -- NPC /y Chat
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", ChatFilterFunc) -- NPC /p Chat
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", ChatFilterFunc) -- NPC /w Chat
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", ChatFilterFunc) -- NPC /e Chat
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PING", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_HORDE", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_ALLIANCE", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SKILL", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_OPENING", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_TRADESKILLS", ChatFilterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_EMOTE", ChatFilterFunc) -- NPC Boss /e Chat
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", ChatFilterFunc) -- NPC Boss /w Chat
	
	
	
	if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
		hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function(self)
			if not QuestTextMogrifier:ShouldNotEditText() then
				C_Timer.After(0.3, function()
					--Talker Text
					self.TextFrame.Text:SetText(QuestTextMogrifier:DoTextRename(self.TextFrame.Text:GetText()))
				end);
			end
		end)
	end
	
	
	
	-- Speech Bubbles
	-- with Code Modified from https://www.wowinterface.com/forums/showpost.php?p=336696&postcount=2
	function QuestTextMogrifier:ModSpeechBubbles()
		--Slight timer so the bubble has chance to fade in
		C_Timer.After(.05, function()
			if not QuestTextMogrifier:ShouldNotEditText() then
				for _, bubble in pairs(C_ChatBubbles.GetAllChatBubbles()) do -- This -should- only affect NPC speech bubbles, player speech bubbles are protected
					for i = 1, bubble:GetNumChildren() do
						local child = select(i, select(i, bubble:GetChildren()))
						if(child) then
							if (child:GetObjectType() == "Frame") and (child.String) and (child.Center) then
								for i = 1, child:GetNumRegions() do
									local region = select(i, child:GetRegions())
									if (region:GetObjectType() == "FontString") then
									
										thisBubbleText = region:GetText()
										
										region:SetText(QuestTextMogrifier:DoTextRename(thisBubbleText))
										
										--Resize bubble to accomodate new text
										if (region:GetStringWidth() >= region:GetWrappedWidth()) then
											region:SetWidth(region:GetWrappedWidth())
										else
											--region:SetWidth(region:GetStringWidth())
											region:SetWidth(region:GetWrappedWidth())
										end
										
										
									end
								end
							end
						end
					end
				end
			end
		end)
	end

end

function QuestTextMogrifier:ITEM_TEXT_READY(event, arg1, arg2)
	if (not self:ShouldNotEditText()) then
		
		local creator = ItemTextGetCreator();
		if ( creator ) then
			creator = "\n\n"..ITEM_TEXT_FROM.."\n"..creator.."\n";
			ItemTextPageText:SetText(self:DoTextRename(ItemTextGetText())..creator);
		else
			ItemTextPageText:SetText(self:DoTextRename(ItemTextGetText()));
		end
		
	end
end


function QuestTextMogrifier:ShouldNotEditText()
	if (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()) then
		return true
	end
	
	return false
end


function QuestTextMogrifier:DoTextRename(textToRename)
	textToRename = textToRename or ""
	
	if (canaccessvalue and not canaccessvalue(textToRename)) then
		return textToRename
	end

	thisTextToReturn = textToRename or ""
	
	for _,v in pairs(self.db.profile.textReplacements) do 
		if (v.textSearch ~= "" and v.textReplace ~= "") then
			
			thisTextToReturn = thisTextToReturn:gsub(string.lower(v.textSearch .. " "),string.lower(v.textReplace) .. " ")
			thisTextToReturn = thisTextToReturn:gsub(string.lower(v.textSearch .. ","),string.lower(v.textReplace) .. ",")
			thisTextToReturn = thisTextToReturn:gsub(string.lower(v.textSearch .. "."),string.lower(v.textReplace) .. ".")
			thisTextToReturn = thisTextToReturn:gsub(string.lower(v.textSearch .. "?"),string.lower(v.textReplace) .. "?")
			thisTextToReturn = thisTextToReturn:gsub(string.lower(v.textSearch .. "!"),string.lower(v.textReplace) .. "!")
			
			thisTextToReturn = thisTextToReturn:gsub(string.upper(v.textSearch .. " "),string.upper(v.textReplace) .. " ")
			thisTextToReturn = thisTextToReturn:gsub(string.upper(v.textSearch .. ","),string.upper(v.textReplace) .. ",")
			thisTextToReturn = thisTextToReturn:gsub(string.upper(v.textSearch .. "."),string.upper(v.textReplace) .. ".")
			thisTextToReturn = thisTextToReturn:gsub(string.upper(v.textSearch .. "?"),string.upper(v.textReplace) .. "?")
			thisTextToReturn = thisTextToReturn:gsub(string.upper(v.textSearch .. "!"),string.upper(v.textReplace) .. "!")
			
			thisTextToReturn = thisTextToReturn:gsub(v.textSearch .. " ",v.textReplace .. " ")
			thisTextToReturn = thisTextToReturn:gsub(v.textSearch .. ",",v.textReplace .. ",")
			thisTextToReturn = thisTextToReturn:gsub(v.textSearch .. ".",v.textReplace .. ".")
			thisTextToReturn = thisTextToReturn:gsub(v.textSearch .. "?",v.textReplace .. "?")
			thisTextToReturn = thisTextToReturn:gsub(v.textSearch .. "!",v.textReplace .. "!")
			
		end

	end
	
	return thisTextToReturn
end