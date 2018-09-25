--Saved Variables:
ForgottenChat_Channels={}
	--This hilds general saved variables for basic ForgottenChat_Channels which are not covered in ForgottenChat.  Indexed by character.realm
ForgottenChat_ChannelsFrames={}
	--This holds all information relevant for ChannelFrames such as Name, default channel, etc.  Indexed by character.realm


	
--Randomly Accessed, Non-Persistant Variables for ForgottenChat_Channels
local FCCVar_ToHide={0,0,0,0,0,0,0}
local FCCVar_ToShow={0,0,0,0,0,0,0}
local PlayerIndex=""

	
-- Functions essential for loading, and core functionality --
function FCC_OnLoad()
	FCCC_RegisterAddin("CHANNELS")
end
function FCC_OnEvent(event)
	if(arg1=="ForgottenChatChannels")then
		FCC_Initialization()
	end
end
function FCC_Initialization()
	PlayerIndex=UnitName("player").."."..GetRealmName()
	--For forgottenChat_Channels, all saved variables are referanced directly from the array.
	if (ForgottenChat_Channels[PlayerIndex]==nil)then
		ForgottenChat_Channels[PlayerIndex]={}
		ForgottenChat_Channels[PlayerIndex][1]=0		--1=hide the default channels
		ForgottenChat_Channels[PlayerIndex][2]=1		--1=disable FCChannels
		
		--Setup a default profile
	end
	if(ForgottenChat_ChannelsFrames[PlayerIndex]==nil)then
		--{Size,name, visible, CurrentState, minimze in combat, maximize in combat,MinimizeUp...}
		ForgottenChat_ChannelsFrames[PlayerIndex]={}
		ForgottenChat_ChannelsFrames[PlayerIndex][1]={{200,150},"Channel Widget #1",0,0,0,0,0}
		ForgottenChat_ChannelsFrames[PlayerIndex][2]={{200,150},"Channel Widget #2",0,0,0,0,0}
		ForgottenChat_ChannelsFrames[PlayerIndex][3]={{200,150},"Channel Widget #3",0,0,0,0,0}
		ForgottenChat_ChannelsFrames[PlayerIndex][4]={{200,150},"Channel Widget #4",0,0,0,0,0}
		ForgottenChat_ChannelsFrames[PlayerIndex][5]={{200,150},"Channel Widget #5",0,0,0,0,0}
		ForgottenChat_ChannelsFrames[PlayerIndex][6]={{200,150},"Channel Widget #6",0,0,0,0,0}
		ForgottenChat_ChannelsFrames[PlayerIndex][7]={{200,150},"Channel Widget #7",0,0,0,0,0}
		--Setup a default profile
	end
	FCC_SetupAllWidgets()
	FCC_SetupOptionFrame()
	for i=1, 7 do
		getglobal("FC_Channel"..i.."_Chat"):SetID(i)
	end
	if(ForgottenChat_Channels[PlayerIndex][2]==1)then
		for i=1, 7 do
			getglobal("FC_Channel"..i.."_Chat").ready=0
			--Disables the Chatframe Events
		end
		for i=1, 7 do
			getglobal("FCChanWidg"..i):Disable()
		end
	end
end
function FCC_SetupAllWidgets()
	for i=1, 7 do
		--Set Name
		getglobal("FC_Channel"..i.."_MoveIt_Name"):SetText(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][2])
		
		--Set Visible
		if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][3]==1) then 
			getglobal("FC_Channel"..i):Show()
		end
		getglobal("FC_Channel"..i.."_Chat"):Show()
		
		--Set Size
		FCC_ResizeWidget(i)
		--Set Minimized/Maximized
		if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][4]==1)then
			getglobal("FC_Channel"..i.."_Chat"):Hide()
		end
		--Set Color
		getglobal("FC_Channel"..i.."_MoveIt_Name"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("NameColor")))
		
		
		getglobal("FC_Channel"..i):SetAlpha(FCCC_GetVariable("Transparency"))
		getglobal("FC_Channel"..i.."_MoveIt"):SetAlpha(1)
		getglobal("FC_Channel"..i.."_Chat"):SetAlpha(1)
		getglobal("FC_Channel"..i.."_MinimizeButton"):SetAlpha(1)
	end
	FCC_SetDefaultState()
end

function FCC_EnterCombat()
	for i=1, 7 do
		if(getglobal("FC_Channel"..i):IsVisible())then
			if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][6]==1)then
				if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][4]==1)then
					--Combat Maximize
					getglobal("FC_Channel"..i).CombatMaximized=1
					FCC_MinimizeWidget(i, 0)
				end
			elseif(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][5]==1)then
				if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][4]==0)then
					--CombatMinimize
					getglobal("FC_Channel"..i).CombatMinimized=1
					FCC_MinimizeWidget(i, 1)
				end
			end
		end
	end
end
function FCC_ExitCombat()
	for i=1, 7 do
		if(getglobal("FC_Channel"..i).CombatMaximized==1)then
			--Un-Maximize it
			getglobal("FC_Channel"..i).CombatMaximized=0
			FCC_MinimizeWidget(i,1)
		elseif(getglobal("FC_Channel"..i).CombatMinimized==1)then
			--Un-Minimize it
			getglobal("FC_Channel"..i).CombatMinimized=0
			FCC_MinimizeWidget(i,0)
		end
	end
end

function FCC_ResizeWidget(frameNum)
	getglobal("FC_Channel"..frameNum):SetHeight(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][2])
	getglobal("FC_Channel"..frameNum):SetWidth(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][1])	
	getglobal("FC_Channel"..frameNum.."_MoveIt"):SetWidth(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][1])
	getglobal("FC_Channel"..frameNum.."_Chat"):SetWidth(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][1]-20)
	getglobal("FC_Channel"..frameNum.."_Chat"):SetHeight(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][2]-40)
end
function FCC_MinimizeWidget(frameNum, toState)
--0 represents a Maximized State, 1 = minimized
	Frm=getglobal("FC_Channel"..frameNum)
	thisState=ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][4]
	MinimizeUp=ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][7]
	if(toState==nil)then
		--If undefined, this will toggle the current state.
		toState=abs(thisState-1)
	end
	if(thisState==toState)then
		--No change is needed
		return
	end
	Bottom=Frm:GetBottom()
	Left=Frm:GetLeft()
	Frm:ClearAllPoints()
	if(thisState==0)then
		--Minimizing
		ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][4]=1
		Frm:SetHeight(30)
		getglobal("FC_Channel"..frameNum.."_Chat"):Hide()
		--This will shift the now minimized frame down or up depending on the minimizing protocol.
		if(MinimizeUp==0)then
			--Minimizing with a Minimize Up configuration
			Frm:SetPoint("BOTTOMLEFT",Left, Bottom)
		else
			--Minimizing with a Minimize Down configuration
			Frm:SetPoint("BOTTOMLEFT",Left, Bottom+ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][2]-30)
		end
	elseif(thisState==1)then
		--Maximizing
		ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][4]=0
		Frm:SetHeight(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][2])
		getglobal("FC_Channel"..frameNum.."_MoveIt_Name"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("NameColor")))
		getglobal("FC_Channel"..frameNum.."_Chat"):Show()
		--This will shift the now minimized frame down or up depending on the minimizing protocol.
		if(MinimizeUp==0)then
			--Maximizing with a Minimize Up configuration
			Frm:SetPoint("BOTTOMLEFT",Left, Bottom)
		else
			--Maximizing with a Minimize Down configuration
			Frm:SetPoint("BOTTOMLEFT",Left, Bottom-ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][2]+30)
		end
	end	
end
function FCC_SetTransparency(Trans)
	for i=1, 7 do
		getglobal("FC_Channel"..i):SetAlpha(Trans)
		getglobal("FC_Channel"..i.."_MoveIt"):SetAlpha(1)
		getglobal("FC_Channel"..i.."_Chat"):SetAlpha(1)
		getglobal("FC_Channel"..i.."_MinimizeButton"):SetAlpha(1)
	end
end

--Functions for maintaining saved variables
function FCC_SetupOptionFrame()
	for i=1, 7 do
		getglobal("FCChanWidg"..i.."_Name"):SetText(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][i][2])
		if(ForgottenChat_Channels[FCCC_GetPlayerIndex()][2]==1)then
			getglobal("FCChanWidg"..i):Disable()
		else
			getglobal("FCChanWidg"..i):Enable()
		end
	end
	FCDisableChannels:SetChecked(ForgottenChat_Channels[FCCC_GetPlayerIndex()][2])
end
function FCC_ShowEditOptions(frameNum)
	FCChanDetailsName:Show()
	FCChannelSave:Show()
	FCChanNameEntry:Show()
	FCChanNameEntry:SetText(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][2])
	FCChanDetailsCombatHide:Show()
	FCChanDetailsCombatShow:Show()
	FCCombatHideEntry:Show()
	FCCombatShowEntry:Show()
	if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][5]==1)then
		FCCombatHideEntry:SetChecked(1)
	else
		FCCombatHideEntry:SetChecked(0)
	end
	if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][6]==1)then
		FCCombatShowEntry:SetChecked(1)
	else
		FCCombatShowEntry:SetChecked(0)
	end
	if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][3]==1)then
		FCUseEntry:SetChecked(1)
	else
		FCUseEntry:SetChecked(0)
	end
	if(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][7]==1)then
		FCMinUp:SetChecked(1)
	else
		FCMinUp:SetChecked(0)
	end
	FCChanDetailsUse:Show()
	FCUseEntry:Show()
	FCMinUp:Show()
	FCChanDetailsMinimizeUp:Show()
end
function FCC_HideEditOptions(frameNum)
	if(frameNum==8)then return end
	FCChanDetailsName:Hide()
	FCChannelSave:Hide()
	ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][2]=FCChanNameEntry:GetText()
	getglobal("FCChanWidg"..frameNum.."_Name"):SetText(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][2])
	getglobal("FC_Channel"..frameNum.."_MoveIt_Name"):SetText(ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][2])
	FCChanNameEntry:Hide()
	FCChanDetailsCombatHide:Hide()
	FCChanDetailsCombatShow:Hide()
	if(FCCombatHideEntry:GetChecked()==1)then ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][5] = 1 else ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][5] = 0 end
	FCCombatHideEntry:Hide()
	if(FCCombatShowEntry:GetChecked()==1)then ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][6] = 1 else ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][6] = 0 end
	FCCombatShowEntry:Hide()
	if(FCUseEntry:GetChecked()==1)then ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][3] = 1 else ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][3] = 0 end
	FCChanDetailsUse:Hide()
	FCUseEntry:Hide()
	if(FCMinUp:GetChecked()==1)then ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][7] = 1 else ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][7] = 0 end
	FCMinUp:Hide()
	FCChanDetailsMinimizeUp:Hide()
end
function FCC_GrabNewDimensions(frameName)
	frameNum=tonumber(string.sub(frameName, string.len(frameName)))
	ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][2]=getglobal(frameName):GetHeight()
	ForgottenChat_ChannelsFrames[FCCC_GetPlayerIndex()][frameNum][1][1]=getglobal(frameName):GetWidth()
	FCC_ResizeWidget(frameNum)
end
function FCC_SetDefaultState()
	PlayerIndex=UnitName("player").."."..GetRealmName()
	if(ForgottenChat_Channels[PlayerIndex][1]==0)then return end
	for i=1, 7 do
		getglobal("ChatFrame"..i):Hide()
	end
	ChatFrameMenuButton:Hide()
end
function FCC_ShowChannels(button, number)
	if(button=="RightButton")then
		ToggleDropDownMenu(1, nil, getglobal("ChatFrame"..number.."TabDropDown"), this:GetName(), 0, 0);
	end
end
function FCC_ToggleOption(Option, State, Other)
	if(State==nil)then State=0 end
	if(Option=="ChannelState")then
		ForgottenChat_Channels[FCCC_GetPlayerIndex()][2]=State
	end
end
