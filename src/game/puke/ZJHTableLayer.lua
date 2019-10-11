local StaticData = require("app.static.StaticData")
local ZJHGameCommon = require("game.puke.ZJHGameCommon") 
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
    if action == NetMsgId.REC_SUB_S_SEND_CARD_ZJH then

        self:showCountDown(ZJHGameCommon.gameConfig.wQuitTimer)
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        local uiButton_start = ccui.Helper:seekWidgetByName(self.root,"Button_start")
        uiButton_start:setVisible(false)
        local wChairID = pBuffer.wCurrentUser
        -- self:setHandCard(wChairID,pBuffer.cbCardData)
        -- self:showHandCard(wChairID,1)   
        pBuffer.wChairID = pBuffer.wCurrentUser 
        self:showOperation(pBuffer)
        for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
            if ZJHGameCommon.player[i] ~= nil then
                -- ZJHGameCommon.player[i].lTableScore = pBuffer.lTableScore[i]
                self:showHandPBCard(i,3)
                local viewID = ZJHGameCommon:getViewIDByChairID(i)
                local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",viewID))
                uiPanel_scorePos:removeAllChildren()
            end 
        end 
        local uiButton_show = ccui.Helper:seekWidgetByName(self.root,"Button_show")
        uiButton_show:setVisible(false)
     
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
    elseif action == NetMsgId.SUB_S_ADD_SCORE then
        self:showCountDown(ZJHGameCommon.gameConfig.wQuitTimer)
        local wChairID = pBuffer.wAddScoreUser
        local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
        uiPanel_betting:setVisible(false)
        local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",viewID))
        uiPanel_scorePos:removeAllChildren()
        local uiTextAtlasScore = nil
        local uiImgZ = nil
        local uiImage_betting = ccui.ImageView:create("puke/table/ok_ui_f_point_bg.png")
        uiImgZ = ccui.TextAtlas:create(string.format(":%d",pBuffer.lAddScoreCount),"fonts/game_table_countdown_num.png",18,28,'0')
        uiImage_betting:addChild(uiImgZ)
        uiImgZ:setPosition(72,17) 
        uiPanel_scorePos:addChild(uiImage_betting)
        uiImage_betting:setPosition(0,0) 

        pBuffer.wChairID = pBuffer.wCurrentUser 
        self:showOperation(pBuffer)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 


    elseif action == NetMsgId.SUB_S_COMPARE_CARD then
        print("++++++++++++++++++比牌动画及其效果++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")

        self:ShowPK(pBuffer)

        pBuffer.wChairID = pBuffer.wLostUser
        self:setHandCard(pBuffer.wChairID,pBuffer.cbHandCardData)
        self:showHandCard(pBuffer.wChairID,2)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 

    elseif action == NetMsgId.SUB_S_LOOK_CARD then

        --self:showCountDown(ZJHGameCommon.gameConfig.wQuitTimer)
        pBuffer.wChairID = pBuffer.wLookCardUser
        ZJHGameCommon.player[pBuffer.wChairID].wLookCardUser = true
        -- print("++++++++++++++++++看牌++++++++++++++++")
        -- print("++++++++++++++++++++++++++++++++++++++++++++++++")
        -- print("++++++++++++++++++++++++++++++++++++++++++++++++")
        -- print("++++++++++++++++++++++++++++++++++++++++++++++++")
        -- print("++++++++++++++++++++++++++++++++++++++++++++++++")
        -- print("++++++++++++++++++++++++++++++++++++++++++++++++")

        self:changeNote()
        self:setHandCard(pBuffer.wChairID,pBuffer.cbCardData)
        self:showHandCard(pBuffer.wChairID,2)
        self:showOperation(pBuffer)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 

    elseif action == NetMsgId.SUB_S_GIVE_UP_ZJH then
        print("++++++++++++++++++弃牌动画及其效果++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        print("++++++++++++++++++++++++++++++++++++++++++++++++")
        pBuffer.wChairID = pBuffer.wGiveUpUser
        self:setHandCard(pBuffer.wChairID,pBuffer.cbHandCardData)
        self:showHandCard(pBuffer.wChairID,2)
        
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 
    -- elseif action == NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD then
    --     local wChairID = pBuffer.wChairID
    --     self:setHandCard(wChairID,pBuffer.cbCardData)
    --     -- if not self:isLightCardType() then
    --         self:showHandCard(wChairID,3)
    --     -- end
    --     for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
    --         if ZJHGameCommon.player[i] ~= nil  and i ~= wChairID then
    --             self:showHandPBCard(i,3)
    --         end 
    --     end 
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

    elseif action == NetMsgId.REC_SUB_S_BETTING_HSP then
        local wChairID = pBuffer.wChairID
        self:showCountDown(2)
        if ZJHGameCommon:getRoleChairID() == pBuffer.wChairID then
            local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
            uiPanel_betting:setVisible(true)
            local uiListView_betting = ccui.Helper:seekWidgetByName(self.root,"ListView_betting")
            uiListView_betting:removeAllItems()
            local tableBettingType = {0,1,2,3}
            print("推注+++++++++++",pBuffer.cbBettingOne,pBuffer.cbBettingTwo,pBuffer.cbBettingThree,pBuffer.cbGenZhu,pBuffer.cbJiaZhuOne,pBuffer.cbJiaZhuTwo)
            if pBuffer.cbBettingType == 1 then 
                tableBettingType = {0,pBuffer.cbBettingOne,pBuffer.cbBettingTwo,pBuffer.cbBettingThree}
            elseif pBuffer.cbBettingType == 2 then 
                if pBuffer.cbGenZhu == 0 then
                    tableBettingType = {0,pBuffer.cbJiaZhuOne,pBuffer.cbJiaZhuTwo}
                else
                    tableBettingType = {0,100,pBuffer.cbJiaZhuOne,pBuffer.cbJiaZhuTwo}
                end 
            elseif pBuffer.cbBettingType == 3 then 
                tableBettingType = {0,100}               
            end 

            for key, var in pairs(tableBettingType) do
                local imgBT = nil
                local imgZ  = nil 
                local imgN  = nil 
            	if  var == 0 then
                    imgBT = "puke/table/ok_ui_f_btn_red.png"
                    imgZ = ccui.ImageView:create("puke/table/ok_ui_f_xz_qipai.png")
                elseif var == 100 then
                    imgBT = "puke/table/ok_ui_f_btn_blue.png"
                    imgZ = ccui.ImageView:create("puke/table/ok_ui_f_xz_genzhu.png")
                    --imgN = ccui.ImageView:create(string.format("puke/table/num/ok_btn_%d.png",pBuffer.cbGenZhu))

                    imgN = ccui.TextAtlas:create(string.format(":%d",pBuffer.cbGenZhu),"fonts/game_table_countdown_num.png",18,28,'0')
                else
                    imgBT = "puke/table/ok_ui_f_btn_orange.png"   -- string.format("puke/table/pukenew_scorebtn_%d.png",var)
                    imgZ = ccui.ImageView:create("puke/table/ok_ui_f_xz_jiazhu.png")
                    --imgN = ccui.ImageView:create(string.format("puke/table/num/ok_btn_%d.png",var))

                    imgN = ccui.TextAtlas:create(string.format(":%d",var),"fonts/game_table_countdown_num.png",18,28,'0')
                end               
               -- local img = ccui.ImageView:create(string.format("game/shuaiz_%d.png",var))
                local item = ccui.Button:create(imgBT,imgBT,imgBT)
                item:addChild(imgZ,1000)
                imgZ:setPosition(69,35)
                if imgN ~= nil then 
                    item:addChild(imgN,1000)
                    imgN:setPosition(69,35)
                end 
                item.data = var
                uiListView_betting:pushBackCustomItem(item)
                print("个人信息+++++++++++",ZJHGameCommon:getRoleChairID(),item.data,pBuffer.cbBettingType,pBuffer.cbGenZhu )
                Common:addTouchEventListener(item,function() 

                    if item.data == 100 then 
                        item.data = pBuffer.cbGenZhu 

                        print("发送我要干什么个人信息+++++++++++",ZJHGameCommon:getRoleChairID(),item.data,pBuffer.cbBettingType)
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_BETTING_HSP,"wlb",pBuffer.wChairID,item.data,3)
                    else
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_BETTING_HSP,"wlb",pBuffer.wChairID,item.data,pBuffer.cbBettingType)
                    end 
                end)
            end
            uiListView_betting:setDirection(ccui.ListViewDirection.horizontal)
            uiListView_betting:refreshView()
            uiListView_betting:setPositionX(uiListView_betting:getParent():getContentSize().width/2-uiListView_betting:getInnerContainerSize().width/2)
            uiListView_betting:setDirection(ccui.ScrollViewDir.none) 
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.REC_SUB_S_BETTING_RESULT then
        local wChairID = pBuffer.wChairID
        if wChairID == ZJHGameCommon:getRoleChairID() then
            local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
            uiPanel_betting:setVisible(false)
            local uiListView_betting = ccui.Helper:seekWidgetByName(self.root,"ListView_betting")
            uiListView_betting:removeAllItems()
        end
        local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
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
        for i = 1, ZJHGameCommon.gameConfig.bMultiple do
            local img = string.format("puke/table/pukenew_cellbtn_%d.png",i)
            local item = ccui.Button:create(img,img,img)
            uiListView_grabBanker:pushBackCustomItem(item)
            Common:addTouchEventListener(item,function() 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_GRAB_BANKER,"wb",ZJHGameCommon:getRoleChairID(),i)
            end)
        end
        uiListView_grabBanker:setDirection(ccui.ListViewDirection.horizontal)
        uiListView_grabBanker:refreshView()
        uiListView_grabBanker:setPositionX(uiListView_grabBanker:getParent():getContentSize().width/2-uiListView_grabBanker:getInnerContainerSize().width/2)
        uiListView_grabBanker:setDirection(ccui.ScrollViewDir.none) 

        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
         
    elseif action == NetMsgId.REC_SUB_S_SHOW_RESULT_HSP then
        local wChairID = pBuffer.wChairID

        if wChairID == 1 then 
            local a = 1 
        end
        if wChairID == ZJHGameCommon:getRoleChairID() then
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
        self:showHandCard(wChairID,2)--,pBuffer.cbValueType
        --ZJHGameCommon:playAnimation(self.root, pBuffer.cbValueType,pBuffer.wChairID)


        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.REC_SUB_S_SHOW_TIPS then
        self:showCountDown(3)
        local uiButton_show = ccui.Helper:seekWidgetByName(self.root,"Button_show")
        uiButton_show:setVisible(false)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
        if self:isLightCardType() then
            local Button_rubCard = ccui.Helper:seekWidgetByName(self.root,"Button_rubCard")
            Button_rubCard:setVisible(true)
            Button_rubCard:setEnabled(true)
        end
    elseif action == NetMsgId.REC_SUB_S_GAME_END then    ---显示亮牌  取代亮牌提示

        for i = 0 , 7 do 
            local cbCardData = pBuffer.cbCardData[i]
            if cbCardData[1] ~= 0 then 
                self:setHandCard(i,cbCardData)
                self:showHandCard(i,2)--,pBuffer.cbValueType
            end 
        end 
        --mUserCardNum
     --   self:showUserCardNum(pBuffer)

        for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
            if ZJHGameCommon.player[i] ~= nil then
            local viewID = ZJHGameCommon:getViewIDByChairID(i)
            local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",viewID))
            uiPanel_scorePos:removeAllChildren()
            end 
        end 

        local wChairID = pBuffer.wChairID
        local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
        uiPanel_betting:setVisible(false)
        local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
        local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",viewID))
        uiPanel_scorePos:removeAllChildren()
        local uiTextAtlasScore = nil
        if pBuffer.lGameScore > 0 then
            if wChairID == ZJHGameCommon:getRoleChairID() then
                ZJHGameCommon:playAnimation(self.root, "赢",pBuffer.wChairID)
            end
            uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/fonts_6.png",26,43,'0')
        else
            uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/fonts_7.png",26,43,'0')
        end
        uiPanel_tipsCard:addChild(uiTextAtlasScore)
        uiTextAtlasScore:setPosition(uiPanel_scorePos:getPosition())  
        uiTextAtlasScore:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.ScaleTo:create(0.5,1.2),cc.ScaleTo:create(0.5,1.0))) 

        self:showCountDown(3)
        local uiButton_show = ccui.Helper:seekWidgetByName(self.root,"Button_show")
        uiButton_show:setVisible(false)
        
        if self:isLightCardType() then
            local Button_rubCard = ccui.Helper:seekWidgetByName(self.root,"Button_rubCard")
            Button_rubCard:setVisible(true)
            Button_rubCard:setEnabled(true)
        end


    -- elseif action == NetMsgId.REC_SUB_S_YAZHU_RETURN then    ---显示亮牌  取代亮牌提示

    --     local wChairID = pBuffer.wChairID
    --     local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
    --     uiPanel_betting:setVisible(false)
    --     local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
    --     local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",viewID))
    --     uiPanel_scorePos:removeAllChildren()
    --     local uiTextAtlasScore = nil
    --     local uiImgZ = nil
    --     local uiImBG = nil
    --     local uiImage_betting = ccui.ImageView:create("puke/table/ok_ui_f_point_bg.png")
    --     if pBuffer.mYaZhuType == 1 then 
    --         --uiImgZ = ccui.ImageView:create(string.format("puke/table/num/ok_gen_%d.png",pBuffer.lGameScore))
    --         uiImgZ = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/game_table_countdown_num.png",18,28,'0')
    --         uiImBG = ccui.ImageView:create("puke/table/ok_ui_f_jiazhu.png")

    --         ZJHGameCommon:playAnimation(self.root,pBuffer.lGameScore,pBuffer.wChairID)

    --     elseif pBuffer.mYaZhuType == 2 then 
    --         --uiImgZ = ccui.ImageView:create(string.format("puke/table/num/ok_gen_%d.png",pBuffer.lGameScore))
    --         uiImgZ = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/game_table_countdown_num.png",18,28,'0')
    --         uiImBG = ccui.ImageView:create("puke/table/ok_ui_f_jiazhu.png")
    --         ZJHGameCommon:playAnimation(self.root,30,pBuffer.wChairID)
    --     elseif pBuffer.mYaZhuType == 3 then 
    --         --uiImgZ = ccui.ImageView:create(string.format("puke/table/num/ok_gen_%d.png",pBuffer.lGameScore))
    --         uiImgZ = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/game_table_countdown_num.png",18,28,'0')
    --         uiImBG = ccui.ImageView:create("puke/table/ok_ui_f_genzhu.png")


    --         ZJHGameCommon:playAnimation(self.root,20,pBuffer.wChairID)
    --     else
    --         uiImgZ = ccui.ImageView:create("puke/table/ok_ui_f_giveup.png")
    --         uiImBG = ccui.ImageView:create("common/hall_5.png")
    --         self:showHandPBCard(wChairID,1)

    --         ZJHGameCommon:playAnimation(self.root,25,pBuffer.wChairID)
    --     end
    --     uiImage_betting:addChild(uiImgZ)
    --     uiImgZ:setPosition(72,17) 
    --     uiImage_betting:addChild(uiImBG)
    --     uiImBG:setPosition(72,17) 
    --     uiPanel_scorePos:addChild(uiImage_betting)
    --     uiImage_betting:setPosition(0,0) 

    --     -- if pBuffer.lGameScore > 0 then
    --     --     if wChairID == ZJHGameCommon:getRoleChairID() then
    --     --         ZJHGameCommon:playAnimation(self.root, "赢",pBuffer.wChairID)
    --     --     end
    --     --     uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/fonts_6.png",26,43,'0')
    --     -- else
    --     --     uiTextAtlasScore = ccui.TextAtlas:create(string.format(":%d",pBuffer.lGameScore),"fonts/fonts_7.png",26,43,'0')
    --     -- end
    --     -- uiPanel_scorePos:addChild(uiTextAtlasScore)
    --     -- uiTextAtlasScore:setPosition(0,0)  
    --     -- uiTextAtlasScore:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.ScaleTo:create(0.5,1.2),cc.ScaleTo:create(0.5,1.0))) 

    --     self:showCountDown(3)
        
    --     if self:isLightCardType() then
    --         local Button_rubCard = ccui.Helper:seekWidgetByName(self.root,"Button_rubCard")
    --         Button_rubCard:setVisible(true)
    --         Button_rubCard:setEnabled(true)
    --     end
        
    else
    
    end
	
end

function TableLayer:ShowPK(pBuffer)

    local uiPanel_PKend = ccui.Helper:seekWidgetByName(self.root,"Panel_PKend")
    uiPanel_PKend:setVisible(true)

    local pt_Q = {
        cc.p(0, 360.00),
        cc.p(1280, 360.00)
    }

    local pt_H = {
        cc.p(400.20, 360.00),
        cc.p(933.80, 360.00)
    }
    for i = 1 , 2 do

        local wChairID = pBuffer.wCompareUser[i] 
        local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
        local uiImage_play = ccui.Helper:seekWidgetByName(self.root,string.format("Image_play%d",i))
        uiImage_play:setPosition(pt_Q[i])
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiImage_play,"Image_avatar")
        Common:requestUserAvatar(ZJHGameCommon.player[wChairID].dwUserID,ZJHGameCommon.player[wChairID].szPto,uiImage_avatar,"img")
        local uiText_num = ccui.Helper:seekWidgetByName(uiImage_play,"Text_num")
        uiText_num:setString(string.format("%d",ZJHGameCommon.player[wChairID].lTableScore))
        local uiImage_shu = ccui.Helper:seekWidgetByName(uiImage_play,"Image_shu")
        uiImage_shu:setVisible(false)

        uiImage_play:runAction(cc.Sequence:create( 
        cc.MoveTo:create(0.5,pt_H[i]),
        cc.CallFunc:create(function(sender,event) 
            if  pBuffer.wCompareUser[i] == pBuffer.wLostUser then
                uiImage_shu:setVisible(true)
            end
        end),
        cc.DelayTime:create(1),
        cc.CallFunc:create(function(sender,event) 
            uiPanel_PKend:setVisible(false)
        end)))
    end 

end 

function TableLayer:showCountDown(cbWaitType)
    local uiImage_countdown = ccui.Helper:seekWidgetByName(self.root,"Image_countdown")
    uiImage_countdown:setVisible(true)
    local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:setString(cbWaitType)
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
    -- local uiImage_waitType = ccui.Helper:seekWidgetByName(self.root,"Image_waitType")
    -- uiImage_waitType:setVisible(true)
    -- if cbWaitType == 1 then
    --     -- uiImage_waitType:loadTexture("puke/table/pukenew_4.png")
    --     local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    --     uiAtlasLabel_countdownTime:removeAllChildren()
    --     ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/qiangzhuangdonghua/qiangzhuangdonghua.ExportJson")
    --     local armature = ccs.Armature:create("qiangzhuangdonghua")
    --     uiAtlasLabel_countdownTime:addChild(armature)
    --     armature:getAnimation():playWithIndex(0)
    --     armature:setPosition(armature:getParent():getContentSize().width/2,60)
    -- elseif cbWaitType == 2 then
    --     -- uiImage_waitType:loadTexture("puke/table/pukenew_5.png")
    --     local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    --     uiAtlasLabel_countdownTime:removeAllChildren()
    --     ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/yafendonghua/yafendonghua.ExportJson")
    --     local armature = ccs.Armature:create("yafendonghua")
    --     uiAtlasLabel_countdownTime:addChild(armature)
    --     armature:getAnimation():playWithIndex(0)
    --     armature:setPosition(armature:getParent():getContentSize().width/2,-80)
    -- else
    --     -- uiImage_waitType:loadTexture("puke/table/pukenew_15.png")
    --     -- local uiAtlasLabel_countdownTime = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_countdownTime")
    --     -- uiAtlasLabel_countdownTime:removeAllChildren()
    --     -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/liangpaidonghua/liangpaidonghua.ExportJson")
    --     -- local armature = ccs.Armature:create("liangpaidonghua")
    --     -- uiAtlasLabel_countdownTime:addChild(armature)
    --     -- armature:getAnimation():playWithIndex(0)
    --     -- armature:setPosition(armature:getParent():getContentSize().width/2,60)
    -- end
end

function TableLayer:changeNote()
    local rate  = 1 

    if ZJHGameCommon.player[ZJHGameCommon:getRoleChairID()].wLookCardUser == true then 
        rate = 2
    end   
    rate = (ZJHGameCommon.gameConfig.dwMaxOutSorce/10)*rate

    local tableBettingType = {1,2,4,6,8,10}

    for i = 1, 6 do
        local uiButton_Note = ccui.Helper:seekWidgetByName(self.root,string.format("Button_Note_%d",i))
        local uiAtlasLabel = ccui.Helper:seekWidgetByName(self.root,string.format("AtlasLabel_%d",i))
        local num = tableBettingType[i]*(ZJHGameCommon.gameConfig.dwMaxOutSorce/10)
        if  ZJHGameCommon.lCellScore >= num then 
            uiButton_Note:setEnabled(false)
            uiButton_Note:setColor(cc.c3b(170,170,170))    
        end 
        local data = 0
        if ZJHGameCommon.player[ZJHGameCommon:getRoleChairID()].wLookCardUser == true then 
            data = tableBettingType[i]*rate
            uiAtlasLabel:setString(string.format("%d",data))
        else
            uiAtlasLabel:setString(string.format("%d",num))
        end 
       
        
        Common:addTouchEventListener(uiButton_Note,function() 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_SCORE,"l",string.format("%d",num))
        end) 
    end     
end

function TableLayer:changeMatch()
    for i = 2 , 8 do
        local uiButton_Match = ccui.Helper:seekWidgetByName(self.root,string.format("Button_Match%d",i))
        uiButton_Match:setVisible(false)
    end 
    for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
        if ZJHGameCommon.player[i] ~= nil and ZJHGameCommon.player[i].wGiveUpUser == false then
            -- ZJHGameCommon.player[i].lTableScore = pBuffer.lTableScore[i]
            -- self:showHandPBCard(i,3)
            local viewID = ZJHGameCommon:getViewIDByChairID(i)
            if viewID ~= 1 then 
                local uiButton_Match = ccui.Helper:seekWidgetByName(self.root,string.format("Button_Match%d",viewID))
                uiButton_Match:setVisible(true)
                Common:addTouchEventListener(uiButton_Match,function() 
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_COMPARE_CARD,"w", i)
                end)  
            end 
        end 
    end   
end


function TableLayer:showOperation(pBuffer)


    self:changeMatch()
    local uiPanel_betting = ccui.Helper:seekWidgetByName(self.root,"Panel_betting")
    uiPanel_betting:setVisible(true)
    local uiPanel_AddNote = ccui.Helper:seekWidgetByName(self.root,"Panel_AddNote")
    uiPanel_AddNote:setVisible(false)
    uiPanel_AddNote:setEnabled(false)

    local uiPanel_Match = ccui.Helper:seekWidgetByName(self.root,"Panel_Match")
    uiPanel_Match:setVisible(false)
    uiPanel_Match:setEnabled(false)

    Common:addTouchEventListener(uiPanel_AddNote,function() 
        uiPanel_AddNote:setVisible(false)
        uiPanel_AddNote:setEnabled(false)
    end,true)

    Common:addTouchEventListener(uiPanel_Match,function() 
        uiPanel_Match:setVisible(false)
        uiPanel_Match:setEnabled(false)
    end,true)

    local tableBettingType = {1,2,4,6,8,10}
    local uiButton_Discard = ccui.Helper:seekWidgetByName(self.root,"Button_Discard")
    local uiButton_LookCrad = ccui.Helper:seekWidgetByName(self.root,"Button_LookCrad")
    local uiButton_MatchCard = ccui.Helper:seekWidgetByName(self.root,"Button_MatchCard")
    local uiButton_FollowUp = ccui.Helper:seekWidgetByName(self.root,"Button_FollowUp")
    local uiButton_AddNote = ccui.Helper:seekWidgetByName(self.root,"Button_AddNote")

    Common:addTouchEventListener(uiButton_Discard,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_GIVE_UP_ZJH,"")
    end)   

    Common:addTouchEventListener(uiButton_LookCrad,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_LOOK_CARD,"")
    end)  

    Common:addTouchEventListener(uiButton_MatchCard,function() 
        uiPanel_Match:setVisible(true)
        uiPanel_Match:setEnabled(true)
    end)   
     Common:addTouchEventListener(uiButton_FollowUp,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_ADD_SCORE,"l",0)
    end)    
    Common:addTouchEventListener(uiButton_AddNote,function() 
        uiPanel_AddNote:setVisible(true)
        uiPanel_AddNote:setEnabled(true)
    end)  

    if ZJHGameCommon:getRoleChairID() == pBuffer.wChairID then
        uiButton_LookCrad:setEnabled(true)
        uiButton_LookCrad:setColor(cc.c3b(255,255,255))
        uiButton_MatchCard:setEnabled(true)
        uiButton_MatchCard:setColor(cc.c3b(255,255,255))
        uiButton_FollowUp:setEnabled(true)
        uiButton_FollowUp:setColor(cc.c3b(255,255,255))
        uiButton_AddNote:setEnabled(true)
        uiButton_AddNote:setColor(cc.c3b(255,255,255))
        if ZJHGameCommon.player[ZJHGameCommon:getRoleChairID()].wLookCardUser == true then
            uiButton_LookCrad:setEnabled(false)
            uiButton_LookCrad:setColor(cc.c3b(170,170,170))
        end 
        if ZJHGameCommon.player[ZJHGameCommon:getRoleChairID()].wGiveUpUser == true then
        end 

        if ZJHGameCommon.wOKlookCard ~= nil and ZJHGameCommon.wOKlookCard == false then 
            uiButton_LookCrad:setEnabled(false)
            uiButton_LookCrad:setColor(cc.c3b(170,170,170))
            uiButton_MatchCard:setEnabled(false)
            uiButton_MatchCard:setColor(cc.c3b(170,170,170))
        end 

        if ZJHGameCommon.lCellScore == ZJHGameCommon.gameConfig.dwMaxOutSorce then 
            uiButton_AddNote:setEnabled(false)
            uiButton_AddNote:setColor(cc.c3b(170,170,170))
        end 

    else
        uiButton_LookCrad:setEnabled(false)
        uiButton_MatchCard:setEnabled(false)
        uiButton_FollowUp:setEnabled(false)
        uiButton_AddNote:setEnabled(false)       
        uiButton_LookCrad:setColor(cc.c3b(170,170,170))
        uiButton_MatchCard:setColor(cc.c3b(170,170,170))
        uiButton_FollowUp:setColor(cc.c3b(170,170,170))
        uiButton_AddNote:setColor(cc.c3b(170,170,170))
        if ZJHGameCommon.player[ZJHGameCommon:getRoleChairID()].wGiveUpUser == true then
            uiPanel_betting:setVisible(false) 
        end
    end 

end 
-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function TableLayer:setHandCard(wChairID,cbCardData)
    ZJHGameCommon.player[wChairID].cbCardData = cbCardData
end

--更新手牌
function TableLayer:showHandCard(wChairID,effectsType)
    if ZJHGameCommon.player[wChairID].cbCardData == nil then
        return
    end
    local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
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
    --effectsType 0断线重连发牌  1正常发牌  2亮牌 3 自己手牌外加搓牌（明牌抢庄特有）
    if viewID == 1 and effectsType == 2 then
        beganX = (size.width - (stepX*2+cardWidth))/2
    elseif viewID == 1 then
        stepX = cardWidth
    end
    for i = 1, 3 do
        local data = ZJHGameCommon.player[wChairID].cbCardData[i]
        local Scale_x = 1
        local Scale_y = 1
        local card = nil 
        if data ~= 0 then  
            card = ZJHGameCommon:getCardNode(data) 
        else
            card = ZJHGameCommon:getCardNode(0)
            Scale_x = 0.96
            Scale_y = 0.93
        end 
        if effectsType == 3 and i == 3 then 
            card = ZJHGameCommon:getCardNode(0)
            Scale_x = 0.96
            Scale_y = 0.93
        end 
        uiPanel_handCard:addChild(card) 
        card:setScale(cardScale* Scale_x,cardScale* Scale_y)
        card:setAnchorPoint(cc.p(0,0))
        card.data = data
        if effectsType == 1 then
            if ZJHGameCommon.player[wChairID].cbCardData[3] == 0 then
                local pt = cc.p(beganX + (i)*stepX, 0)
                card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
                card.pt = pt
                card:stopAllActions()
                card:runAction(cc.MoveTo:create(time,pt))
            elseif  ZJHGameCommon.player[wChairID].cbCardData[3] ~= 0 then
                local pt = cc.p(beganX + (i)*stepX, 0)
                card.pt = pt
                if i == 3 then 
                    card:setPosition(cc.p(0,360))
                    card:runAction(cc.MoveTo:create(time,pt))
                else
                    card:setPosition(pt)
                end  
            end             
        elseif effectsType == 2 then  
            -- local pt = cc.p(beganX + (i)*stepX, 0)            
            -- if viewID == 1 then
                local ptTemp = cc.p(0 + (i)*cardWidth, 0)
                card:setPosition(ptTemp)
                --card:setColor(cc.c3b(170,170,170))   
                -- card.pt = pt
                -- card:stopAllActions()
                -- card:runAction(cc.MoveTo:create(time,pt))
            -- else
            --     print("别人的手牌显示",data,wChairID)
            --     card.pt = pt
            --     card:setPosition(card.pt)
            -- end

            print("别人的手牌显示++++++++++++++",data,wChairID)
        else
            local pt = cc.p(beganX + (i)*stepX, 0)
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
    local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))

    -- if effectsType ~= 3 then 
        uiPanel_handCard:removeAllChildren()
    -- end 
    print("发牌了")

    local pos = cc.p(uiPanel_handCard:getPosition())
    local size = uiPanel_handCard:getContentSize()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local anchorPoint = uiPanel_handCard:getAnchorPoint()
    local index = 0
    local time = 0.1
    local offset = 15
    local cardScale = 0.5
    if viewID == 1 then
        cardScale = 0.8
    end

    local cardWidth = 161 * cardScale
    local cardHeight = 231 * cardScale
    local stepX = cardWidth*0.35
    local stepY = cardHeight
    local beganX = 0    
    if viewID == 1 then
        stepX = cardWidth
    end
    local card = nil 
    for i = 1, 3 do
        card = ZJHGameCommon:getCardNode(0)
        uiPanel_handCard:addChild(card) 
        card:setScale(cardScale*0.96,cardScale*0.93)
        card:setAnchorPoint(cc.p(0,0))
        -- -- card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
        -- local pt = cc.p(beganX + (i)*stepX, 0)  
        -- card.pt = pt
        -- card:stopAllActions()
        -- --card:runAction(cc.MoveTo:create(0.2,pt)) 
        -- card:setPosition(pt)   
        
        if effectsType == 1 then
            local pt = cc.p(beganX + (i)*stepX, 0)
            card:setPosition(cc.p(card:getParent():convertToNodeSpace(cc.p(visibleSize.width/2, 0))))
            card.pt = pt
            card:stopAllActions()
            card:runAction(cc.MoveTo:create(time,pt))
        elseif effectsType == 3 then
            local pt = cc.p(beganX + (i)*stepX, 0)
            card.pt = pt
            card:setPosition(pt)
            --card:setColor(cc.c3b(170,170,170))        
        end
    end 
end 

function TableLayer:showUserCardNum(pBuffer)
    if pBuffer.mUserCardNum[pBuffer.wChairID] == 0 then 
        return
    end 
    local viewID = ZJHGameCommon:getViewIDByChairID(pBuffer.wChairID)
    if viewID == 1 then 
        return
    end 
    local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
    local uiPanel_tipsCardPosUser = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
    local uiImage_betting = ccui.ImageView:create("puke/table/ok_ui_ddz_r_item_bg1.png")
    uiPanel_tipsCard:addChild(uiImage_betting)
    local uiHongZiCount = ccui.Text:create(string.format("点数:%d",pBuffer.mUserCardNum[pBuffer.wChairID]),"fonts/DFYuanW7-GB2312.ttf","30")
    uiHongZiCount:setTextColor(cc.c3b(255,255,255)) 
    uiHongZiCount:setAnchorPoint(cc.p(0.5,0.5))
    uiImage_betting:addChild(uiHongZiCount)
    uiHongZiCount:setPosition(72,16)
    uiImage_betting:setPosition(uiPanel_tipsCardPosUser:getPosition())
    print("++++++++++++++++",uiPanel_tipsCardPosUser:getPositionX(),uiPanel_tipsCardPosUser:getPositionY())
    -- if viewID == 1 then
    --     uiImage_betting:setPositionY(uiHongZiCount:getPositionY() + 50)
    -- end
    uiHongZiCount:runAction(cc.Sequence:create(cc.DelayTime:create(6),cc.RemoveSelf:create()))
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
    -- if ZJHGameCommon.gameConfig.bPlayerCount ~= nil then
    --     bPlayerCount = ZJHGameCommon.gameConfig.bPlayerCount 
    -- elseif ZJHGameCommon.tableConfig.tableParameter ~= nil then
    --     bPlayerCount = ZJHGameCommon.tableConfig.tableParameter.bPlayerCount
    -- else
    --    if  ZJHGameCommon.tableConfig.wKindID == 51 then 
    --         bPlayerCount =  6
    --    else
            bPlayerCount =  8
    --    end 
    -- end  

    local uiImage_Points = ccui.Helper:seekWidgetByName(self.root,"Image_Points")
    uiImage_Points:setVisible(false)

    local uiPanel_PZscore = ccui.Helper:seekWidgetByName(self.root,"Panel_PZscore")
    uiPanel_PZscore:setVisible(false)
    local uiImage_PZscore = ccui.Helper:seekWidgetByName(self.root,"Image_PZscore")
    uiImage_PZscore:setVisible(false)
    --用户层  tableConfig.tableParameter
    for i = 1, bPlayerCount do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        uiPanel_player:setVisible(false)
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        uiImage_avatar:loadTexture("common/hall_avatar.png")
        uiImage_avatar:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then
                for key, var in pairs(ZJHGameCommon.player) do
                    if ZJHGameCommon:getViewIDByChairID(var.wChairID) == i then
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_PLAYER_INFO,"d",var.dwUserID)
                        break
                    end
                end
            end
        end)    
        local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        local uiImage_laba = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_laba")
        uiImage_laba:setVisible(false)
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
        uiText_name:setString("")
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        uiText_score:setString("")
        local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
        uiImage_ready:setVisible(false)
        local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
        uiImage_chat:setVisible(false)
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
    local uiPanel_PKend = ccui.Helper:seekWidgetByName(self.root,"Panel_PKend")
    uiPanel_PKend:setVisible(false)
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
        dump(ZJHGameCommon.player, 'PlayerInfo::')
        for i,v in pairs(ZJHGameCommon.player or {}) do
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
                    local wChairID = ZJHGameCommon:getRoleChairID()
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
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOW_HSP,"w",ZJHGameCommon:getRoleChairID())
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

        -- local pBuffer ={}
        -- pBuffer.wCompareUser = {}
        -- pBuffer.wCompareUser[1] = 1
        -- pBuffer.wCompareUser[2] = 2
        -- pBuffer.wLostUser = 1

        -- self:ShowPK(pBuffer)
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
            require("common.GameChatLayer"):create(ZJHGameCommon.tableConfig.wKindID,function(index) 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_EXPRESSION,"ww",index,ZJHGameCommon:getRoleChairID())
            end, 
            function(index,contents)
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SEND_CHAT,"dwbnsdns",
                    ZJHGameCommon:getRoleChairID(),index,ZJHGameCommon:getUserInfo(ZJHGameCommon:getRoleChairID()).cbSex,32,"",string.len(contents),string.len(contents),contents)
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
        for key, var in pairs(ZJHGameCommon.player) do
            currentPlayerCount = currentPlayerCount + 1
        end
        local player = "("
        for key, var in pairs(ZJHGameCommon.player) do
            if key == 0 then
                player = player..var.szNickName
            else
                player = player.."、"..var.szNickName
            end
        end
        player = player..")"
        local data = clone(UserData.Share.tableShareParameter[3])
        data.dwClubID = ZJHGameCommon.tableConfig.dwClubID
        data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name,
            ZJHGameCommon.tableConfig.wTbaleID,ZJHGameCommon.tableConfig.wTableNumber,
            ZJHGameCommon.gameConfig.bPlayerCount,ZJHGameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
        data.szShareContent = GameDesc:getGameDesc(ZJHGameCommon.tableConfig.wKindID,ZJHGameCommon.gameConfig,ZJHGameCommon.tableConfig).." (点击加入游戏)"
        data.szShareUrl = string.format(data.szShareUrl, ZJHGameCommon.tableConfig.szGameID)
        if ZJHGameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
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
    if ZJHGameCommon.tableConfig.nTableType > TableType_GoldRoom then
        self:addVoice()
        uiButton_cancel:setVisible(false)
        if ZJHGameCommon.tableConfig.wCurrentNumber > 0 then
            uiButton_Invitation:setVisible(false)
            uiButton_out:setVisible(false)
            uiButton_SignOut:setVisible(false)
        end 
        uiText_title:setString(string.format("%s 房间号:%d 局数:%d/%d",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name,ZJHGameCommon.tableConfig.wTbaleID,ZJHGameCommon.tableConfig.wCurrentNumber,ZJHGameCommon.tableConfig.wTableNumber))

        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
        local waitArmature=ccs.Armature:create("dengdaihaoyou")
        waitArmature:setPosition(-179.2,-158)        
        if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
            waitArmature:setPosition(0,-158)
        end 
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_Invitation:addChild(waitArmature)   

    elseif ZJHGameCommon.tableConfig.nTableType == TableType_GoldRoom then            
        self:addVoice()
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        if ZJHGameCommon.gameState == ZJHGameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
        else
            uiButton_voice:setVisible(false)
            uiButton_expression:setVisible(false)
        end 
        if ZJHGameCommon.tableConfig.cbLevel == 2 then
            uiText_title:setString(string.format("%s 中级场 倍率 %d",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name,ZJHGameCommon.tableConfig.wCellScore))
        elseif ZJHGameCommon.tableConfig.cbLevel == 3 then
            uiText_title:setString(string.format("%s 高级场 倍率 %d",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name,ZJHGameCommon.tableConfig.wCellScore))
        else
            uiText_title:setString(string.format("%s 初级场 倍率 %d",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name,ZJHGameCommon.tableConfig.wCellScore))
        end
        self:drawnout() 
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
        
    elseif ZJHGameCommon.tableConfig.nTableType == TableType_SportsRoom then            
        self:addVoice()
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        if ZJHGameCommon.gameState == ZJHGameCommon.GameState_Start  then
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
        uiText_title:setString(string.format("%s 竞技场",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name))
        self:drawnout() 
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
    else
        local uiPanel_ui = ccui.Helper:seekWidgetByName(self.root,"Panel_ui")
        uiPanel_ui:setVisible(false)
        uiText_title:setString(string.format("%s 牌局回放",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name))
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
    ZJHGameCommon.gameState = state 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if state == ZJHGameCommon.GameState_Init then
        
    elseif state == ZJHGameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        local uiButton_start = ccui.Helper:seekWidgetByName(self.root,"Button_start")
        uiButton_start:setVisible(false)
        local bPlayerCount = nil    
        bPlayerCount =  8
        for i = 1, bPlayerCount do
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            uiImage_ready:setVisible(false)
            if ZJHGameCommon.player[i-1] ~= nil then
                ZJHGameCommon.player[i-1].bReady = false
            end 
        end      
    elseif state == ZJHGameCommon.GameState_Over then
        UserData.Game:addGameStatistics(ZJHGameCommon.tableConfig.wKindID)
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
        data.chirID = ZJHGameCommon:getRoleChairID()
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
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE,"wwwdddnsnf",ZJHGameCommon:getRoleChairID(),packCount,i,data.time,fileSize,periodSize,32,data.file,periodSize,periodData)
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
            local viewID = ZJHGameCommon:getViewIDByChairID(data.chirID)
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
    require("common.PositionLayer"):create(ZJHGameCommon.tableConfig.wKindID)
end

function TableLayer:showPlayerInfo(infoTbl)       -- 查看玩家信息
    Common:palyButton()
    --require("common.PersonalLayer"):create(ZJHGameCommon.tableConfig.wKindID,dwUserID,dwShamUserID)

    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(infoTbl, self):createGame("game.puke.ZJHPersonInfor"))
end

function TableLayer:showChat(pBuffer)
    local viewID = ZJHGameCommon:getViewIDByChairID(pBuffer.dwUserID)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
    local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_chat")
    uiText_chat:setString(pBuffer.szChatContent)
    uiImage_chat:setVisible(true)
    uiImage_chat:setScale(0)
    uiImage_chat:stopAllActions()
    uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1),cc.DelayTime:create(5),cc.Hide:create()))
    local wKindID = ZJHGameCommon.tableConfig.wKindID
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
	local viewID = ZJHGameCommon:getViewIDByChairID(pBuffer.wChairID)
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
    for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
        local wChairID = i
        if ZJHGameCommon.player ~= nil and ZJHGameCommon.player[wChairID] ~= nil then
            self:showHandCard(wChairID,0)
        end
    end

    local regionSound = cc.UserDefault:getInstance():getFloatForKey('volumeSelect', 1) 
    if regionSound == 0 then
        GameCommon.regionSound = 0
    else 
        GameCommon.regionSound = 1
    end
end

--是否是明牌抢庄
function TableLayer:isLightCardType()
    if ZJHGameCommon.gameConfig.bCuopai ~= 1 then --StaticData.Hide[CHANNEL_ID].btn15 == 0  or 
        return false
    end
    
    local tableCnf = ZJHGameCommon.tableConfig or {}
    local gameCnf = ZJHGameCommon.gameConfig or {}
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
	for key, var in pairs(ZJHGameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = ZJHGameCommon:getViewIDByChairID(var.wChairID, true)
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
	
	if ZJHGameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(ZJHGameCommon.player or {}) do
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
				for i, v in pairs(ZJHGameCommon.player or {}) do
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