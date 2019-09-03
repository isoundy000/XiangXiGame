local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local SDHGameCommon = require("game.puke.SDHGameCommon")  
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

local SDHTableLayer = require("game.puke.SDHTableLayer")

local APPNAME = 'puke'
local GameLayer = class("GameLayer",function()
    return ccui.Layout:create()
end)

function GameLayer:create(...)
    local view = GameLayer.new()
    view:onCreate(...)
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

function GameLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:registListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 0 ,false)
    end
end

function GameLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if SDHGameCommon.tableConfig.nTableType ~= TableType_Playback and self.scheduleUpdateObj then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
    end
    
end

function GameLayer:onCleanup()

end

function GameLayer:onCreate(...)
    self:startGame(...)
end

function GameLayer:startGame(...)
    self:removeAllChildren()
    self:stopAllActions()
    local params = {...}
    SDHGameCommon.dwUserID = params[1]
    SDHGameCommon.tableConfig = params[2]
    SDHGameCommon.playbackData = params[3]
    SDHGameCommon.player = {}
    SDHGameCommon.gameConfig = {}

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerSanDaHa.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    SDHGameCommon:init()
    -- if SDHGameCommon.tableConfig.tableParameter.b15Or16 == 1 then 
        -- SDHGameCommon.MAX_COUNT = 16
    -- else
    --     SDHGameCommon.MAX_COUNT = 15
    -- end
    self.tableLayer = SDHTableLayer:create(self.root)
    self:addChild(self.tableLayer)
    self.tableLayer:initUI()
    self.tableLayer:updateGameState(SDHGameCommon.GameState_Init)
    self.isRunningActions = false
    self.userMsgArray = {} --消息缓存
    SDHGameCommon.regionSound = 0
    
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
        uiButton_Invitation:setVisible(false)
    end
    self:loadingPlayback()
end

function GameLayer:loadingPlayback()
    if SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        return
    end
    local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
    uiPanel_end:setVisible(true)
    uiPanel_end:removeAllChildren()
    uiPanel_end:stopAllActions()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayer_PlaybacLayer.csb")
    uiPanel_end:addChild(csb)
    local root = csb:getChildByName("Panel_root")
    local uiImage_bg = ccui.Helper:seekWidgetByName(root,"Image_bg")
    uiImage_bg:setPositionY(uiImage_bg:getPositionY()+70)
    local uiButton_return = ccui.Helper:seekWidgetByName(root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end)
    local uiButton_play = ccui.Helper:seekWidgetByName(root,"Button_play")
    uiButton_play:setColor(cc.c3b(170,170,170))
    local uiButton_nextStep = ccui.Helper:seekWidgetByName(root,"Button_nextStep")
    Common:addTouchEventListener(uiButton_play,function(sender,event)
        uiButton_nextStep:setColor(cc.c3b(170,170,170))
        uiButton_play:setColor(cc.c3b(255,255,255))
        root:stopAllActions() 
        root:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.DelayTime:create(0),
            cc.CallFunc:create(function(sender,event) self:update(0) end)
            )))
    end)
    Common:addTouchEventListener(uiButton_nextStep,function(sender,event) 
        uiButton_play:setColor(cc.c3b(170,170,170))
        uiButton_nextStep:setColor(cc.c3b(255,255,255))
        root:stopAllActions() 
        self:update()
    end)
    self:AnalysisPlaybackData()
end

function GameLayer:AnalysisPlaybackData()
    if SDHGameCommon.playbackData == nil then
        return
    end
    local luaFunc = require("common.Serialize"):create("",0)
    for key, var in pairs(SDHGameCommon.playbackData) do
        luaFunc:writeSendBuffer(var.cbData,var.wDataSize)
    end
    while 1 do
        local wIdentifier = luaFunc:readRecvWORD()           --类型标示
        local wDataSize = luaFunc:readRecvWORD()             --数据长度
        local mainCmdID = luaFunc:readRecvWORD()            --主命令码
        local subCmdID = luaFunc:readRecvWORD()             --子命令码
        print("回放标志:",wIdentifier,wDataSize,mainCmdID,subCmdID)
        if self:readBuffer(luaFunc,mainCmdID,subCmdID) == false then
            return
        end       
    end
end

function GameLayer:SUB_GR_MATCH_TABLE_ING(event)
    local data = event._usedata
    self:startGame(UserData.User.userID, data)
end

function GameLayer:EVENT_TYPE_NET_RECV_MESSAGE(event)
	local netID = event._usedata
	if netID ~= NetMgr.NET_GAME then
	   return
	end
    local netInstance = NetMgr:getGameInstance()
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    
    local luaFunc = netInstance.cppFunc
    self:readBuffer(luaFunc, mainCmdID, subCmdID)
end

function GameLayer:readBuffer(luaFunc, mainCmdID, subCmdID)
    local _tagMsg = {}
    _tagMsg.mainCmdID = mainCmdID
    _tagMsg.subCmdID = subCmdID
    _tagMsg.pBuffer = {}
    
    if mainCmdID == NetMsgId.MDM_GR_USER then   
       if subCmdID == NetMsgId.SUB_GR_USER_READY then
            --服务器广播用户准备
            local dwUserID = luaFunc:readRecvDWORD()         --用户id
            local wChairID = luaFunc:readRecvWORD()         --椅子号
            SDHGameCommon.player[wChairID].bReady = true
            self:updatePlayerReady()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
            --好友房大结算
            _tagMsg.pBuffer.dwUserCount = luaFunc:readRecvDWORD()                       --用户总数
            _tagMsg.pBuffer.dwDataCount = luaFunc:readRecvDWORD()                       --数据条数
            _tagMsg.pBuffer.tScoreInfo = {}                                             --统计信息
            _tagMsg.pBuffer.bigWinner = 0
            _tagMsg.pBuffer.bigWinerScore = 0
            for i = 1, 8 do
                _tagMsg.pBuffer.tScoreInfo[i] = {}
                _tagMsg.pBuffer.tScoreInfo[i].dwUserID = luaFunc:readRecvDWORD()        --用户ID
                _tagMsg.pBuffer.tScoreInfo[i].player = SDHGameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
                _tagMsg.pBuffer.tScoreInfo[i].totalScore = 0
                _tagMsg.pBuffer.tScoreInfo[i].lScore = {}
                for j = 1, 20 do
                    _tagMsg.pBuffer.tScoreInfo[i].lScore[j] = luaFunc:readRecvLong()       --用户积分
                    _tagMsg.pBuffer.tScoreInfo[i].totalScore = _tagMsg.pBuffer.tScoreInfo[i].totalScore + _tagMsg.pBuffer.tScoreInfo[i].lScore[j]
                end
                if _tagMsg.pBuffer.tScoreInfo[i].totalScore > _tagMsg.pBuffer.bigWinerScore then
                    _tagMsg.pBuffer.bigWinner = _tagMsg.pBuffer.tScoreInfo[i].dwUserID
                    _tagMsg.pBuffer.bigWinerScore = _tagMsg.pBuffer.tScoreInfo[i].totalScore
                end
            end
            _tagMsg.pBuffer.dwTableOwnerID = luaFunc:readRecvDWORD()                    --房主ID
            _tagMsg.pBuffer.szOwnerName = luaFunc:readRecvString(32)                    --房主名字
            _tagMsg.pBuffer.szGameID = luaFunc:readRecvString(32)                    --结算唯一标志
            _tagMsg.pBuffer.tableConfig = SDHGameCommon.tableConfig
            _tagMsg.pBuffer.gameConfig = SDHGameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(SDHGameCommon.tableConfig.wKindID,SDHGameCommon.gameConfig,SDHGameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_CONNECT then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            SDHGameCommon.player[wChairID].cbOnline = 0
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_OFFLINE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            SDHGameCommon.player[wChairID].cbOnline = 0x06
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_LEAVE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            if SDHGameCommon.dwUserID == dwUserID then
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            else
                SDHGameCommon.player[wChairID] = nil
                self:updatePlayerInfo()
                self:updatePlayerPosition()
            end
            return true
            
        elseif subCmdID == NetMsgId.RET_GR_USER_SET_POSITION then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local location = {}
            location.x = luaFunc:readRecvDouble()
            location.y = luaFunc:readRecvDouble()
            local dwUserID = luaFunc:readRecvDWORD()
            local wChairID = luaFunc:readRecvWORD()
            if SDHGameCommon.player[wChairID] ~= nil then
                SDHGameCommon.player[wChairID].location = location
            end
            return true
                
        elseif subCmdID == NetMsgId.SUB_GR_TABLE_STATUS then 
            SDHGameCommon.tableConfig.wTableNumber = luaFunc:readRecvWORD()       --房间局数
            SDHGameCommon.tableConfig.wCurrentNumber = luaFunc:readRecvWORD()    --当前局数
            local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
            local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")
            local roomId = SDHGameCommon.tableConfig.wTbaleID or 0
            local randCeil = SDHGameCommon.tableConfig.wCurrentNumber or 0
            local randFloor = SDHGameCommon.tableConfig.wTableNumber or 0
            uiText_title:setString(StaticData.Games[SDHGameCommon.tableConfig.wKindID].name)
            uiText_des:setString(string.format("房间号:%d 局数:%d/%d",roomId,randCeil,randFloor))
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_SUCCESS then
            if SDHGameCommon.gameState ~= SDHGameCommon.GameState_Init  or SDHGameCommon.tableConfig.wCurrentNumber ~= 0 then
                require("common.MsgBoxLayer"):create(0,nil,"房间解散成功！") 
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            else
                if not UserData.Guild.isChangeClubTable then
                    require("common.MsgBoxLayer"):create(2,nil,"房间解散成功！",function(sender,event) 
                        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                    end)
                else
                    EventMgr:dispatch(EventType.RET_FREE_CLUB_CHANGE_TABLE_NOTICES)
                end
            end
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_STATE then
            local data = {}
            data.dwDisbandedTime = luaFunc:readRecvDWORD()
            data.wAdvocateDisbandedID = luaFunc:readRecvWORD()
            data.cbDisbandeState = {}
            for i = 1, 8 do
                data.cbDisbandeState[i] = luaFunc:readRecvByte()
            end
            data.dwUserIDALL = {}
            for i = 1, 8 do
                data.dwUserIDALL[i] = luaFunc:readRecvDWORD()
            end
            data.szNickNameALL = {}
            for i = 1, 8 do
                data.szNickNameALL[i] = luaFunc:readRecvString(32)
            end
            require("common.DissolutionLayer"):create(SDHGameCommon.player,data)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_COME then 
            --用户进入
            local data = {}
            data.dwUserID = luaFunc:readRecvDWORD()
            data.wChairID = luaFunc:readRecvWORD()
            data.szNickName = luaFunc:readRecvString(32)
            data.szPto = luaFunc:readRecvString(256)
            data.cbSex = luaFunc:readRecvByte()
            data.lScore = luaFunc:readRecvLong() 
            data.dwPlayAddr = luaFunc:readRecvDWORD() 
            data.cbOnline = luaFunc:readRecvByte() 
            data.bReady = luaFunc:readRecvBool() 
            data.location = {}
            data.location.x = luaFunc:readRecvDouble()
            data.location.y = luaFunc:readRecvDouble()
            
            
            data.other = nil
            data.bUserCardCount = 0
            data.cbCardData = nil
            data.bUserWarn = false
            SDHGameCommon.player[data.wChairID] = data
            if data.dwUserID == SDHGameCommon.dwUserID or SDHGameCommon.meChairID == nil then
                SDHGameCommon.meChairID = data.wChairID
            end
                --距离报警 
            if SDHGameCommon.tableConfig.wCurrentNumber ~= nil and SDHGameCommon.tableConfig.wCurrentNumber == 0 then
                SDHGameCommon.DistanceAlarm = 0
            end
            self:updatePlayerInfo()
            self:updatePlayerOnline()
            self:updatePlayerReady()
			self:updatePlayerPosition()
            return true

        elseif subCmdID == NetMsgId.SUB_GR_PLAYER_INFO then 
            --查看玩家信息
            _tagMsg.pBuffer.dwUserID = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.lWinCount = luaFunc:readRecvLong()  
            _tagMsg.pBuffer.lLostCount = luaFunc:readRecvLong()  
            _tagMsg.pBuffer.dwPlayTimeCount = luaFunc:readRecvDWORD()  
            _tagMsg.pBuffer.dwPlayAddr = luaFunc:readRecvDWORD() 
            _tagMsg.pBuffer.dwShamUserID = luaFunc:readRecvDWORD()
            self.tableLayer:showPlayerInfo(_tagMsg.pBuffer)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_SEND_CHAT then
            --用户语言文字聊天
            _tagMsg.pBuffer.dwUserID = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.dwSoundID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbSex = luaFunc:readRecvByte()
            _tagMsg.pBuffer.szNickName = luaFunc:readRecvString(32)
            _tagMsg.pBuffer.dwChatLength = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.szChatContent = luaFunc:readRecvString(_tagMsg.pBuffer.dwChatLength)
            self.tableLayer:showChat(_tagMsg.pBuffer)
            return
        elseif subCmdID == NetMsgId.RET_GET_REDENVELOPE_REWARD then	
            _tagMsg.pBuffer.lRet = luaFunc:readRecvLong()   --0成功   1活动结束     2参数错误   3 玩家不存在           
            _tagMsg.pBuffer.bType = luaFunc:readRecvByte()      --0金币	1红包
            _tagMsg.pBuffer.lCount = luaFunc:readRecvLong()     -- 数量   
            local a = 10
            self.tableLayer:showReward(_tagMsg.pBuffer)
            return     
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.RET_SC_GAME_CONFIG then
            SDHGameCommon.gameConfig = require("common.GameConfig"):getParameter(SDHGameCommon.tableConfig.wKindID,luaFunc)
            local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
            uiText_desc:setString(GameDesc:getGameDesc(SDHGameCommon.tableConfig.wKindID,SDHGameCommon.gameConfig,SDHGameCommon.tableConfig))
            return true
        elseif subCmdID == NetMsgId.REC_SUB_S_JIAPIAO then
            _tagMsg.pBuffer.bIsJiaPiao = {}
            for i = 1 , 3 do
                _tagMsg.pBuffer.bIsJiaPiao[i] = luaFunc:readRecvBool()         --是否已漂
                print("++++++++接受~~~~~~++++++~~~~~~",_tagMsg.pBuffer.bIsJiaPiao[i])	
            end

            _tagMsg.pBuffer.bJiaPiaoCount = {}
            for i = 1 , 3 do
                _tagMsg.pBuffer.bJiaPiaoCount[i] = luaFunc:readRecvByte()         --飘分值
            end
        elseif subCmdID == NetMsgId.SDH_SUB_S_GAME_START then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 60 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()
            
        elseif subCmdID == NetMsgId.SDH_SUB_S_LAND_SCORE then
            _tagMsg.pBuffer.bLandUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bCurrentScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bGiveUpScore = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.bGiveUpScore[i] = luaFunc:readRecvBool()
            end
            _tagMsg.pBuffer.wUserScore = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.wUserScore[i] = luaFunc:readRecvWORD()
            end

        elseif subCmdID == NetMsgId.SDH_SUB_S_SEND_CONCEAL then
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bLandScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbConcealCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbConcealCard = {}
            for i = 1 , 9 do
                _tagMsg.pBuffer.cbConcealCard[i] = luaFunc:readRecvByte()
            end
             _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 60 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()

        elseif subCmdID == NetMsgId.SDH_SUB_S_BACK_CARD then
            _tagMsg.pBuffer.bLandUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bCurrentScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 60 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbConcealCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbConcealCard = {}
            for i = 1 , 9 do
                _tagMsg.pBuffer.cbConcealCard[i] = luaFunc:readRecvByte()
            end

        elseif subCmdID == NetMsgId.SDH_SUB_S_GAME_PLAY then
            _tagMsg.pBuffer.cbMainColor = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
             _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 60 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()

        elseif subCmdID == NetMsgId.SDH_SUB_S_OUT_CARD then
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wWinerUser = luaFunc:readRecvWORD()
             _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 60 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bLastTurn = luaFunc:readRecvBool()
            _tagMsg.pBuffer.bFirstOut = luaFunc:readRecvBool()
            _tagMsg.pBuffer.bCardType = luaFunc:readRecvByte()

        elseif subCmdID == NetMsgId.SDH_SUB_S_TURN_BALANCE then
            _tagMsg.pBuffer.wTurnWinner = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbScoreCardCount = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.cbScoreCardCount[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbScoreCardData = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.cbScoreCardData[i] = {}
                for j=1,24 do
                    _tagMsg.pBuffer.cbScoreCardData[i][j] = luaFunc:readRecvByte()
                end
            end
            _tagMsg.pBuffer.PlayerScore = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.PlayerScore[i] = luaFunc:readRecvWORD()
            end

        elseif subCmdID == NetMsgId.SDH_SUB_S_LOOK_RECARD_CARD then
            _tagMsg.pBuffer.szNickName = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.szNickName[i] = luaFunc:readRecvString(32)
            end
            _tagMsg.pBuffer.szLogoInfo = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.szLogoInfo[i] = luaFunc:readRecvString(256)
            end
            _tagMsg.pBuffer.dwUserID = {}
            for i=1,4 do
                _tagMsg.pBuffer.dwUserID[i] = luaFunc:readRecvDWORD()
            end
            _tagMsg.pBuffer.wBankUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bRecordCardData = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.bRecordCardData[i] = {}
                for j=1,60 do
                    _tagMsg.pBuffer.bRecordCardData[i][j] = luaFunc:readRecvByte()
                end
            end
            _tagMsg.pBuffer.bRecordCardCount = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.bRecordCardCount[i] = luaFunc:readRecvByte()
            end

        elseif subCmdID == NetMsgId.SDH_SUB_S_USER_SURRENDER then
            _tagMsg.pBuffer.bCode = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bSurrenderUser = {}
            for i=1,4 do
                _tagMsg.pBuffer.bSurrenderUser[i] = luaFunc:readRecvByte()
            end
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_CARD_PDK then
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , SDHGameCommon.MAX_COUNT do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bStartCard = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()

        elseif subCmdID == NetMsgId.SUB_S_USER_PASS_CARD_PDK then
            _tagMsg.pBuffer.bNewTurn = luaFunc:readRecvBool()
            _tagMsg.pBuffer.wPassUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
        elseif subCmdID == NetMsgId.SUB_S_BOMB_PDK then   
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()   
            _tagMsg.pBuffer.lBombScore = {}
            for i=1,3 do
                _tagMsg.pBuffer.lBombScore[i] = luaFunc:readRecvLong()
                print("+++++++++++炸弹分数+++++",i,_tagMsg.pBuffer.lBombScore[i])
            end
        elseif subCmdID == NetMsgId.SUB_S_WARN_INFO_PDK then
            _tagMsg.pBuffer.wWarnUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bWarn = luaFunc:readRecvByte()

        elseif subCmdID == NetMsgId.SUB_S_GAME_END_PDK then
            _tagMsg.pBuffer.lScore = {}
            for i=1,4 do
                _tagMsg.pBuffer.lScore[i] = luaFunc:readRecvLong()
            end
            _tagMsg.pBuffer.wGameScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wConcealTime = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wConcealScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbConcealCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbConcealCard = {}
            for i=1,9 do
                _tagMsg.pBuffer.cbConcealCard[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bAddConceal = luaFunc:readRecvBool()

        elseif subCmdID == NetMsgId.SUB_S_RESEDCARD_PDK then
            _tagMsg.pBuffer.bTurnUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bTurnCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.bTurnData = {}
            for i=1,60 do
                _tagMsg.pBuffer.bTurnData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bUserCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.bCardData = {}
            for i=1,60 do
                _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
            end
            
        elseif subCmdID == NetMsgId.SUB_S_SITFAILED then
            _tagMsg.pBuffer.wErrorCode = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.lScore = luaFunc:readRecvLong()
            require("common.MsgBoxLayer"):create(2,nil , "您的金币不符" , function(sender,event) 
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GF_USER_EXPRESSION then
            _tagMsg.pBuffer.wIndex = luaFunc:readRecvWORD()     --索引
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()   --椅子号
            self.tableLayer:showExperssion(_tagMsg.pBuffer)
            return true
        elseif subCmdID == NetMsgId.SUB_GF_USER_EFFECTS then
            local wIndex = luaFunc:readRecvWORD()     --索引
            local wChairID = luaFunc:readRecvWORD()   --椅子号
            local wTargetD = luaFunc:readRecvWORD()   --目标
            self.tableLayer:playSkelStartToEndPos(wChairID,wTargetD,wIndex)        
        elseif subCmdID == NetMsgId.SUB_GF_USER_VOICE then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()               --座位号
            _tagMsg.pBuffer.wPackCount = luaFunc:readRecvWORD()             --包总数
            _tagMsg.pBuffer.wPackIndex = luaFunc:readRecvWORD()            --当前包索引
            _tagMsg.pBuffer.dwTime = luaFunc:readRecvDWORD()                --播放时长
            _tagMsg.pBuffer.dwFileSize = luaFunc:readRecvDWORD()            --文件总长度
            _tagMsg.pBuffer.dwPeriodSize = luaFunc:readRecvDWORD()          --文件一段长度
            _tagMsg.pBuffer.szFileName = luaFunc:readRecvString(32)         --文件名字
            _tagMsg.pBuffer.szPeriodData = luaFunc:readRecvBuffer(_tagMsg.pBuffer.dwPeriodSize) --文件数据
            self.tableLayer:OnUserChatVoice(_tagMsg.pBuffer)      
            return true

        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then 
            _tagMsg.pBuffer.bStatus = luaFunc:readRecvByte()  
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bCardData = {}
            for i=1,60 do
                _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bUserCardCount = {}
            for i=1,4 do
                _tagMsg.pBuffer.bUserCardCount[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wLastOutUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bTurnCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.bTurnCardData = {}
            for i=1,60 do
                _tagMsg.pBuffer.bTurnCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bCurrentScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wUserScore = {}
            for i=1,4 do
                _tagMsg.pBuffer.wUserScore[i] = luaFunc:readRecvWORD()
            end
            _tagMsg.pBuffer.cbConcealCount = luaFunc:readRecvByte()  
            _tagMsg.pBuffer.cbConcealCard = {}
            for i=1,9 do
                _tagMsg.pBuffer.cbConcealCard[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbMainColor = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wGameScore = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.wWinerUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bSurrenderUser = {}
            for i=1,4 do
                _tagMsg.pBuffer.bSurrenderUser[i] = luaFunc:readRecvByte()
            end
            
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
    else
        
        return false
    end
    if self.userMsgArray == nil then 
        return false
    end
    table.insert(self.userMsgArray,#self.userMsgArray + 1,_tagMsg)
    
    print("当前消息数量:%d",#self.userMsgArray)
    printInfo(_tagMsg)
    return true
end

function GameLayer:EVENT_TYPE_CACEL_MESSAGE_BLOCK(event)
    self.isRunningActions = false
end

--消息队列
function GameLayer:update(delta)
    if self.isRunningActions then
        return
    end
    if self.userMsgArray == nil then
        return
    end
    if #self.userMsgArray <=0 then
        return
    end
    local _tagMsg = self.userMsgArray[1]
    self:OnGameMessageRun(_tagMsg)
    --删除动作
    table.remove(self.userMsgArray,1)
end

--消息执行
function GameLayer:OnGameMessageRun(_tagMsg)
    local mainCmdID = _tagMsg.mainCmdID
    local subCmdID = _tagMsg.subCmdID
    local pBuffer = _tagMsg.pBuffer
    
    if mainCmdID == NetMsgId.MDM_GR_USER then   
        if subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
            self:removeAllChildren()
            local path = self:requireClass('PDKGameRoomEnd')
            local box = require("app.MyApp"):create(pBuffer):createGame(path)
            self:addChild(box)
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.SDH_SUB_S_GAME_START then
            --开始游戏
            self.tableLayer:updateGameState(SDHGameCommon.GameState_Start)
            local wChairID = pBuffer.wChairID
            for i = 0, 4 do
                if SDHGameCommon.player[i] ~= nil then
                    SDHGameCommon.player[i].bUserCardCount = pBuffer.cbCardCount
                end
            end

            SDHGameCommon.wBankerUser = pBuffer.wCurrentUser
            self.tableLayer:setHandCard(wChairID,SDHGameCommon.player[wChairID].bUserCardCount, pBuffer.cbCardData)
            
            local viewID = SDHGameCommon:getViewIDByChairID(pBuffer.wCurrentUser)
            self.tableLayer:showHandCard(wChairID,1)         
            self:updatePlayerInfo()
            self:updatehandplate()
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_GAME_START,pBuffer)
            -- self.tableLayer:shoutSorceCtr(pBuffer.wCurrentUser)

        elseif subCmdID == NetMsgId.SDH_SUB_S_LAND_SCORE then
            if pBuffer.bCurrentScore == 255 then
                SDHGameCommon:playAnimationEx("不叫", pBuffer.bLandUser)
            else
                SDHGameCommon:playAnimationEx(string.format("%d分",pBuffer.bCurrentScore), pBuffer.bLandUser)
            end

            if pBuffer.wCurrentUser ~= 65535 then
                self.tableLayer:showCountDown(pBuffer.wCurrentUser, true)     
                self.tableLayer:shoutSorceCtr(pBuffer)
            end
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SDH_SUB_S_SEND_CONCEAL then
            SDHGameCommon.wBankerUser = pBuffer.wBankerUser
            SDHGameCommon.bLandScore = pBuffer.bLandScore
            self:updateBankerUser()
            self.tableLayer:showCountDown(pBuffer.wCurrentUser, true)  
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_SEND_CONCEAL,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SDH_SUB_S_BACK_CARD then
            SDHGameCommon.bLandScore = pBuffer.bCurrentScore
            SDHGameCommon.cbConcealCount = pBuffer.cbConcealCount
            SDHGameCommon.cbConcealCard = pBuffer.cbConcealCard
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_BACK_CARD,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SDH_SUB_S_GAME_PLAY then
            self.tableLayer:showCountDown(pBuffer.wCurrentUser)
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_GAME_PLAY,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SDH_SUB_S_OUT_CARD then
            SDHGameCommon.player[pBuffer.wOutCardUser].bUserCardCount = SDHGameCommon.player[pBuffer.wOutCardUser].bUserCardCount - pBuffer.cbCardCount
            if pBuffer.bFirstOut == true then
                SDHGameCommon.firstOutCard = pBuffer.cbCardData
                SDHGameCommon.firstOutCount = pBuffer.cbCardCount
            end
            self:updatehandplate()
            self.tableLayer:showCountDown(pBuffer.wCurrentUser, pBuffer.bLastTurn)
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_OUT_CARD,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SDH_SUB_S_TURN_BALANCE then
            self.tableLayer:showCountDown(pBuffer.wCurrentUser)
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_TURN_BALANCE,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
        elseif subCmdID == NetMsgId.SDH_SUB_S_LOOK_RECARD_CARD then
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_LOOK_RECARD_CARD,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SDH_SUB_S_USER_SURRENDER then
            self.tableLayer:doAction(NetMsgId.SDH_SUB_S_USER_SURRENDER,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.REC_SUB_S_JIAPIAO then 
            print("++++++++接受++++++~~~~~~",SDHGameCommon.gameConfig)
            self:updatePlayerPiaoFen(pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end))) 
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_CARD_PDK then
            local wChairID = pBuffer.wChairID
            SDHGameCommon.player[wChairID].bUserCardCount = SDHGameCommon.MAX_COUNT
            self.tableLayer:setHandCard(wChairID,SDHGameCommon.player[wChairID].bUserCardCount, pBuffer.cbCardData)
            self.tableLayer:showHandCard(wChairID,1)     
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
   
        elseif subCmdID == NetMsgId.SUB_S_BOMB_PDK then     
            for i = 0 , SDHGameCommon.gameConfig.bPlayerCount do
                if SDHGameCommon.player[i] ~= nil then
                    SDHGameCommon.player[i].lScore = SDHGameCommon.player[i].lScore + pBuffer.lBombScore[i+1]
                end
            end
            self:updatePlayerlScore()
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        elseif subCmdID == NetMsgId.SUB_S_WARN_INFO_PDK then
            self.tableLayer:doAction(NetMsgId.SUB_S_WARN_INFO_PDK,pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_GAME_END_PDK then
            for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
                SDHGameCommon.player[i-1].lScore = SDHGameCommon.player[i-1].lScore + pBuffer.lScore[i]
                SDHGameCommon.player[i-1].bReady = false
            end
            self:updatePlayerlScore()

            local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            uiPanel_end:setVisible(true)
            uiPanel_end:removeAllChildren()
            uiPanel_end:stopAllActions()
            uiPanel_end:runAction(cc.Sequence:create(
                cc.DelayTime:create(1),
                cc.CallFunc:create(function()
                    if pBuffer.bAddConceal then
                        self.tableLayer:refreshScores(pBuffer.wGameScore)
                    end
                    local path = self:requireClass('SDHGameEndLayer')
                    uiPanel_end:addChild(require("app.MyApp"):create(pBuffer):createGame(path))
                end)
            ))
            self.tableLayer:doAction(NetMsgId.SUB_S_GAME_END_PDK,pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SUB_S_RESEDCARD_PDK then
            local wChairID = SDHGameCommon:getRoleChairID()
            SDHGameCommon.player[wChairID].bUserCardCount = pBuffer.bUserCardCount
            self.tableLayer:setHandCard(wChairID,SDHGameCommon.player[wChairID].bUserCardCount,pBuffer.bCardData)
            self.tableLayer:showHandCard(wChairID,0)

            if pBuffer.bTurnCount > 0 then
                local data = {
                    cbCardCount = pBuffer.bTurnCount,
                    cbCardData = pBuffer.bTurnData,
                    wCurrentUser = wChairID,
                    wOutCardUser = pBuffer.bTurnUser,
                }
                self.tableLayer:doAction(NetMsgId.SDH_SUB_S_OUT_CARD,data)
            end
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
                        
        else 
            return print("error, not found this :",mainCmdID, subCmdID)
        end

    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then
            --游戏重连
            SDHGameCommon.mainColor = pBuffer.cbMainColor
            SDHGameCommon.bLandScore = pBuffer.bCurrentScore
            SDHGameCommon.cbConcealCount = pBuffer.cbConcealCount
            SDHGameCommon.cbConcealCard = pBuffer.cbConcealCard
            self.tableLayer:updateGameState(SDHGameCommon.GameState_Start)
            local wChairID = SDHGameCommon:getRoleChairID()
            SDHGameCommon.wBankerUser = pBuffer.wBankerUser
            for i = 1, SDHGameCommon.gameConfig.bPlayerCount do
                SDHGameCommon.player[i-1].bUserCardCount = pBuffer.bUserCardCount[i]
            end
            self:updatehandplate()
            self.tableLayer:setHandCard(wChairID,SDHGameCommon.player[wChairID].bUserCardCount,pBuffer.bCardData)
            self.tableLayer:showHandCard(wChairID,0)
            self:updateBankerUser()
            self:updatePlayerInfo()
            self.tableLayer:showCountDown(pBuffer.wCurrentUser, true)
            self.tableLayer:reconnectTable(pBuffer)

            if pBuffer.bStatus == 105 then
                --叫分状态
                self.tableLayer:shoutSorceCtr({
                    wCurrentUser = pBuffer.wCurrentUser, 
                    bCurrentScore = pBuffer.bCurrentScore, 
                    wUserScore = pBuffer.wUserScore})
            elseif pBuffer.bStatus == 102 then
                --埋底状态
                self.tableLayer:conCealCtr({
                    wCurrentUser = pBuffer.wCurrentUser, 
                    cbCardCount = SDHGameCommon.player[wChairID].bUserCardCount,
                    cbCardData = pBuffer.bCardData,
                    cbConcealCount = pBuffer.cbConcealCount,
                    cbConcealCard = pBuffer.cbConcealCard,
                    bLandScore = pBuffer.bCurrentScore,
                })
            elseif pBuffer.bStatus == 101 then
                --叫主状态
                self.tableLayer:shoutBankerCtr({
                    wCurrentUser = pBuffer.wCurrentUser,
                })

                if pBuffer.wBankerUser == SDHGameCommon:getRoleChairID() then
                    local Button_buttomCard = ccui.Helper:seekWidgetByName(self.root,"Button_buttomCard")
                    Button_buttomCard:setTouchEnabled(true)
                    Button_buttomCard:setColor(cc.c3b(255, 255, 255))
                end

            elseif pBuffer.bStatus == 103 then
                --出牌状态
                self.tableLayer:showCountDown(pBuffer.wCurrentUser)

                if pBuffer.bTurnCardCount > 0 then
                    SDHGameCommon.bIsOutCard = true
                    local data = {
                        cbCardCount = pBuffer.bTurnCardCount,
                        cbCardData = pBuffer.bTurnCardData,
                        wCurrentUser = pBuffer.wCurrentUser,
                        wOutCardUser = pBuffer.wLastOutUser,
                        wWinerUser = pBuffer.wWinerUser,
                    }
                    self.tableLayer:doAction(NetMsgId.SDH_SUB_S_OUT_CARD,data)
                end

                if pBuffer.wBankerUser == SDHGameCommon:getRoleChairID() then
                    local Button_buttomCard = ccui.Helper:seekWidgetByName(self.root,"Button_buttomCard")
                    Button_buttomCard:setTouchEnabled(true)
                    Button_buttomCard:setColor(cc.c3b(255, 255, 255))
                end
            end   
            self.tableLayer:reconnectSurrender(pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
    else
        return print("error, not found this :",mainCmdID, subCmdID)
    end
    self.isRunningActions = true
    
end

function GameLayer:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    self:startGame(UserData.User.userID, data)
    if self.tableLayer then
        self.tableLayer:setUserHeadCliping(data.node, data.img)
    end
end

--更新玩家信息
function GameLayer:updatePlayerInfo()
    if SDHGameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    uiPanel_player:setVisible(true)
    for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i - 1
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        uiPanel_player:setVisible(true)
        
        if SDHGameCommon.player == nil or SDHGameCommon.player[wChairID] == nil then
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(false)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
           uiImage_avatar:loadTexture("common/hall_avatar.png")
            -- Common:setUserHeadCliping(uiImage_avatar)
            self:userInfoState(wChairID,false)
        else
            print(wChairID, viewID,SDHGameCommon.player[wChairID].szNickName)
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            self:userInfoState(wChairID,true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(SDHGameCommon.player[wChairID].dwUserID,SDHGameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setString(SDHGameCommon.player[wChairID].szNickName)
            local Text_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score") 
            --个人添加
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(SDHGameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))             
        end
    end
    self.tableLayer:refreshTableInfo()
end

function GameLayer:updatePlayerPiaoFen(pBuffer)
    if SDHGameCommon.gameConfig == nil then
        return
   end
   for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
    print("++++++++接受++++++~~~~~~",pBuffer.bIsJiaPiao[i],SDHGameCommon.meChairID,wChairID)
        local wChairID = i-1
        if SDHGameCommon.player ~= nil and SDHGameCommon.player[wChairID] ~= nil  then
            if SDHGameCommon.meChairID == wChairID then 
                local uiPanel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
                if  pBuffer.bIsJiaPiao[i] == false then 
                    print("++++++++接受++++++~~~~~~",pBuffer.bIsJiaPiao[i])
                    --飘分
                   -- local uiPanel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
                    uiPanel_piaoFen:setVisible(true)
                    self.tableLayer:addClickItem()
                else
                    uiPanel_piaoFen:setVisible(false)
                end 
            end       
            local viewID = SDHGameCommon:getViewIDByChairID(wChairID) 
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_piao = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_piao")
            uiImage_piao:setVisible(false)
            print('--->>xx>>>x',pBuffer.bIsJiaPiao[i],pBuffer.bJiaPiaoCount[i])      
            if pBuffer.bIsJiaPiao[i] == true and pBuffer.bJiaPiaoCount[i] ~= 0  then
                uiImage_piao:setVisible(true)
                uiImage_piao:loadTexture(string.format('game/pukenew_score_%d.png', pBuffer.bJiaPiaoCount[i]))
            end
        end 
   end 
end 

function GameLayer:updatePlayerlScore()
    if SDHGameCommon.gameConfig == nil then
        return
    end
    for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        local dwGold = Common:itemNumberToString(SDHGameCommon.player[wChairID].lScore)
        uiText_score:setString(tostring(dwGold))   
    end
end

function GameLayer:updateBankerUser()
    for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
        if SDHGameCommon.player[wChairID] ~= nil and SDHGameCommon.player[wChairID].wChairID == SDHGameCommon.wBankerUser then
            uiImage_banker:setVisible(true)
        else
            uiImage_banker:setVisible(false)
        end 
    end
end

function GameLayer:updatePlayerReady()
    if SDHGameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if SDHGameCommon.player ~= nil and SDHGameCommon.player[wChairID] ~= nil then
            local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            local BitmapFontLabel_score = ccui.Helper:seekWidgetByName(uiPanel_player,"BitmapFontLabel_score")
            if SDHGameCommon.player[wChairID].bReady == true then
                uiImage_ready:setVisible(true)
                BitmapFontLabel_score:setVisible(false)
            else
                uiImage_ready:setVisible(false)
            end
            if SDHGameCommon.player[wChairID].dwUserID == SDHGameCommon.dwUserID and SDHGameCommon.player[wChairID].bReady == true or SDHGameCommon.gameState == SDHGameCommon.GameState_Start then
                local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
                uiButton_ready:setVisible(false)
            end            
        end     
    end

end

function GameLayer:updatePlayerOnline()
    if SDHGameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if SDHGameCommon.player ~= nil and SDHGameCommon.player[wChairID] ~= nil then
            local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_offline = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_offline")
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            if SDHGameCommon.player[wChairID].cbOnline == 0x06 then
                uiImage_offline:setVisible(true)
                uiImage_avatar:setColor(cc.c3b(170,170,170))
            else
                uiImage_offline:setVisible(false)
                uiImage_avatar:setColor(cc.c3b(255,255,255))
            end
            self:userInfoState(wChairID,true)
        end     
    end
end

function GameLayer:updatehandplate()
    if  SDHGameCommon.gameConfig == nil then
        return
    end

    for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_paishu = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_paishu")
        uiImage_paishu:setVisible(true)   
        local uiText_Houdplate = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_Houdplate")
        uiText_Houdplate:setString(string.format("%d",SDHGameCommon.player[wChairID].bUserCardCount))
    end
end

function GameLayer:updatePlayerPosition()
    if SDHGameCommon.tableConfig.nTableType == TableType_FriendRoom or SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom and SDHGameCommon.tableConfig.wCurrentNumber == 0  then
        self.tableLayer:showPlayerPosition(SDHGameCommon.tableConfig.wKindID)
    end
end

function GameLayer:requireClass(name)
	local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

--isInGame 是否在游戏里面
function GameLayer:userInfoState( wChairID,isInGame )
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    if viewID == 1 then
        return
    end
    if uiPanel_player then
        local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame_defout")

        --uiPanel_playerInfo:setVisible(not isInGame)
    
        local Image_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        Image_avatar:setVisible(isInGame)
    
        local Image_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        Image_avatarFrame:setVisible(isInGame)
    end
end

return GameLayer


