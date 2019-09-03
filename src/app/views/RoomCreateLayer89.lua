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
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer89.csb")
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
    table.remove(items,3)
    local uiButton_deathCard = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"Button_deathCard")
    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            uiButton_deathCard:setVisible(false)
        else
            uiButton_deathCard:setVisible(true)
        end
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiButton_deathCard:setVisible(true)
        if self.recordCreateParameter["bDeathCard"] ~= nil and self.recordCreateParameter["bDeathCard"] == 1 then
            uiButton_deathCard:setBright(true)
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiButton_deathCard:setVisible(false)
    end
    Common:addCheckTouchEventListener({uiButton_deathCard},true)
    --封顶
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    local uiSlider_parameter = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"Slider_parameter")
    local uiText_sliderValue = ccui.Helper:seekWidgetByName(uiSlider_parameter,"Text_sliderValue")
    local maxValue = 1000
    local Value = 0
    table.remove(items,3)
    Common:addCheckTouchEventListener(items, false, function(index)
    	if index == 1 then
    	   uiSlider_parameter:setVisible(false)
    	else
    	   uiSlider_parameter:setVisible(true)
           uiSlider_parameter:setPercent(0)
           uiText_sliderValue:setString(string.format("%d", 0))
           Value = 0
    	end
    end)
    uiSlider_parameter:addEventListener(function(sender, event) 
        uiText_sliderValue:setString(string.format("%d", uiSlider_parameter:getPercent()*10))
        Value = uiSlider_parameter:getPercent()*10
    end)
    if self.recordCreateParameter["bMaxLost"] ~= nil and self.recordCreateParameter["bMaxLost"] ~= 0 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiSlider_parameter:setVisible(true)
        uiSlider_parameter:setParent(self.recordCreateParameter["bMaxLost"]/maxValue)
        uiText_sliderValue:setString(string.format("%d", self.recordCreateParameter["bMaxLost"]))
        Value = self.recordCreateParameter["bMaxLost"]
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiSlider_parameter:setVisible(false)
    end

    --Button_jia
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_jia"), function() 
        Value = Value + 1
        uiSlider_parameter:setPercent(Value/10)
        uiText_sliderValue:setString(string.format("%d", Value))
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_jian"), function() 
        Value = Value - 1
        uiSlider_parameter:setPercent(Value/10)
        uiText_sliderValue:setString(string.format("%d", Value))
    end)

     --选择冲囤
     local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
     Common:addCheckTouchEventListener(items)
     if self.recordCreateParameter["bStartTun"] ~= nil and self.recordCreateParameter["bStartTun"] == 1 then
         items[2]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end 
     elseif self.recordCreateParameter["bStartTun"] ~= nil and self.recordCreateParameter["bStartTun"] == 2 then
         items[3]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end 
     elseif self.recordCreateParameter["bStartTun"] ~= nil and self.recordCreateParameter["bStartTun"] == 3 then
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
 
     --特殊
     local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
     Common:addCheckTouchEventListener(items,true)
     if self.recordCreateParameter["bYiWuShi"] ~= nil and self.recordCreateParameter["bYiWuShi"] == 1 then
         items[1]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end 
     end
     if self.recordCreateParameter["bMingWei"] ~= nil and self.recordCreateParameter["bMingWei"] == 1 then
         items[2]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end 
     end
     if self.recordCreateParameter["b3Long5Kan"] ~= nil and self.recordCreateParameter["b3Long5Kan"] == 1 then
         items[3]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end 
     end


    --选择玩法
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    local uiPanel_xuanXiang = uiListView_parameterList:getItem(6)
    local uiListView_parameter1 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter1")
    Common:addCheckTouchEventListener(uiListView_parameter1:getItems(),true)
    local uiListView_parameter2 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter2")
    Common:addCheckTouchEventListener(uiListView_parameter2:getItems(),true)
    local uiListView_parameter3 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter3")
    Common:addCheckTouchEventListener(uiListView_parameter3:getItems(),true)
    local uiListView_parameter4 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter4")
    Common:addCheckTouchEventListener(uiListView_parameter4:getItems(),true)
    local uiListView_parameter5 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter5")
    Common:addCheckTouchEventListener(uiListView_parameter5:getItems(),true)
    local uiListView_parameter6 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter6")
    Common:addCheckTouchEventListener(uiListView_parameter6:getItems(),true)
    Common:addCheckTouchEventListener(items,false, function(index)
    	if index == 1 then
    	    uiListView_parameter1:setVisible(true)
            uiListView_parameter2:setVisible(true)
            uiListView_parameter3:setVisible(true)
            uiListView_parameter4:setVisible(true)
            uiListView_parameter5:setVisible(false)
            uiListView_parameter6:setVisible(false)
    	elseif index == 2 then
            uiListView_parameter1:setVisible(false)
            uiListView_parameter2:setVisible(false)
            uiListView_parameter3:setVisible(false)
            uiListView_parameter4:setVisible(false)
            uiListView_parameter5:setVisible(true)
            uiListView_parameter6:setVisible(true)
    	else
            uiListView_parameter1:setVisible(false)
            uiListView_parameter2:setVisible(false)
            uiListView_parameter3:setVisible(false)
            uiListView_parameter4:setVisible(false)
            uiListView_parameter5:setVisible(false)
            uiListView_parameter6:setVisible(false)
    	end
    end)
    
    self.MingTang_Null                   =0x00000000
    self.MingTang_ZiMo                   =0x00000001
    self.MingTang_47Hong                 =0x00000002
    self.MingTang_HongHu                 =0x00000004
    self.MingTang_HongWu                 =0x00000008
    self.MingTang_HeiHu                  =0x00000010
    self.MingTang_DianHu                 =0x00000020
    self.MingTang_TingHu                 =0x00000040
    self.MingTang_TianHu                 =0x00000080
    self.MingTang_DiHu                   =0x00000100
    self.MingTang_HaiDiHu                =0x00000200
    self.MingTang_DuiDuiHu               =0x00000400
    self.MingTang_DaZiHu                 =0x00000800
    self.MingTang_XiaoZiHu               =0x00001000
    self.MingTang_ZhenHangHangXing       =0x00002000
    self.MingTang_JiaHangHangXing        =0x00004000
    self.MingTang_TuanYuanDieJia         =0x00008000
    self.MingTang_TuanYuan               =0x00010000
    self.MingTang_DanPiao                =0x00020000
    self.MingTang_ShuangPiao             =0x00040000
    self.MingTang_Yin                    =0x00080000
    self.MingTang_Gai                    =0x00100000
    self.MingTang_Bei                    =0x00200000
    self.MingTang_Shun                   =0x00400000
    self.MingTang_ShuaHou                =0x00800000
    self.MingTang_ZhuoXiaoSan            =0x01000000
    self.MingTang_HuangFan				 =0x02000000
    self.MingTang_Max                    =0x80000000
    if self.recordCreateParameter["bMingType"] ~= nil and self.recordCreateParameter["bMingType"] == 0 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiListView_parameter1:setVisible(false)
        uiListView_parameter2:setVisible(false)
        uiListView_parameter3:setVisible(false)
        uiListView_parameter4:setVisible(false)
        uiListView_parameter5:setVisible(false)
        uiListView_parameter6:setVisible(false)
    elseif self.recordCreateParameter["bMingType"] ~= nil and self.recordCreateParameter["bMingType"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiListView_parameter1:setVisible(false)
        uiListView_parameter2:setVisible(false)
        uiListView_parameter3:setVisible(false)
        uiListView_parameter4:setVisible(false)
        uiListView_parameter5:setVisible(true)
        uiListView_parameter6:setVisible(true)
        if self.recordCreateParameter["dwMingTang"] ~= nil then
            local items5 = uiListView_parameter5:getItems()
            if Bit:_and(self.MingTang_Yin,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items5[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items5[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_ZhenHangHangXing,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items5[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items5[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_ShuaHou,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items5[3]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items5[3],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_HaiDiHu,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items5[4]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items5[4],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end

            local items6 = uiListView_parameter6:getItems()
            if Bit:_and(self.MingTang_TingHu,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items6[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items6[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_HuangFan,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items6[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items6[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_ZhuoXiaoSan,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items6[3]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items6[3],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end

        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiListView_parameter1:setVisible(true)
        uiListView_parameter2:setVisible(true)
        uiListView_parameter3:setVisible(true)
        uiListView_parameter4:setVisible(true)
        uiListView_parameter5:setVisible(false)
        uiListView_parameter6:setVisible(false)
        if self.recordCreateParameter["dwMingTang"] ~= nil then
            local items1 = uiListView_parameter1:getItems()
            if Bit:_and(self.MingTang_Yin,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items1[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items1[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_ZhenHangHangXing,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items1[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items1[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_TuanYuan,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items1[3]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items1[3],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_47Hong,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items1[4]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items1[4],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            local items2 = uiListView_parameter2:getItems()
            if Bit:_and(self.MingTang_Shun,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items2[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items2[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_DanPiao,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items2[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items2[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_Bei,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items2[3]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items2[3],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_Gai,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items2[4]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items2[4],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end

            local items3 = uiListView_parameter3:getItems()
            if Bit:_and(self.MingTang_ShuaHou,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items3[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items3[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_HaiDiHu,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items3[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items3[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_TingHu,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items3[3]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items3[3],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            if Bit:_and(self.MingTang_HuangFan,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items3[4]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items3[4],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
            local items4 = uiListView_parameter4:getItems()
            if Bit:_and(self.MingTang_ZhuoXiaoSan,self.recordCreateParameter["dwMingTang"]) ~= 0 then
                items4[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items4[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
            end
        end
    end

    --选择托管时间
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bHostedTime"] ~= nil and self.recordCreateParameter["bHostedTime"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bHostedTime"] ~= nil and self.recordCreateParameter["bHostedTime"] == 2 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bHostedTime"] ~= nil and self.recordCreateParameter["bHostedTime"] == 3 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bHostedTime"] ~= nil and self.recordCreateParameter["bHostedTime"] == 5 then
        items[5]:setBright(true)
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

    if self.showType == 3 then
        self.tableFriendsRoomParams = {[1] = {wGameCount = 1}}
        self:SUB_CL_FRIENDROOM_CONFIG_END()
    else
        UserData.Game:sendMsgGetFriendsRoomParam(self.wKindID)
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
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
                isFound = true
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
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local tableParameter = {}
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    if items[1]:isBright() and self.tableFriendsRoomParams[1] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[1].wGameCount
    elseif items[2]:isBright() and self.tableFriendsRoomParams[2] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[2].wGameCount
    elseif items[3]:isBright() and self.tableFriendsRoomParams[3] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[3].wGameCount
    else
        return
    end
    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    table.remove(items,3)
    local uiButton_deathCard = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"Button_deathCard")
    tableParameter.bDeathCard = 0
    if items[1]:isBright() then
        tableParameter.bPlayerCount = 3
        tableParameter.bPlayerCountType = 0
    elseif items[2]:isBright() then
        tableParameter.bPlayerCount = 2
        tableParameter.bPlayerCountType = 0
        if uiButton_deathCard:isBright() then
            tableParameter.bDeathCard = 1 
        end
    else
        return
    end
    
    --封顶
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    local uiText_sliderValue = ccui.Helper:seekWidgetByName(uiSlider_parameter,"Text_sliderValue")
    if items[1]:isBright() then
        tableParameter.bMaxLost = 0
    else
        tableParameter.bMaxLost = tonumber(uiText_sliderValue:getString())
    end

    --选择冲囤
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if items[2]:isBright() then
        tableParameter.bStartTun = 1
    elseif items[3]:isBright() then
        tableParameter.bStartTun = 2
    elseif items[4]:isBright() then
        tableParameter.bStartTun = 3
    else
        tableParameter.bStartTun = 0
    end
    
    --特殊
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bYiWuShi = 1
    else
        tableParameter.bYiWuShi = 0
    end
    if items[2]:isBright() then
        tableParameter.bMingWei = 1
    else
        tableParameter.bMingWei = 0
    end
    if items[3]:isBright() then
        tableParameter.b3Long5Kan = 1
    else
        tableParameter.b3Long5Kan = 0
    end


    --选择名堂
    tableParameter.dwMingTang = 0
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    local uiPanel_xuanXiang = uiListView_parameterList:getItem(6)
    local uiListView_parameter1 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter1")
    local uiListView_parameter2 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter2")
    local uiListView_parameter3 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter3")
    local uiListView_parameter4 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter4")
    local uiListView_parameter5 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter5")
    local uiListView_parameter6 = ccui.Helper:seekWidgetByName(uiPanel_xuanXiang,"ListView_parameter6")
    if items[1]:isBright() then
        tableParameter.bMingType = 2
        local items1 = uiListView_parameter1:getItems()
        if items1[1]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_Yin)
        end
        if items1[2]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZhenHangHangXing)
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_JiaHangHangXing)
        end
        if items1[3]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_TuanYuan)
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_TuanYuanDieJia)
        end
        if items1[4]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_47Hong)
        end
        
        local items2 = uiListView_parameter2:getItems()
        if items2[1]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_Shun)
        end
        if items2[2]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DanPiao)
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ShuangPiao)
        end
        if items2[3]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_Bei)
        end
        if items2[4]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_Gai)
        end

        local items3 = uiListView_parameter3:getItems()
        if items3[1]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ShuaHou)
        end
        if items3[2]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HaiDiHu)
        end
        if items3[3]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_TingHu)
        end
        if items3[4]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HuangFan)
        end
        local items4 = uiListView_parameter4:getItems()
        if items4[1]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZhuoXiaoSan)
        end
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZiMo)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HongHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HeiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DianHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_TianHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DuiDuiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DaZiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_XiaoZiHu)
        -- tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZhuoXiaoSan)
        


    elseif items[2]:isBright() then
        tableParameter.bMingType = 1
        local items5 = uiListView_parameter5:getItems()
        if items5[1]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_Yin)
        end
        if items5[2]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZhenHangHangXing)
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_JiaHangHangXing)
        end
        if items5[3]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ShuaHou)
        end
        if items5[4]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HaiDiHu)
        end


        local items6 = uiListView_parameter6:getItems()
        if items6[1]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_TingHu)
        end
        if items6[2]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HuangFan)
        end
        if items6[3]:isBright() then
            tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZhuoXiaoSan)
        end


        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZiMo)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HongHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HeiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DianHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_TianHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DuiDuiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DaZiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_XiaoZiHu)
    else
        tableParameter.bMingType = 0
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_ZiMo)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HongHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HongWu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_HeiHu)
        tableParameter.dwMingTang = Bit:_or(tableParameter.dwMingTang,self.MingTang_DianHu)
    end

    --选择托管时间
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bHostedTime = 0
    elseif items[2]:isBright() then
        tableParameter.bHostedTime = 1
    elseif items[3]:isBright() then
        tableParameter.bHostedTime = 2
    elseif items[4]:isBright() then
        tableParameter.bHostedTime = 3
    elseif items[5]:isBright() then
        tableParameter.bHostedTime = 5
    end

    tableParameter.FanXing = {}
    tableParameter.FanXing.bType = 0
    tableParameter.FanXing.bCount = 0
    tableParameter.FanXing.bAddTun = 0
    tableParameter.bLaiZiCount = 0
    tableParameter.bLiangPai = 0
    tableParameter.bCanHuXi = 15
    tableParameter.bHuType = 0
    tableParameter.bFangPao = 0
    tableParameter.bSettlement = 0
    tableParameter.bSocreType = 1
    tableParameter.bTurn = 0
    tableParameter.bPaoTips = 0
    tableParameter.bStartBanker = 0
          
   if self.showType ~= 2 and nTableType == TableType_FriendRoom then
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
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请前往商城充值？",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的金币不足!")
                        end
                        return
                end  
                elseif data.dwExpendType == 2 then--元宝
                    if UserData.User.dwIngot  < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足,请前往商城购买？",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的元宝不足!")
                        end
                        return
                end 
                elseif data.dwExpendType == 3 then--道具
                    local itemCount = UserData.Bag:getBagPropCount(data.dwSubType)
                    if itemCount < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的道具不足,请前往商城购买?",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
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

    UserData.Game:saveCreateParameter(self.wKindID,tableParameter)

    --亲友圈自定义创房
    if self.showType == 2 then
        local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
        uiButton_create:removeAllChildren()
        uiButton_create:addChild(require("app.MyApp"):create(TableType_ClubRoom,1,self.wKindID,tableParameter.wGameCount,self.dwClubID,tableParameter):createView("InterfaceCreateRoomNode"))
        return
    end 
    --设置亲友圈   
    if nTableType == TableType_ClubRoom then
        EventMgr:dispatch(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,{wKindID = self.wKindID,wGameCount = tableParameter.wGameCount,tableParameter = tableParameter})      
        return
    end

    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    uiButton_create:removeAllChildren()
    uiButton_create:addChild(require("app.MyApp"):create(nTableType,0,self.wKindID,tableParameter.wGameCount,UserData.Guild.dwPresidentID,tableParameter):createView("InterfaceCreateRoomNode"))

end

return RoomCreateLayer

