local GameCommon = require("game.majiang.GameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local GameLogic = require("game.majiang.GameLogic")
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local UserData = require("app.user.UserData")
local GameEndLayer = class("GameEndLayer",function()
    return ccui.Layout:create()
end)

function GameEndLayer:create(pBuffer)
    local view = GameEndLayer.new()
    view:onCreate(pBuffer)
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

function GameEndLayer:onEnter()
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:registListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
        require("common.Common"):screenshot(FileName.battlefieldScreenshot)
    end)))
end

function GameEndLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:unregistListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
end

function GameEndLayer:onCleanup()

end

function GameEndLayer:onCreate(pBuffer) 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerMaJiang_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
        uiButton_return:setVisible(false)
    end
    local function onEventReturn(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    	end
    end
    uiButton_return:addTouchEventListener(onEventReturn)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    local uiImage_continue = ccui.Helper:seekWidgetByName(self.root,"Image_continue")
    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
        if GameCommon.tableConfig.wCurrentNumber==GameCommon.tableConfig.wTableNumber then
            uiButton_continue:setVisible(true)
            local textureName = nil
            textureName = "newcommon/ok_ui_p_btn_pic6.png"       
            local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
            uiImage_continue:loadTexture(textureName)
            uiImage_continue:setContentSize(texture:getContentSizeInPixels())        
        else
            uiButton_continue:setVisible(true)     
        end
    else
        uiButton_continue:setVisible(true)
    end 
    uiButton_continue:setPressedActionEnabled(true)
    local function onEventContinue(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
                if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                    EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                else
                    GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                end
            elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then 
                GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
            else
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end   
    	end
    end
    uiButton_continue:addTouchEventListener(onEventContinue)

    local uiButton_share = ccui.Helper:seekWidgetByName(self.root, "Button_share")
    uiButton_share:setPressedActionEnabled(true)
    local function onEventShare(sender, event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[6])
            data.szShareImg = FileName.battlefieldScreenshot
            require("app.MyApp"):create(data):createView("ShareLayer")
        end
    end
    uiButton_share:addTouchEventListener(onEventShare)

    local uiPanel_reward = ccui.Helper:seekWidgetByName(self.root,"Panel_reward")
    local uiButton_Gold = ccui.Helper:seekWidgetByName(self.root,"Button_Gold")
    local uiButton_Money = ccui.Helper:seekWidgetByName(self.root,"Button_Money")
    local uiText_Gold = ccui.Helper:seekWidgetByName(self.root,"Text_Gold")
    local uiText_Money = ccui.Helper:seekWidgetByName(self.root,"Text_Money")
    local Gold = math.floor( (pBuffer.lGameScore[GameCommon.meChairID+1]*0.9)/ 1)
    local Money = math.floor( (pBuffer.lGameScore[GameCommon.meChairID+1]*0.35)/ 1)
    uiText_Gold:setString(string.format("+%d",Gold))       
    uiText_Money:setString(string.format("+%d",Money))
    uiPanel_reward:setVisible(false)
    Common:addTouchEventListener(uiButton_Gold,function() 
        GameCommon:GetReward(0)
    end)
    Common:addTouchEventListener(uiButton_Money,function() 
        GameCommon:GetReward(1)
    end)
    local uiText_timedown = ccui.Helper:seekWidgetByName(self.root,"Text_timedown")
    if GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom and pBuffer.lGameScore[GameCommon.meChairID+1] > 0 then 
        uiPanel_reward:setVisible(true)
        uiButton_return:setVisible(false)
        uiButton_continue:setVisible(false)
        uiButton_share:setVisible(false)
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(15),
            cc.CallFunc:create(function(sender,event) 
                uiPanel_reward:setVisible(false)
                uiButton_return:setVisible(true)
                uiButton_continue:setVisible(true)
                uiButton_share:setVisible(true)
                GameCommon:GetReward(0)
        end)))

        uiText_timedown:setString(15)        
        local function onEventTime(sender,event)
            local currentTime = tonumber(uiText_timedown:getString())
            currentTime = currentTime - 1
            if currentTime < 0 then
                currentTime = 0
            end
            uiText_timedown:setString(tostring(currentTime))   
            -- 自己出牌最后5秒倒计时音效
            if viewID == 1 and currentTime <= 5 and currentTime >=2 then
                self.warningID = Common:playEffect('majiang/sound/timeup_alarm.mp3')
            end
        end   
        uiText_timedown:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime))))   
    end 

    local uiText_Gamename = ccui.Helper:seekWidgetByName(self.root, "Text_Gamename")
    uiText_Gamename:setString("湘西猪笼子") 
    local uiText_room = ccui.Helper:seekWidgetByName(self.root, "Text_room")
    local uiText_num = ccui.Helper:seekWidgetByName(self.root, "Text_num")
    uiText_room:setString(string.format("房间号:%d",GameCommon.tableConfig.wTbaleID)) 
    uiText_num:setString(string.format("局数:%d/%d",GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))
    
    local uiText_time = ccui.Helper:seekWidgetByName(self.root, "Text_time")   
    local date = os.date("*t", os.time())
    uiText_time:setString(string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
    --显示桌面、显示结算
    local uiPanel_look = ccui.Helper:seekWidgetByName(self.root,"Panel_look")
    local uiButton_look = ccui.Helper:seekWidgetByName(self.root,"Button_look")
    Common:addTouchEventListener(uiButton_look,function() 
        if uiPanel_look:isVisible() then
            uiPanel_look:setVisible(false)
            uiButton_look:setBright(false)
        else
            uiPanel_look:setVisible(true)
            uiButton_look:setBright(true)
        end
    end)
    local uiText_info = ccui.Helper:seekWidgetByName(self.root,"Text_info")
    if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
        uiText_info:setString(string.format("倍率 %d\n消耗%d",pBuffer.lCellScore,pBuffer.lGameTax))
    else
        uiText_info:setString("")
    end
    local uiImage_result = ccui.Helper:seekWidgetByName(self.root,"Image_biaoti") 
    local textureName = nil
    if pBuffer.wWinner[GameCommon:getRoleChairID()+1] == true then
        textureName = "gameend/little_account_title_win.png"   
    else
        textureName = "gameend/little_account_title_lose.png"       
    end
    local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
    uiImage_result:loadTexture(textureName)
    uiImage_result:setContentSize(texture:getContentSizeInPixels())   
    
    local uiImage_dice = ccui.Helper:seekWidgetByName(self.root,"Image_dice")
    uiImage_dice:setVisible(false)
    local uiPanel_dice = ccui.Helper:seekWidgetByName(self.root,"Panel_dice")
    local size = uiPanel_dice:getContentSize()
    local line = 0  
    for i = 1, 85 do
        local data = pBuffer.bZhaNiao[i]
        if data ~= 0 and  data ~= 255  then
            uiImage_dice:setVisible(true)
            local cardScale = 0.5
            local cardWidth = 81 * cardScale
            local cardHeight = 114 * cardScale
            local stepX = cardWidth + 5
            local beganX = size.width/2
            local beganY = size.height - 30
            local size = cc.size(cardWidth,cardHeight)
            local card = GameCommon:getDiscardCardAndWeaveItemArray(data,1)
            uiPanel_dice:addChild(card)
            card:setScale(cardScale)          
            card:setPosition(beganX + stepX*line ,beganY)    
            line = line + 1
            local value = Bit:_and(data,0x0F)
            if value == 1 or value == 5 or value == 9 then
                local img = ccui.ImageView:create("majiang/table/endlyer_6.png")
                if  GameCommon.gameConfig.bMaType == 3 then  
                    img:setVisible(false)
                end                 
                card:addChild(img,1000)
                local scale = card:getContentSize().width / img:getContentSize().width
                img:setScale(scale)
                img:setPosition(img:getParent():getContentSize().width/2,img:getContentSize().height/2)
            end  
        else
            break
        end
    end
    uiImage_dice:setContentSize(cc.size(141.00+(line-1)*43,76.00))   


    local uiListView_player = ccui.Helper:seekWidgetByName(self.root,"ListView_player")
    local uiPanel_itemWin = ccui.Helper:seekWidgetByName(self.root,"Panel_itemWin")
    uiPanel_itemWin:retain()
    uiListView_player:removeAllItems()
    for i = 1,GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1    
        local var = GameCommon.player[wChairID]
        local viewID = GameCommon:getViewIDByChairID(wChairID)            
        local item = uiPanel_itemWin:clone()
        uiListView_player:pushBackCustomItem(item)
        local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
         Common:requestUserAvatar(var.dwUserID,var.szPto,uiImage_avatar,"clip")
        local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
        local name = Common:getShortName(var.szNickName,8,6)
        uiText_name:setString(name)
        uiText_name:setTextColor(cc.c3b(0,0,0))
        local uiImage_zhuang = ccui.Helper:seekWidgetByName(item,"Image_zhuang")
        if i == GameCommon.wBankerUser + 1 then
            local img = ccui.ImageView:create("game/game_table_banker.png")
            uiImage_avatar:addChild(img,1000)
            img:setPosition(10.00,86.00)            
        else
            uiImage_zhuang:setVisible(false)
        end

        ------方位----
        local uiImage_fangwei = ccui.Helper:seekWidgetByName(item,"Image_fangwei")
        local textureName = nil 
        if viewID == 1 then
            textureName = "newcommon/wanjiabiaoji_1.png"
        elseif viewID == 2 then
            textureName = "newcommon/wanjiabiaoji_2.png"
        elseif viewID == 3 then 
            if GameCommon.gameConfig.bPlayerCount == 3 then 
                textureName = "newcommon/wanjiabiaoji_4.png"
            else
                textureName = "newcommon/wanjiabiaoji_3.png"
            end 
        elseif viewID == 4 then 
            textureName = "newcommon/wanjiabiaoji_4.png"
        end 
        uiImage_fangwei:loadTexture(textureName)
        ------------

        local uiListView_mingTang = ccui.Helper:seekWidgetByName(item,"ListView_mingTang")
        GameCommon.IsQIangGangHu = 0
        local desc = ""
        desc = desc.. self:showMingTang(pBuffer.wChiHuKind[i])--,pBuffer.mFanCount[i]

        if GameCommon.gameConfig.bMaType ~= 4 and pBuffer.mYMQZNiaoCOUNT[i] ~= 0 then
            desc = desc.." 中码"..string.format("x%d",pBuffer.mYMQZNiaoCOUNT[i])
        end

        local uiText_hu = ccui.Helper:seekWidgetByName(uiListView_mingTang,"Text_hu")
        uiText_hu:setString(desc)
        uiText_hu:setColor(cc.c3b(127,90,46)) 

        local uiImage_winType = ccui.Helper:seekWidgetByName(item,"Image_winType")
        if pBuffer.wProvideUser < GameCommon.gameConfig.bPlayerCount then
            if pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == true then
                local textureName = "majiang/table/end_zimo.png"
                local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
                uiImage_winType:loadTexture(textureName)
                uiImage_winType:setContentSize(texture:getContentSizeInPixels())
            elseif pBuffer.wWinner[i] == true then
                local textureName = "majiang/table/end_hupai.png"
                local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
                uiImage_winType:loadTexture(textureName)
                uiImage_winType:setContentSize(texture:getContentSizeInPixels())
            elseif pBuffer.wProvideUser == wChairID and pBuffer.wWinner[i] == false then
                local textureName = "majiang/table/end_fangpao.png"
                local texture = cc.Director:getInstance():getTextureCache():addImage(textureName)
                uiImage_winType:loadTexture(textureName)
                uiImage_winType:setContentSize(texture:getContentSizeInPixels())
            else
                uiImage_winType:setVisible(false)
            end
        else
            uiImage_winType:setVisible(false)
        end
        
        local uiListView_card = ccui.Helper:seekWidgetByName(item,"ListView_card")
        for j = 1, pBuffer.cbWeaveItemCount[i] do
            local content = self:getWeaveItemArray(pBuffer.WeaveItemArray[i][j])
            uiListView_card:pushBackCustomItem(content)
        end
        local isFound = false
        for j = 1 , pBuffer.cbCardCount[i] do
            local cardScale = 0.65
            local cardWidth = 81 * cardScale
            local cardHeight = 114 * cardScale
            local size = cc.size(cardWidth,cardHeight)
            local content = ccui.Layout:create()
            content:setContentSize(size)
            uiListView_card:pushBackCustomItem(content)
            local data = pBuffer.cbCardData[i][j]
            local card = GameCommon:getDiscardCardAndWeaveItemArray(data,1)
            content:addChild(card)
            card:setScale(cardScale)
            card:setPosition(size.width/2,size.height/2)
            if isFound == false and data == pBuffer.cbChiHuCard[i] then
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("majiang/animation/hudepaitishi/hudepaitishi.ExportJson")
                local armature = ccs.Armature:create("hudepaitishi")
                armature:getAnimation():playWithIndex(0,-1,1)
                armature:setAnchorPoint(cc.p(0,0))
                armature:setPosition(0,2)
                card:addChild(armature)
                armature:setScale(1)
                isFound = true
            end
        end

        local uiText_PiaoFunzi = ccui.Helper:seekWidgetByName(item,"Text_PiaoFunzi")
        uiText_PiaoFunzi:setColor(cc.c3b(127,90,46))
        local uiText_PiaoFun = ccui.Helper:seekWidgetByName(item,"Text_PiaoFun")
        if GameCommon.gameConfig.bJiaPiao ~= 0 and GameCommon.wPiaoCount[i-1] ~= 0 then 
            uiText_PiaoFun:setString(string.format("%d",GameCommon.wPiaoCount[i-1]))
        else
            uiText_PiaoFun:setString("")
            uiText_PiaoFun:setVisible(false)
        end 
        uiText_PiaoFun:setColor(cc.c3b(127,90,46))

        local uiText_FanFunzi = ccui.Helper:seekWidgetByName(item,"Text_FanFunzi")
        uiText_FanFunzi:setColor(cc.c3b(127,90,46))
        uiText_FanFunzi:setString("")
        local uiText_FanFun = ccui.Helper:seekWidgetByName(item,"Text_FanFun")
        -- if pBuffer.cbAddGangScore[i] ~= 0 then 
        --     uiText_FanFun:setString(string.format("%d",pBuffer.cbAddGangScore[i]))
        -- else
            uiText_FanFun:setString("")
        -- end 
        uiText_FanFun:setColor(cc.c3b(127,90,46))



        local uiText_GangFunzi = ccui.Helper:seekWidgetByName(item,"Text_GangFunzi")
        uiText_GangFunzi:setColor(cc.c3b(127,90,46))
        local uiText_GangFun = ccui.Helper:seekWidgetByName(item,"Text_GangFun")
        if pBuffer.cbAddGangScore[i] ~= 0 then 
            uiText_GangFun:setString(string.format("%d",pBuffer.cbAddGangScore[i]))
        else
            uiText_GangFun:setString("")
            uiText_GangFun:setVisible(false)
        end 
        uiText_GangFun:setColor(cc.c3b(127,90,46))

        local uiAtlasLabel_score = ccui.Helper:seekWidgetByName(item,"AtlasLabel_score")
        if pBuffer.lGameScore[i] < 0 then       
            uiAtlasLabel_score:setProperty(string.format("/%d",pBuffer.lGameScore[i]),"fonts/font_num_blue.png",26,34,'/')              
        elseif  pBuffer.lGameScore[i] >= 0 then
            uiAtlasLabel_score:setProperty(string.format("/%d",pBuffer.lGameScore[i]),"fonts/font_num_red.png",26,34,'/')
        end
        local Text_zhongfen = ccui.Helper:seekWidgetByName(item,"Text_zhongfen")
        Text_zhongfen:setColor(cc.c3b(127,90,46))
    end
    uiPanel_itemWin:release()
end

function GameEndLayer:getWeaveItemArray(var)
    
   local cardScale = 0.65
    local cardWidth = 81 * cardScale
    local cardHeight = 114 * cardScale
    local size = cc.size(cardWidth*3+5,cardHeight)
    local content = ccui.Layout:create()
    content:setContentSize(size)
    local cbCardList = {}
    if Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_PENG) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
        cbCardList = {var.cbCenterCard,var.cbCenterCard+1,var.cbCenterCard+2}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
        cbCardList = {var.cbCenterCard-1,var.cbCenterCard,var.cbCenterCard+1}
    elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
        cbCardList = {var.cbCenterCard-1,var.cbCenterCard-2,var.cbCenterCard}
    else
        assert(false,"吃牌类型错误")
    end
    for k, v in pairs(cbCardList) do
        local card = nil
        if k < 4 and var.cbPublicCard == 2 and (Bit:_and(var.cbWeaveKind,GameCommon.WIK_GANG) ~= 0 or Bit:_and(var.cbWeaveKind,GameCommon.WIK_FILL) ~= 0) then
            card = GameCommon:getDiscardCardAndWeaveItemArray(0,1)
        else
            card = GameCommon:getDiscardCardAndWeaveItemArray(v,1)
            if k == 1 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                card:setColor(cc.c3b(170,170,170))
            elseif k == 2 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                card:setColor(cc.c3b(170,170,170))
            elseif k == 3 and Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                card:setColor(cc.c3b(170,170,170))
            else
            end
        end
        content:addChild(card)
        if k == 4 then
            card:setScale(cardScale) 
            card:setPosition(cardWidth/2+(2-1)*cardWidth,size.height/2+12)
            card:setLocalZOrder(4)  
        else
            card:setScale(cardScale) 
            card:setPosition(cardWidth/2+(k-1)*cardWidth,size.height/2)
            card:setLocalZOrder(3-k)      
        end
    end
    return content
end

function GameEndLayer:showMingTang(wChiHuKind)
    local desc = ""
    --清水胡
    if Bit:_and(wChiHuKind,GameCommon.CHR_QING_YI_SE) ~= 0 then
        desc =desc.."清水胡"
    end
    --小七对
    if Bit:_and(wChiHuKind,GameCommon.CHK_QI_XIAO_DUI) ~= 0 then
        desc =desc.."小七对"      
    end 
    return desc
end

function GameEndLayer:RET_GET_MALL_LOG_FINISH(event)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    local uiPanel_reward = ccui.Helper:seekWidgetByName(self.root,"Panel_reward")
    uiPanel_reward:setVisible(false)
    uiButton_return:setVisible(true)
    uiButton_continue:setVisible(true)
    local uiButton_share = ccui.Helper:seekWidgetByName(self.root,"Button_share")
    uiButton_share:setVisible(true)
end 

function GameEndLayer:SUB_GR_MATCH_TABLE_FAILED(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    if data.wErrorCode == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您在游戏中!")
    elseif data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"游戏配置发生错误!")
    elseif data.wErrorCode == 2 then
        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function()             require("app.views.NewXXMallLayer"):create(2) end)
        else
            require("common.MsgBoxLayer"):create(0,nil,"您的金币不足!")
        end
    elseif data.wErrorCode == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"您的金币已超过上限，请前往更高一级匹配!")
    elseif data.wErrorCode == 4 then
        require("common.MsgBoxLayer"):create(0,nil,"房间已满,稍后再试!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"未知错误,请升级版本!") 
    end
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
end

return GameEndLayer
