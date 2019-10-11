local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local GameCommon = require("game.puke.GameCommon")  
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

local NiuTableLayer = require("game.puke.NiuTableLayer")


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
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 0 ,false)
    end

end

function GameLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if GameCommon.tableConfig.nTableType ~= TableType_Playback and self.scheduleUpdateObj then
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
    GameCommon.dwUserID = params[1]
    GameCommon.tableConfig = params[2]
    GameCommon.playbackData = params[3]
    GameCommon.player = {}
    GameCommon.gameConfig = {}
    
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerNewNiu.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb     
    GameCommon:init()
    GameCommon.MAX_COUNT = 15
    self.tableLayer = NiuTableLayer:create(self.root)
    self:addChild(self.tableLayer)
    self.tableLayer:initUI()
    self.tableLayer:updateGameState(GameCommon.GameState_Init)
    self.isRunningActions = false
    self.userMsgArray = {} --消息缓存
    GameCommon.regionSound = 0
    
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
        uiButton_Invitation:setVisible(false)
    end
    self:loadingPlayback()
end

function GameLayer:loadingPlayback()
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
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
    if GameCommon.playbackData == nil then
        return
    end
    local luaFunc = require("common.Serialize"):create("",0)
    for key, var in pairs(GameCommon.playbackData) do
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
    print(string.format("game: mainCmdID = %d  subCmdID = %d",mainCmdID,subCmdID))
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
            GameCommon.player[wChairID].bReady = true
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
                _tagMsg.pBuffer.tScoreInfo[i].player = GameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
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
            _tagMsg.pBuffer.tableConfig = GameCommon.tableConfig
            _tagMsg.pBuffer.gameConfig = GameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因

        elseif subCmdID == NetMsgId.SUB_GR_GAME_STATISTICS then
            _tagMsg.pBuffer.dwUserCount = luaFunc:readRecvDWORD()                       --用户总数
			_tagMsg.pBuffer.dwDataCount = luaFunc:readRecvDWORD()                       --数据条数
            _tagMsg.pBuffer.tScoreInfo = {}                                             --统计信息
            _tagMsg.pBuffer.statistics = {}                                             --统计
			_tagMsg.pBuffer.bigWinner = 0
			_tagMsg.pBuffer.bigWinerScore = 0
            for i = 1, 8 do
                _tagMsg.pBuffer.statistics[i] = {}
				_tagMsg.pBuffer.tScoreInfo[i] = {}
				_tagMsg.pBuffer.tScoreInfo[i].dwUserID = luaFunc:readRecvDWORD()        --用户ID
				_tagMsg.pBuffer.tScoreInfo[i].player = GameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
				_tagMsg.pBuffer.tScoreInfo[i].totalScore = luaFunc:readRecvLong()       --用户总积分
                print("+++++++++++++~~~~~~",i,_tagMsg.pBuffer.tScoreInfo[i].totalScore)
                for j=1,16 do
                    _tagMsg.pBuffer.statistics[i][j] = luaFunc:readRecvByte()        --用户ID
                end

			end
			_tagMsg.pBuffer.dwTableOwnerID = luaFunc:readRecvDWORD()                    --房主ID
			_tagMsg.pBuffer.szOwnerName = luaFunc:readRecvString(32)                    --房主名字
            _tagMsg.pBuffer.szGameID = luaFunc:readRecvString(32)                    --结算唯一标志
            _tagMsg.pBuffer.GameCommon = GameCommon
			_tagMsg.pBuffer.tableConfig = GameCommon.tableConfig
			_tagMsg.pBuffer.gameConfig = GameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID, GameCommon.gameConfig, GameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因

        elseif subCmdID == NetMsgId.SUB_GR_USER_CONNECT then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            GameCommon.player[wChairID].cbOnline = 0
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_OFFLINE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            GameCommon.player[wChairID].cbOnline = 0x06
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_LEAVE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            if GameCommon.dwUserID == dwUserID then
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            else
                GameCommon.player[wChairID] = nil
                self:updatePlayerInfo()
            end
            return true
            
        elseif subCmdID == NetMsgId.RET_GR_USER_SET_POSITION then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local location = {}
            location.x = luaFunc:readRecvDouble()
            location.y = luaFunc:readRecvDouble()
            local dwUserID = luaFunc:readRecvDWORD()
            local wChairID = luaFunc:readRecvWORD()
            if GameCommon.player[wChairID] ~= nil then
                GameCommon.player[wChairID].location = location
            end
            return true
                
        elseif subCmdID == NetMsgId.SUB_GR_TABLE_STATUS then 
            GameCommon.tableConfig.wTableNumber = luaFunc:readRecvWORD()       --房间局数
            GameCommon.tableConfig.wCurrentNumber = luaFunc:readRecvWORD()    --当前局数
            local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
            uiText_title:setString(string.format("%s 房间号:%d 局数:%d/%d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_SUCCESS then
            if GameCommon.gameState ~= GameCommon.GameState_Init then
                require("common.MsgBoxLayer"):create(0,nil,"房间解散成功！") 
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            else
                require("common.MsgBoxLayer"):create(2,nil,"房间解散成功！",function(sender,event) 
                    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                end)   
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
            require("common.DissolutionLayer"):create(GameCommon.player,data)
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
            data.cbBetting = 0
            data.cbGrabBanker = 0
            printInfo(data)
            GameCommon.player[data.wChairID] = data
            if data.dwUserID == GameCommon.dwUserID or GameCommon.meChairID == nil then
                GameCommon.meChairID = data.wChairID
            end
            self:updatePlayerInfo()
            self:updatePlayerOnline()
            self:updatePlayerReady()
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
            
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.RET_SC_GAME_CONFIG then
            GameCommon.gameConfig = require("common.GameConfig"):getParameter(GameCommon.tableConfig.wKindID,luaFunc)
            local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
            uiText_desc:setString(GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig))
            return true
			
        elseif subCmdID == NetMsgId.SUB_S_GAME_START_PDK then 
            
        elseif subCmdID == NetMsgId.REC_SUB_S_UPDATE_BANKER then
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbGrabBanker = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.cbGrabBanker[i] = luaFunc:readRecvByte()
            end
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SEND_CARD then
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1, 5 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD then
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1, 5 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bBettingType = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wPushChairID = luaFunc:readRecvByte()   --推注用户
        
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING_RESULT then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbBetting = luaFunc:readRecvByte()
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bMultiple = luaFunc:readRecvByte() 
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bMultiple = luaFunc:readRecvByte() 
        
        elseif subCmdID == NetMsgId.REC_SUB_S_GAME_END then
            _tagMsg.pBuffer.lGameScore = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong()  
            end
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_RESULT then
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1, 5 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbValueType = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbMaxValue = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbFanBei = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbLastCardData = luaFunc:readRecvByte()
    
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_TIPS then
            
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
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()                    --庄家用户
            _tagMsg.pBuffer.wPushChairID = luaFunc:readRecvWORD()                    --推注用户
            _tagMsg.pBuffer.isGameStart = luaFunc:readRecvBool()                    --游戏是否开始
            _tagMsg.pBuffer.cbWaitType = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbPlayingCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbPlaying = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.cbPlaying[i] = luaFunc:readRecvBool()                  --亮牌
            end
            _tagMsg.pBuffer.cbBetting = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.cbBetting[i] = luaFunc:readRecvByte()               --玩家押注
            end
            _tagMsg.pBuffer.cbGrabBanker = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.cbGrabBanker[i] = luaFunc:readRecvByte()            --抢庄
            end
            _tagMsg.pBuffer.cbShow = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.cbShow[i] = luaFunc:readRecvBool()                  --亮牌
            end
            _tagMsg.pBuffer.bCardData = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.bCardData[i] ={}
                for j = 1, 5 do
                    _tagMsg.pBuffer.bCardData[i][j] = luaFunc:readRecvByte()        --扑克
                end                    
            end
            _tagMsg.pBuffer.stuCompareCard = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.stuCompareCard[i] = {}
                _tagMsg.pBuffer.stuCompareCard[i].cbCardData = {}
                for j = 1, 5 do
                    _tagMsg.pBuffer.stuCompareCard[i].cbCardData[j] = luaFunc:readRecvByte()
                end
                _tagMsg.pBuffer.stuCompareCard[i].wChairID = luaFunc:readRecvWORD()
                _tagMsg.pBuffer.stuCompareCard[i].cbValueType = luaFunc:readRecvByte()
                _tagMsg.pBuffer.stuCompareCard[i].cbMaxValue = luaFunc:readRecvByte()
                _tagMsg.pBuffer.stuCompareCard[i].cbFanBei = luaFunc:readRecvByte()
            end   
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
    else
        print("not found this mainCmdID : %d",mainCmdID)
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
        
        if subCmdID == NetMsgId.SUB_GR_GAME_STATISTICS then
            self:removeAllChildren()
            local layer = require("common.KwxDLGameOver"):create(pBuffer)
            self:addChild(layer)
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end

        -- if subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
        --     self:removeAllChildren()
        --     local layer = require("common.FriendsRoomEndLayer"):create(pBuffer)
        --     self:addChild(layer)
        -- else
        --     return print("error, not found this :",mainCmdID, subCmdID)
        -- end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.SUB_S_GAME_START_PDK then
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        elseif subCmdID == NetMsgId.REC_SUB_S_UPDATE_BANKER then
            GameCommon.wBankerUser = pBuffer.wBankerUser
            self:updateBankerUser(pBuffer.cbGrabBanker)
            local time = 0
            if GameCommon.gameConfig.bBankerType == 1 then
                time = 2
            elseif GameCommon.gameConfig.bBankerType == 2 and (GameCommon.gameConfig ~= nil and GameCommon.tableConfig.wCurrentNumber == 1) then
                time = 2
            end
            self:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SEND_CARD then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_SEND_CARD,pBuffer)
      
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD then
            self:updatePlayerPush()
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING then
            self:updatePlayerPush(pBuffer.wPushChairID)
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_BETTING,pBuffer)
        
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING_RESULT then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_BETTING_RESULT,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT,pBuffer)
                    
        elseif subCmdID == NetMsgId.REC_SUB_S_GAME_END then
            for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
                if GameCommon.player[i] ~= nil then
                    GameCommon.player[i].lScore = GameCommon.player[i].lScore + pBuffer.lGameScore[i]
                    self.tableLayer:doAction(NetMsgId.REC_SUB_S_GAME_END,{wChairID = i, lGameScore = pBuffer.lGameScore[i]})
                    if GameCommon.tableConfig.nTableType == TableType_GoldRoom then
                        GameCommon.player[i].lScore = GameCommon.player[i].lScore - GameCommon.tableConfig.wCellScore/2
                        if GameCommon.player[i].lScore < 0 then
                            GameCommon.player[i].lScore = 0
                        end
                    end
                end
            end
            self:updatePlayerlScore()
            self.tableLayer:updateGameState(GameCommon.GameState_Over)
            local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            uiPanel_end:setVisible(true)
            uiPanel_end:stopAllActions()
            if GameCommon.tableConfig.nTableType ~= TableType_Playback then
                local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
                uiButton_continue:setVisible(true)
                Common:addTouchEventListener(uiButton_continue,function() 
                    uiPanel_end:stopAllActions()
                    if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                        EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                    else
                        GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                    end
                end)
            end 
            uiPanel_end:stopAllActions()
            uiPanel_end:runAction(cc.Sequence:create(
                cc.CallFunc:create(function(sender,event) 
                    if GameCommon.tableConfig.nTableType == TableType_SportsRoom then
                        pBuffer.wKindID =GameCommon.tableConfig.wKindID
                        uiPanel_end:addChild(require("common.SportsGameEndLayer"):create(pBuffer))  
                    end 
                end),
                cc.DelayTime:create(4),
                cc.CallFunc:create(function(sender,event) 
                    if GameCommon.tableConfig.nTableType > TableType_GoldRoom then
                        if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                            EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                        else
                            GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                        end
                    else
                        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                    end
                end)))
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_RESULT then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_SHOW_RESULT,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_TIPS then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_SHOW_TIPS,pBuffer)
                                    
        else 
            return print("error, not found this :",mainCmdID, subCmdID)
        end

    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then
            --游戏重连
            local wChairID = GameCommon:getRoleChairID()
            if pBuffer.cbPlaying[wChairID] == true then 
                if pBuffer.cbWaitType ~= 0 then
                    self.tableLayer:updateGameState(GameCommon.GameState_Start)
                end
                
                GameCommon.wBankerUser = pBuffer.wBankerUser
                self:updateBankerUser(pBuffer.cbGrabBanker)
                self.tableLayer:showCountDown(pBuffer.cbWaitType)
                if pBuffer.cbWaitType == 1 then
                    --抢庄
                    for i = 0, GameCommon.gameConfig.bPlayerCount-1 do
                        if pBuffer.cbGrabBanker[i] > 0 then
                            local viewID = GameCommon:getViewIDByChairID(i)
                            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                            local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
                            uiImage_grabBanker:setVisible(true)
                            uiImage_grabBanker:loadTexture(string.format("puke/table/pukenew_cell_%d.png",pBuffer.cbGrabBanker[i]))
                        end
                    end
                    self.tableLayer:setHandCard(wChairID,pBuffer.bCardData[wChairID])
                    self.tableLayer:showHandCard(wChairID,0)

                    for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
                        if GameCommon.player[i] ~= nil  and i ~= wChairID then
                            if  GameCommon.gameConfig.bBankerType == 1 then 
                                self.tableLayer:showHandPBCard(i,2)   
                            else
                                self.tableLayer:showHandPBCard(i,1)   
                            end 
                        end 
                    end 

                    if pBuffer.cbGrabBanker[wChairID] == 0 then
                         self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER)
                         return
                    else
                    
                    end
                elseif pBuffer.cbWaitType == 2 then
                    --押注
                    self:updatePlayerPush(pBuffer.wPushChairID)
                    if GameCommon.gameConfig.bBankerType == 1 then
                        self.tableLayer:setHandCard(wChairID,pBuffer.bCardData[wChairID])
                        self.tableLayer:showHandCard(wChairID,0)

                        for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
                            if GameCommon.player[i] ~= nil  and i ~= wChairID then
                                if  GameCommon.gameConfig.bBankerType == 1 then 
                                    self.tableLayer:showHandPBCard(i,2)   
                                else
                                    self.tableLayer:showHandPBCard(i,1)   
                                end 
                            end 
                        end 

                        local viewID = GameCommon:getViewIDByChairID(pBuffer.wBankerUser)
                        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                        local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
                        uiImage_grabBanker:setVisible(true)
                        uiImage_grabBanker:loadTexture(string.format("puke/table/pukenew_cell_%d.png",pBuffer.cbGrabBanker[pBuffer.wBankerUser]))
                    end
                    if pBuffer.cbBetting[wChairID] == 0 then
                        self.tableLayer:doAction(NetMsgId.REC_SUB_S_BETTING, {wChairID = pBuffer.wPushChairID, bBettingType = GameCommon.gameConfig.bBettingType})
                        return
                    end
                    
            
                elseif pBuffer.cbWaitType == 3 then
                    --亮牌
                    if GameCommon.gameConfig.bBankerType == 1 then
                        local viewID = GameCommon:getViewIDByChairID(pBuffer.wBankerUser)
                        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                        local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
                        uiImage_grabBanker:setVisible(true)
                        uiImage_grabBanker:loadTexture(string.format("puke/table/pukenew_cell_%d.png",pBuffer.cbGrabBanker[pBuffer.wBankerUser]))
                    end
                    for i = 0, GameCommon.gameConfig.bPlayerCount-1 do
                        if pBuffer.cbBetting[i] > 0 then
                            local viewID = GameCommon:getViewIDByChairID(i)
                            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                            local uiImage_betting = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_betting")
                            uiImage_betting:setVisible(true)
                            local uiText_fenshu = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_fenshu")
                            uiText_fenshu:setString(string.format("%d分",pBuffer.cbBetting))
                            --uiImage_betting:loadTexture(string.format("puke/table/pukenew_score_%d.png",pBuffer.cbBetting[i]))
                        end
                        if pBuffer.cbShow[i] == true then
                            self.tableLayer:setHandCard(i,pBuffer.stuCompareCard[i].cbCardData)
                            self.tableLayer:showHandCard(i,2,pBuffer.stuCompareCard[i].cbValueType)
                            GameCommon:playAnimation(self.root,pBuffer.stuCompareCard[i].cbValueType,i)
                        end
                    end
                    if pBuffer.cbShow[wChairID] == false then
                        self.tableLayer:setHandCard(wChairID,pBuffer.bCardData[wChairID])
                        self.tableLayer:showHandCard(wChairID,0)
                        self.tableLayer:doAction(NetMsgId.REC_SUB_S_SHOW_TIPS)
                        return
                    end
                else
                
                end
            end
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
end

--更新玩家信息
function GameLayer:updatePlayerInfo(wNewChairID)
    if GameCommon.gameConfig == nil then
        return
    end
    if wNewChairID == nil then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
        uiPanel_player:setVisible(true)
        for i = 1 , GameCommon.gameConfig.bPlayerCount do
            local wChairID = i - 1
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            if GameCommon.player == nil or GameCommon.player[wChairID] == nil then
                local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
                uiPanel_playerInfo:setVisible(false)
                uiPanel_player:setVisible(false)
            else
                uiPanel_player:setVisible(true)
                print(wChairID, viewID,GameCommon.player[wChairID].szNickName)
                local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
                uiPanel_playerInfo:setVisible(true)
                local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
                Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
                local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
                uiText_name:setString(GameCommon.player[wChairID].szNickName)
                --个人添加
                local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
                local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
            	uiText_score:setString(tostring(dwGold))             
            end
        end
    else
        local wChairID = wNewChairID
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        if GameCommon.player == nil or GameCommon.player[wChairID] == nil then
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(false)
            uiPanel_player:setVisible(false)
        else
            uiPanel_player:setVisible(true)
            print(wChairID, viewID,GameCommon.player[wChairID].szNickName)
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
            --个人添加
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))             
        end
    end
end

function GameLayer:updatePlayerlScore()
    if GameCommon.gameConfig == nil then
        return
    end
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player[wChairID] then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))   
        end
    end
end

function GameLayer:updateBankerUser(cbGrabBanker)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    uiPanel_player:stopAllActions()
    if (GameCommon.gameConfig.bBankerType == 1 or ((GameCommon.gameConfig.bBankerType == 2 or GameCommon.gameConfig.bBankerType == 4) and (GameCommon.gameConfig ~= nil and GameCommon.tableConfig.wCurrentNumber == 1))) and cbGrabBanker ~= nil and GameCommon.player[GameCommon.wBankerUser] ~= nil then
        local value = cbGrabBanker[GameCommon.wBankerUser]
        local tableSwitchBanker = {}
        for i = 0, 7 do
            if cbGrabBanker[i] == value then
                local viewID = GameCommon:getViewIDByChairID(i)
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
                local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
                uiImage_grabBanker:loadTexture(string.format("puke/table/pukenew_cell_%d.png",cbGrabBanker[i]))
                table.insert(tableSwitchBanker,#tableSwitchBanker+1,uiImage_banker)
            end
        end
        local index = 0
        local count = #tableSwitchBanker
        local time = os.time()
        local function onBanker(sender,event)
            index = index + 1
            local target = (index + count)%count + 1
            for key, var in pairs(tableSwitchBanker) do
                if target == key then
                    var:setVisible(true)
                else
                    var:setVisible(false)
                end
        	end
            if os.time() - time > 1.5 then
                uiPanel_player:stopAllActions()
                self:updateBankerUser()
        	end
        end
        if #tableSwitchBanker >= 2 then
            require("common.Common"):playEffect("puke/table/suijizhuang.mp3")
            uiPanel_player:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(onBanker),cc.DelayTime:create(0.1))))
        else
            self:updateBankerUser()
        end
    else
         for i = 1 , GameCommon.gameConfig.bPlayerCount do
            local wChairID = i-1
            if GameCommon.player[wChairID] ~= nil then
                local viewID = GameCommon:getViewIDByChairID(wChairID)
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
                local uiImage_grabBanker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_grabBanker")
                print("庄家用户++++++++++++++",GameCommon.wBankerUser,GameCommon.player[wChairID].wChairID )
                if GameCommon.player[wChairID].wChairID == GameCommon.wBankerUser then
                    uiImage_banker:setVisible(true)
                    uiImage_grabBanker:setVisible(true)
                    if cbGrabBanker ~= nil then
                        uiImage_grabBanker:loadTexture(string.format("puke/table/pukenew_cell_%d.png",cbGrabBanker[wChairID]))
                    end
                else
                    uiImage_banker:setVisible(false)
                    uiImage_grabBanker:setVisible(false)
                end 
            end
        end
    end
end

function GameLayer:updatePlayerReady()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
            if GameCommon.player[wChairID].bReady == true then
                uiImage_ready:setVisible(true)
                if wChairID == GameCommon:getRoleChairID() then
                    uiButton_ready:setVisible(false)
                end 
            end          
        end     
    end
    local wChairID = GameCommon:getRoleChairID()
    if GameCommon.gameConfig ~= nil and GameCommon.tableConfig.wCurrentNumber == 0 and GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil and GameCommon.player[wChairID].bReady == true then
        local uiButton_start = ccui.Helper:seekWidgetByName(self.root,"Button_start")
        uiButton_start:setVisible(true)
    end
end

function GameLayer:updatePlayerOnline()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_offline = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_offline")
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            if GameCommon.player[wChairID].cbOnline == 0x06 then
                uiImage_offline:setVisible(true)
                uiImage_avatar:setColor(cc.c3b(170,170,170))
            else
                uiImage_offline:setVisible(false)
                uiImage_avatar:setColor(cc.c3b(255,255,255))
            end
        end     
    end
end
function GameLayer:updatePlayerPush(wPushChairID)
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_tuizhu = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_tuizhu")
            if wPushChairID ~= nil and wPushChairID == wChairID and wPushChairID ~= GameCommon.wBankerUser then
                uiImage_tuizhu:setVisible(true)
                ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("puke/animation/ketuizhu-donghua/ketuizhu-donghua.ExportJson")
                local armature=ccs.Armature:create("ketuizhu-donghua")
                armature:getAnimation():playWithIndex(0)
                uiImage_tuizhu:addChild(armature)
            else
                uiImage_tuizhu:setVisible(false) 
            end
        end     
    end
end

return GameLayer


