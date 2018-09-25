--Saved Variables:
ForgottenChat_General={}
	--This holds all settings used in ALL plugins for FC
ForgottenChat_Aliases={}
	--This holds all personal aliases.  Indexed by realm
ForgottenChat_Blacklist={}
	--This holds all blacklist items.  Simply table, basic indexing.
	

--Randomly Accessed Runtime Variables
local IsFCChannelsInstalled=0
local IsFCLogInstalled=0
local IsFCCoreInstalled=0
local FCCCPlayerIndex=""
FCVar_ColorChanging=""
local FCVar_CopiedProfile={}
local FCVar_UserDisabled=false


local OldChatFrame_OnEvent=ChatFrame_OnEvent

-- Functions essential for loading, and core functionality --
function FCCC_OnLoad()
	--Basic OnLoad function(s)... Setting up the slash handler
	SlashCmdList["FORGOTTENCHATCC"] = function(msg) FCCC_SlashHandler(msg) end;
	SLASH_FORGOTTENCHATCC1 = "/fc";
end
function FCCC_OnEvent(event)
	--Basic event handler.
	if (event == "ADDON_LOADED") and (arg1=="ForgottenChatCC") then
		FCCC_Initialization()
	elseif(event=="CHAT_MSG_WHISPER")then
		if(FCVar_UserDisabled==true)then return end
		valid=FCCC_IsValidWhisper(arg1, arg2)
		if(valid==1)then FCCC_IncomingMessage(arg2, arg1) end
	elseif(event=="CHAT_MSG_WHISPER_INFORM")then
		if(FCVar_UserDisabled==true)then return end
		valid=FCCC_IsValidWhisper(arg1, arg2, 0)
		if(valid==1)then FCCC_OutgoingMessage(arg2, arg1) end
	elseif(event=="CHAT_MSG_AFK")then
		if(FCVar_UserDisabled==true)then return end
		AFKMessage="is Away From Keyboard: "..arg1
		FCCC_AFKMessage(arg2, arg1)
	elseif(event=="WHO_LIST_UPDATE")then
		FC_WhoActivated()
	elseif(event=="PLAYER_REGEN_DISABLED")then
		if(FCVar_UserDisabled==true)then return end
		FCCC_EnterCombat()
	elseif(event=="PLAYER_REGEN_ENABLED")then
		if(FCVar_UserDisabled==true)then return end
		FCCC_ExitCombat()
	end
end
function FCCC_Initialization()
	FCCCPlayerIndex=UnitName("player").."."..GetRealmName()
	OldChatFrame_OnEvent=ChatFrame_OnEvent
	ChatFrame_OnEvent=FCCC_ChatFrame_OnEvent
	
	--Creates a default profile for a new character
	if(ForgottenChat_General==nil)then ForgottenChat_General={} end
	if(ForgottenChat_General[FCCCPlayerIndex]==nil)then ForgottenChat_General[FCCCPlayerIndex]={} FCCC_SetupDefaultProfile(FCCCPlayerIndex) end
	
	if(ForgottenChat_Aliases==nil)then ForgottenChat_Aliases={} end
	if(ForgottenChat_Aliases[GetRealmName()]==nil)then ForgottenChat_Aliases[GetRealmName()]={} end
	
	DEFAULT_CHAT_FRAME:AddMessage('|cff0000FFForgotten Chat Control Center:|r Player Found '..UnitName("player"), 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	
	--Verifies that the saved variables are not corrupt
	FCCC_VerifySavedVariables()
	GuildRoster();
end
function FCCC_RegisterAddin(which)
	if(which=="CORE")then
		IsFCCoreInstalled=1;
		DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r CORE Registered", 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	end
	if(which=="LOG")then
		IsFCLogInstalled=1;
		DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r LOG Registered", 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	end
	if(which=="CHANNELS")then
		IsFCChannelsInstalled=1;
		DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r CHANNELS Registered", 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	end
end
function FCCC_SlashHandler(msg)
	--Basic slash handler.
	if (msg=="") then
		if(FCCC_Options:IsVisible())then
			FCCC_Options:Hide()
		else
			FCCC_Options:Show()
		end
	elseif(msg=="enable")then
		if(IsFCCoreInstalled==1)then
			FC_Enable()
		end
		
		if(FCVar_UserDisabled==true)then
			OldChatFrame_OnEvent=ChatFrame_OnEvent
			ChatFrame_OnEvent=FCCC_ChatFrame_OnEvent
			FCVar_UserDisabled=false
			DEFAULT_CHAT_FRAME:AddMessage('|cff0000FFForgotten Chat Control Center:|r Enabled', 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
		end
		
	elseif(msg=="disable")then
		if(IsFCCoreInstalled==1)then
			FC_Disable()
		end
		
		if(FCVar_UserDisabled==false)then
			ChatFrame_OnEvent=OldChatFrame_OnEvent
			FCVar_UserDisabled=true
			DEFAULT_CHAT_FRAME:AddMessage('|cff0000FFForgotten Chat Control Center:|r Disabled', 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
		end
	elseif(msg=="log")then
		if(IsFCLogInstalled==1)then 
			FCL_ShowHistory() 
		else 
			DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r LOG not installed", 100, 100, 100, 1.0, UIERRORS_HOLD_TIME) 
		end
	else
		FC_AllocateFrame(msg)
	end
end

--Saved Variable maintenance
function FCCC_SetVariable(Setting, Value)
	if(Value==nil)then Value=0 end
	ForgottenChat_General[FCCCPlayerIndex][Setting]=Value
end
function FCCC_GetVariable(Setting)
	return ForgottenChat_General[FCCCPlayerIndex][Setting]
end
function FCCC_SetupDefaultProfile(PlayerIndex)
	--Set ALL needed variables to their default state.
	ForgottenChat_General[PlayerIndex]={}
	ForgottenChat_General[PlayerIndex]["MinimizeUp"]=1
	ForgottenChat_General[PlayerIndex]["TimeStamp"]=1
	ForgottenChat_General[PlayerIndex]["LoadMinimized"]=0
	ForgottenChat_General[PlayerIndex]["CombatMinimize"]=0
	ForgottenChat_General[PlayerIndex]["CombatHide"]=0
	ForgottenChat_General[PlayerIndex]["InboundColor"]="1,0.67,0.95"
	ForgottenChat_General[PlayerIndex]["OutboundColor"]="0,1,1"
	ForgottenChat_General[PlayerIndex]["HighlightColor"]="0,0,0"
	ForgottenChat_General[PlayerIndex]["NameColor"]="1,1,1"
	ForgottenChat_General[PlayerIndex]["DetailColor"]="0,1,0"
	ForgottenChat_General[PlayerIndex]["HistoryColor"]="0,0,1"
	ForgottenChat_General[PlayerIndex]["AFKColor"]="1,0,0"
	ForgottenChat_General[PlayerIndex]["PulseColor"]="0,0,0"
	ForgottenChat_General[PlayerIndex]["Transparency"]=1
	ForgottenChat_General[PlayerIndex]["GuildAndFriendsOnly"]=0
	ForgottenChat_General[PlayerIndex]["MAXwidgets"]=14
	ForgottenChat_General[PlayerIndex]["AudibleAlert"]=1
	ForgottenChat_General[PlayerIndex]["DisplayNumUnread"]=1
	ForgottenChat_General[PlayerIndex]["FontSize"]=12
	ForgottenChat_General[PlayerIndex]["COREdimension"]="350x140"	
	ForgottenChat_General[PlayerIndex]["EditOnClick"]=1
	ForgottenChat_General[PlayerIndex]["WidgetScale"]=1
	ForgottenChat_General[PlayerIndex]["TimeoutSeconds"]=180
	ForgottenChat_General[PlayerIndex]["LevelThreshold"]=1
	ForgottenChat_General[PlayerIndex]["SelectiveWidgets"]=0
	ForgottenChat_General[PlayerIndex]["IgnoreWhos"]=1
	ForgottenChat_General[PlayerIndex]["RecordHistory"]=1
	ForgottenChat_General[PlayerIndex]["EmptyOnLoad"]=1
	ForgottenChat_General[PlayerIndex]["HistoryLinesInWidget"]=20
	ForgottenChat_General[PlayerIndex]["UseAnchor"]="OFF"
	ForgottenChat_General[PlayerIndex]["LockAnchor"]=0
	ForgottenChat_General[PlayerIndex]["HideAnchor"]=0
	ForgottenChat_General[PlayerIndex]["ActionButtons"]=0
	ForgottenChat_General[PlayerIndex]["ScrollButtons"]=0
	
	
	FCCC_AddBlacklist("GA\t")
	FCCC_AddBlacklist("[CTA]")
	FCCC_AddBlacklist("LVPN")
	FCCC_AddBlacklist("LVBM")
	FCCC_AddBlacklist("YOU ARE THE BOMB!")
	FCCC_AddBlacklist("YOU HAVE BURNING ADRENALINE!")
	FCCC_AddBlacklist("You are Little Red")
	FCCC_AddBlacklist("You are being watched!")
end
function FCCC_VerifySavedVariables()
	ProfileBackup={}

	numNew=0
	numDropped=0
	numRetained=0
	numOriginalSettings=0
	
	--Copy ALL elements of the current saved variables into the BackupProfile
	for index, entry in pairs(ForgottenChat_General[FCCCPlayerIndex])do
		ProfileBackup[index]=ForgottenChat_General[FCCCPlayerIndex][index]
		numOriginalSettings=numOriginalSettings+1
	end
	
	--Set the current profile to the default profile
	ForgottenChat_General[FCCCPlayerIndex]=nil
	FCCC_SetupDefaultProfile(FCCCPlayerIndex)
	
	--Iterate over the current (default) profile.  For each entry if the index is in the backup profile, then replace the default entry with the one in the backup
	for index, entry in pairs(ForgottenChat_General[FCCCPlayerIndex])do
		if(ProfileBackup[index]~=nil)then
			-- Valid Saved Variable index found.  copy to the new profile
			ForgottenChat_General[FCCCPlayerIndex][index]=ProfileBackup[index]
			numRetained=numRetained+1
		else
			numNew=numNew+1
		end
	end
	
	--Change Reporting
	if(numNew>0)then
		DEFAULT_CHAT_FRAME:AddMessage('|cff0000FFForgotten Chat Control Center:|r '..numNew..' Variables missing.  Reset to default', 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	end
	numDropped=numOriginalSettings-numRetained
	if(numDropped>0)then
		DEFAULT_CHAT_FRAME:AddMessage('|cff0000FFForgotten Chat Control Center:|r '..numDropped..' Variables deleted.', 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	end
end
function FCCC_ColorPicked()
	if(FCVar_ColorChanging=="")then return end
	R,G,B = ColorPickerFrame:GetColorRGB();
	FCCC_SetVariable(FCVar_ColorChanging, R..","..G..","..B)
	getglobal("FCCC_Options_Appearance_Panel_"..FCVar_ColorChanging.."_Chooser_Text"):SetTextColor(R,G,B)
end

--Regarding incoming and outgoing whispers specificly
function FCCC_IncomingMessage(Name, Text, afk)
	if(IsFCCoreInstalled==1)then
		FC_IncomingMessage(Name, Text, afk)
	end
	if(IsFCLogInstalled==1)then
		FCL_IncomingMessage(Name, Text, afk)
	end
	
	
	--Allows the user to press R to reply wo whispers.
	ChatEdit_SetLastTellTarget(ChatFrame1.editBox, Name)
end
function FCCC_OutgoingMessage(Name, Text, Language)
	if(IsFCCoreInstalled==1)then
		FC_OutgoingMessage(Name, Text, Language)
	end
	if(IsFCLogInstalled==1)then
		FCL_OutgoingMessage(Name, Text, Language)
	end
	
	ChatEdit_SetLastToldTarget(ChatFrame1.editBox, Name)
end
function FCCC_AFKMessage(name, message)
	if(IsFCCoreInstalled==1)then
		FC_AFKMessage(name, message)
		DEFAULT_CHAT_FRAME:AddMessage("AFK message noted")
	end
end
function FCCC_IsValidWhisper(Text, Name)
	if(FCCC_IsGuildieOrFriend(Name)==false) and (FCCC_GetVariable("SelectiveWidgets")==1) then return 0 end
	
	if(Text==nil)then return 1 end
	if(Name==nil)then return 1 end
	for i=1, table.getn(ForgottenChat_Blacklist) do
		smple=string.sub(Text, 1, string.len(ForgottenChat_Blacklist[i]))
		if (smple==ForgottenChat_Blacklist[i]) then
			return 0
		end
	end
	return 1;
end
function FCCC_IsGuildieOrFriend(Name)
	--Checks Aliases
	if(ForgottenChat_Aliases[Name]~=nil)then return true end
	
	--Checks Friends
	for i=1, GetNumFriends() do
		name, level, class, area, connected, status = GetFriendInfo(i)
		if(name==Name) then return true end
	end
	
	--Checks Guildies
	for i=1, GetNumGuildMembers() do
		name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
		if(name==Name) then return true end
	end

	return false
end
function FCCC_FormatNick(Name)
	if ( IsAddOnLoaded("ChatMOD") ) then
		return SCCN_ColorNickName(Name);
	else
		return "["..Name.."]"
	end
end

--Combat functions
function FCCC_EnterCombat()
	if(IsFCCoreInstalled==1)then
		FC_EnterCombat()
	end
	if(IsFCChannelsInstalled==1)then
		FCC_EnterCombat()
	end
	
end
function FCCC_ExitCombat()
	if(IsFCCoreInstalled==1)then
		FC_ExitCombat()
	end
	if(IsFCChannelsInstalled==1)then
		FCC_ExitCombat()
	end
end

--Utility functions
function FCCC_ParseColor(ColorString)
	r=0
	g=0
	b=0
	--if(ColorString==nil)then return nil end
	locComma=string.find(ColorString, ",")
	r=string.sub(ColorString,0,locComma-1)
	ColorString=string.sub(ColorString, locComma+1)
	locComma=string.find(ColorString, ",")
	g=string.sub(ColorString,0,locComma-1)
	ColorString=string.sub(ColorString, locComma+1)
	b=ColorString
	return r,g,b
end
function FCCC_ParseDimension(DimensionString)
	H=0
	W=0
	locX=string.find(DimensionString, "x")
	W=string.sub(DimensionString,0,locX-1)
	H=string.sub(DimensionString,locX+1)
	return H, W
end
function FCCC_GetPlayerIndex()
	return FCCCPlayerIndex
end

--Hooks
function FCCC_ChatFrame_OnEvent(event)
	--Needs implementing!
	if(event=="CHAT_MSG_WHISPER") or (event=="CHAT_MSG_WHISPER_INFORM") or (event=="CHAT_MSG_AFK") or (event=="CHAT_MSG_DND")then
		if(FCCC_IsValidWhisper(arg1, arg2)==0)then
		else
			return
		end
	end
	OldChatFrame_OnEvent(event)
end

--List Displaying
function FCCC_UpdateBlacklist(topIndex)
	table.sort(ForgottenChat_Blacklist)
	--Updates the Blacklist on the options frame starting at row topIndex
	for ind=1, 12 do
		--Clears all elements of the blacklist.
		getglobal("FCCC_Options_Blacklist_Panel_Entry"..ind.."_Text"):SetText("")
		getglobal("FCCC_Options_Blacklist_Panel_Entry"..ind):SetText("")
		getglobal("FCCC_Options_Blacklist_Panel_Entry"..ind):Hide()
	end
	
	--each row contains three elements, 'start' finds the proper element within the list for that row.
	start=topIndex
	j=1
	for i=start, start+11 do
		--Displays the desired list elements from start to start+35
		if(i>table.getn(ForgottenChat_Blacklist))then break end
		--Concatenates long blacklist elements to the first 12 characters followed by an elipse (...)
		getglobal("FCCC_Options_Blacklist_Panel_Entry"..j.."_Text"):SetText(ForgottenChat_Blacklist[i])
		getglobal("FCCC_Options_Blacklist_Panel_Entry"..j):Show()
		j=j+1
	end
	
	i=table.getn(ForgottenChat_Blacklist)
	if(i<=12)then
		--the entire list can be displayed on one unscrolling list.
		FCCC_Options_Blacklist_Panel_Scroller:SetMinMaxValues(1,1)
	else
		--Finds the new maximum value of the scroll list.  
		FCCC_Options_Blacklist_Panel_Scroller:SetMinMaxValues(1,table.getn(ForgottenChat_Blacklist)-11)
	end
end
function FCCC_RemoveBlacklist(Text)
	--Removes the requested item from the Blacklist.
	for i=1, table.getn(ForgottenChat_Blacklist) do
		if(ForgottenChat_Blacklist[i]==Text)then
			table.remove(ForgottenChat_Blacklist, i)
			i=i-1
		end
	end
end
function FCCC_AddBlacklist(Text)
	--Checks if an entry is in the blacklist.  if it is not, adds it.
	for i=1, table.getn(ForgottenChat_Blacklist) do
		if(ForgottenChat_Blacklist[i]==Text)then
			return
		end
	end
	table.insert(ForgottenChat_Blacklist, Text)
end
--
function FCCC_UpdateAliasList(topIndex)
	table.sort(ForgottenChat_Aliases[GetRealmName()])
	--This function updates the alias list on the options framestarting at topIndex
	for ind=1, 12 do
		--Clears all 12 list elements.
		getglobal("FCCC_Options_Aliases_Panel_Entry"..ind.."_Alias"):SetText("")
		getglobal("FCCC_Options_Aliases_Panel_Entry"..ind):SetText("")
		getglobal("FCCC_Options_Aliases_Panel_Entry"..ind):Hide()
		getglobal("FCCC_Options_Aliases_Panel_Entry"..ind.."_DeleteButton"):Hide()
	end
	i=1
	j=1
	for index, entry in pairs(ForgottenChat_Aliases[GetRealmName()]) do
		if(i>=topIndex) and (i<topIndex+12)then
			--Displays the topIndex's element through to the topIndex+12'th element in the list
			getglobal("FCCC_Options_Aliases_Panel_Entry"..j.."_Character"):SetText(index)
			getglobal("FCCC_Options_Aliases_Panel_Entry"..j.."_Alias"):SetText(ForgottenChat_Aliases[GetRealmName()][index])
			getglobal("FCCC_Options_Aliases_Panel_Entry"..j):Show()
			getglobal("FCCC_Options_Aliases_Panel_Entry"..j.."_DeleteButton"):Show()
			j=j+1
		end
		i=i+1
	end
	
	if(i<=12)then
		--the entire list will be displayed on a single, un-scrolling list.
		FCCC_Options_Aliases_Panel_Scroller:SetMinMaxValues(1,1)
	else		
		--The list will require scrolling.
		FCCC_Options_Aliases_Panel_Scroller:SetMinMaxValues(1,i-12)
	end
end
function FCCC_RemoveAliasFromList(Character) 
	--Guess what this does.
	ForgottenChat_Aliases[GetRealmName()][Character]=nil
end
function FCCC_SetAlias(Character, Alias)
	ForgottenChat_Aliases[GetRealmName()][Character]=Alias
end
--
function FCCC_UpdateProfileList(topIndex)
	for ind=1, 10 do
		--Clears all 10 list elements.
		getglobal("FCCC_Options_Profiles_Panel_Entry"..ind.."_Text"):SetText("")
		getglobal("FCCC_Options_Profiles_Panel_Entry"..ind).profile=""
		getglobal("FCCC_Options_Profiles_Panel_Entry"..ind):Hide()
	end
	i=1
	j=1
	for index, entry in pairs(ForgottenChat_General) do
		if(i>=topIndex) and (i<topIndex+10)then
			--Displays the topIndex's element through to the topIndex+12'th element in the list
			dot=string.find(index, "%.")
			
			getglobal("FCCC_Options_Profiles_Panel_Entry"..j).stringName=string.sub(index, 1, dot-1).." of "..string.sub(index, dot+1)
			getglobal("FCCC_Options_Profiles_Panel_Entry"..j.."_Text"):SetText(getglobal("FCCC_Options_Profiles_Panel_Entry"..j).stringName)
			getglobal("FCCC_Options_Profiles_Panel_Entry"..j).profile=index
			getglobal("FCCC_Options_Profiles_Panel_Entry"..j):Show()
			j=j+1
		end
		i=i+1
	end

	if(i<=10)then
		--the entire list will be displayed on a single, un-scrolling list.
		FCCC_Options_Profiles_Panel_Scroller:SetMinMaxValues(1,1)
	else		
		--The list will require scrolling.
		FCCC_Options_Profiles_Panel_Scroller:SetMinMaxValues(1,i-10)
	end
end
function FCCC_DeleteProfile(profileName)
	ForgottenChat_General[profileName]=nil
end
function FCCC_CopyProfile(profileName)
	FCVar_CopiedProfile={}
	for index, entry in pairs(ForgottenChat_General[profileName]) do
		FCVar_CopiedProfile[index]=ForgottenChat_General[profileName][index]
	end
end
function FCCC_PasteProfile(newName)
	for index, entry in pairs(FCVar_CopiedProfile)do
		ForgottenChat_General[newName][index]=FCVar_CopiedProfile[index]
	end
	if(newName==FCCCPlayerIndex)then 
		DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r Some changes may require logout before taking effect", 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
	end
end

