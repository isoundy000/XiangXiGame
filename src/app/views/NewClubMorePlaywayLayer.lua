--[[
*名称:NewClubMorePlaywayLayer
*描述:多种玩法
*作者:admin
*创建日期:2019-09-17 10:59:51
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local Log               = require("common.Log")

local NewClubMorePlaywayLayer = class("NewClubMorePlaywayLayer", cc.load("mvc").ViewBase)

function NewClubMorePlaywayLayer:onConfig()
    self.widget         = {
    	{"Panel_mask"},
        {"Button_editorBtn", "onEditorBtn"},
        {"Button_allPWBtn", "onAllPWBtn"},
        {"Text_allPWFont"},
        {"Image_PWFrame"},
        {"ListView_PWList"},
        {"Image_CPWAll", "onCPWAll"},
        {"Image_CPWAllLight"},
        {"ListView_CPWList"},
        {"Image_PWItem"},
        {"Image_CPWItem"},
    }
end

function NewClubMorePlaywayLayer:onEnter()
end

function NewClubMorePlaywayLayer:onExit()
end

function NewClubMorePlaywayLayer:onCreate(param)
	self.parent = param[1]
	self.clubData = self.parent.clubData
	--dump(self.clubData)
	self.Image_PWFrame:setVisible(false)
	self.Panel_mask:setVisible(false)
	self.Image_CPWAll:setPositionX(62)
	self.ListView_CPWList:setContentSize(cc.size(1188, 60))
	self.ListView_CPWList:setInnerContainerSize(cc.size(1188, 60))
	self.ListView_CPWList:refreshView()

	local curGameId = cc.UserDefault:getInstance():getIntegerForKey('CurSelGameID', 0)
	self:switchChildPlaywayUI(curGameId)

	-- local callback = function()
 --        self:onAllPWBtn()
 --    end
 --    Common:registerScriptMask(self.Panel_mask, callback)
end

function NewClubMorePlaywayLayer:onEditorBtn()
	if self.Button_editorBtn:getTitleText() == '聊天' then
	    self.parent.Image_chatRedPoint:setVisible(false)
	    local box = require("app.MyApp"):create(self.clubData):createView('GroupLayer')
	    self.parent:addChild(box)
    elseif self.Button_editorBtn:getTitleText() == '编辑' then
    	self:switchPlaywayUI(2)
	elseif self.Button_editorBtn:getTitleText() == '确定' then
    	self:switchPlaywayUI(1)
	end
end

function NewClubMorePlaywayLayer:onAllPWBtn()
	if self.Image_PWFrame:isVisible() then
		self.Image_PWFrame:stopAllActions()
		self.Image_PWFrame:setPosition(133, 0)
        local moveto = cc.MoveTo:create(0.2, cc.p(133, -575))
        local callfunc = cc.CallFunc:create(function()
            self.Image_PWFrame:setVisible(false)
            self.parent.ScrollView_clubTbl:setPositionX(30)
			self.Panel_mask:setVisible(false)
			self.Button_editorBtn:setTitleText('聊天')
			self.Image_CPWAll:setPositionX(62)
			self.ListView_CPWList:setContentSize(cc.size(1188, 60))
			self.ListView_CPWList:setInnerContainerSize(cc.size(1188, 60))
			self.ListView_CPWList:refreshView()
        end)
        self.Image_PWFrame:runAction(cc.Sequence:create(moveto, callfunc))
	else
		self.Image_PWFrame:setPosition(133, -575)
		self.Image_PWFrame:stopAllActions()
	    local moveto = cc.MoveTo:create(0.2, cc.p(133, 0))
	    local callfunc = cc.CallFunc:create(function()
	        self.Image_PWFrame:setVisible(true)
	    end)
	    self.Image_PWFrame:runAction(cc.Sequence:create(moveto, callfunc))

		self:switchPlaywayUI(1)
	end
end

function NewClubMorePlaywayLayer:onCPWAll()
	if not tolua.isnull(self.curSelChildBtn) then
		self.curSelChildBtn:setVisible(false)
	end
	self.Image_CPWAllLight:setVisible(true)
	self.curSelChildBtn = self.Image_CPWAllLight
	self.parent:createClubTable(0)
end

function NewClubMorePlaywayLayer:filterGameIdList(isHaveShow)
	local list = {0}
	local wKindID = self.clubData.wKindID or {}
	for _,id in ipairs(wKindID) do
		local isInsert = true
		if id ~= 0 then
			for __,v in ipairs(list) do
				if id == v then
					isInsert = false
					break
				end
			end
		else
			isInsert = false
		end

		if isInsert then
			table.insert(list, id)
		end
	end

	if isHaveShow then
		local showList = {}
		for i,v in ipairs(list) do
			local IsShowKey = 'IsShowGame' .. v
			local isShow = cc.UserDefault:getInstance():getBoolForKey(IsShowKey,true)
			if isShow then
				table.insert(showList, v)
			end
		end
		return showList
	else
	    local tempList = {}
	    for i=#list,1,-1 do
	    	local IsShowKey = 'IsShowGame' .. list[i]
			local isShow = cc.UserDefault:getInstance():getBoolForKey(IsShowKey,true)
			if isShow then
				table.insert(tempList, 1, list[i])
			else
				table.insert(tempList, list[i])
			end
	    end
	    return tempList
	end
end

-- ctype 1编辑  2确定
function NewClubMorePlaywayLayer:switchPlaywayUI(ctype)
	self.parent.ScrollView_clubTbl:setPositionX(300)
	self.Image_CPWAll:setPositionX(342)
	self.ListView_CPWList:setContentSize(cc.size(910, 60))
	self.ListView_CPWList:setInnerContainerSize(cc.size(910, 60))
	self.ListView_CPWList:refreshView()
	self.Image_PWFrame:setVisible(true)
	self.Panel_mask:setVisible(true)
	self.ListView_PWList:removeAllItems()
	if ctype == 1 then
		local gameList = self:filterGameIdList(true)
		local curGameId = cc.UserDefault:getInstance():getIntegerForKey('CurSelGameID', 0)
		self.Button_editorBtn:setTitleText('编辑')
		for i,v in ipairs(gameList) do
			local gameinfo = StaticData.Games[v]
			local item = self.Image_PWItem:clone()
			self.ListView_PWList:pushBackCustomItem(item)
			local Image_light = item:getChildByName('Image_light')
			local Text_index = item:getChildByName('Text_index')
			local Image_isShow = item:getChildByName('Image_isShow')
			local Text_pwname = item:getChildByName('Text_pwname')
			Text_index:setColor(cc.c3b(146, 50, 4))
			Text_pwname:setColor(cc.c3b(146, 50, 4))
			Image_isShow:setVisible(false)
			Image_light:setVisible(false)
			
			if i == 1 then
				Text_index:setVisible(false)
				Text_pwname:setString('全部玩法')
			else
				Text_index:setString(i - 1)
				Text_pwname:setString(gameinfo.name)
				
			end

			if curGameId == v then
				Image_light:setVisible(true)
				self.lastPressBtn = Image_light
			end

            item:setTouchEnabled(true)
        	item:addClickEventListener(function() 
        		if not tolua.isnull(self.lastPressBtn) then
					self.lastPressBtn:setVisible(false)
				end
                Image_light:setVisible(true)
				self.lastPressBtn = Image_light
				self:switchChildPlaywayUI(v)
				self.parent:createClubTable(0)
        	end)
		end
	else
		local gameList = self:filterGameIdList(false)
		self.Button_editorBtn:setTitleText('确定')
		for i,v in ipairs(gameList) do
			local gameinfo = StaticData.Games[v]
			local item = self.Image_PWItem:clone()
			self.ListView_PWList:pushBackCustomItem(item)
			local Image_light = item:getChildByName('Image_light')
			local Text_index = item:getChildByName('Text_index')
			local Image_isShow = item:getChildByName('Image_isShow')
			local Text_pwname = item:getChildByName('Text_pwname')
			Text_index:setVisible(false)
			Text_pwname:setColor(cc.c3b(146, 50, 4))
			Image_light:setVisible(false)
			Image_isShow:setVisible(true)
			local IsShowKey = 'IsShowGame' .. v

			if i == 1 then
				Image_isShow:setVisible(false)
				Image_light:setVisible(true)
				Text_pwname:setString('全部玩法')
			else
				local isShow = cc.UserDefault:getInstance():getBoolForKey(IsShowKey,true)
				if isShow then
					Text_index:setString('显示')
					Image_isShow:loadTexture('kwxclub/club_yh_10.png')
				else
					Text_index:setString('隐藏')
					Image_isShow:loadTexture('kwxclub/club_yh_14.png')
				end
				Text_pwname:setString(gameinfo.name)

				item:setTouchEnabled(true)
            	item:addClickEventListener(function() 
            		if Text_index:getString() == '隐藏' then
            			Text_index:setString('显示')
						Image_isShow:loadTexture('kwxclub/club_yh_10.png')
						cc.UserDefault:getInstance():setBoolForKey(IsShowKey,true)
					else
						Text_index:setString('隐藏')
						Image_isShow:loadTexture('kwxclub/club_yh_14.png')
						cc.UserDefault:getInstance():setBoolForKey(IsShowKey,false)
					end
					local curGameId = cc.UserDefault:getInstance():getIntegerForKey('CurSelGameID', 0)
					self:switchChildPlaywayUI(curGameId)
            	end)
			end
		end
	end
end

--gameid 0全部玩法  other:具体玩法
function NewClubMorePlaywayLayer:switchChildPlaywayUI(gameid)
	self.ListView_CPWList:removeAllItems()

	local gameid, curSelPlaywayId = self:checkCurSelelctGame(gameid)
	if curSelPlaywayId == 0 then
		self.Image_CPWAllLight:setVisible(true)
		self.curSelChildBtn = self.Image_CPWAllLight
	else
		self.Image_CPWAllLight:setVisible(false)
	end

	local IsShowKey = 'IsShowGame' .. gameid
	local isShow = cc.UserDefault:getInstance():getBoolForKey(IsShowKey,true)
	if not isShow then
		gameid = 0
	end

	if gameid == 0 then
		self.Text_allPWFont:setString('全部玩法')
	else
		local gameinfo = StaticData.Games[gameid]
		self.Text_allPWFont:setString(gameinfo.name)
	end
	cc.UserDefault:getInstance():setIntegerForKey('CurSelGameID', gameid)
	
	local wKindID = self.clubData.wKindID or {}
	local szParameterName = self.clubData.szParameterName
	for i,id in ipairs(wKindID) do
		local IsShowKey = 'IsShowGame' .. id
		local isShow = cc.UserDefault:getInstance():getBoolForKey(IsShowKey,true)
		if id and id ~= 0 and (gameid == id or gameid == 0) and isShow then
			local item = self.Image_CPWItem:clone()
			local Image_light = item:getChildByName('Image_light')
			local Text_cpwname = item:getChildByName('Text_cpwname')
			Text_cpwname:setString(szParameterName[i])

			if curSelPlaywayId == self.clubData.dwPlayID[i] then
				Image_light:setVisible(true)
	    		self.curSelChildBtn = Image_light
	    		self.ListView_CPWList:insertCustomItem(item, 0)
	    	else
	    		self.ListView_CPWList:pushBackCustomItem(item)
			end

			item:setTouchEnabled(true)
	    	item:addClickEventListener(function()
	    		if not tolua.isnull(self.curSelChildBtn) then
	    			self.curSelChildBtn:setVisible(false)
	    		end
	    		Image_light:setVisible(true)
	    		self.curSelChildBtn = Image_light
	    		self.parent:createClubTable(self.clubData.dwPlayID[i])
	    	end)
		end
	end
	self.parent:createClubTable(curSelPlaywayId)
end

function NewClubMorePlaywayLayer:checkCurSelelctGame(gameid)
	gameid = gameid or 0
	local checkType = 0 --不存在玩法
	local curSelPlaywayId = cc.UserDefault:getInstance():getIntegerForKey('CurSelPlaywayId', 0)
	local wKindID = self.clubData.wKindID or {}
	for i,id in ipairs(wKindID) do
		local IsShowKey = 'IsShowGame' .. id
		local isShow = cc.UserDefault:getInstance():getBoolForKey(IsShowKey,true)
		if id and id ~= 0 and (gameid == id or gameid == 0) and isShow then
			if curSelPlaywayId == self.clubData.dwPlayID[i] then
				checkType = 2  --存在玩法
				break
			end
			checkType = 1  --只有游戏，玩法不在
		end
	end

	if checkType == 0 then
		return 0, 0
	elseif checkType == 1 then
		return gameid, 0
	else
		return gameid, curSelPlaywayId
	end
end

return NewClubMorePlaywayLayer