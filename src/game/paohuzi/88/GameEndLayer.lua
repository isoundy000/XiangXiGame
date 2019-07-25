local GameCommon = require("game.paohuzi.GameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local GameLogic = require("game.paohuzi.88.GameLogic")
local Common = require("common.Common")

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
end

function GameEndLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:unregistListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
end

function GameEndLayer:onCleanup()

end

function GameEndLayer:onCreate(pBuffer)  
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerYZZiPai_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")   
    
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    local function onEventReturn(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end
    end
    uiButton_return:addTouchEventListener(onEventReturn)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
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
    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
        uiButton_return:setVisible(false)
        uiButton_continue:setPositionX(uiButton_continue:getParent():getContentSize().width/2)
    end

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
    if GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom and pBuffer.lGameScore[GameCommon.meChairID+1] > 0 then 
        uiPanel_reward:setVisible(true)
        uiButton_return:setVisible(false)
        uiButton_continue:setVisible(false)
        local uiText_autoGetReward = ccui.Helper:seekWidgetByName(self.root,"Text_autoGetReward")
        local time = 15
        uiText_autoGetReward:setString(string.format("%d秒后自动领取",time))
        uiText_autoGetReward:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event)
            time = time - 1
            uiText_autoGetReward:setString(string.format("%d秒后自动领取",time))
            if time == 0 then
                uiPanel_reward:setVisible(false)
                uiButton_return:setVisible(true)
                uiButton_continue:setVisible(true)
                GameCommon:GetReward(0)
                return
            end
        end))))
    end 

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
    local  integral = nil
    self.WPnumber = 0
    local number = 0
    for i=1 , GameCommon.gameConfig.bPlayerCount do
        if number < pBuffer.lGameScore[i] then 
            number = pBuffer.lGameScore[i]
        end
        print("玩家得分",pBuffer.lGameScore[i],number)    
    end  

    local uiPanel_result = ccui.Helper:seekWidgetByName(self.root,"Panel_result")
    local viewID = GameCommon:getViewIDByChairID(pBuffer.wWinUser)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("yongzhou/anim/jiesuanshuying/jiesuanshuying.ExportJson")
    local waitArmature=ccs.Armature:create("jiesuanshuying")
    waitArmature:setPosition(0,-100)            
    if GameCommon.gameConfig.bPlayerCount == 3 then        
        if viewID == 2 then --上家赢      
            waitArmature:getAnimation():playWithIndex(2)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 1 then --自己赢  
            waitArmature:getAnimation():playWithIndex(0)
            uiPanel_result:addChild(waitArmature) 
        elseif viewID == 3 then --下家赢    
            waitArmature:getAnimation():playWithIndex(1)
            uiPanel_result:addChild(waitArmature)   
        else
            --无放炮
        end       
    elseif GameCommon.gameConfig.bPlayerCount == 4 then             
        if viewID == 2 then --上家赢     
            waitArmature:getAnimation():playWithIndex(2)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 1 then --自己赢    
            waitArmature:getAnimation():playWithIndex(0)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 4 then --下家赢
            waitArmature:getAnimation():playWithIndex(1)
            uiPanel_result:addChild(waitArmature)
        elseif viewID == 3 then  --对家赢 
            waitArmature:getAnimation():playWithIndex(3)
            uiPanel_result:addChild(waitArmature)
        else
            --无放炮
        end
    elseif GameCommon.gameConfig.bPlayerCount == 2 then     
        if viewID == 1 then --自己赢 
            waitArmature:getAnimation():playWithIndex(0)
            uiPanel_result:addChild(waitArmature)
        else
            waitArmature:getAnimation():playWithIndex(3)
            uiPanel_result:addChild(waitArmature)
        end
    end   

    local uiText_beilv = ccui.Helper:seekWidgetByName(self.root,"Text_beilv")
    uiText_beilv:setString(string.format("倍率：%d",pBuffer.wBeilv))
    local uiText_xiaohao = ccui.Helper:seekWidgetByName(self.root,"Text_xiaohao")
    uiText_xiaohao:setString(string.format("本局消耗：%d",pBuffer.lGameTax))


    local uiText_room = ccui.Helper:seekWidgetByName(self.root,"Text_room")
    local uiText_num = ccui.Helper:seekWidgetByName(self.root,"Text_num")
    uiText_room:setVisible(false)
    uiText_num:setVisible(false)
    if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType== TableType_RedEnvelopeRoom then
        uiText_beilv:setVisible(true)
        uiText_xiaohao:setVisible(true)
    else
        uiText_beilv:setVisible(false)
        uiText_xiaohao:setVisible(false)
        uiText_room:setString(string.format("房间号：%d",GameCommon.tableConfig.wTbaleID)) 
        uiText_num:setString(string.format("局数：%d/%d",GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))
        uiText_room:setVisible(true)   
        uiText_num:setVisible(true)
    end
    
    --结算信息
    local uiListView_info = ccui.Helper:seekWidgetByName(self.root,"ListView_info")
    local uiPanel_defaultInfo = ccui.Helper:seekWidgetByName(self.root,"Panel_defaultInfo")
    uiPanel_defaultInfo:retain()
    uiListView_info:removeAllItems()
    
    local item = uiPanel_defaultInfo:clone()
    local uiHongZiCount = ccui.Text:create("红字数","fonts/DFYuanW7-GB2312.ttf","30")
    item:addChild(uiHongZiCount)     
    uiHongZiCount:setTextColor(cc.c3b(255,165,0)) 
    uiHongZiCount:setAnchorPoint(cc.p(0,0.5))
    uiHongZiCount:setPosition(0,uiHongZiCount:getParent():getContentSize().height/2)
    local uiAtlasLabel_num = ccui.TextAtlas:create(string.format("%d",pBuffer.HuCardInfo.cbHuXiCount),"yongzhou/ui/yongzhou_gameendnum.png",17,24,'0')
    item:addChild(uiAtlasLabel_num)
    uiAtlasLabel_num:setAnchorPoint(cc.p(1,0.5))
    uiAtlasLabel_num:setPosition(uiAtlasLabel_num:getParent():getContentSize().width,uiAtlasLabel_num:getParent():getContentSize().height/2)
    uiListView_info:pushBackCustomItem(item)
    uiPanel_defaultInfo:release()

    local ListView_Characterbox = nil
    local ListView_Characterbox4 = ccui.Helper:seekWidgetByName(self.root,"ListView_Characterbox4")
    ListView_Characterbox4:setVisible(false)    
    local ListView_Characterbox3 = ccui.Helper:seekWidgetByName(self.root,"ListView_Characterbox3")
    ListView_Characterbox3:setVisible(false)
    local ListView_Characterbox2 = ccui.Helper:seekWidgetByName(self.root,"ListView_Characterbox2")
    ListView_Characterbox2:setVisible(false)
    
    if GameCommon.gameConfig.bPlayerCount == 3 then
        ListView_Characterbox3:setVisible(true)
        ListView_Characterbox = ListView_Characterbox3
    elseif GameCommon.gameConfig.bPlayerCount == 4 then
        ListView_Characterbox4:setVisible(true)
        ListView_Characterbox = ListView_Characterbox4
    elseif GameCommon.gameConfig.bPlayerCount == 2 then
        ListView_Characterbox2:setVisible(true)
        ListView_Characterbox = ListView_Characterbox2
    end 
    for key, var in pairs(GameCommon.player) do
        local viewID = GameCommon:getViewIDByChairID(var.wChairID)   
        if  viewID == 3 and GameCommon.gameConfig.bPlayerCount == 2 then 
            viewID = 2 
        end        
        local root = ccui.Helper:seekWidgetByName(ListView_Characterbox,string.format("Panel_Characterbox%d",viewID))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(root,"Image_avatar")
        Common:requestUserAvatar(var.dwUserID,var.szPto,uiImage_avatar,"img") 
        local uiText_name = ccui.Helper:seekWidgetByName(root,"Text_name")       
        uiText_name:setString(string.format("%s",var.szNickName)) 
        local uiText_ID = ccui.Helper:seekWidgetByName(root,"Text_ID")       
        uiText_ID:setString(string.format("ID:%s",var.dwUserID)) 
        local uiAtlasLabel_money = ccui.Helper:seekWidgetByName(root,"Text_money")
        if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType  == TableType_RedEnvelopeRoom then
            uiText_ID:setVisible(false)
        end 
        local dwGold = Common:itemNumberToString(pBuffer.lGameScore[var.wChairID + 1])   
        if pBuffer.lGameScore[var.wChairID + 1] > 0 then 
            uiAtlasLabel_money:setString('+' ..tostring(dwGold))
        else      
            uiAtlasLabel_money:setString(tostring(dwGold))
        end     
    --    uiAtlasLabel_money:setString(string.format("%d",pBuffer.lGameScore[var.wChairID+1] ))
       
        if var.wChairID == GameCommon.meChairID then 
            uiText_name:setColor(cc.c3b(255,255,0))
            uiAtlasLabel_money:setColor(cc.c3b(255,255,0))
        end 

        if GameCommon.gameConfig.bPlayerCount == 4 then
            local uiImage_banker = ccui.Helper:seekWidgetByName(root,"Image_banker")
            uiImage_banker:setVisible(false)
        end
    end
    self:showPaiXing(pBuffer)
    self:showMingTang(pBuffer)
    self:showDiPai(pBuffer)
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    -- uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%d-%d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
    -- end),cc.DelayTime:create(1))))
end

--显示牌型和眼牌
function GameEndLayer:showPaiXing(pBuffer)
    local uiListView_weave = ccui.Helper:seekWidgetByName(self.root,"ListView_weave")
    local uiPanel_defaultWeave = ccui.Helper:seekWidgetByName(self.root,"Panel_defaultWeave")
    uiPanel_defaultWeave:retain()
    uiListView_weave:removeAllChildren()
    local isAddHuPai = false
    for WeaveItemIndex = 1 , pBuffer.HuCardInfo.cbWeaveCount do
        local item = uiPanel_defaultWeave:clone()
        local   WeaveItemArray= pBuffer.HuCardInfo.WeaveItemArray[WeaveItemIndex]            --组合扑克
        for i = 1 , WeaveItemArray.cbCardCount do
            local data = WeaveItemArray.cbCardList[i]
            local _spt=GameCommon:getDiscardCardAndWeaveItemArray(data)
            _spt:setPosition(cc.p(0,(i - 1)*GameCommon.CARD_HUXI_HEIGHT))
            _spt:setAnchorPoint(cc.p(0,0))
            item:addChild(_spt)
        end

        for i = 1 , WeaveItemArray.cbCardCount do
            local data = WeaveItemArray.cbCardList[i]
            local _spt=GameCommon:getDiscardCardAndWeaveItemArray(data)
            if data == pBuffer.cbHuCard and not isAddHuPai then --胡牌
                local di = cc.Sprite:create('zipai/table/img_15.png')
                _spt:addChild(di)
                local size = _spt:getContentSize()
                di:setPosition(size.width / 2,size.height / 2)
                isAddHuPai = true
            end
            _spt:setPosition(cc.p(0,(i - 1)*GameCommon.CARD_HUXI_HEIGHT))
            _spt:setAnchorPoint(cc.p(0,0))
            item:addChild(_spt)
        end

        local WeaveType=self:getSptWeaveType(WeaveItemArray.cbWeaveKind)
        WeaveType:setPosition(cc.p(GameCommon.CARD_HUXI_WIDTH*0.5,5*GameCommon.CARD_HUXI_HEIGHT))
        item:addChild(WeaveType)

        -- local huxicout=GameLogic:GetWeaveHuXi(clone(WeaveItemArray))
        -- local Weavecout=cc.Label:createWithSystemFont(string.format("%d",huxicout), "Arial", 30)
        -- Weavecout:setPosition(cc.p(GameCommon.CARD_HUXI_WIDTH*0.5,-GameCommon.CARD_HUXI_HEIGHT + 20))
        -- item:addChild(Weavecout)

        uiListView_weave:pushBackCustomItem(item)
    end
    uiPanel_defaultWeave:release()
    --眼牌
    if pBuffer.HuCardInfo.cbWeaveCount<=6 and pBuffer.HuCardInfo.cbCardEye ~=0 then
        local item = uiPanel_defaultWeave:clone()
        for i = 0 , 1 do
            local data = pBuffer.HuCardInfo.cbCardEye
            local _spt=GameCommon:getDiscardCardAndWeaveItemArray(data)
            _spt:setPosition(cc.p(0,i*GameCommon.CARD_HUXI_HEIGHT))
            _spt:setAnchorPoint(cc.p(0,0))
            item:addChild(_spt)
        end
        uiListView_weave:pushBackCustomItem(item)
    end 
end

--显示名堂
function GameEndLayer:showMingTang(pBuffer)    
    local uiListView_player = ccui.Helper:seekWidgetByName(self.root,"ListView_player")
    local uiPanel_defaultPalyer = ccui.Helper:seekWidgetByName(self.root,"Panel_defaultPalyer")
    uiPanel_defaultPalyer:retain()
    uiListView_player:removeAllItems()
  
    
    local MingTang_Null                   =0x00000000
    local MingTang_ZiMo                   =0x00000001
    local MingTang_Max                    =0x80000000
    
    if Bit:_and(pBuffer.HuCardInfo.dwMingTang,MingTang_ZiMo)~= 0 then
        local item = uiPanel_defaultPalyer:clone()
        local uiText_mingTang = ccui.Helper:seekWidgetByName(item,"Text_mingTang")
        uiText_mingTang:setTextColor(cc.c3b(255,165,0))
        local uiText_mingTangNumber = ccui.Helper:seekWidgetByName(item,"Text_mingTangNumber")
        uiText_mingTangNumber:setTextColor(cc.c3b(255,165,0))
        uiText_mingTang:setString("自摸")
        uiText_mingTangNumber:setString("+1红")
        uiListView_player:pushBackCustomItem(item)
    end

    uiPanel_defaultPalyer:release()
end

--显示底牌
function GameEndLayer:showDiPai(pBuffer)
    local uiListView_diPai1 = ccui.Helper:seekWidgetByName(self.root,"ListView_diPai1")
    local uiListView_diPai2 = ccui.Helper:seekWidgetByName(self.root,"ListView_diPai2")
    for i = 1, pBuffer.bLeftCardCount do
        if pBuffer.bLeftCardDataEx[i] ~= 0 then
            local item = GameCommon:getDiscardCardAndWeaveItemArray(pBuffer.bLeftCardDataEx[i])
            if i<= 17 then
                uiListView_diPai1:pushBackCustomItem(item)
            else
                uiListView_diPai2:pushBackCustomItem(item)
            end
        end
    end
end

function GameEndLayer:getSptWeaveType(type)
    local sptname = ""
    if type == GameCommon.ACK_TI then
        sptname="zipai/table/endlayer11.png"
    elseif type == GameCommon.ACK_PAO then
        sptname="zipai/table/endlayer9.png"
    elseif type == GameCommon.ACK_WEI then
        sptname="zipai/table/endlayer12.png"
    elseif type == GameCommon.ACK_CHI then
        sptname="zipai/table/endlayer8.png"
    elseif type == GameCommon.ACK_PENG then
        sptname="zipai/table/endlayer10.png"
    else

    end
    return cc.Sprite:create(sptname)
end

function GameEndLayer:RET_GET_MALL_LOG_FINISH(event)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    local uiPanel_reward = ccui.Helper:seekWidgetByName(self.root,"Panel_reward")
    uiPanel_reward:setVisible(false)
    uiButton_return:setVisible(true)
    uiButton_continue:setVisible(true)
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
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
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
end
return GameEndLayer
