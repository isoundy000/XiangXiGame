local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")


local DissolutionLayer = class("DissolutionLayer", function()
    return ccui.Layout:create()
end)


function DissolutionLayer:create(player,data)
    local view = DissolutionLayer.new()
    view:onCreate(player,data)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit()
        elseif eventType == "cleanup" then
            view:onCleanup()
        end  
    end
    view:registerScriptHandler(onEventHandler)
    return view
end

function DissolutionLayer:onEnter()
    
end

function DissolutionLayer:onExit()
    
end

function DissolutionLayer:onCleanup()
end

function DissolutionLayer:onCreate(player,data)
    require("common.SceneMgr"):switchTips(self)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("DissolutionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    --进度动作
    local uiText_countdown = ccui.Helper:seekWidgetByName(self.root,"Text_countdown")
    uiText_countdown:setString(string.format("%d秒后自动解散",data.dwDisbandedTime))
    uiText_countdown:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function(sender,event) 
           uiText_countdown:setString(string.format("%d秒后自动解散",data.dwDisbandedTime))
            data.dwDisbandedTime = data.dwDisbandedTime - 1
            if data.dwDisbandedTime < 0 then
                data.dwDisbandedTime = 0
            end
        end)
    )))
    
    local uiPanel_btn = ccui.Helper:seekWidgetByName(self.root,"Panel_btn")
    uiPanel_btn:setVisible(false)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_agree"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",true)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_refuse"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",false)
    end)


    local count = 0
    for i = 1, 8 do
        if data.wKindID ~= nil and data.wKindID  == 42 then 
            if data.dwUserIDALL[i] ~= 0 and player ~= nil and player[i] ~= nil then
                count = count + 1
            end 
        else 
            if data.dwUserIDALL[i] ~= 0 and player ~= nil and player[i-1] ~= nil then
                count = count + 1
            end
        end 
    end
    local uiPanel_contents = nil  
    local uiPanel_contents6 = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local uiPanel_contents8 = ccui.Helper:seekWidgetByName(self.root,"Panel_contents8")
    if count > 4  then 
        uiPanel_contents6:removeFromParent()
        uiPanel_contents = uiPanel_contents8
    else
        uiPanel_contents8:removeFromParent()
        uiPanel_contents = uiPanel_contents6
    end 

    if count <= 4  then 

        --local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
        uiPanel_player:retain()
        uiPanel_contents:removeAllChildren()
        for i=1,count do
            if data.dwUserIDALL[i] ~= 0 then
                local item = uiPanel_player:clone()
                uiPanel_contents:addChild(item)
                local uiImage_state = ccui.Helper:seekWidgetByName(item,"Image_state")
                if data.cbDisbandeState[i] == 1 then
                    uiImage_state:loadTexture("game/dismiss/dismiss_agree.png")
                elseif data.cbDisbandeState[i] == 2 then
                    uiImage_state:loadTexture("game/dismiss/dismiss_refuse.png")
                    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.RemoveSelf:create()))
                    require("common.MsgBoxLayer"):create(2,nil,string.format("%s拒绝解散房间",data.szNickNameALL[i])) 
                    return
                else
                    uiImage_state:loadTexture("game/dismiss/dismiss_wait.png")
                    if data.dwUserIDALL[i] == UserData.User.userID then
                        uiPanel_btn:setVisible(true)
                    end
                end
                local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
                uiText_name:setColor(cc.c3b(132,52,12))
                uiText_name:setString(data.szNickNameALL[i])
                local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
                Common:requestUserAvatar(data.dwUserIDALL[i],player[i-1].szPto,uiImage_avatar,"clip")
                local uiImage_clip = ccui.Helper:seekWidgetByName(item,"Image_clip")
            end
        end
        uiPanel_player:release()

        local items = uiPanel_contents:getChildren()
        local size = uiPanel_player:getContentSize()
        local contentSize = uiPanel_contents:getContentSize()
        local interval = contentSize.width/(#items+1)
        for k,v in pairs(items) do
            v:setPosition(interval*k,contentSize.height/2)
        end

    else
        local uiListView_content = ccui.Helper:seekWidgetByName(self.root,"ListView_content")
        local uiPanel_player = uiListView_content:getItem(0)
        uiPanel_player:retain()
        uiListView_content:removeAllItems()
        local color = cc.c3b(0,0,0)
        local refuseName = ""
        local advocateName = ""
        local isSwitch = true
        for i = 1, count do
            if data.dwUserIDALL[i] ~= 0 and player ~= nil and player[i-1] ~= nil then
                local item = uiPanel_player:clone()
                uiListView_content:pushBackCustomItem(item)
                local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
                uiText_name:setTextColor(cc.c3b(0,0,0))
                uiText_name:setString(data.szNickNameALL[i])
                uiText_name:setFontName("fonts/DFYuanW7-GB2312.ttf")
                local uiText_tongyi = ccui.Helper:seekWidgetByName(item,"Text_tongyi")
                uiText_tongyi:setFontName("fonts/DFYuanW7-GB2312.ttf")
                if data.cbDisbandeState[i] == 1 then
                    uiText_tongyi:setString("同意")
                    uiText_tongyi:setTextColor(cc.c3b(255,255,0))
                    if data.wAdvocateDisbandedID == i-1 then
                        advocateName = data.szNickNameALL[i]
                    end
                elseif data.cbDisbandeState[i] == 2 then
                    uiText_tongyi:setString("拒绝")
                    uiText_tongyi:setTextColor(cc.c3b(255,255,0))
                    refuseName = data.szNickNameALL[i]
                    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.RemoveSelf:create()))
                    require("common.MsgBoxLayer"):create(2,nil,string.format("%s拒绝解散房间",data.szNickNameALL[i])) 
                    return
                else
                    if data.dwUserIDALL[i] == UserData.User.userID then
                        uiPanel_btn:setVisible(true)
                    end
                    uiText_tongyi:setString("等待中")
                    uiText_tongyi:setTextColor(cc.c3b(0,128,0))
                end     
            end 
        end

    end



end

return DissolutionLayer
    