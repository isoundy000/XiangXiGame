local StaticData = require("app.static.StaticData")
local GameCommon = require("game.puke.GameCommon") 
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Bit = require("common.Bit")
local Common = require("common.Common")
local Base64 = require("common.Base64")
local LocationSystem = require("common.LocationSystem")
local Default = require("common.Default")
local UserData = require("app.user.UserData")
local GameDesc = require("common.GameDesc")

local TableLayer = class("TableLayer",function()
    return ccui.Layout:create()
end)

function TableLayer:create(root)
    local view = TableLayer.new()
    view:onCreate(root)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit() 
        end  
    end  
    view:registerScriptHandler(onEventHandler)
    return view
end

function TableLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
end

function TableLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
end

function TableLayer:onCreate(root)
    self.root = root
    return true
end

function TableLayer:doAction(action,pBuffer)
    if action == NetMsgId.REC_SUB_S_SEND_CARD then
        local wChairID = pBuffer.wChairID
        self:setHandCard(wChairID,pBuffer.cbCardData)
        self:showHandCard(wChairID,1)        
        for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
            if GameCommon.player[i] ~= nil  and i ~= wChairID then
                if  GameCommon.gameConfig.bBankerType == 1 then 
                    self:showHandPBCard(i,2)   
                else
                    self:showHandPBCard(i,1)   
                end 
            end 
        end 
     
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD then
        local wChairID = pBuffer.wChairID
        self:setHandCard(wChairID,pBuffer.cbCardData)
        -- if not self:isLightCardType() then
            self:showHandCard(wChairID,3)
        -- end
        for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
            if GameCommon.player[i] ~= nil  and i ~= wChairID then
                self:showHandPBCard(i,3)
            end 
        end 
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

    elseif action == NetMsgId.REC_SUB_S_BETTING then
        local wChairID = pBuffer.wChairID
        self:showCountDown(2)
        if GameCommon:getRoleChairID() ~= GameCommon.wBankerUser then
            local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
            uiPanel_betting:setVisible(true)
            local uiListView_betting = ccui.Helper:seekWidgetByName(self.root,"ListView_betting")
            uiListView_betting:removeAllItems()
            local tableBettingType = {1,2,3,4}
            if GameCommon.gameConfig.bBettingType == 2 then
                tableBettingType = {5,6,7,8}
            elseif GameCommon.gameConfig.bBettingType == 3 then
                tableBettingType = {1,2}
            elseif GameCommon.gameConfig.bBettingType == 4 then
                tableBettingType = {2,4}
            elseif GameCommon.gameConfig.bBettingType == 5 then
                tableBettingType = {3,6}
            elseif GameCommon.gameConfig.bBettingType == 6 then
                tableBettingType = {4,8}
            elseif GameCommon.gameConfig.bBettingType == 7 then
                tableBettingType = {5,10}
            end
            if wChairID == GameCommon:getRoleChairID() then
                if GameCommon.gameConfig.bBettingType == 1 then
                    table.insert(tableBettingType,#tableBettingType+1,5)
                    table.insert(tableBettingType,#tableBettingType+1,10)
                    table.insert(tableBettingType,#tableBettingType+1,20)
                elseif GameCommon.gameConfig.bBettingType == 2 then
                    table.insert(tableBettingType,#tableBettingType+1,10)
                    table.insert(tableBettingType,#tableBettingType+1,20)
                elseif GameCommon.gameConfig.bBettingType == 3 then
                    table.insert(tableBettingType,#tableBettingType+1,5)
                    table.insert(tableBettingType,#tableBettingType+1,10)
                elseif GameCommon.gameConfig.bBettingType == 4 then
                    table.insert(tableBettingType,#tableBettingType+1,10)
                    table.insert(tableBettingType,#tableBettingType+1,20)
                elseif GameCommon.gameConfig.bBettingType == 5 then
                    table.insert(tableBettingType,#tableBettingType+1,15)
                    table.insert(tableBettingType,#tableBettingType+1,30)
                elseif GameCommon.gameConfig.bBettingType == 6 then
                    table.insert(tableBettingType,#tableBettingType+1,20)
                    table.insert(tableBettingType,#tableBettingType+1,40)
                elseif GameCommon.gameConfig.bBettingType == 7 then
                    table.insert(tableBettingType,#tableBettingType+1,25)
                    table.insert(tableBettingType,#tableBettingType+1,50)
                end
            end
            for key, var in pairs(tableBettingType) do
            	local img = string.format("puke/table/pukenew_scorebtn_%d.png",var)
            	if (GameCommon.gameConfig.bBettingType == 1 or GameCommon.gameConfig.bBettingType == 3 )  and var == 5 then
                    img = "puke/table/pukenew_scorebtn_5_ex.png"
                elseif GameCommon.gameConfig.bBettingType ~= 7 and var == 10 then
                    img = "puke/table/pukenew_scorebtn_10_ex.png"
            	end
                local item = ccui.Button:create(img,img,img)
                uiListView_betting:pushBackCustomItem(item)
                Common:addTouchEventListener(item,function() 
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_BETTING,"wb",GameCommon:getRoleChairID(),var)
                end)
            end
            if #tableBettingType >= 7 then
                uiListView_betting:setItemsMargin(10)
            elseif #tableBettingType <= 2 then
                uiListView_betting:setItemsMargin(50)
            end
            uiListView_betting:setDirection(ccui.ListViewDirection.horizontal)
            uiListView_betting:refreshView()
            uiListView_betting:setPositionX(uiListView_betting:getParent():getContentSize().width/2-uiListView_betting:getInnerContainerSize().width/2)
            uiListView_betting:setDirection(ccui.ScrollViewDir.none) 
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.REC_SUB_S_BETTING_RESULT then
        local wChairID = pBuffer.wChairID
        if wChairID == GameCommon:getRoleChairID() then
            local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
            uiPanel_betting:setVisible(false)
            local uiListView_betting = ccui.Helper:seekWidgetByName(self.root,"ListView_betting")
            uiListView_betting:removeAllItems()
        end
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_betting = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_betting")
        uiImage_betting:setVisible(true)
        uiImage_betting:loadTexture(string.format("puke/table/pukenew_score_%d.png",pBuffer.cbBetting))
        uiImage_betting:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1.2),cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
    elseif action == NetMsgId.REC_SUB_S_GRAB_BANKER then
        self:showCountDown(1)
        local uiPanel_grabBanker = ccui.Helper:seekWidgetByName(self.root,"Panel_grabBanker")
        uiPanel_grabBanker:setVisible(true)
        local uiListView_grabBanker = ccui.Helper:seekWidgetByName(self.root,"ListView_grabBanker")
        uiListView_grabBanker:removeAllItems()
        for i = 1, GameCommon.gameConfig.bMultiple do
            local img = string.format("puke/table/pukenew_cellbtn_%d.png",i)
            local item = ccui.Button:create(img,img,img)
            uiListView_grabBanker:pushBackCustomItem(item)
            Common:addTouchEventListener(item,function() 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_GRAB_BANKER,"wb",GameCommon:getRoleChairID(),i)
            end)
        end
        uiListView_grabBanker:setDirection(ccui.ListViewDirection.horizontal)
        uiListView_grabBanker:refreshView()
        uiListView_grabBanker:setPositionX(uiListView_grabBanker:getParent():getContentSize().width/2-uiListView_grabBanker:getInnerContainerSize().width/2)
        uiListView_grabBanker:setDirection(ccui.ScrollViewDir.none) 

        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT then
        local wChairID = pBuffer.wChairID
        if wChairID == GameCommon:getRoleChairID() then
            local uiPanel_grabBanker = ccui.Helper:seekWidgetByName(self.root,"Panel_grabBanker")
            uiPanel_grabBanker:setVisible(false)
            local uiListView_grabBanker = ccui.Helper:seekWidgetByName(self.root,"ListView_grabBanker")
            uiListView_grabBanker:removeAllItems()
        end
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
        uiImage_grabBanker:setVisible(true)
        uiImage_grabBanker:loadTexture(string.format("puke/table/pukenew_cell_%d.png",pBuffer.bMultiple))
        uiImage_grabBanker:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1.2),cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
    elseif action == NetMsgId.REC_SUB_S_SHOW_RESULT then
        local wChairID = pBuffer.wChairID
        if wChairID == GameCommon:getRoleChairID() then
            local uiButton_show = ccui.Helper:seekWidgetByName(self.root,"Button_show")
            uiButton_show:setVisible(false)
            local Button_rubCard = ccui.Helper:seekWidgetByName(self.root,"Button_rubCard")
            Button_rubCard:setVisible(false)
            local turnCardNode = self:getChildByName('turnCardNode')
            if turnCardNode then
                turnCardNode:removeFromParent()
            end       
            local uiPanel_chuopai = ccui.Helper:seekWidgetByName(self.root,"Panel_chuopai")
            uiPanel_chuopai:setVisible(false)
            uiPanel_chuopai:removeAllChildren()
        end

        self:setHandCard(wChairID,pBuffer.cbCardData)
        self:showHandCard(wChairID,2,pBuffer)
        GameCommon:playAnimation(self.root, pBuffer.cbValueType,pBuffer.wChairID)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.REC_SUB_S_SHOW_TIPS then
        self:showCountDown(3)
        local uiButton_show = ccui.Helper:seekWidgetByName(self.root,"Button_show")
        uiButton_show:setVisible(true)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
        if self:isLightCardType() then
            local Button_rubCard = ccui.Helper:seekWidgetByName(self.root,"Button_rubCard")
            Button_rubCard:setVisible(true)
            Button_rubCard:setEnabled(true)
        end
    elseif action == NetMsgId.REC_SUB_S_GAME_END then
        local wChairID = pBuffer.wChairID
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",viewID))
        local uiTextAtlasScore = nil
        if pBuffer.lGameScore > 0 then
            if wChairID == GameCommon:getRoleChairID() then
                GameCommon:playAnimation(self.root, "赢",pBuffer.wChairID)
            end
            uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/fonts_6.png",26,43,'0')
        else
            uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/fonts_7.png",26,43,'0')
        end
        uiPanel_tipsCard:addChild(uiTextAtlasScore)
        uiTextAtlasScore:setPosition(uiPanel_scorePos:getPosition())  
        uiTextAtlasScore:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.ScaleTo:create(0.5,1.2),cc.ScaleTo:create(0.5,1.0))) 
        
    else
    
    end
	
end

function TableLayer:showCountDown(cbWaitType)
    local uiImage_countdown = ccui.Helper:seekWidgetByName(self.root,"Image_countdown")
    uiImage_countdown:setVisible(true)
    local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:setString(4)
    local function onEventTime(sender,event)
        local currentTime = tonumber(uiAtlasLabel_countdownTime:getString())
        currentTime = currentTime - 1
        if currentTime < 0 then
            currentTime = 0
        end
        uiAtlasLabel_countdownTime:setString(tostring(currentTime))
    end
    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime))))    
    local uiImage_waitType = ccui.Helper:seekWidgetByName(self.root,"Image_waitType")
    uiImage_waitType:setVisible(true)
    if cbWaitType == 1 then
        uiImage_waitType:loadTexture("puke/table/pukenew_4.png")
        local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
        uiAtlasLabel_countdownTime:removeAllChildren()
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/qiangzhuangdonghua/qiangzhuangdonghua.ExportJson")
        local armature = ccs.Armature:create("qiangzhuangdonghua")
        uiAtlasLabel_countdownTime:addChild(armature)
        armature:getAnimation():playWithIndex(0)
        armature:setPosition(armature:getParent():getContentSize().width/2,-40)
    elseif cbWaitType == 2 then
        uiImage_waitType:loadTexture("puke/table/pukenew_5.png")
        local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
        uiAtlasLabel_countdownTime:removeAllChildren()
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/yafendonghua/yafendonghua.ExportJson")
        local armature = ccs.Armature:create("yafendonghua")
        uiAtlasLabel_countdownTime:addChild(armature)
        armature:getAnimation():playWithIndex(0)
        armature:setPosition(armature:getParent():getContentSize().width/2,-40)
    else
        uiImage_waitType:loadTexture("puke/table/pukenew_15.png")
        local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
        uiAtlasLabel_countdownTime:removeAllChildren()
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/liangpaidonghua/liangpaidonghua.ExportJson")
        local armature = ccs.Armature:create("liangpaidonghua")
        uiAtlasLabel_countdownTime:addChild(armature)
        armature:getAnimation():playWithIndex(0)
        armature:setPosition(armature:getParent():getContentSize().width/2,-40)
    end
end

-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function TableLayer:setHandCard(wChairID,cbCardData)
    GameCommon.player[wChairID].cbCardData = cbCardData
end

--更新手牌
function TableLayer:showHandCard(wChairID,effectsType,pBuffer)
    if GameCommon.player[wChairID].cbCardData == nil then
        return
    end
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    uiPanel_handCard:removeAllChildren()
    local pos = cc.p(uiPanel_handCard:getPosition())
    local size = uiPanel_handCard:getContentSize()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local anchorPoint = uiPanel_handCard:getAnchorPoint()
    local index = 0
    local time = 0.1
    local offset = 15
    local cardScale = 0.8
    if viewID ~= 1 then
        cardScale = 0.5
    end
    local cardWidth = 161 * cardScale
    local cardHeight = 231 * cardScale
    local stepX = cardWidth*0.35
    local stepY = cardHeight
    local beganX = 0
    --effectsType 0设置  1发牌  2亮牌 3 自己手牌外加搓牌（明牌抢庄特有）-- 4 其他人遮罩的牌  暂定
     if viewID == 1 and effectsType == 2 then
        beganX = (size.width - (stepX*4+cardWidth))/2
    elseif viewID == 1 then
        stepX = cardWidth
    end
    for i = 1, 5 do
        local data = GameCommon.player[wChairID].cbCardData[i]
        if data == 0 then 
            return
        end 
        local Scale_x = 1
        local Scale_y = 1
        local card = GameCommon:getCardNode(data)
        if effectsType == 3 and i == 5 then 
            card = GameCommon:getCardNode(0)
            Scale_x = 0.96
            Scale_y = 0.93
        end 
        uiPanel_handCard:addChild(card) 
        card:setScale(cardScale* Scale_x,cardScale* Scale_y)
        card:setAnchorPoint(cc.p(0,0))
        card.data = data
        if effectsType == 1 then
            local pt = cc.p(beganX + (i-1)*stepX, 0)
            card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
            card.pt = pt
            card:stopAllActions()
            card:runAction(cc.MoveTo:create(time,pt))
            
        elseif effectsType == 2 then  
            local pt = cc.p(beganX + (i-1)*stepX, 0)
            if pBuffer.cbValueType == nil then
                
            elseif pBuffer.cbValueType >= GameCommon.NiuType_1 and pBuffer.cbValueType <= GameCommon.NiuType_Niu then
                if i >= 4 then
                    pt.x = pt.x + offset
                end
            elseif pBuffer.cbValueType == GameCommon.NiuType_Bomb then
                if i >= 5 then
                    pt.x = pt.x + offset
                end
            elseif pBuffer.cbValueType == GameCommon.NiuType_NULL then
                if i >= 2 then
                    pt.x = pt.x + offset
                end
            elseif pBuffer.cbValueType == GameCommon.NiuType_Gourd then
                if i >= 4 then
                    pt.x = pt.x + offset
                end
            else
            
            end

            if pBuffer.cbLastCardData == data then
                pt.y = 10
                local tipsImage = ccui.ImageView:create('puke/table/sign3.png')
                card:addChild(tipsImage)
                tipsImage:setPosition(92,154)
            end 
            if viewID == 1 then
                local ptTemp = cc.p(0 + (i-1)*cardWidth, 0)
                card:setPosition(ptTemp)
                card.pt = pt
                card:stopAllActions()
                card:runAction(cc.MoveTo:create(time,pt))
            else
                card.pt = pt
                card:setPosition(card.pt)
            end
        else
            local pt = cc.p(beganX + (i-1)*stepX, 0)
            card.pt = pt
            if effectsType == 3 and i == 5 then 
                card:setPosition(cc.p(0,360))--card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, visibleSize.height/2))
                card:runAction(cc.MoveTo:create(time,pt))
            else
                card:setPosition(pt)
            end            
        end
    end
end

--更新手牌背景
function TableLayer:showHandPBCard(wChairID,effectsType)
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    if viewID  == 1 then
        return
    end 
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))

    if effectsType ~= 3 then 
        uiPanel_handCard:removeAllChildren()
    end 

    local pos = cc.p(uiPanel_handCard:getPosition())
    local size = uiPanel_handCard:getContentSize()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local anchorPoint = uiPanel_handCard:getAnchorPoint()
    local index = 0
    local time = 0.1
    local offset = 15
    local cardScale = 0.5
    -- if viewID ~= 1 then
    --     cardScale = 0.5
    -- end
    local cardWidth = 161 * cardScale
    local cardHeight = 231 * cardScale
    local stepX = cardWidth*0.35
    local stepY = cardHeight
    local beganX = 0
    local card = nil 
    --effectsType 1 发五张  2  发4张  3 发 1张
    if effectsType == 1 then 
        for i = 1, 5 do
            card = GameCommon:getCardNode(0)
            uiPanel_handCard:addChild(card) 
            card:setScale(cardScale*0.96,cardScale*0.93)
            card:setAnchorPoint(cc.p(0,0))
            card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
            local pt = cc.p(beganX + (i-1)*stepX, 0)  
            card.pt = pt
            card:stopAllActions()
            card:runAction(cc.MoveTo:create(0.2,pt))   
            
        end 
    elseif effectsType == 2 then 
            for i = 1, 4 do
                card = GameCommon:getCardNode(0)
                uiPanel_handCard:addChild(card) 
                card:setScale(cardScale*0.96,cardScale*0.93)
                card:setAnchorPoint(cc.p(0,0))
                card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
                local pt = cc.p(beganX + (i-1)*stepX, 0)  
                card.pt = pt
                card:stopAllActions()
                card:runAction(cc.MoveTo:create(0.2,pt))                 
            end 
    
    elseif effectsType == 3 then   

        card = GameCommon:getCardNode(0)
        uiPanel_handCard:addChild(card) 
        card:setScale(cardScale*0.96,cardScale*0.93)
        card:setAnchorPoint(cc.p(0,0))
        card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
        local pt = cc.p(beganX + (5-1)*stepX, 0)  
        card.pt = pt
        card:stopAllActions()
        card:runAction(cc.MoveTo:create(0.1,pt))                    
    end 

end 

function TableLayer:initUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    require("common.Common"):playEffect("game/pipeidonghua.mp3")
    --背景层
    -- local uiImage_watermark = ccui.Helper:seekWidgetByName(self.root,"Image_watermark")
    -- uiImage_watermark:ignoreContentAdaptWithSize(true)
    -- uiImage_watermark:loadTexture(StaticData.Channels[CHANNEL_ID].icon)
    local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
    uiText_desc:setString("")
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%02d-%02d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
    end),cc.DelayTime:create(1))))
    --卡牌层

    --动画层
    local uiImage_countdown = ccui.Helper:seekWidgetByName(self.root,"Image_countdown")
    uiImage_countdown:setVisible(false)
    local bPlayerCount = nil    
    -- if GameCommon.gameConfig.bPlayerCount ~= nil then
    --     bPlayerCount = GameCommon.gameConfig.bPlayerCount 
    -- elseif GameCommon.tableConfig.tableParameter ~= nil then
    --     bPlayerCount = GameCommon.tableConfig.tableParameter.bPlayerCount
    -- else
    --    if  GameCommon.tableConfig.wKindID == 51 then 
    --         bPlayerCount =  6
    --    else
            bPlayerCount =  8
    --    end 
    -- end  
    --用户层  tableConfig.tableParameter
    for i = 1, bPlayerCount do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        uiPanel_player:setVisible(false)
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        uiImage_avatar:loadTexture("common/hall_avatar.png")
        uiImage_avatar:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then
                for key, var in pairs(GameCommon.player) do
                    if GameCommon:getViewIDByChairID(var.wChairID) == i then
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_PLAYER_INFO,"d",var.dwUserID)
                        break
                    end
                end
            end
        end)    
        local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        local uiImage_laba = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_laba")
        uiImage_laba:setVisible(false)
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
        uiImage_banker:setVisible(false)
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
        uiText_name:setString("")
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        uiText_score:setString("")
        local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
        uiImage_ready:setVisible(false)
        local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
        uiImage_chat:setVisible(false)
        local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
        uiImage_grabBanker:setVisible(false)
        local uiImage_betting = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_betting")
        uiImage_betting:setVisible(false)
        local uiImage_offline = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_offline")  
        uiImage_offline:setVisible(false)
    end

    --UI层
    local uiButton_start = ccui.Helper:seekWidgetByName(self.root,"Button_start")
    uiButton_start:setVisible(false)
    Common:addTouchEventListener(uiButton_start,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_START_GAME,"")
    end)

    -- 
    local uiPanel_chuopai = ccui.Helper:seekWidgetByName(self.root,"Panel_chuopai")
    uiPanel_chuopai:setVisible(false)
    uiPanel_chuopai:removeAllChildren()
    --     uiPanel_chuopai:setVisible(false)
    --     -- uiPanel_chuopai:setEnabled(false)
    -- end
    -- Common:playPopupAnim(uiPanel_chuopai, nil, callback)
    --搓牌
    local Button_rubCard = ccui.Helper:seekWidgetByName(self.root,"Button_rubCard")
    Button_rubCard:setVisible(false)
    Common:addTouchEventListener(Button_rubCard,function() 
        -- local turnCardNode = require('common.RubCardLayer')(2)
        -- if turnCardNode then
        --     self:addChild(turnCardNode)
        --     turnCardNode:setName('turnCardNode')
        -- end
        Button_rubCard:setEnabled(false)

        local myRoleData = {}
        print('MyRole userid = ', UserData.User.userID)
        dump(GameCommon.player, 'PlayerInfo::')
        for i,v in pairs(GameCommon.player or {}) do
            if tonumber(v.dwUserID) == tonumber(UserData.User.userID) then
                myRoleData = v
                break
            end
        end
    
        local handCardArr = myRoleData.cbCardData
        if not handCardArr then
            printError('player card info no find')
            return
        end
        local pos = cc.p(uiPanel_chuopai:getPosition())
    
        local data = handCardArr[#handCardArr]
        local value = Bit:_and(data,0x0F)
        local color = Bit:_rshift(Bit:_and(data,0xF0),4)
        local blackorred = color%2
        local cardIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_PukeCardBg,0)
        local szBack = string.format('puke/table/puke_bg%d.png', cardIndex)
        local frontPath = string.format('puke/card/cardcuopai/puke_%d_%d',color,value)
        local childColor = string.format('puke/card/cardcuopai/%d_Small', color)
        local childPath = string.format('puke/card/cardcuopai/%d_black',value)        
        if blackorred == 1 then 
            childPath = string.format('puke/card/cardcuopai/%d_red',value)
        end 
        local params = {
            frontPath = frontPath,
            backPath = 'puke/card/cardcuopai/puke_bg0',
            childPath = childPath,
            childColor = childColor,
            showEndCall = function()
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
                    uiPanel_chuopai:removeAllChildren()  
                    uiPanel_chuopai:setVisible(false) 
                    -- uiPanel_chuopai:setEnabled(false)
                    local wChairID = GameCommon:getRoleChairID()
                    self:showHandCard(wChairID,0)
                    Button_rubCard:setVisible(false)
                end)))
             end,
            pos = pos,
            
        }
        local Director = cc.Director:getInstance()
        local WinSize = Director:getWinSize()
        local rubbingCard = require("app.views.RubbingCards").new(params)
        rubbingCard:setScale(1.3)
        rubbingCard:setPositionX(-162*1.3)
        uiPanel_chuopai:addChild(rubbingCard)
        local tipsImage = ccui.ImageView:create('puke/table/pukenew_17.png')
        uiPanel_chuopai:addChild(tipsImage)
        tipsImage:setPosition(pos.x*1.6, pos.y)
        tipsImage:setName('tipsImage')
        tipsImage:setScale(0.8)
        uiPanel_chuopai:setVisible(true)
        uiPanel_chuopai:setEnabled(true)
    end)

    --亮牌
    local uiButton_show = ccui.Helper:seekWidgetByName(self.root,"Button_show")
    uiButton_show:setVisible(false)
    Common:addTouchEventListener(uiButton_show,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOW,"")
        uiButton_show:setVisible(false)
        Button_rubCard:setVisible(false)
    end)

    local uiPanel_grabBanker = ccui.Helper:seekWidgetByName(self.root,"Panel_grabBanker")
    uiPanel_grabBanker:setVisible(false)
    local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
    uiPanel_betting:setVisible(false)
    local uiButton_menu = ccui.Helper:seekWidgetByName(self.root,"Button_menu")
    local uiPanel_function = ccui.Helper:seekWidgetByName(self.root,"Panel_function")
    uiPanel_function:setEnabled(false)
    Common:addTouchEventListener(uiButton_menu,function() 
        uiPanel_function:stopAllActions()
        uiPanel_function:runAction(cc.Sequence:create(cc.MoveTo:create(0.2,cc.p(-99,0)),cc.CallFunc:create(function(sender,event) 
            uiPanel_function:setEnabled(true)
        end)))
        uiButton_menu:stopAllActions()
        uiButton_menu:runAction(cc.ScaleTo:create(0.2,0))
    end)
    uiPanel_function:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_function:stopAllActions()
            uiPanel_function:runAction(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
                uiPanel_function:setEnabled(false)
            end),cc.MoveTo:create(0.2,cc.p(0,0))))
            uiButton_menu:stopAllActions()
            uiButton_menu:runAction(cc.ScaleTo:create(0.2,1))
        end
    end)  
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_Pukeliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Pukeliangdu,0)
    if UserDefault_Pukeliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_settings"),function() 
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SettingsLayer"))
    end)
    local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    uiButton_expression:setPressedActionEnabled(true)
    local function onEventExpression(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.GameChatLayer"):create(GameCommon.tableConfig.wKindID,function(index) 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_EXPRESSION,"ww",index,GameCommon:getRoleChairID())
            end, 
            function(index,contents)
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SEND_CHAT,"dwbnsdns",
                    GameCommon:getRoleChairID(),index,GameCommon:getUserInfo(GameCommon:getRoleChairID()).cbSex,32,"",string.len(contents),string.len(contents),contents)
            end)
        end
    end
    uiButton_expression:addTouchEventListener(onEventExpression)
--    uiButton_expression:setVisible(false)
    local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
    Common:addTouchEventListener(uiButton_ready,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"o",false)
    end) 
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    Common:addTouchEventListener(uiButton_Invitation,function() 
        local currentPlayerCount = 0
        for key, var in pairs(GameCommon.player) do
            currentPlayerCount = currentPlayerCount + 1
        end
        local player = "("
        for key, var in pairs(GameCommon.player) do
            if key == 0 then
                player = player..var.szNickName
            else
                player = player.."、"..var.szNickName
            end
        end
        player = player..")"
        local data = clone(UserData.Share.tableShareParameter[3])
        data.dwClubID = GameCommon.tableConfig.dwClubID
        data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[GameCommon.tableConfig.wKindID].name,
            GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wTableNumber,
            GameCommon.gameConfig.bPlayerCount,GameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
        data.szShareContent = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig).." (点击加入游戏)"
        data.szShareUrl = string.format(data.szShareUrl, GameCommon.tableConfig.szGameID)
        if GameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
            data.cbTargetType = Bit:_xor(data.cbTargetType,0x20)
        end
        require("app.MyApp"):create(data):createView("ShareLayer")
    end)
    local uiButton_disbanded = ccui.Helper:seekWidgetByName(self.root,"Button_disbanded")
    Common:addTouchEventListener(uiButton_disbanded,function() 
        require("common.MsgBoxLayer"):create(1,nil,"是否确定解散房间？",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
        end)
    end)
    local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
    Common:addTouchEventListener(uiButton_cancel,function() 
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end)  
    local uiButton_out = ccui.Helper:seekWidgetByName(self.root,"Button_out")
    Common:addTouchEventListener(uiButton_out,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定离开房间?\n房主离开意味着房间被解散",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_LEAVE_TABLE_USER,"")
        end)
    end) 
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end)
    end)
    
    local uiButton_SignOut = ccui.Helper:seekWidgetByName(self.root,"Button_SignOut")
    Common:addTouchEventListener(uiButton_SignOut,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end)
    end) 
    
    if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9  then
    else
        uiButton_SignOut:setVisible(false)
        uiButton_out:setPositionX(visibleSize.width*0.36)       
        uiButton_Invitation:setPositionX(visibleSize.width*0.64)  
    end 
    --结算层
    local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
    uiPanel_end:setVisible(false)
    --灯光层
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")    
    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
        self:addVoice()
        uiButton_cancel:setVisible(false)
        if GameCommon.tableConfig.wCurrentNumber > 0 then
            uiButton_Invitation:setVisible(false)
            uiButton_out:setVisible(false)
            uiButton_SignOut:setVisible(false)
        end 
        uiText_title:setString(string.format("%s 房间号:%d 局数:%d/%d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))

        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
        local waitArmature=ccs.Armature:create("dengdaihaoyou")
        waitArmature:setPosition(-179.2,-158)        
        if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
            waitArmature:setPosition(0,-158)
        end 
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_Invitation:addChild(waitArmature)   

    elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then            
        self:addVoice()
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        if GameCommon.gameState == GameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
        else
            uiButton_voice:setVisible(false)
            uiButton_expression:setVisible(false)
        end 
        if GameCommon.tableConfig.cbLevel == 2 then
            uiText_title:setString(string.format("%s 中级场 倍率 %d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wCellScore))
        elseif GameCommon.tableConfig.cbLevel == 3 then
            uiText_title:setString(string.format("%s 高级场 倍率 %d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wCellScore))
        else
            uiText_title:setString(string.format("%s 初级场 倍率 %d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wCellScore))
        end
        self:drawnout() 
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
        
    elseif GameCommon.tableConfig.nTableType == TableType_SportsRoom then            
        self:addVoice()
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        if GameCommon.gameState == GameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
            if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
                uiButton_Invitation:setVisible(false)
            else
                uiButton_Invitation:setVisible(true)
            end
        else
            uiButton_voice:setVisible(false)
            uiButton_expression:setVisible(false)
        end 
        uiText_title:setString(string.format("%s 竞技场",StaticData.Games[GameCommon.tableConfig.wKindID].name))
        self:drawnout() 
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
    else
        local uiPanel_ui = ccui.Helper:seekWidgetByName(self.root,"Panel_ui")
        uiPanel_ui:setVisible(false)
        uiText_title:setString(string.format("%s 牌局回放",StaticData.Games[GameCommon.tableConfig.wKindID].name))
    end
end

function TableLayer:drawnout()
    local uiImage_countdown = ccui.Helper:seekWidgetByName(self.root,"Image_countdown")
    uiImage_countdown:setVisible(true)
    local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:setString(8)
    local function onEventTime(sender,event)
        local currentTime = tonumber(uiAtlasLabel_countdownTime:getString())
        currentTime = currentTime - 1
        if currentTime < 0 then
            currentTime = 0
        end
        uiAtlasLabel_countdownTime:setString(tostring(currentTime))
        if currentTime == 0 then 
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end 
    end
    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime))))  
end 

function TableLayer:updateGameState(state)
    GameCommon.gameState = state 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if state == GameCommon.GameState_Init then
        
    elseif state == GameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        local uiButton_start = ccui.Helper:seekWidgetByName(self.root,"Button_start")
        uiButton_start:setVisible(false)
        local bPlayerCount = nil    
        -- if GameCommon.gameConfig.bPlayerCount ~= nil then
        --     bPlayerCount = GameCommon.gameConfig.bPlayerCount 
        -- elseif GameCommon.tableConfig.tableParameter ~= nil then
        --     bPlayerCount = GameCommon.tableConfig.tableParameter.bPlayerCount
        -- else
        --    if  GameCommon.tableConfig.wKindID == 51 then 
        --         bPlayerCount =  6
        --    else
                bPlayerCount =  8
        --    end 
        -- end 
        for i = 1, bPlayerCount do
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            uiImage_ready:setVisible(false)
            if GameCommon.player[i-1] ~= nil then
                GameCommon.player[i-1].bReady = false
            end 
        end      
    elseif state == GameCommon.GameState_Over then
        UserData.Game:addGameStatistics(GameCommon.tableConfig.wKindID)
        local uiImage_countdown = ccui.Helper:seekWidgetByName(self.root,"Image_countdown")
        uiImage_countdown:setVisible(false)
    else
    
    end
end

--语音
function TableLayer:addVoice()
    self.tableVoice = {}
    local startVoiceTime = 0
    local maxVoiceTime = 15
    local intervalTimePackage = 0.1
    local fileName = "temp_voice.mp3"
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local animVoice = cc.CSLoader:createNode("VoiceNode.csb")
    self:addChild(animVoice,120)
    local root = animVoice:getChildByName("Panel_root")
    local uiPanel_recording = ccui.Helper:seekWidgetByName(root,"Panel_recording")
    local uiPanel_cancel = ccui.Helper:seekWidgetByName(root,"Panel_cancel")
    local uiText_surplus = ccui.Helper:seekWidgetByName(root,"Text_surplus")
    animVoice:setVisible(false)

    --重置状态
    local duration = 0
    local function resetVoice()
        startVoiceTime = 0
        animVoice:stopAllActions()
        animVoice:setVisible(false)
        uiPanel_recording:setVisible(true)

        local uiImage_pro = ccui.Helper:seekWidgetByName(root,"Image_pro")
        uiImage_pro:removeAllChildren()
        local volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music",1)
        cc.SimpleAudioEngine:getInstance():setMusicVolume(volumeMusic)
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
        uiButton_voice:removeAllChildren()
        local node = require("common.CircleLoadingBar"):create("game/tablenew_23.png")
        node:setColor(cc.c3b(0,0,0))
        uiButton_voice:addChild(node)
        node:setPosition(node:getParent():getContentSize().width/2,node:getParent():getContentSize().height/2)
        node:start(1)
        uiButton_voice:setEnabled(false)
        uiButton_voice:stopAllActions()
        uiButton_voice:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
            uiButton_voice:setEnabled(true)
        end)))
    end

    root:setTouchEnabled(true)
    root:addTouchEventListener(function(sender,event) 
        UserData.Game:cancelVoice()
        resetVoice() 
    end)

    local function onEventSendVoic(event)
        if self.root == nil then
            return
        end
        if cc.PLATFORM_OS_ANDROID == cc.Application:getInstance():getTargetPlatform() then
            if event == nil or string.len(event) <= 0 then
                return
            else
                event = Base64.decode(event)
            end
            local file = io.open(FileDir.dirVoice..fileName,"wb+")
            file:write(event)
            file:close()
        end
        if cc.FileUtils:getInstance():isFileExist(FileDir.dirVoice..fileName) == false then
            print("没有找到录音文件",FileDir.dirVoice..fileName)
            return
        end
        local fp = io.open(FileDir.dirVoice..fileName,"rb")
        local fileData = fp:read("*a")
        fp:close()

        local data = {}
        data.chirID = GameCommon:getRoleChairID()
        data.time = duration
        data.file = string.format("%d_%d.mp3",os.time(),UserData.User.userID)

        local fp = io.open(FileDir.dirVoice..data.file,"wb+")
        fp:write(fileData)
        fp:close()
        table.insert(self.tableVoice,#self.tableVoice + 1,data) 

        cc.FileUtils:getInstance():removeFile(FileDir.dirVoice..fileName)   --windows test

        local fileSize = string.len(fileData)
        local packSize = 1024
        local additional = fileSize%packSize
        if additional > 0 then
            additional = 1
        else
            additional = 0
        end
        local packCount = math.floor(fileSize/packSize) + additional
        local currentPos = 0
        for i = 1 , packCount do
            local periodData = string.sub(fileData,1,packSize)
            fileData = string.sub(fileData,packSize + 1)
            local periodSize = string.len(periodData)
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE,"wwwdddnsnf",GameCommon:getRoleChairID(),packCount,i,data.time,fileSize,periodSize,32,data.file,periodSize,periodData)
        end

    end

    local function onEventVoice(sender,event)
        if event == ccui.TouchEventType.began then
            startVoiceTime = 0
            uiButton_voice:setEnabled(false)
            animVoice:setVisible(true)
            cc.SimpleAudioEngine:getInstance():setMusicVolume(0) 
            cc.SimpleAudioEngine:getInstance():setEffectsVolume(0) 
            uiPanel_recording:setVisible(true)
            startVoiceTime = os.time()
            UserData.Game:startVoice(FileDir.dirVoice..fileName,maxVoiceTime,onEventSendVoic)

            local node = require("common.CircleLoadingBar"):create("common/yuying02.png")
            local uiImage_pro = ccui.Helper:seekWidgetByName(root,"Image_pro")
            uiImage_pro:removeAllChildren()
            uiImage_pro:addChild(node)
            node:setPosition(node:getParent():getContentSize().width/2,node:getParent():getContentSize().height/2)
            node:start(maxVoiceTime)

            local currentTime = 0
            uiText_surplus:stopAllActions()
            uiText_surplus:setString(string.format("还剩%d秒",maxVoiceTime - currentTime))
            uiText_surplus:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
                currentTime = currentTime + 1
                if currentTime > maxVoiceTime then
                    uiText_surplus:stopAllActions()
                    return
                end
                uiText_surplus:setString(string.format("还剩%d秒",maxVoiceTime - currentTime))
            end))))

        elseif event == ccui.TouchEventType.ended then
            if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
                UserData.Game:cancelVoice()
                resetVoice()
                return
            end
            duration = os.time() - startVoiceTime
            resetVoice()
            UserData.Game:overVoice()
            --onEventSendVoic() --windows test
        elseif event == ccui.TouchEventType.canceled then   
            if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
                resetVoice()
                return
            end
            resetVoice()
            UserData.Game:cancelVoice()
        end
    end
    uiButton_voice:addTouchEventListener(onEventVoice)
    local function onEventPlayVoice(sender,event)
        if #self.tableVoice > 0 then
            local data = self.tableVoice[1]
            table.remove(self.tableVoice,1)
            if data.time > maxVoiceTime then
                data.time = maxVoiceTime
            end
            local viewID = GameCommon:getViewIDByChairID(data.chirID)
            local wanjia = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_laba = ccui.Helper:seekWidgetByName(wanjia,"Image_laba")
            local blinks = math.floor(data.time*2)+1
            uiImage_laba:stopAllActions()
            uiImage_laba:runAction(cc.Sequence:create(
                cc.Show:create(),
                cc.CallFunc:create(function(sender,event) 
                    require("common.Common"):playVoice(FileDir.dirVoice..data.file)
                end),
                cc.Blink:create(data.time,blinks) ,
                cc.Hide:create(),
                cc.DelayTime:create(1),
                cc.CallFunc:create(function(sender,event) 
                    cc.FileUtils:getInstance():removeFile(FileDir.dirVoice..data.file) 
                    onEventPlayVoice()
                end)
            ))

        else
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(onEventPlayVoice)))
        end
    end
    onEventPlayVoice()
end

function TableLayer:OnUserChatVoice(event)
    if self.tableVoicePackages == nil then
        self.tableVoicePackages = {}
    end
    if self.tableVoicePackages[event.szFileName] == nil then
        self.tableVoicePackages[event.szFileName] = {}
    end
    self.tableVoicePackages[event.szFileName][event.wPackIndex] = event

    --组包
    if event.wPackCount == #self.tableVoicePackages[event.szFileName] then
        local fileData = ""
        local data = nil
        for key, var in pairs(self.tableVoicePackages[event.szFileName]) do
            fileData = fileData..var.szPeriodData
            if data == nil then
                data = {}
                data.chirID = var.wChairID
                data.time = var.dwTime
                data.file = var.szFileName
            end
        end 
        local fp = io.open(FileDir.dirVoice..data.file,"wb+")
        fp:write(fileData)
        fp:close()
        table.insert(self.tableVoice,#self.tableVoice + 1,data)
        self.tableVoicePackages[event.szFileName] = nil
        print("插入一条语音...",fileData)
    end
end
    
function TableLayer:showPlayerPosition()   -- 显示玩家距离
    require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
end

function TableLayer:showPlayerInfo(infoTbl)       -- 查看玩家信息
    Common:palyButton()
    --require("common.PersonalLayer"):create(GameCommon.tableConfig.wKindID,dwUserID,dwShamUserID)

    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(infoTbl,self):createGame("game.puke.NiuPersonInfor"))
end

function TableLayer:showChat(pBuffer)
    local viewID = GameCommon:getViewIDByChairID(pBuffer.dwUserID)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
    local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_chat")
    uiText_chat:setString(pBuffer.szChatContent)
    uiImage_chat:setVisible(true)
    uiImage_chat:setScale(0)
    uiImage_chat:stopAllActions()
    uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1),cc.DelayTime:create(5),cc.Hide:create()))
    local wKindID = GameCommon.tableConfig.wKindID
    local Chat = nil
    if CHANNEL_ID == 4 or CHANNEL_ID == 5 then 
       Chat = require("common.Chat")[3]
    elseif CHANNEL_ID == 10 or CHANNEL_ID == 11 then
        Chat = require("common.Chat")[0]
    else 
        if wKindID == 33 or wKindID == 34 or wKindID == 35 or wKindID == 36 or wKindID == 37 then
            Chat = require("common.Chat")[1]
        elseif wKindID == 47 or wKindID == 48 or wKindID == 49 then
            Chat = require("common.Chat")[2]
        else    
            Chat = require("common.Chat")[0]
        end
    end
    local data = Chat[pBuffer.dwSoundID]
    if data ~= nil and data.sound[pBuffer.cbSex] ~= "" then
        require("common.Common"):playEffect(data.sound[pBuffer.cbSex])
    end
end

function TableLayer:showExperssion(pBuffer)
	local viewID = GameCommon:getViewIDByChairID(pBuffer.wChairID)
    local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
    local uiPanel_tipsCardPosUser = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
    local filename = ""
    if pBuffer.wIndex == 0 then
        filename = "biaoqing-kaixin"
    elseif pBuffer.wIndex == 1 then
        filename = "biaoqing-shengqi"
    elseif pBuffer.wIndex == 2 then
        filename = "biaoqing-xihuan"
    elseif pBuffer.wIndex == 3 then
        filename = "biaoqing-cool"
    elseif pBuffer.wIndex == 4 then
        filename = "biaoqing-jingdai"
    elseif pBuffer.wIndex == 5 then
        filename = "biaoqing-daku" 
    else
        return
    end
    
    require("common.Common"):playEffect(string.format("expression/sound/%s.mp3",filename))
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(string.format("expression/animation/%s.ExportJson",filename))
    local  armature = ccs.Armature:create(filename)
    uiPanel_tipsCard:addChild(armature)
    armature:setScale(0.4)
    armature:getAnimation():playWithIndex(0)
    armature:setPosition(uiPanel_tipsCardPosUser:getPosition())
    if viewID == 1 then
        armature:setPositionY(armature:getPositionY() + 50)
    end
    armature:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.RemoveSelf:create()))
end

function TableLayer:EVENT_TYPE_SKIN_CHANGE(event)
    local data = event._usedata
    if data ~= 2 then
        return
    end
    --亮度
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_Pukeliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Pukeliangdu,0)
    if UserDefault_Pukeliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
    --牌背
    for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
        local wChairID = i
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            self:showHandCard(wChairID,0)
        end
    end
end

--是否是明牌抢庄
function TableLayer:isLightCardType()
    if GameCommon.gameConfig.bCuopai ~= 1 then --StaticData.Hide[CHANNEL_ID].btn15 == 0  or 
        return false
    end
    
    local tableCnf = GameCommon.tableConfig or {}
    local gameCnf = GameCommon.gameConfig or {}
    printInfo('table card type = %d', tableCnf.wKindID or 0)
    printInfo('game config type = %d', gameCnf.bBankerType or 0)

    local kindCnf = {51, 55, 56, 57, 58, 59}
    for i,v in ipairs(kindCnf) do
        if v == tableCnf.wKindID and gameCnf.bBankerType == 1 then
            return true
        end
    end
    return false
end

--==============================--
--desc:表情互动
--time:2018-08-14 07:40:11
--@wChairID:
--@return 
--==============================--

function TableLayer:getViewWorldPosByChairID(wChairID)
	for key, var in pairs(GameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = GameCommon:getViewIDByChairID(var.wChairID, true)
			local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
			local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
			return uiImage_avatar:getParent():convertToWorldSpace(cc.p(uiImage_avatar:getPosition()))
		end
	end
end

function TableLayer:playSketlAnim(sChairID, eChairID, index,indexEx)

    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil!')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

	local Animation = require("game.puke.Animation")
	local AnimCnf = Animation[24]
	
	if not AnimCnf[index] then
		return
	end
    
    indexEx = indexEx or ''
	local skele_key_name = 'hhhudong_' .. index .. indexEx
	local spos = self:getViewWorldPosByChairID(sChairID)
	local epos = self:getViewWorldPosByChairID(eChairID)
	local image = ccui.ImageView:create(AnimCnf[index].imageFile .. '.png')
	self:addChild(image)
	image:setPosition(spos)
	local moveto = cc.MoveTo:create(0.6, cc.p(epos))
	local callfunc = cc.CallFunc:create(function()
		local path = AnimCnf[index].animFile
		local skeletonNode = cusNode:getChildByName(skele_key_name)
		if not skeletonNode then
			skeletonNode = sp.SkeletonAnimation:create(path .. '.json', path .. '.atlas', 1)
			cusNode:addChild(skeletonNode)
			skeletonNode:setName(skele_key_name)
		end
		skeletonNode:setPosition(epos)
		skeletonNode:setAnimation(0, AnimCnf[index].animName, false)
		skeletonNode:setVisible(true)
		image:removeFromParent()

		skeletonNode:registerSpineEventHandler(function(event)
			skeletonNode:setVisible(false)
		end, sp.EventType.ANIMATION_END)
		
		local soundData = AnimCnf[index]
		local soundFile = ''
		if soundData then
			local sound = soundData.sound
			if sound then
				soundFile = sound[0]
			end
		end
		if soundFile ~= "" then
			require("common.Common"):playEffect(soundFile)
		end
	end)
	image:runAction(cc.Sequence:create(moveto, callfunc))
end

--表情互动
function TableLayer:playSkelStartToEndPos(sChairID, eChairID, index)
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('PDKOpenUserEffect', true) --是否接受别人的互动
	
	if GameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(GameCommon.player or {}) do
				if v.wChairID ~= sChairID then
					self:playSketlAnim(sChairID, v.wChairID, index, v.wChairID)
				end
			end
		else
			self:playSketlAnim(sChairID, eChairID, index,0)
		end
	else
		if self.isOpen then
			if sChairID == eChairID then
				for i, v in pairs(GameCommon.player or {}) do
					if v.wChairID ~= sChairID then
						self:playSketlAnim(sChairID, v.wChairID, index, v.wChairID)
					end
				end
			else
				self:playSketlAnim(sChairID, eChairID, index,0)
			end
		end
	end
end

return TableLayer