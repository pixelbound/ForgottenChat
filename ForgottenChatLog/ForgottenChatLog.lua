ForgottenChat_History={}
SessionHistory={}
FCVar_PlayerSearchFilterResults={}

--Methods REQUIRED by FCCC
function FCL_OnLoad()
	FCCC_RegisterAddin("LOG")
	if(ForgottenChat_History==nil)then 
		ForgottenChat_History={} 
	end
	if(ForgottenChat_History[FCCC_GetPlayerIndex()]==nil) then 
		ForgottenChat_History[FCCC_GetPlayerIndex()]={} 
	end
	if(FCCC_GetVariable("EmptyOnLoad")==1)then 
		ForgottenChat_History[FCCC_GetPlayerIndex()]={}
	end
end
function FCL_IncomingMessage(Name, Text, afk)
	--This function handles all incoming messages.
	if(FCCC_GetVariable("RecordHistory")==0)then return end
	
	--Long Term history
	if(ForgottenChat_History[FCCC_GetPlayerIndex()]==nil) then ForgottenChat_History[FCCC_GetPlayerIndex()]={} end
	if(ForgottenChat_History[FCCC_GetPlayerIndex()][Name]==nil)then
		ForgottenChat_History[FCCC_GetPlayerIndex()][Name]={"<I>"..line}
		if(IMHistoryList:IsVisible())then FCL_UpdateHistoryList(IMHistoryList_Scroller:GetValue()) end
	else
		ForgottenChat_History[FCCC_GetPlayerIndex()][Name][table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name])+1]="<I>"..line
	end
	
	--Session History
	if(SessionHistory==nil)then 
		SessionHistory={"<I>"..line}
	else
		SessionHistory[table.getn(SessionHistory)+1]="<I>"..line
	end
end
function FCL_OutgoingMessage(Name, Text, Language)
	if(FCCC_GetVariable("RecordHistory")==0)then return end
	
	--Long Term history
	if(ForgottenChat_History[FCCC_GetPlayerIndex()]==nil) then ForgottenChat_History[FCCC_GetPlayerIndex()]={} end
	if(ForgottenChat_History[FCCC_GetPlayerIndex()][Name]==nil)then
		ForgottenChat_History[FCCC_GetPlayerIndex()][Name]={"<O>"..line}
		if(IMHistoryList:IsVisible())then FCL_UpdateHistoryList(IMHistoryList_Scroller:GetValue()) end
	else
		ForgottenChat_History[FCCC_GetPlayerIndex()][Name][table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name])+1]="<O>"..line
	end
	
	--Session History
	if(SessionHistory==nil)then 
		SessionHistory={"<O>"..line}
	else
		SessionHistory[table.getn(SessionHistory)+1]="<O>"..line
	end
end

function FCL_ShowHistory()
	if(IMHistory:IsVisible())then
		IMHistory:Hide()
	else
		IMHistory:Show()
	end
end
function FCL_PutHistoryToWidgetChat(frame, Name)
	--Setup History
	if(ForgottenChat_History[FCCC_GetPlayerIndex()]==nil)then ForgottenChat_History[FCCC_GetPlayerIndex()]={} end
	if(ForgottenChat_History[FCCC_GetPlayerIndex()][Name]==nil)then
		--No history for the player
	else
		--Adds the history with the player to the widget.
			m=0
		if(table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name])>FCCC_GetVariable("HistoryLinesInWidget"))then
			for i=table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name])-FCCC_GetVariable("HistoryLinesInWidget")+1, table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name]) do
				getglobal(frame):AddMessage(string.sub(ForgottenChat_History[FCCC_GetPlayerIndex()][Name][i],4), FCCC_ParseColor(FCCC_GetVariable("HistoryColor")))
			end
		else
			for i=1, table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name]) do
				getglobal(frame):AddMessage(string.sub(ForgottenChat_History[FCCC_GetPlayerIndex()][Name][i],4), FCCC_ParseColor(FCCC_GetVariable("HistoryColor")))
			end
		end
	end
end

function FCL_UpdateHistoryList(topIndex, UserName)
	if(UserName==nil)then UserName=FCCC_GetPlayerIndex() end
	for i=1, 30 do
		getglobal("IMHistoryList_Entry"..i.."_Text"):SetText("")
		getglobal("IMHistoryList_Entry"..i.."_Text"):SetTextColor(1,0.75,0.75)
		getglobal("IMHistoryList_Entry"..i):Hide()
	end
	
	--Sorting alphabetically
	temp={}
	for index, entry in pairs(ForgottenChat_History[UserName]) do
		table.insert(temp, index)
	end
	table.sort(temp)
	i=1
	j=1
	for index, entry in pairs(temp) do
		if(i>=topIndex) and (i<topIndex+30)then
			--Display on element j!
			getglobal("IMHistoryList_Entry"..j)
			getglobal("IMHistoryList_Entry"..j.."_Text"):SetText(temp[index])
			if(FCVar_PlayerSearchFilterResults[temp[index]]==1)then
				getglobal("IMHistoryList_Entry"..j.."_Text"):SetTextColor(1,0,0)
			end
			getglobal("IMHistoryList_Entry"..j):Show()
			j=j+1
		end
		i=i+1
	end

	if(i<=30)then
		--the entire list will be displayed on a single, un-scrolling list.
		IMHistoryList_Scroller:SetMinMaxValues(1,1)
	else		
		--The list will require scrolling.
		IMHistoryList_Scroller:SetMinMaxValues(1,i-30)
	end
end
function FCL_DisplayHistoryList(Name, session)
	if(session==1)then HistoryList=SessionHistory else HistoryList=ForgottenChat_History[FCCC_GetPlayerIndex()][Name] end
	IMHistory_Chat:Clear()
	for index=1, table.getn(HistoryList) do
		color=FCCC_GetVariable("HistoryColor")
		if(string.sub(HistoryList[index],1,3)=="<O>")then
			color=FCCC_GetVariable("OutboundColor")
		elseif(string.sub(HistoryList[index],1,3)=="<I>")then
			color=FCCC_GetVariable("InboundColor")
		end
		IMHistory_Chat:AddMessage(string.sub(HistoryList[index],4), FCCC_ParseColor(color))
	end
end
function FCL_DisplaySearchResults(SearchString, Name)
	IMHistory_Chat:Clear()
	if(SearchString==" Search ") or (SearchString=="") then 
		FCL_DisplayHistoryList(Name)
		return
	end
	
	if(Name==nil)then
		for indexA, entry in pairs(ForgottenChat_History[FCCC_GetPlayerIndex()]) do
			for i=1, table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][indexA]) do
				text=ForgottenChat_History[FCCC_GetPlayerIndex()][indexA][i]
				a,b=string.find(text, SearchString)
				if not(a==nil)then
					--This string MATCHES, 
					FCVar_PlayerSearchFilterResults[indexA]=1
					--Select the color...
					color=FCCC_GetVariable("HistoryColor")
					if(string.sub(HistoryList[index],1,3)=="<O>")then
						color=FCCC_GetVariable("OutboundColor")
					elseif(string.sub(HistoryList[index],1,3)=="<I>")then
						color=FCCC_GetVariable("InboundColor")
					end
					
					--Highlight the word.
					Output=string.sub(text,1,a-1)
					Output=Output.."|cffFF0000"..string.sub(text, a,b).."|r"
					Output=Output..string.sub(text, b+1)
					IMHistory_Chat:AddMessage(string.sub(Output,4), FCCC_ParseColor(color))
				end
			end
		end
		FCL_UpdateHistoryList(IMHistoryList_Scroller:GetValue())
	else
		for i=1, table.getn(ForgottenChat_History[FCCC_GetPlayerIndex()][Name]) do
			text=ForgottenChat_History[FCCC_GetPlayerIndex()][Name][i]
			a,b=string.find(text, SearchString)
			if not(a==nil)then
				--This string MATCHES, 
				FCVar_PlayerSearchFilterResults[Name]=1
				color=FCCC_GetVariable("HistoryColor")
				if(string.sub(HistoryList[index],1,3)=="<O>")then
					color=FCCC_GetVariable("OutboundColor")
				elseif(string.sub(HistoryList[index],1,3)=="<I>")then
					color=FCCC_GetVariable("InboundColor")
				end
				
				--Highlight the word.
				Output=string.sub(text,1,a-1)
				Output=Output.."|cffFF0000"..string.sub(text, a,b).."|r"
				Output=Output..string.sub(text, b+1)
				IMHistory_Chat:AddMessage(string.sub(Output,4), FCCC_ParseColor(color))
			end
		end
	
	end
end
--