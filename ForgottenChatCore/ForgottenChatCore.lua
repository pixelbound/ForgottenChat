local FCVar_UsedFrames={}
	-- Indexing into this Table by Player Name will return the number of the frame they have associated with them
local FCVar_FramesAllUsed=0
	-- Is set to 1 when all 12 Frames are in use
local FCVar_LastActive= {0,0,0,0,0,0,0,0,0,0,0,0}
	-- Each index will hold a value representing the time that that respective frame was last USED.  Smaller numbers represent Older frames
local FCVar_OrderCreated={}
local FCVar_IMFrames={1,2,3,4,5,6,7,8,9,10,11,12}
	-- Each Index represents a consecutive Frame, if the field is 0, the frame is in use by another name.  a Non-Zero value shows that the frame is not in use.
local FCVar_CurrentlyEngaged=false
	-- Is set to 1 if the player is in combat
local FCVar_RecentWhos={}
	-- Holds all the /who info for people you have recently talked to.
local FCVar_CurrentlyOpenEditBox=""
local FCVar_RecentWhos={}
local FCVar_UseWho=""
FCVar_CurrentlyOpenEditBox=""

--set to true if these have been hooked
local FC_CraftFrameHooked=false;
local FC_TradeskillFrameHooked=false;
local FC_AuctionFrameHooked=false;
local FC_TradeFrameHooked=false;
local FC_LootRollBoxHooked=false;
	
--Binding variables
BINDING_HEADER_FORGOTTENCHATCORE = "ForgottenChat";
BINDING_NAME_BINDING_FCC1 = "Reply";
BINDING_NAME_BINDING_FCC2 = "Minimize all";
BINDING_NAME_BINDING_FCC3 = "Maximize all";
BINDING_NAME_BINDING_FCC4 = "Close all";
BINDING_NAME_BINDING_FCC5 = "Enable/Disable";
	
--Methods REQUIRED by FCCC
function FC_OnLoad()
	FCCC_RegisterAddin("CORE")
	
	if(FCCC_GetVariable("UseAnchor")=="OFF")then
		FCAnchorFrame:Hide()
	else
		FCAnchorFrame:Show()
		H, W = FCCC_ParseDimension(FCCC_GetVariable("COREdimension"))
		FCAnchorFrame:SetWidth(W)
	end
	
	--Set up hooks
	FC_hooksecurefunc("ContainerFrameItemButton_OnClick",FC_ContainerFrameItemButton_OnClick)
	FC_hooksecurefunc("PaperDollItemSlotButton_OnClick",FC_PaperDollItemSlotButton_OnClick)
	FC_hooksecurefunc("MerchantItemButton_OnClick",FC_MerchantItemButton_OnClick)
	FC_hooksecurefunc("BankFrameItemButtonGeneric_OnClick",FC_BankFrameItemButtonGeneric_OnClick)
	FC_hooksecurefunc("QuestLogRewardItem_OnClick",FC_QuestLogRewardItem_OnClick)
	FC_hooksecurefunc("LootFrameItem_OnClick",FC_LootFrameItem_OnClick)
	FC_SetupLootRollBoxHooks()
	LoadAddOn("Blizzard_InspectUI")
	FC_hooksecurefunc("InspectPaperDollItemSlotButton_OnClick",FC_InspectPaperDollItemSlotButton_OnClick)
	--Tradeskill and craft (enchant) frames are hooked on their respective frame OnShow events (this .xml) page
	StackSplitFrame:SetScript("OnShow", function() if(FCVar_CurrentlyOpenEditBox~="")then this:Hide() else end end)
end

function FC_hooksecurefunc(Name, Func)
	local OldFunc = getglobal(Name)
	local NewFunc = function(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
		local x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20 = OldFunc(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
		
		Func(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
		
		return x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20
	end
	setglobal(Name, NewFunc)
end

function FC_IncomingMessage(Name, Text, afk)
	--This function handles all incoming messages.
	
	MsgDate= date("%H:%M")
	
	if(FCVar_UsedFrames[Name]==nil)then
		--Decides what to do if there is no frame associated to Name
		if(FCVar_FramesAllUsed==1) and (FCCC_GetVariable("MAXwidgets")>=1)then
			FC_DeAllocateFrameOldest()
			FC_AllocateFrame(Name)
			--Old frame is de-allocated and reused for the new message when too many frames are currently in use.
		elseif(FCVar_FramesAllUsed==0)then
			FC_AllocateFrame(Name)
			--New frame used
		else
			--No spare frames left
		end
	end
	if(FCVar_UsedFrames[Name]==nil)then
		
	else
		--at this point, if there is no FCVar_UsedFrames[Name], then something broke!
		FCVar_LastActive[FCVar_UsedFrames[Name]]=time()
		getglobal("Window"..FCVar_UsedFrames[Name]).SecondsSinceLastEvent=0
		--Appends the timestamp, name, and text into a single string.
		if(FCCC_GetVariable("TimeStamp")==1)then
			line="<"..MsgDate.."> "..FCCC_FormatNick(Name).." "..Text
		else
			line=FCCC_FormatNick(Name).." "..Text
		end
		--Adds the line to the window
		getglobal("Window"..FCVar_UsedFrames[Name].."_Chat"):AddMessage(line, FCCC_ParseColor(FCCC_GetVariable("InboundColor")))
					
		--Sets the variable for the hotkey
		FCVar_LastFrameToGetWhisper="Window"..FCVar_UsedFrames[Name].."_EditBox"
		if(getglobal("Window"..FCVar_UsedFrames[Name]).Minimized==1)then
			--Handles protocol when the frame is minimized, 'flashes', alerts, and displays the number of unread messages.
			if(FCCC_GetVariable("AudibleAlert")==1)then
				PlaySound("TellMessage")
			end
			getglobal("Window"..FCVar_UsedFrames[Name]).UnReadMessages=getglobal("Window"..FCVar_UsedFrames[Name]).UnReadMessages+1
			getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias"):SetText(getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias").BaseName.."   ("..getglobal("Window"..FCVar_UsedFrames[Name]).UnReadMessages..")")
			getglobal("Window"..FCVar_UsedFrames[Name]).isPulsing=true
		end
	end
end
function FC_OutgoingMessage(Name, Text, Language)
	MsgDate= date("%H:%M")

	if(FCVar_UsedFrames[Name]==nil)then
		if(FCVar_FramesAllUsed==1) and (FCCC_GetVariable("MAXwidgets")>=1)then
			FC_DeAllocateFrameOldest()
			FC_AllocateFrame(Name)
			--Old frame used
		elseif(FCVar_FramesAllUsed==0)then
			FC_AllocateFrame(Name)
			--New frame used
		else
			--No frame used
		end
	end
	if(FCVar_UsedFrames[Name]==nil)then
		
	else
		--at this point, if there is no FCVar_UsedFrames[Name], then something broke!
		FCVar_LastActive[FCVar_UsedFrames[Name]]=time()
		getglobal("Window"..FCVar_UsedFrames[Name]).SecondsSinceLastEvent=0
		if(FCCC_GetVariable("TimeStamp")==1)then
			line="<"..MsgDate.."> "..FCCC_FormatNick(UnitName("player")).." "..Text
		else
			line=FCCC_FormatNick(UnitName("player")).." "..Text
		end
		getglobal("Window"..FCVar_UsedFrames[Name].."_Chat"):AddMessage(line, FCCC_ParseColor(FCCC_GetVariable("OutboundColor")))
		getglobal("Window"..FCVar_UsedFrames[Name].."_EditBox"):AddHistoryLine(Text)
	end
end
function FC_AFKMessage(name, message)
	getglobal("Window"..FCVar_UsedFrames[name].."_Chat"):AddMessage(name.." is currently AFK: "..message, FCCC_ParseColor(FCCC_GetVariable("AFKColor")))
end
function FC_Enable()
	
end
function FC_Disable()
	FC_MassClose()
end

-- Functions for Opening, Closing, Minimizing and Automation of widgets
function FC_AllocateFrame(Name)
	--This function finds a frame that is not currently in use, and allocates it to the name given.
	for i=1, 12 do
		--There is already a widget for the specified person
		if(getglobal("Window"..i).Name==Name)then return end
	end
	for i=1, table.getn(FCVar_IMFrames) do
		--scans all widgets seeing if it can be used.
		if(FCVar_IMFrames[i]==0)then
			--Frame is in use, find another.
		elseif(i>FCCC_GetVariable("MAXwidgets"))then
			--Max number of frames are used, no frame is allocated
			FCVar_FramesAllUsed=1
			return
		else
			--frame is not in use and can be chosen and configured.
			FCVar_IMFrames[i]=0
			FCVar_UsedFrames[Name]=i
			getglobal("Window"..i):Show()
			FCVar_LastActive[FCVar_UsedFrames[Name]]=time()
			if(i>=FCCC_GetVariable("MAXwidgets"))then
				--Max number of frames are used
				FCVar_FramesAllUsed=1
			end
			getglobal("Window"..FCVar_UsedFrames[Name]).Name=Name
			FCVar_OrderCreated[table.getn(FCVar_OrderCreated)+1]=FCVar_UsedFrames[Name]
			--returns when the frame is allocated.
			FC_SetupWindow(Name)
			FC_AnchorCascade()
			return
		end
	end
	--If all frames are NOT in use, this code will not execute.
	FCVar_FramesAllUsed=1
end
function FC_DeAllocateFrameByName(Name)
	if not(FCVar_UsedFrames[Name]==nil)then
		--If there is a frame allocated to the name, it is flagged for re-allocation.
		FC_ToggleMinimizeWindow("Window"..FCVar_UsedFrames[Name], 0)
		FCVar_IMFrames[FCVar_UsedFrames[Name]]=FCVar_UsedFrames[Name]
		FCVar_LastActive[FCVar_UsedFrames[Name]]=0
		getglobal("Window"..FCVar_UsedFrames[Name]):Hide()
		getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias"):SetText("Null")
		getglobal("Window"..FCVar_UsedFrames[Name]).Name="Null"
		FCVar_FramesAllUsed=0
		for index, entry in pairs(FCVar_OrderCreated)do
			if(FCVar_OrderCreated[index]==FCVar_UsedFrames[Name])then
				table.remove(FCVar_OrderCreated,index)
			end
		end
		
		FCVar_UsedFrames[Name]=nil
		FC_AnchorCascade()
	end
end
function FC_TimeoutFrame(Name)
	for index, entry in pairs(FCVar_UsedFrames)do
		if("Window"..FCVar_UsedFrames[index]==Name)then player=index end
	end
	FC_DeAllocateFrameByName(player)
end
function FC_DeAllocateFrameOldest()
	--finds and deallocates the oldest frame.
	Oldest={}
	Oldest[0]=0
	Oldest[1]=0
	for i=1, table.getn(FCVar_IMFrames) do
		if(FCVar_LastActive[i]>=Oldest[1])then
			Oldest[0]=i
			Oldest[1]=FCVar_LastActive[i]
		end
	end
	-- At this point, Oldest should hold respectivly, the Oldest Frame Number, and the Time Code for that Frame
	if not(Oldest[0]==0)then
		FC_DeAllocateFrameByName(getglobal("Window"..Oldest[0]).Name)
	end
end
function FC_CloseButtonClicked(ParentName)
	--Deallocates the closed frame.
	FC_DeAllocateFrameByName(getglobal(ParentName).Name)
end
function FC_ToggleMinimizeWindow(frame, toState)
	if(FCCC_GetVariable("UseAnchor")=="OFF")then
		--0 represents a Maximized State, 1 = minimized
		Frm=getglobal(frame)
		thisState=Frm.Minimized
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
			Frm.Minimized=1
			Frm:SetHeight(30)
			getglobal(frame.."_Chat"):Hide()
			getglobal(frame.."_EditBox"):Hide()
			getglobal(frame.."_WhoField"):Hide()
			h,w = FCCC_ParseDimension(FCCC_GetVariable("COREdimension"))
			--This will shift the now minimized frame down or up depending on the minimizing protocol.
			if(FCCC_GetVariable("MinimizeUp")==1)then
				--Minimizing with a Minimize Up configuration
				Frm:SetPoint("BOTTOMLEFT",Left, Bottom)
			else
				--Minimizing with a Minimize Down configuration
				Frm:SetPoint("BOTTOMLEFT",Left, Bottom+h-30)
			end
		elseif(thisState==1)then
			--Maximizing
			Frm.UnReadMessages=0
			getglobal(Frm:GetName().."_MoveIt_Alias"):SetText(getglobal(Frm:GetName().."_MoveIt_Alias").BaseName)
			Frm.Minimized=0
			h,w = FCCC_ParseDimension(FCCC_GetVariable("COREdimension"))
			Frm:SetHeight(h)
			getglobal(frame.."_Chat"):Show()
			getglobal(frame.."_WhoField"):Show()
			getglobal(frame.."_MoveIt_Alias"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("NameColor")))
			Frm.isPulsing=false
			Frm.SecondsSinceLastEvent=0
			--This will shift the now minimized frame down or up depending on the minimizing protocol.
			if(FCCC_GetVariable("MinimizeUp")==1)then
				--Maximizing with a Minimize Up configuration
				Frm:SetPoint("BOTTOMLEFT",Left, Bottom)
			else
				--Maximizing with a Minimize Down configuration
				Frm:SetPoint("BOTTOMLEFT",Left, Bottom-h+30)
			end
		end	
	else
		Frm=getglobal(frame)
		thisState=Frm.Minimized
		if(toState==nil)then
			--If undefined, this will toggle the current state.
			toState=abs(thisState-1)
		end
		if(thisState==toState)then
			--No change is needed
			return
		end
		if(thisState==0)then
			--Minimizing
			Frm.Minimized=1
			Frm:SetHeight(30)
			getglobal(frame.."_Chat"):Hide()
			getglobal(frame.."_EditBox"):Hide()
			getglobal(frame.."_WhoField"):Hide()
		elseif(thisState==1)then
			--Maximizing
			Frm.UnReadMessages=0
			getglobal(Frm:GetName().."_MoveIt_Alias"):SetText(getglobal(Frm:GetName().."_MoveIt_Alias").BaseName)
			Frm.Minimized=0
			h,w = FCCC_ParseDimension(FCCC_GetVariable("COREdimension"))
			Frm:SetHeight(h)
			getglobal(frame.."_Chat"):Show()
			getglobal(frame.."_WhoField"):Show()
			getglobal(frame.."_MoveIt_Alias"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("NameColor")))
			Frm.isPulsing=false
			Frm.SecondsSinceLastEvent=0
		end
		
	end
end
function FC_PerformCleanup()
	--This function is called every time the user selects a new target and performs
	--two functions.  Hides all the edit boxes, and checks all widgets to see if they
	--are to be timed out.
	--Removes the Edit Boxes.
	for i=1, 12 do
		if(getglobal("Window"..i.."_EditBox"):GetText()=="")then
			getglobal("Window"..i.."_EditBox"):Hide()
		end
	end
end
function FC_MassMinimize()
	for i=1, 12 do
		FC_ToggleMinimizeWindow("Window"..i, 1)
	end
end
function FC_MassMaximize()
	for i=1, 12 do
		FC_ToggleMinimizeWindow("Window"..i, 0)
	end
end
function FC_MassClose()
	for i=1, 12 do
		FC_DeAllocateFrameOldest()
	end
end
function FC_AnchorCascade()
	if(FCCC_GetVariable("UseAnchor")=="DOWN")then
		--Hides the anchor frame if desired
		if(FCCC_GetVariable("HideAnchor")==1)then
			FCAnchorFrame:Hide()
		else
			FCAnchorFrame:Show()
		end		for index, entry in pairs(FCVar_OrderCreated)do
			if(FCVar_OrderCreated[index]==nil)then
			
			elseif(index==1)then
				getglobal("Window"..FCVar_OrderCreated[1]):ClearAllPoints()
				getglobal("Window"..FCVar_OrderCreated[1]):SetPoint("TOP",FCAnchorFrame,"BOTTOM",0,4)
			else
				getglobal("Window"..FCVar_OrderCreated[index]):ClearAllPoints()
				getglobal("Window"..FCVar_OrderCreated[index]):SetPoint("TOP", "Window"..FCVar_OrderCreated[index-1],"BOTTOM",0,4)
			end
		end
	elseif(FCCC_GetVariable("UseAnchor")=="UP")then
		--Hides the anchor frame if desired
		if(FCCC_GetVariable("HideAnchor")==1)then
			FCAnchorFrame:Hide()
		else
			FCAnchorFrame:Show()
		end
		for index, entry in pairs(FCVar_OrderCreated)do
			if(FCVar_OrderCreated[index]==nil)then
			
			elseif(index==1)then
				getglobal("Window"..FCVar_OrderCreated[1]):ClearAllPoints()
				getglobal("Window"..FCVar_OrderCreated[1]):SetPoint("BOTTOM",FCAnchorFrame,"TOP",0,-4)
			else
				getglobal("Window"..FCVar_OrderCreated[index]):ClearAllPoints()
				getglobal("Window"..FCVar_OrderCreated[index]):SetPoint("BOTTOM", "Window"..FCVar_OrderCreated[index-1],"TOP",0,-4)
			end
		end
	else
		FCAnchorFrame:Hide()
		return
	end
end
function FC_EnterCombat()
	if(FCCC_GetVariable("CombatMinimize")==1)then
		--Minimize all un-minimized windows.
		for i=1, 12 do
			if(getglobal("Window"..i).Minimized==0) and (FCVar_IMFrames[i]==0) then
				getglobal("Window"..i).CombatMinimized=1;
				FC_ToggleMinimizeWindow("Window"..i,1)
			end
		end
	elseif(FCCC_GetVariable("CombatHide")==1)then
		--Hide all visible windows.
		for i=1, 12 do
			if(getglobal("Window"..i):IsVisible()) and (FCVar_IMFrames[i]==0) then
				getglobal("Window"..i).CombatHidden=1
				getglobal("Window"..i,1):Hide()
			end
		end
	end
end
function FC_ExitCombat()
	if(FCCC_GetVariable("CombatMinimize")==1)then
		--Maximize all auto-minimized windows.
		for i=1, 12 do
			if(getglobal("Window"..i).CombatMinimized==1)then
				getglobal("Window"..i).CombatMinimized=0
				FC_ToggleMinimizeWindow("Window"..i,0)
			end
		end
	elseif(FCCC_GetVariable("CombatHide")==1)then
		--Show all auto-hidden windows.
		for i=1, 12 do
			if(getglobal("Window"..i).CombatHidden==1) then
				getglobal("Window"..i).CombatHidden=0
				getglobal("Window"..i,1):Show()
			end
		end
	end
end



-- Functions for keeping Widget Appearances up to date
function FC_PulseWidget(elapsed)
	this.TimeSinceLastUpdate = this.TimeSinceLastUpdate + elapsed; 
	timeDelta=0.2
	if (this.TimeSinceLastUpdate > timeDelta) then
		if(this.isPulsing==false)then return end
	    step = this.PulseStep
		-- Steps 1-10 from Name To Pulse
		-- Steps 11-20 Pulse to Name
		-- Steps 21-50 Name
		nameR, nameG, nameB = FCCC_ParseColor(FCCC_GetVariable("NameColor"))
		pulseR, pulseG, pulseB = FCCC_ParseColor(FCCC_GetVariable("PulseColor"))
		dR = (pulseR-nameR)*.1
		dG = (pulseG-nameG)*.1
		dB = (pulseB-nameB)*.1
		
		if(step==50)then this.PulseStep=1 else this.PulseStep=step+1 end
		
		if(step>=21)then
			if(step==21)then getglobal(this:GetName().."_MoveIt_Alias"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("NameColor"))) end
		elseif(step>=1)and(step<=10)then
			--From Name to Pulse
			getglobal(this:GetName().."_MoveIt_Alias"):SetTextColor(nameR+dR*step,nameG+dG*step,nameB+dB*step)
		elseif(step>=11)and(step<=20)then
			aStep=step-10
			--From Pulse to Name
			getglobal(this:GetName().."_MoveIt_Alias"):SetTextColor(pulseR-dR*aStep,pulseG-dG*aStep,pulseB-dB*aStep)
		end
		this.TimeSinceLastUpdate = 0;
	end
	
end
function FC_SetupWindow(Name)
	--Sets up the frame associated to 'Name', as per the saved variables.
	getglobal("Window"..FCVar_UsedFrames[Name]).Name=Name
	
	if(not(ForgottenChat_Aliases[GetRealmName()][Name]==nil))then
		--Show Alias, Hide Name
		getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias"):SetText(ForgottenChat_Aliases[GetRealmName()][Name])
		getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias").BaseName=ForgottenChat_Aliases[GetRealmName()][Name]
	else
		-- Hide Alias, Show Name
		getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias"):SetText(Name)
		getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias").BaseName=Name
	end
	getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt_Alias"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("NameColor")))
	getglobal("Window"..FCVar_UsedFrames[Name]).UnReadMessages=0
	
	--Resets the chat log
	Frame=getglobal("Window"..FCVar_UsedFrames[Name].."_Chat")
	Frame:Clear()
	Frame:ScrollToBottom()
	Path,_,Flags=Frame:GetFont()
	Frame:SetFont(Path,FCCC_GetVariable("FontSize"),Flags)
	Frame:Show()
		
	getglobal("Window"..FCVar_UsedFrames[Name].."_EditBox"):Hide()
	getglobal("Window"..FCVar_UsedFrames[Name].."_EditBox"):SetText("")
	
	--Set /Who Data
	getglobal("Window"..FCVar_UsedFrames[Name].."_WhoField"):SetTextColor(FCCC_ParseColor(FCCC_GetVariable("DetailColor")))
	FC_UpdateWhoField(Name)
		--This line is included in case the widget is auto-closed due to the level threshold
		if(FCVar_UsedFrames[Name]==nil)then 
			if(FCVar_UsedFrames==nil)then FCVar_UsedFrames={} end
			return
		end
	
	--Set Size
	FC_ResizeWidget(FCVar_UsedFrames[Name])

	getglobal("Window"..FCVar_UsedFrames[Name]):SetAlpha(FCCC_GetVariable("Transparency"))
	getglobal("Window"..FCVar_UsedFrames[Name].."_MoveIt"):SetAlpha(1)
	getglobal("Window"..FCVar_UsedFrames[Name].."_Chat"):SetAlpha(1)
	getglobal("Window"..FCVar_UsedFrames[Name].."_CloseButton"):SetAlpha(1)
	getglobal("Window"..FCVar_UsedFrames[Name].."_MinimizeButton"):SetAlpha(1)
	getglobal("Window"..FCVar_UsedFrames[Name].."_EditBox"):SetAlpha(1)
	
	if(FCCC_GetVariable("ScrollButtons")==0)then
		getglobal("Window"..FCVar_UsedFrames[Name].."_BottomButton"):Hide()
		getglobal("Window"..FCVar_UsedFrames[Name].."_DownButton"):Hide()
		getglobal("Window"..FCVar_UsedFrames[Name].."_UpButton"):Hide()
	elseif(FCCC_GetVariable("ScrollButtons")==1)then
		getglobal("Window"..FCVar_UsedFrames[Name].."_BottomButton"):Show()
		getglobal("Window"..FCVar_UsedFrames[Name].."_DownButton"):Show()
		getglobal("Window"..FCVar_UsedFrames[Name].."_UpButton"):Show()
	end
		
	if(FCCC_GetVariable("ActionButtons")==0)then
		getglobal("Window"..FCVar_UsedFrames[Name].."_IgnoreButton"):Hide()
		getglobal("Window"..FCVar_UsedFrames[Name].."_InviteButton"):Hide()
		getglobal("Window"..FCVar_UsedFrames[Name].."_DoWhoButton"):Hide()
	elseif(FCCC_GetVariable("ActionButtons")==1)then
		getglobal("Window"..FCVar_UsedFrames[Name].."_IgnoreButton"):Show()
		getglobal("Window"..FCVar_UsedFrames[Name].."_InviteButton"):Show()
		getglobal("Window"..FCVar_UsedFrames[Name].."_DoWhoButton"):Show()
	end
	
	--Makes sure the widget is minimized/maximized as desired
	getglobal("Window"..FCVar_UsedFrames[Name]).Minimized=0
	if(FCCC_GetVariable("LoadMinimized")==1)then
		FC_ToggleMinimizeWindow("Window"..FCVar_UsedFrames[Name], 1)
	end
	getglobal("Window"..FCVar_UsedFrames[Name]).isPulsing=false
	
	--Set history
	if(IsAddOnLoaded("ForgottenChatLog"))then
		FCL_PutHistoryToWidgetChat("Window"..FCVar_UsedFrames[Name].."_Chat",Name)
	end
end
function FC_ResizeWidget(which)
	h,w = FCCC_ParseDimension(FCCC_GetVariable("COREdimension"))
	if(which==0)or(which==nil)then
		--resize all widgets
		FCAnchorFrame:SetWidth(w)
		for i=1, 12 do
			FC_ResizeWidget(i)
		end
	else
		if(getglobal("Window"..which).Minimized~=1)then
			getglobal("Window"..which):SetHeight(h)
			getglobal("Window"..which):SetWidth(w)	
			getglobal("Window"..which.."_MoveIt"):SetWidth(w)
			getglobal("Window"..which.."_Chat"):SetWidth(w-20)
			getglobal("Window"..which.."_Chat"):SetHeight(h-50)
		end
		FC_SetWidgetScale(which)
	end
end
function FC_SetTransparent()
	--Sets the transparency of all widgets
	for i=1, 12 do
		getglobal("Window"..i):SetAlpha(FCCC_GetVariable("Transparency"))
		getglobal("Window"..i.."_MoveIt"):SetAlpha(1)
		getglobal("Window"..i.."_Chat"):SetAlpha(1)
		getglobal("Window"..i.."_CloseButton"):SetAlpha(1)
		getglobal("Window"..i.."_MinimizeButton"):SetAlpha(1)
		getglobal("Window"..i.."_EditBox"):SetAlpha(1)
	end
end
function FC_SetFontSize()
	--Sets the text size on all the widgets.
	for i=1, 12 do
		Frame=getglobal("Window"..i.."_Chat")
		Path,_,Flags=Frame:GetFont()
		Frame:SetFont(Path,FCCC_GetVariable("FontSize"),Flags)
	end
end
function FC_SetWidgetScale(i)
	if(true)then return end
	getglobal("Window"..i):SetScale(FCCC_GetVariable("WidgetScale"))
end
function FC_ResetWidgetPositions()
	--this function was inculded to fix an issue where widgets would move off the edge of the screen
	--and become un-movable.  After execution, all widgets will be vertically aligned near the center
	--of the screen de-allocated
	Resetting=1
	for i=1, 12 do
		FC_DeAllocateFrameOldest()
	end
	FC_AllocateFrame("A")
	FC_AllocateFrame("B")
	FC_AllocateFrame("C")
	FC_AllocateFrame("D")
	FC_AllocateFrame("E")
	FC_AllocateFrame("F")
	FC_AllocateFrame("G")
	FC_AllocateFrame("H")
	FC_AllocateFrame("I")
	FC_AllocateFrame("J")
	FC_AllocateFrame("K")
	FC_AllocateFrame("L")
	FCVal=(GetScreenHeight()/2)-90
	for i=1, 12 do
		FC_ToggleMinimizeWindow("Window"..i, 1)
		getglobal("Window"..i):ClearAllPoints()
		getglobal("Window"..i):SetPoint("TOP" ,0 , (-1)*FCVal)
		FCVal=FCVal+30
	end
	for i=1, 12 do
		FC_DeAllocateFrameOldest()
	end
	Resetting=0
end
function FC_UpdateWhoField(Name)
	if(FCCC_GetVariable("IgnoreWhos")==1)then getglobal("Window"..FCVar_UsedFrames[Name].."_WhoField"):SetText("") return end
	found=0
	charname, guildname, level, race, class, zone, partied = ""
	if(FCVar_RecentWhos[Name]==nil)then
		--Checks if they are in the same BG as you... Otherwise continues with standard /who retrieval.
		if(string.find(Name, "-")~=nil)then
			--Char is inside a BG
			for i=1, GetNumBattlefieldScores() do
				name, _, _, _, _, _, _, race, class, _, _ = GetBattlefieldScore(i)
				if(name==Name)then
					getglobal("Window"..FCVar_UsedFrames[Name].."_WhoField"):SetText("BG Member: "..name.." "..race.." "..class)
					return
				end
			end
		end
	
	
		--Scans the currently open who results before performing it's own /who
		for i=1, GetNumWhoResults() do	
			charname, guildname, level, race, class, zone, partied = GetWhoInfo(i);
			if(charname==Name)then
				found=1
				break
			end
		end
		
		if(found==1)then
			--a match was found, and it will be used.
			FCVar_UseWho=""
			if(guildname=="")then
				getglobal("Window"..FCVar_UsedFrames[Name].."_WhoField"):SetText(level.." "..race.." "..class)
				FCVar_RecentWhos[Name]=level.." "..race.." "..class
			else
				getglobal("Window"..FCVar_UsedFrames[Name].."_WhoField"):SetText("<"..guildname.."> "..level.." "..race.." "..class)
				FCVar_RecentWhos[Name]="<"..guildname.."> "..level.." "..race.." "..class
			end
			if(level<=FCCC_GetVariable("LevelThreshold") and (FCCC_IsGuildieOrFriend(Name)==false))then
				FC_DeAllocateFrameByName(Name)
				DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r Message ignored from "..Name..", player is below level "..FCCC_GetVariable("LevelThreshold"), 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
				FCVar_RecentWhos[Name]=nil
			end
		else
			--No match is found, must perform my own /who
			SetWhoToUI(1)
			FCVar_UseWho=Name
			SendWho(Name);
			-- this Method will 'continue' in FC_WhoActivated() when the /who command has been completed
		end
	else
		--A previously recorded /who can be used.
		getglobal("Window"..FCVar_UsedFrames[Name].."_WhoField"):SetText(FCVar_RecentWhos[Name])
	end
end
function FC_WhoActivated()
	if(FCVar_UseWho=="")then
		SetWhoToUI(0)
		return
	else
		SetWhoToUI(0)
		--Scans the who results for a match
		charname, guildname, level, race, class, zone, partied=""
		for i=1, GetNumWhoResults() do
			charname, guildname, level, race, class, zone, partied = GetWhoInfo(i);
			if(charname==FCVar_UseWho)then
				break
			end
		end
		--If there are no results, this will fix a bug where class==nil
		if(charname~=FCVar_UseWho)then
			charname=""
			guildname="Information could not be found"
			level=""
			race=""
			class=""
			zone=""
			partied =""
		end
		HideUIPanel(FriendsFrame)
		if(FCVar_UseWho==nil)then FCVar_UseWho="" return end
		if(guildname=="")then
			getglobal("Window"..FCVar_UsedFrames[FCVar_UseWho].."_WhoField"):SetText(level.." "..race.." "..class)
			FCVar_RecentWhos[FCVar_UseWho]=level.." "..race.." "..class
		else
			getglobal("Window"..FCVar_UsedFrames[FCVar_UseWho].."_WhoField"):SetText("<"..guildname.."> "..level.." "..race.." "..class)
			FCVar_RecentWhos[FCVar_UseWho]="<"..guildname.."> "..level.." "..race.." "..class	
		end	
		if(level<=FCCC_GetVariable("LevelThreshold")) and not(FCCC_IsGuildieOrFriend(FCVar_UseWho)) then
			FC_DeAllocateFrameByName(FCVar_UseWho)
			DEFAULT_CHAT_FRAME:AddMessage("|cff0000FFForgotten Chat Control Center:|r Message ignored from "..FCVar_UseWho..", player is below level "..FCCC_GetVariable("LevelThreshold"), 100, 100, 100, 1.0, UIERRORS_HOLD_TIME)
			FCVar_RecentWhos[FCVar_UseWho]=nil
		end
		FCVar_UseWho=""
	end
end


-- Frame specific or General UI required functions
function FC_EnterPressed(frame)
	--sends the message contained within the edit box.
	text=getglobal(frame.."_EditBox"):GetText()
	Name=getglobal(frame).Name
	if(string.sub(text,1,1)=='/')then
		--If the text starts with a slash, then it treats it as a slash command, 
		--which is forwarded to the chatframe1
		ChatFrame1.editBox:SetText(text)
		ChatEdit_SendText(ChatFrame1.editBox, 1)
	else
		SendChatMessage(text, "WHISPER", FCVar_Language, Name);
	end
	if(IsShiftKeyDown())then
		getglobal(frame.."_EditBox"):SetText("")
	else
		FC_HideEditBox(frame)
	end
end
function FC_EscapePressed(frame)
	FC_HideEditBox(frame)
end
function FC_HideEditBox(frame)
	getglobal(frame.."_EditBox"):Hide()
	getglobal(frame.."_EditBox"):SetText("")
end
function FC_ShowEditBox(frame, source)
	if(source=="CLICK") and (FCCC_GetVariable("EditOnClick")==1)then
		if(not getglobal(frame.."_EditBox"):IsVisible())then
			getglobal(frame.."_EditBox"):Show()
			getglobal(frame.."_EditBox"):SetFocus()
			getglobal("ChatFrameEditBox"):Hide()
		elseif(getglobal(frame.."_EditBox"):IsVisible()) and (getglobal(frame.."_EditBox"):GetText()=="")then
			FC_HideEditBox(frame)
		end
	elseif(source=="ENTER") and (FCCC_GetVariable("EditOnClick")==0)then
		getglobal(frame.."_EditBox"):Show()
		getglobal(frame.."_EditBox"):SetFocus()
		getglobal("ChatFrameEditBox"):Hide()
	end
end

--Hooked functions for linking items
function FC_SetLastOpenBox(box)
	FCVar_CurrentlyOpenEditBox=box
end
function FC_GetLastOpenBox()
	return FCVar_CurrentlyOpenEditBox
end

function FC_ContainerFrameItemButton_OnClick(button, ignoreModifiers)
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( button == "LeftButton" ) then
			if ( IsShiftKeyDown() and not ignoreModifiers ) then
				if ( getglobal(FCVar_CurrentlyOpenEditBox):IsVisible() ) then
					getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetContainerItemLink(this:GetParent():GetID(), this:GetID()))
				end
			end
		end
	end
end
function FC_PaperDollItemSlotButton_OnClick(button, ignoreModifiers)
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( button == "LeftButton" ) then
			if ( IsShiftKeyDown() and not ignoreModifiers ) then
				getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetInventoryItemLink("player", this:GetID()));
			end
		end
	end	
					
end
function FC_MerchantItemButton_OnClick(button, ignoreModifiers)
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( MerchantFrame.selectedTab == 1 ) then
			if ( button == "LeftButton" and not ignoreModifiers ) then
				if ( IsShiftKeyDown() ) then
					getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetMerchantItemLink(this:GetID()))
				end
			end
		end
	end
end
function FC_BankFrameItemButtonGeneric_OnClick(button)
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( button == "LeftButton" ) then
			if ( IsShiftKeyDown() and not this.isBag ) then
				getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetContainerItemLink(BANK_CONTAINER, this:GetID()));
			end
		end
	end
end
function FC_InspectPaperDollItemSlotButton_OnClick(button)
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( button == "LeftButton" ) then
			if ( IsShiftKeyDown() ) then
				getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetInventoryItemLink(InspectFrame.unit, this:GetID()));
			end
		end
	end
end
function FC_QuestLogRewardItem_OnClick()
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( IsShiftKeyDown() ) then
			if ( this.rewardType ~= "spell" ) then
				getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetQuestLogItemLink(this.type, this:GetID()));
			end
		end
	end
end
function FC_LootFrameItem_OnClick(button)
	if(FCVar_CurrentlyOpenEditBox~="")then
		if ( button == "LeftButton" ) then
			if ( IsShiftKeyDown() ) then
				getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetLootSlotLink(this.slot))
			end
		end
	end
end

--Craft, Auction, and Tradeskill functions should all be re-checked occasionally, since they are overwriting default Blizzard xml defined functions
--Refer to the Setup...Hooks() functions to find where the scripts are copied from
function FC_Tradeskill_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, this:GetID()));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, this:GetID()))
		else
			ChatEdit_InsertLink(GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, this:GetID()));
		end
	end
end
function FC_TradeskillSkill_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetTradeSkillItemLink(TradeSkillFrame.selectedSkill));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetTradeSkillItemLink(TradeSkillFrame.selectedSkill))
		else
			ChatEdit_InsertLink(GetTradeSkillItemLink(TradeSkillFrame.selectedSkill));
		end
	end
end
function FC_CraftIcon_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetCraftItemLink(GetCraftSelectionIndex()));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetCraftItemLink(GetCraftSelectionIndex()))
		else
			ChatEdit_InsertLink(GetCraftItemLink(GetCraftSelectionIndex()));
		end
	end
end
function FC_CraftReagentIcon_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetCraftReagentItemLink(GetCraftSelectionIndex(), this:GetID()));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetCraftReagentItemLink(GetCraftSelectionIndex(), this:GetID()))
		else
			ChatEdit_InsertLink(GetCraftReagentItemLink(GetCraftSelectionIndex(), this:GetID()));
		end
	end
end
function FC_AuctionButton_OnClick()
	if ( IsControlKeyDown()  ) then
		DressUpItemLink(GetAuctionItemLink("list", this:GetParent():GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetAuctionItemLink("list", this:GetParent():GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)))
		else
			ChatEdit_InsertLink(GetAuctionItemLink("list", this:GetParent():GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)));
		end
		else
		if ( AUCTION_DISPLAY_ON_CHARACTER == "1" ) then
			DressUpItemLink(GetAuctionItemLink("list", this:GetParent():GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)));
		end
		BrowseButton_OnClick(this:GetParent());
	end
end
function FC_RecipientTradeFrame_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetTradeTargetItemLink(this:GetParent():GetID()));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetTradeTargetItemLink(this:GetParent():GetID()))
		else
			ChatEdit_InsertLink(GetTradeTargetItemLink(this:GetParent():GetID()));
		end
	else
		ClickTargetTradeButton(this:GetParent():GetID());
	end
end
function FC_PlayerTradeFrame_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetTradePlayerItemLink(this:GetParent():GetID()));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetTradePlayerItemLink(this:GetParent():GetID()))
		else
			ChatEdit_InsertLink(GetTradePlayerItemLink(this:GetParent():GetID()));
		end
	else
		ClickTradeButton(this:GetParent():GetID());
	end
end
function FC_RollBoxFrame_OnClick()
	if ( IsControlKeyDown() ) then
		DressUpItemLink(GetLootRollItemLink(this:GetParent().rollID));
	elseif ( IsShiftKeyDown() ) then
		if(FCVar_CurrentlyOpenEditBox~="")then
			getglobal(FCVar_CurrentlyOpenEditBox):Insert(GetLootRollItemLink(this:GetParent().rollID))
		else
			ChatEdit_InsertLink(GetLootRollItemLink(this:GetParent().rollID));
		end
	end
end

function FC_SetupTradeskillHooks()
	if(FC_TradeskillFrameHooked==false)then
		TradeSkillReagent1:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent2:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent3:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent4:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent5:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent6:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent7:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillReagent8:SetScript("OnClick",FC_Tradeskill_OnClick)
		TradeSkillSkillIcon:SetScript("OnClick",FC_TradeskillSkill_OnClick)
		FC_TradeskillFrameHooked=true
	end
end
function FC_SetupCraftHooks()
	if(FC_CraftFrameHooked==false)then
		CraftIcon:SetScript("OnClick",FC_CraftIcon_OnClick)
		CraftReagent1:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent2:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent3:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent4:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent5:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent6:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent7:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		CraftReagent8:SetScript("OnClick",FC_CraftReagentIcon_OnClick)
		FC_CraftFrameHoodked=true
	end
end
function FC_SetupAuctionHooks()
	if(FC_AuctionFrameHooked==false)then
		BrowseButton1Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton2Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton3Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton4Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton5Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton6Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton7Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		BrowseButton8Item:SetScript("OnClick",FC_AuctionButton_OnClick)
		FC_AuctionFrameHooked=true;
	end
end
function FC_SetupTradeHooks()
	if(FC_TradeFrameHooked==false)then
		TradeRecipientItem1ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		TradeRecipientItem2ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		TradeRecipientItem3ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		TradeRecipientItem4ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		TradeRecipientItem5ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		TradeRecipientItem6ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		TradeRecipientItem7ItemButton:SetScript("OnClick", FC_RecipientTradeFrame_OnClick)
		
		TradePlayerItem1ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		TradePlayerItem2ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		TradePlayerItem3ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		TradePlayerItem4ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		TradePlayerItem5ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		TradePlayerItem6ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		TradePlayerItem7ItemButton:SetScript("OnClick", FC_PlayerTradeFrame_OnClick)
		FC_TradeFrameHooked=true
	end
end
function FC_SetupLootRollBoxHooks()
	if(FC_LootRollBoxHooked==false)then
		GroupLootFrame1IconFrame:SetScript("OnClick",FC_RollBoxFrame_OnClick)
		GroupLootFrame2IconFrame:SetScript("OnClick",FC_RollBoxFrame_OnClick)
		GroupLootFrame3IconFrame:SetScript("OnClick",FC_RollBoxFrame_OnClick)
		GroupLootFrame4IconFrame:SetScript("OnClick",FC_RollBoxFrame_OnClick)
		FC_LootRollBoxHooked=true
	end
end

