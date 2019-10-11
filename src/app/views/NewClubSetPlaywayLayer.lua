--[[
*名称:NewClubSetPlaywayLayer
*描述:设置俱乐部玩法
*作者:admin
*创建日期:2019-10-08 10:45:39
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local GameConfig        = require("common.GameConfig")

local NewClubSetPlaywayLayer = class("NewClubSetPlaywayLayer", cc.load("mvc").ViewBase)

function NewClubSetPlaywayLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Button_all", "onAll"},
        {"Button_mj", "onMj"},
        {"Button_pk", "onPK"},
        {"Button_zp", "onZP"},
        {"Button_add", "onAdd"},
        {"Image_noPlayway"},
        {"ListView_playway"},
        {"Image_item"},
    }
    self.curSelType = 0
end

function NewClubSetPlaywayLayer:onEnter()
	EventMgr:registListener(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,self,self.EVENT_TYPE_SETTINGS_CLUB_PARAMETER)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_PLAY,self,self.RET_SETTINGS_CLUB_PLAY)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_PLAY_FINISH,self,self.RET_SETTINGS_CLUB_PLAY_FINISH)
end

function NewClubSetPlaywayLayer:onExit()
	EventMgr:unregistListener(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,self,self.EVENT_TYPE_SETTINGS_CLUB_PARAMETER)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_PLAY,self,self.RET_SETTINGS_CLUB_PLAY)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_PLAY_FINISH,self,self.RET_SETTINGS_CLUB_PLAY_FINISH)
end

function NewClubSetPlaywayLayer:onCreate(param)
	self.clubData = param[1]
	self.quickStartTables = param[2]
	dump(self.clubData)

	if not (self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID)) or self.quickStartTables then
		self.Button_add:setVisible(false)
	end

	self:switchType(0)
end

function NewClubSetPlaywayLayer:onClose()
    self:removeFromParent()
end

function NewClubSetPlaywayLayer:onAll()
	self:switchType(0)
end

function NewClubSetPlaywayLayer:onMj()
	self:switchType(1)
end

function NewClubSetPlaywayLayer:onPK()
	self:switchType(2)
end

function NewClubSetPlaywayLayer:onZP()
	self:switchType(3)
end

function NewClubSetPlaywayLayer:onAdd()
    local roomNode = require("app.MyApp"):create(nil, 1):createView("RoomCreateLayer")
    self:addChild(roomNode)
    roomNode.data = {playid = 0, settype = 1, idx = 0}
    roomNode:setName('RoomCreateLayer')
end

-- itype 0 全部 1 麻将 2 扑克 3 字牌
function NewClubSetPlaywayLayer:switchType(itype)
	self.curSelType = itype
	if itype == 0 then
		self.Button_all:setBright(false)
		self.Button_mj:setBright(true)
		self.Button_pk:setBright(true)
		self.Button_zp:setBright(true)
	elseif itype == 1 then
		self.Button_all:setBright(true)
		self.Button_mj:setBright(false)
		self.Button_pk:setBright(true)
		self.Button_zp:setBright(true)
	elseif itype == 2 then
		self.Button_all:setBright(true)
		self.Button_mj:setBright(true)
		self.Button_pk:setBright(false)
		self.Button_zp:setBright(true)
	elseif itype == 3 then
		self.Button_all:setBright(true)
		self.Button_mj:setBright(true)
		self.Button_pk:setBright(true)
		self.Button_zp:setBright(false)
	end
	self:initSelectPage(itype)
end

function NewClubSetPlaywayLayer:initSelectPage(itype)
	local items = self.ListView_playway:getChildren()
	for i,v in ipairs(items) do
		v:setVisible(false)
	end
    local playwaynum = self:getPlayWayNums()
    -- for i=playwaynum+1, #items do
    --     items[i]:removeFromParent()
    --     items[i] = nil
    -- end

    if playwaynum > 0 then
		self.Image_noPlayway:setVisible(false)
		self.ListView_playway:setVisible(true)
	else
		self.Image_noPlayway:setVisible(true)
		self.ListView_playway:setVisible(false)
		return
	end

	local count = 0
	if itype == 0 then
		for i,id in ipairs(self.clubData.dwPlayID) do
			local kindid = self.clubData.wKindID[i]
	        local gameinfo = StaticData.Games[kindid]
	        if id ~= 0 and gameinfo then
	        	count = count + 1
	        	local item = items[count]
		        if not item then
		            item = self.Image_item:clone()
		            self.ListView_playway:pushBackCustomItem(item)
		        end
		        item:setVisible(true)
		        self:initPlaywayItem(item, count, i)
	        end
		end
	elseif itype == 1 then
		for i,id in ipairs(self.clubData.dwPlayID) do
			local kindid = self.clubData.wKindID[i]
	        local gameinfo = StaticData.Games[kindid]
	        if id ~= 0 and gameinfo and gameinfo.type == 3 then
	        	count = count + 1
	        	local item = items[count]
		        if not item then
		            item = self.Image_item:clone()
		            self.ListView_playway:pushBackCustomItem(item)
		        end
		        item:setVisible(true)
		        self:initPlaywayItem(item, count, i)
	        end
		end
	elseif itype == 2 then
		for i,id in ipairs(self.clubData.dwPlayID) do
			local kindid = self.clubData.wKindID[i]
	        local gameinfo = StaticData.Games[kindid]
	        if id ~= 0 and gameinfo and gameinfo.type == 2 then
	        	count = count + 1
	        	local item = items[count]
		        if not item then
		            item = self.Image_item:clone()
		            self.ListView_playway:pushBackCustomItem(item)
		        end
		        item:setVisible(true)
		        self:initPlaywayItem(item, count, i)
	        end
		end
	elseif itype == 3 then
		for i,id in ipairs(self.clubData.dwPlayID) do
			local kindid = self.clubData.wKindID[i]
	        local gameinfo = StaticData.Games[kindid]
	        if id ~= 0 and gameinfo and gameinfo.type == 1 then
	        	count = count + 1
	        	local item = items[count]
		        if not item then
		            item = self.Image_item:clone()
		            self.ListView_playway:pushBackCustomItem(item)
		        end
		        item:setVisible(true)
		        self:initPlaywayItem(item, count, i)
	        end
		end
	end
	local realHeight = count * (174 + 10)
	if realHeight < 603 then
		realHeight = 603
	end
    self.ListView_playway:setInnerContainerSize(cc.size(1039, realHeight))
end

function NewClubSetPlaywayLayer:initPlaywayItem(item, count, index)
	local kindid = self.clubData.wKindID[index]
    local gameinfo = StaticData.Games[kindid]
	local AtlasLabel_index = ccui.Helper:seekWidgetByName(item, 'AtlasLabel_index')
    local Text_name = ccui.Helper:seekWidgetByName(item, 'Text_name')
    local Text_cusName = ccui.Helper:seekWidgetByName(item, 'Text_cusName')
    local Text_people = ccui.Helper:seekWidgetByName(item, 'Text_people')
    local Text_jushu = ccui.Helper:seekWidgetByName(item, 'Text_jushu')
    local Text_des = ccui.Helper:seekWidgetByName(item, 'Text_des')
    local Button_remove = ccui.Helper:seekWidgetByName(item, 'Button_remove')
    local Button_modify = ccui.Helper:seekWidgetByName(item, 'Button_modify')
    local Button_quick = ccui.Helper:seekWidgetByName(item, 'Button_quick')
    local Text_playing = ccui.Helper:seekWidgetByName(item, 'Text_playing')
    Text_name:setColor(cc.c3b(109, 58, 44))
    Text_cusName:setColor(cc.c3b(109, 58, 44))
    Text_people:setColor(cc.c3b(109, 58, 44))
    Text_jushu:setColor(cc.c3b(109, 58, 44))
    Text_des:setColor(cc.c3b(109, 58, 44))
    Text_playing:setColor(cc.c3b(109, 58, 44))

    if self.quickStartTables then
    	Button_remove:setVisible(false)
    	Button_modify:setVisible(false)
    	Button_quick:setVisible(true)

    	Button_quick:setPressedActionEnabled(true)
	    Button_quick:addClickEventListener(function(sender)
	        require("common.Common"):playEffect("common/buttonplay.mp3")
	    	local kindid = self.clubData.wKindID[index]
	    	local playwayid = self.clubData.dwPlayID[index]
	        for _,v in ipairs(self.quickStartTables) do
	            if v.data and v.data.wTableSubType == playwayid then
	                local data = v.data
	                if (kindid == 51 or kindid == 53 or kindid == 55 or kindid == 56 or kindid == 57 or kindid == 58 or kindid == 59) and data.tableParameter.bCanPlayingJoin == 1 and data.wCurrentChairCount < data.wChairCount  then
	                    require("common.SceneMgr"):switchTips(require("app.MyApp"):create(v.data.dwTableID,self:getEnterTableFigueValue(index)):createView("InterfaceJoinRoomNode"))
	                    return
	                elseif data.bIsGameStart == false and data.wCurrentChairCount < data.wChairCount then
	                    require("common.SceneMgr"):switchTips(require("app.MyApp"):create(v.data.dwTableID,self:getEnterTableFigueValue(index)):createView("InterfaceJoinRoomNode"))
	                    return
	                end
	            end
	        end
	        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(-2,self.clubData.dwPlayID[index],self.clubData.wKindID[index],self.clubData.wGameCount[index],self.clubData.dwClubID,self.clubData.tableParameter[index],self:getEnterTableFigueValue(index)):createView("InterfaceCreateRoomNode"))
	    end)

	    local tableNum = 0
	    local playwayid = self.clubData.dwPlayID[index]
	    for i,v in ipairs(self.quickStartTables) do
	        if v.data and v.data.dwTableID and v.data.wTableSubType == playwayid then
	            tableNum = tableNum + 1
	        end
	    end
	    Text_playing:setString(string.format('%d桌正在牌局', tableNum))
    else
    	Button_remove:setVisible(true)
    	Button_modify:setVisible(true)
    	Button_quick:setVisible(false)

    	Button_remove:setPressedActionEnabled(true)
	    Button_remove:addClickEventListener(function(sender)
	        require("common.Common"):playEffect("common/buttonplay.mp3")
	        local kindid = self.clubData.wKindID[index]
	        local playwayid = self.clubData.dwPlayID[index]
	        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddw",
	            2,self.clubData.dwClubID,playwayid,kindid)
	    end)
	    Button_modify:setPressedActionEnabled(true)
	    Button_modify:addClickEventListener(function(sender)
	        require("common.Common"):playEffect("common/buttonplay.mp3")
	        local kindid = self.clubData.wKindID[index]
	        local playwayid = self.clubData.dwPlayID[index]
	        local roomNode = require("app.MyApp"):create(kindid,1):createView("RoomCreateLayer")
	        self:addChild(roomNode)
	        roomNode.data = {playid = playwayid, settype = 3, idx = index}
	        roomNode:setName('RoomCreateLayer')
	    end)
    end

    AtlasLabel_index:setString(count)
    Text_name:setString(gameinfo.name)
    if self.clubData.szParameterName[index] ~= "" and self.clubData.szParameterName[index] ~= " " then
        Text_cusName:setString(self.clubData.szParameterName[index])
    else
        Text_cusName:setString(gameinfo.name)
    end
    local parameter = self.clubData.tableParameter[index]
    Text_people:setString(string.format('人数:%d人', parameter.bPlayerCount))
    local jushu = self.clubData.wGameCount[index]
    Text_jushu:setString(string.format('局数:%d局', jushu))

    local des = ''
    local cbMode = self.clubData.cbMode[index]
    if cbMode == 1 then
        des = '疲劳值模式/'
    elseif cbMode == 2 then
        des = '元宝模式/'
    else
        des = '圈主模式/'
    end

    if self.clubData.isTableCharge[index] then
	    des = des .. string.format('倍率:%d/门槛:%d/解散限制:%d/', self.clubData.wFatigueCell[index], self.clubData.lTableLimit[index], self.clubData.lFatigueLimit[index])
	end

	local cbPayMode = self.clubData.cbPayMode[index]
    if cbPayMode == 1 then
        des = des .. string.format('大赢家支付%s',self:getLimitDes(self.clubData.dwPayLimit[index], self.clubData.dwPayCount[index], self.clubData.isPercentage[index]))
    elseif cbPayMode == 2 then
        des = des .. string.format('赢家支付%s',self:getLimitDes(self.clubData.dwPayLimit[index], self.clubData.dwPayCount[index], self.clubData.isPercentage[index]))
    elseif cbPayMode == 3 then
        des = des .. string.format('AA支付:%d', self.clubData.dwPayCount[index][1])
    else
        des = des .. string.format('免费')
    end

    local desc = require("common.GameDesc"):getGameDesc(self.clubData.wKindID[index], self.clubData.tableParameter[index])
    des = des .. '\n' .. desc
    Text_des:setString(des)
end

function NewClubSetPlaywayLayer:getPlayWayNums()
    local num = 0
    for i,v in ipairs(self.clubData.wKindID or {}) do
        local gameinfo = StaticData.Games[v]
        if gameinfo then
            num = num + 1
        end
    end
    return num
end

function NewClubSetPlaywayLayer:getLimitDes(limitArr, payCountArr, isPercentage)
    local des = ""
    for i,v in ipairs(limitArr) do
        if i == 1 then
            if isPercentage then
                des = string.format('>%d:%d', v, payCountArr[i]) .. '%'
            else
                des = string.format('>%d:%d', v, payCountArr[i])
            end
        else
            if v > 0 then
                if isPercentage then
                    des = des .. (string.format(' >%d:%d', v, payCountArr[i]) .. '%')
                else
                    des = des .. string.format(' >%d:%d', v, payCountArr[i])
                end
            end
        end
    end
    return des
end

function NewClubSetPlaywayLayer:isAdmin(userid, adminData)
    adminData = adminData or self.clubData.dwAdministratorID
    for i,v in ipairs(adminData or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubSetPlaywayLayer:megerClubData(data)
    if type(data) ~= 'table' then
        return
    end
    self.clubData = self.clubData or {}
    for k,v in pairs(data) do
        self.clubData[k] = v
    end
end

function NewClubSetPlaywayLayer:getEnterTableFigueValue(curPlaywayIdx)
    local maxValue = 0
    local idx = curPlaywayIdx
    if idx then
        for k,v in pairs(self.clubData.dwPayCount[idx]) do
            if maxValue < v then
                maxValue = v
            end
        end
        local value = self.clubData.lTableLimit[idx] + maxValue
        return value
    else
        return 0
    end
end


------------------------------------------------------>>
--设置玩法消息回调
function NewClubSetPlaywayLayer:EVENT_TYPE_SETTINGS_CLUB_PARAMETER(event)
    local data = event._usedata
    dump(data)
    local roomNode = self:getChildByName('RoomCreateLayer')
    if roomNode then
        local isModifyPlayName = self.clubData.wKindID[roomNode.data.idx] ~= data.wKindID
        local cloneData = {}
        cloneData = self:cloneSetData(cloneData, self.clubData)
        cloneData = self:cloneSetData(cloneData, data)
        cloneData = self:cloneSetData(cloneData, roomNode.data)
        local setNode = require("app.MyApp"):create(cloneData, isModifyPlayName):createView("NewClubPlayWayInfoLayer")
        roomNode:addChild(setNode)
    end
end

function NewClubSetPlaywayLayer:cloneSetData(src, dir)
    for k,v in pairs(dir) do
        src[k] = v
    end
    return src
end

--返回设置亲友圈玩法
function NewClubSetPlaywayLayer:RET_SETTINGS_CLUB_PLAY(event)
    local data = event._usedata
    dump(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"设置玩法失败")
        return
    end

    if data.cbPlayCount <= 10 then
        self.playwayData = {}
    end
    self.playwayData = self.playwayData or {}
    for k,v in pairs(data) do
        if type(v) == 'table' and self.playwayData[k] then
            for m,n in ipairs(v) do
                table.insert(self.playwayData[k], n)
            end
        else
            self.playwayData[k] = v
        end
	end
end

function NewClubSetPlaywayLayer:RET_SETTINGS_CLUB_PLAY_FINISH(event)
    local data = event._usedata
    if self.playwayData.cbSettingsType == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"删除玩法成功")
    elseif self.playwayData.cbSettingsType == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"修改玩法成功")
    else
        require("common.MsgBoxLayer"):create(0,nil,"添加玩法成功")
    end

    UserData.Guild:refreshClub(self.playwayData.dwClubID)
    self:megerClubData(self.playwayData)
    self:initSelectPage(self.curSelType)
end

return NewClubSetPlaywayLayer