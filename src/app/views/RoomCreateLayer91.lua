local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventType = require("common.EventType")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

local RoomCreateLayer = class("RoomCreateLayer", cc.load("mvc").ViewBase)

function RoomCreateLayer:onEnter()
    EventMgr:registListener(EventType.SUB_CL_FRIENDROOM_CONFIG,self,self.SUB_CL_FRIENDROOM_CONFIG)
    EventMgr:registListener(EventType.SUB_CL_FRIENDROOM_CONFIG_END,self,self.SUB_CL_FRIENDROOM_CONFIG_END)
end

function RoomCreateLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_FRIENDROOM_CONFIG,self,self.SUB_CL_FRIENDROOM_CONFIG)
    EventMgr:unregistListener(EventType.SUB_CL_FRIENDROOM_CONFIG_END,self,self.SUB_CL_FRIENDROOM_CONFIG_END)
end

function RoomCreateLayer:onCleanup()

end

function RoomCreateLayer:onCreate(parameter)
    self.wKindID  = parameter[1]
    self.showType = parameter[2]
    self.dwClubID = parameter[3]

    self:initUI()

    if self.showType == 3 then
        self.tableFriendsRoomParams = {[1] = {wGameCount = 1}}
        self:SUB_CL_FRIENDROOM_CONFIG_END()
    else
        UserData.Game:sendMsgGetFriendsRoomParam(self.wKindID)
    end
end

function RoomCreateLayer:initUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer91.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.recordCreateParameter = UserData.Game:readCreateParameter(self.wKindID)
    if self.recordCreateParameter == nil then
        self.recordCreateParameter = {}
    end
    local uiListView_create = ccui.Helper:seekWidgetByName(self.root,"ListView_create")
    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    Common:addTouchEventListener(uiButton_create,function() self:onEventCreate(0) end)
    local uiButton_guild = ccui.Helper:seekWidgetByName(self.root,"Button_guild")
    Common:addTouchEventListener(uiButton_guild,function() self:onEventCreate(1) end)
    local uiButton_help = ccui.Helper:seekWidgetByName(self.root,"Button_help")
    Common:addTouchEventListener(uiButton_help,function() self:onEventCreate(-1) end)
    local uiButton_settings = ccui.Helper:seekWidgetByName(self.root,"Button_settings")
    Common:addTouchEventListener(uiButton_settings,function() self:onEventCreate(-2) end)
    if self.showType ~= nil and self.showType == 1 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        
    elseif self.showType ~= nil and self.showType == 3 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)

    elseif self.showType ~= nil and self.showType == 2 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(1)
        uiListView_create:removeItem(1)
    else
        uiListView_create:removeItem(3)
        uiListView_create:removeItem(0)

        if StaticData.Hide[CHANNEL_ID].btn11 ~= 1 then 
            uiListView_create:removeItem(uiListView_create:getIndex(uiButton_help))
        end  
    end
    uiListView_create:refreshView()
    uiListView_create:setContentSize(cc.size(uiListView_create:getInnerContainerSize().width,uiListView_create:getInnerContainerSize().height))
    uiListView_create:setPositionX(uiListView_create:getParent():getContentSize().width/2)
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    uiListView_parameterList:getItem(0):setVisible(false)
    Common:addCheckTouchEventListener(items)

    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 8 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择玩法
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index)
        if index == 1 then
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            uiText_desc:setString("1")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            uiText_desc:setString("2")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
            uiText_desc:setString("3")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            uiText_desc:setString("4")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
            uiText_desc:setString("5")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
            uiText_desc:setString("10")

            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            uiText_desc:setString("10注封顶")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            uiText_desc:setString("20注封顶")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
            uiText_desc:setString("30注封顶")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            uiText_desc:setString("60注封顶")
        else
            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            uiText_desc:setString("10")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            uiText_desc:setString("20")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
            uiText_desc:setString("30")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            uiText_desc:setString("40")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
            uiText_desc:setString("50")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
            uiText_desc:setString("100")

            local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            uiText_desc:setString("100注封顶")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            uiText_desc:setString("200注封顶")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
            uiText_desc:setString("300注封顶")
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            uiText_desc:setString("600注封顶")
        end
    end)
    if self.recordCreateParameter["bPlayWayType"] ~= nil and self.recordCreateParameter["bPlayWayType"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择底注
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index)            
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
        if index == 6 then
            if items[1]:isBright() then
                items[2]:setEnabled(true)
                items[2]:setColor(cc.c3b(255,255,255))            
                items[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end
            end
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            items[1]:setEnabled(false)
            items[1]:setBright(false)
            items[1]:setColor(cc.c3b(170, 170, 170))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        else
            local isHaveDefault = false
            for key, var in pairs(items) do
                if var:isBright() then
                    isHaveDefault = true
                end
            end
            items[1]:setEnabled(true)
            items[1]:setColor(cc.c3b(255, 255, 255))
            if isHaveDefault == false or items[1]:isBright()  then
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end 
            else             
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end       

        end 
    end)
    if self.recordCreateParameter["bPlayWayType"] ~= nil and self.recordCreateParameter["bPlayWayType"] == 1 then
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        uiText_desc:setString("10")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        uiText_desc:setString("20")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        uiText_desc:setString("30")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        uiText_desc:setString("40")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        uiText_desc:setString("50")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
        uiText_desc:setString("100")
    else        
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        uiText_desc:setString("1")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        uiText_desc:setString("2")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        uiText_desc:setString("3")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        uiText_desc:setString("4")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        uiText_desc:setString("5")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
        uiText_desc:setString("10")
    end
        
    if self.recordCreateParameter["dwBaseSorce"] ~= nil and self.recordCreateParameter["dwBaseSorce"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["dwBaseSorce"] ~= nil and self.recordCreateParameter["dwBaseSorce"] == 3 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["dwBaseSorce"] ~= nil and self.recordCreateParameter["dwBaseSorce"] == 4 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["dwBaseSorce"] ~= nil and self.recordCreateParameter["dwBaseSorce"] == 5 then
        items[5]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["dwBaseSorce"] ~= nil and self.recordCreateParameter["dwBaseSorce"] == 10 then
        items[6]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择轮数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bCompareCardCount"] ~= nil and self.recordCreateParameter["bCompareCardCount"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["bCompareCardCount"] ~= nil and self.recordCreateParameter["bCompareCardCount"] == 2 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["bCompareCardCount"] ~= nil and self.recordCreateParameter["bCompareCardCount"] == 3 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择同牌:
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bSameCard"] ~= nil and self.recordCreateParameter["bSameCard"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择押分:
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bMaxLunCount"] ~= nil and self.recordCreateParameter["bMaxLunCount"] == 20 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["bMaxLunCount"] ~= nil and self.recordCreateParameter["bMaxLunCount"] == 30 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择封顶
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)


    if self.recordCreateParameter["bPlayWayType"] ~= nil and self.recordCreateParameter["bPlayWayType"] == 1 then
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        uiText_desc:setString("100注封顶")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        uiText_desc:setString("200注封顶")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        uiText_desc:setString("300注封顶")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        uiText_desc:setString("600注封顶")
    else        
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        uiText_desc:setString("10注封顶")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        uiText_desc:setString("20注封顶")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        uiText_desc:setString("30注封顶")
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        uiText_desc:setString("60注封顶")
    end


    if self.recordCreateParameter["dwBaseSorce"] ~= nil and (self.recordCreateParameter["dwBaseSorce"] == 10 and self.recordCreateParameter["bPlayWayType"] == 0) and  (self.recordCreateParameter["dwBaseSorce"] == 10 and self.recordCreateParameter["bPlayWayType"] == 0) then
        if items[1]:isBright() then
            items[2]:setEnabled(true)
            items[2]:setColor(cc.c3b(255,255,255))            
            items[2]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(215,86,31))
            end
        end
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        items[1]:setEnabled(false)
        items[1]:setBright(false)
        items[1]:setColor(cc.c3b(170, 170, 170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        uiText_desc:setTextColor(cc.c3b(140,102,57))
    elseif self.recordCreateParameter["dwMaxOutSorce"] ~= nil and self.recordCreateParameter["dwMaxOutSorce"] == 20 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["dwMaxOutSorce"] ~= nil and self.recordCreateParameter["dwMaxOutSorce"] == 30 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["dwMaxOutSorce"] ~= nil and self.recordCreateParameter["dwMaxOutSorce"] == 60 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --闷牌:
    local Text_BMValue = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"Text_BMValue")
    local uiText_BMsliderValue = ccui.Helper:seekWidgetByName(Text_BMValue,"Text_BMsliderValue")
    local Value = self.recordCreateParameter["bMastFloorCount"] or 0
    uiText_BMsliderValue:setString(string.format("%d",Value))

   Common:addTouchEventListener(ccui.Helper:seekWidgetByName(Text_BMValue,"Button_jia"), function() 
        Value = Value + 1
        if Value >= 10 then
            Value = 10
        end        
        uiText_BMsliderValue:setString(string.format("%d", Value))
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(Text_BMValue,"Button_jian"), function() 
        Value = Value - 1
        if Value <= 0 then
            Value = 0
        end
        uiText_BMsliderValue:setString(string.format("%d", Value))
    end)

    --选择弃牌:
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["wQuitTimer"] ~= nil and self.recordCreateParameter["wQuitTimer"] == 20 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["wQuitTimer"] ~= nil and self.recordCreateParameter["wQuitTimer"] == 30 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["wQuitTimer"] ~= nil and self.recordCreateParameter["wQuitTimer"] == 40 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["wQuitTimer"] ~= nil and self.recordCreateParameter["wQuitTimer"] == 50 then
        items[5]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["wQuitTimer"] ~= nil and self.recordCreateParameter["wQuitTimer"] == 60 then
        items[6]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --喜钱:
    local Text_THValue = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"Text_THValue")
    local uiText_THsliderValue = ccui.Helper:seekWidgetByName(Text_THValue,"Text_THsliderValue")
    local Value = self.recordCreateParameter["dwTHMoney"] or 0
    uiText_THsliderValue:setString(string.format("%d", Value))

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(Text_THValue,"Button_jia"), function() 
        Value = Value + 5
        if Value >= 30 then
            Value = 30
        end        
        uiText_THsliderValue:setString(string.format("%d", Value))
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(Text_THValue,"Button_jian"), function() 
        Value = Value - 5
        if Value <= 0 then
            Value = 0
        end
        uiText_THsliderValue:setString(string.format("%d", Value))
    end)

    local Text_BZValue = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"Text_BZValue")
    local uiText_BZsliderValue = ccui.Helper:seekWidgetByName(Text_BZValue,"Text_BZsliderValue")
    local Value = self.recordCreateParameter["dwBZMoney"] or 0
    uiText_BZsliderValue:setString(string.format("%d", Value))

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(Text_BZValue,"Button_jia"), function() 
        Value = Value + 10
        if Value >= 50 then
            Value = 50
        end        
        uiText_BZsliderValue:setString(string.format("%d", Value))
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(Text_BZValue,"Button_jian"), function() 
        Value = Value - 10
        if Value <= 0 then
            Value = 0
        end
        uiText_BZsliderValue:setString(string.format("%d", Value))
    end)



    --可选选项
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)

    -- if self.recordCreateParameter["bQuickMode"] == nil or self.recordCreateParameter["bQuickMode"] == 0 then
    --     for key, var in pairs(items) do
    --         -- var:setColor(cc.c3b(170,170,170))
    --         -- var:setEnabled(false)
    --         var:setBright(false)
    --         local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
    --         if uiText_desc ~= nil then 
    --             uiText_desc:setTextColor(cc.c3b(109,58,44))
    --         end
    --     end
    -- end

    if self.recordCreateParameter["bQuickMode"] == nil or self.recordCreateParameter["bQuickMode"] == true then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(false)
    end 

    if self.recordCreateParameter["bCanPlayingJoin"] == nil or self.recordCreateParameter["bCanPlayingJoin"] == true then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(false)
    end

    if self.recordCreateParameter["bCanTouchCard"] ~= nil and self.recordCreateParameter["bCanTouchCard"] == true then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[3]:setBright(false)
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["bMaxA23"] == nil or self.recordCreateParameter["bMaxA23"] == true then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(false)
    end
    if self.recordCreateParameter["bCompareCardDoubleSorce"] ~= nil and self.recordCreateParameter["bCompareCardDoubleSorce"] == true then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(false)
    end  

    if self.recordCreateParameter["b235ChiBaoZi"] ~= nil and self.recordCreateParameter["b235ChiBaoZi"] == true then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[3]:setBright(false)
    end  

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["bSortLookCard"] == nil or self.recordCreateParameter["bSortLookCard"] == true then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(false)
    end
    if self.recordCreateParameter["bSZBigFlower"] ~= nil and self.recordCreateParameter["bSZBigFlower"] == true then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(false)
    end  

end

function RoomCreateLayer:SUB_CL_FRIENDROOM_CONFIG(event)
    local data = event._usedata
    if data.wKindID ~= self.wKindID then
        return
    end
    if self.tableFriendsRoomParams == nil then
        self.tableFriendsRoomParams = {}
    end
    self.tableFriendsRoomParams[data.dwIndexes] = data
end

function RoomCreateLayer:SUB_CL_FRIENDROOM_CONFIG_END(event)
    if self.tableFriendsRoomParams == nil then
        return
    end
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local uiListView_parameter = uiListView_parameterList:getItem(0)
    uiListView_parameter:setVisible(true)
    local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
    local isFound = false
    for key, var in pairs(items) do
        local data = self.tableFriendsRoomParams[key]
    	if data then
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            --    uiText_desc:setString(string.format("%d局",data.wGameCount))
            local uiText_addition = ccui.Helper:seekWidgetByName(var,"Text_addition")
            uiText_addition:setVisible(false)
            if data.dwExpendType == 1 then
                uiText_addition:setString(string.format("金币x%d",data.dwExpendCount))
                uiText_desc:setString(string.format("%d局 金币x%d",data.wGameCount,data.dwExpendCount))
            elseif data.dwExpendType == 2 then
                uiText_addition:setString(string.format("元宝x%d",data.dwExpendCount))
                uiText_desc:setString(string.format("%d局 元宝x%d",data.wGameCount,data.dwExpendCount))
            elseif data.dwExpendType == 3 then
                uiText_addition:setString(string.format("(%sx%d)",StaticData.Items[data.dwSubType].name,data.dwExpendCount))
                uiText_desc:setString(string.format("%d局(%sx%d)",data.wGameCount,StaticData.Items[data.dwSubType].name,data.dwExpendCount))
            else
                uiText_addition:setString("(无消耗)")
                uiText_desc:setString(string.format("%d局(无消耗)",data.wGameCount))
            end
            if isFound == false and self.recordCreateParameter["wGameCount"] ~= nil and self.recordCreateParameter["wGameCount"] == data.wGameCount then
                var:setBright(true)
                isFound = true
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end
            end
    	else
    	   var:setBright(false)
           var:setVisible(false)
           local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
           if uiText_desc ~= nil then 
               uiText_desc:setTextColor(cc.c3b(109,58,44))
           end
    	end
    end
    if isFound == false and items[1]:isVisible() then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end
end

function RoomCreateLayer:onEventCreate(nTableType)
    NetMgr:getGameInstance():closeConnect()
    self.tableParameter = {}
    self:setParameter()

   if self.showType ~= 2 and (nTableType == TableType_FriendRoom or nTableType == TableType_HelpRoom) then
        --普通创房和代开需要判断金币
        local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
        local uiListView_parameter = uiListView_parameterList:getItem(0)
        local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
        for key, var in pairs(items) do
            if var:isBright() then
                local data = self.tableFriendsRoomParams[key]
                if data.dwExpendType == 0 then--无消耗
                elseif data.dwExpendType == 1 then--金币
                    if UserData.User.dwGold  < data.dwExpendCount then
                        require("common.MsgBoxLayer"):create(0,nil,"您的金币不足!")
                        return
                    end  
                elseif data.dwExpendType == 2 then--元宝
                    if UserData.User.dwIngot  < data.dwExpendCount then
                        require("common.MsgBoxLayer"):create(0,nil,"您的元宝不足!")
                        return
                    end 
                elseif data.dwExpendType == 3 then--道具
                    local itemCount = UserData.Bag:getBagPropCount(data.dwSubType)
                    if itemCount < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的道具不足,请前往商城购买?",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("MallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的道具不足!")
                        end
                        return
                    end
                else
                    return
                end
                break
            end
        end
    end

    UserData.Game:saveCreateParameter(self.wKindID,self.tableParameter)

    --亲友圈自定义创房
    if self.showType == 2 then
        local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
        uiButton_create:removeAllChildren()
        uiButton_create:addChild(require("app.MyApp"):create(TableType_ClubRoom,1,self.wKindID,self.tableParameter.wGameCount,self.dwClubID,self.tableParameter):createView("InterfaceCreateRoomNode"))
        return
    end 
    --设置亲友圈   
    if nTableType == TableType_ClubRoom then
        EventMgr:dispatch(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,{wKindID = self.wKindID,wGameCount = self.tableParameter.wGameCount,tableParameter = self.tableParameter})      
        return
    end

    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    uiButton_create:removeAllChildren()
    uiButton_create:addChild(require("app.MyApp"):create(nTableType,0,self.wKindID,self.tableParameter.wGameCount,UserData.Guild.dwPresidentID,self.tableParameter):createView("InterfaceCreateRoomNode"))

end

function RoomCreateLayer:setParameter()
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    if items[1]:isBright() and self.tableFriendsRoomParams[1] then
        self.tableParameter.wGameCount = self.tableFriendsRoomParams[1].wGameCount
    elseif items[2]:isBright() and self.tableFriendsRoomParams[2] then
        self.tableParameter.wGameCount = self.tableFriendsRoomParams[2].wGameCount
    elseif items[3]:isBright() and self.tableFriendsRoomParams[3] then
        self.tableParameter.wGameCount = self.tableFriendsRoomParams[3].wGameCount
    else
        return
    end    
    
    --参与人数写死（八人场）
    self.tableParameter.bPlayerCount = 6
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bPlayerCount = 6
    elseif items[2]:isBright() then
        self.tableParameter.bPlayerCount = 8
    else
        return
    end
    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bPlayWayType = 0
    elseif items[2]:isBright() then
        self.tableParameter.bPlayWayType = 1
    else
        return
    end

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if self.tableParameter.bPlayWayType == 1 then 
        if items[1]:isBright() then
            self.tableParameter.dwBaseSorce = 10
        elseif items[2]:isBright() then
            self.tableParameter.dwBaseSorce = 20
        elseif items[3]:isBright() then
            self.tableParameter.dwBaseSorce = 30
        elseif items[4]:isBright() then
            self.tableParameter.dwBaseSorce = 40
        elseif items[5]:isBright() then
            self.tableParameter.dwBaseSorce = 50
        elseif items[6]:isBright() then
            self.tableParameter.dwBaseSorce = 100
        else
            return
        end
    else
        if items[1]:isBright() then
            self.tableParameter.dwBaseSorce = 1
        elseif items[2]:isBright() then
            self.tableParameter.dwBaseSorce = 2
        elseif items[3]:isBright() then
            self.tableParameter.dwBaseSorce = 3
        elseif items[4]:isBright() then
            self.tableParameter.dwBaseSorce = 4
        elseif items[5]:isBright() then
            self.tableParameter.dwBaseSorce = 5
        elseif items[6]:isBright() then
            self.tableParameter.dwBaseSorce = 10
        else
            return
        end
    end 

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bCompareCardCount = 0
    elseif items[2]:isBright() then
        self.tableParameter.bCompareCardCount = 1
    elseif items[3]:isBright() then
        self.tableParameter.bCompareCardCount = 2
    elseif items[4]:isBright() then
    self.tableParameter.bCompareCardCount = 3
    else
        return
    end

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bSameCard = 0
    elseif items[2]:isBright() then
        self.tableParameter.bSameCard = 1
    else
        return
    end

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bMaxLunCount = 10
    elseif items[2]:isBright() then
        self.tableParameter.bMaxLunCount = 20
    elseif items[3]:isBright() then
        self.tableParameter.bMaxLunCount = 30
    else
        return
    end

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()

    if self.tableParameter.bPlayWayType == 1 then 
        if items[1]:isBright() then
            self.tableParameter.dwMaxOutSorce = 100
        elseif items[2]:isBright() then
            self.tableParameter.dwMaxOutSorce = 200
        elseif items[3]:isBright() then
            self.tableParameter.dwMaxOutSorce = 300
        elseif items[4]:isBright() then
            self.tableParameter.dwMaxOutSorce = 600
        else
            return
        end
    else
        if items[1]:isBright() then
            self.tableParameter.dwMaxOutSorce = 10
        elseif items[2]:isBright() then
            self.tableParameter.dwMaxOutSorce = 20
        elseif items[3]:isBright() then
            self.tableParameter.dwMaxOutSorce = 30
        elseif items[4]:isBright() then
            self.tableParameter.dwMaxOutSorce = 60
        else
            return
        end
    end 
    --  
    local Text_BMValue = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"Text_BMValue")
    local uiText_BMsliderValue = ccui.Helper:seekWidgetByName(Text_BMValue,"Text_BMsliderValue")
    -- if items[1]:isBright() then
        self.tableParameter.bMastFloorCount = tonumber(uiText_BMsliderValue:getString())
    -- elseif items[2]:isBright() then
    --     self.tableParameter.bPlayerCount = 8
    -- else
    --     return
    -- end--  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.wQuitTimer = 10
    elseif items[2]:isBright() then
        self.tableParameter.wQuitTimer = 20
    elseif items[3]:isBright() then
        self.tableParameter.wQuitTimer = 30
    elseif items[4]:isBright() then
        self.tableParameter.wQuitTimer = 40
    elseif items[5]:isBright() then
        self.tableParameter.wQuitTimer = 50
    elseif items[6]:isBright() then
        self.tableParameter.wQuitTimer = 60
    else
        return
    end

    --  
    local Text_THValue = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"Text_THValue")
    local uiText_THsliderValue = ccui.Helper:seekWidgetByName(Text_THValue,"Text_THsliderValue")

    local Text_BZValue = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"Text_BZValue")
    local uiText_BZsliderValue = ccui.Helper:seekWidgetByName(Text_BZValue,"Text_BZsliderValue")

    self.tableParameter.dwTHMoney = tonumber(uiText_THsliderValue:getString())

    self.tableParameter.dwBZMoney = tonumber(uiText_BZsliderValue:getString())

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bQuickMode = true      
    else
        self.tableParameter.bQuickMode = false
    end

    if items[2]:isBright() then
        self.tableParameter.bCanPlayingJoin = true      
    else
        self.tableParameter.bCanPlayingJoin = false
    end

    if items[3]:isBright() then
        self.tableParameter.bCanTouchCard = true      
    else
        self.tableParameter.bCanTouchCard = false
    end

    --  
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(12),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bMaxA23 = true      
    else
        self.tableParameter.bMaxA23 = false
    end

    if items[2]:isBright() then
        self.tableParameter.bCompareCardDoubleSorce = true      
    else
        self.tableParameter.bCompareCardDoubleSorce = false
    end

    if items[3]:isBright() then
        self.tableParameter.b235ChiBaoZi = true      
    else
        self.tableParameter.b235ChiBaoZi = false
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(13),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        self.tableParameter.bSortLookCard = true      
    else
        self.tableParameter.bSortLookCard = false
    end

    if items[2]:isBright() then
        self.tableParameter.bSZBigFlower = true      
    else
        self.tableParameter.bSZBigFlower = false
    end

end

return RoomCreateLayer

