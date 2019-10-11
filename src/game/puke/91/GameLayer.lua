local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local ZJHGameCommon = require("game.puke.ZJHGameCommon")  
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

local ZJHTableLayer = require("game.puke.ZJHTableLayer")


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
    if ZJHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 0 ,false)
    end

end

function GameLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if ZJHGameCommon.tableConfig.nTableType ~= TableType_Playback and self.scheduleUpdateObj then
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
    ZJHGameCommon.dwUserID = params[1]
    ZJHGameCommon.tableConfig = params[2]
    ZJHGameCommon.playbackData = params[3]
    ZJHGameCommon.player = {}
    ZJHGameCommon.gameConfig = {}
    
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerNewZJH.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb     
    ZJHGameCommon:init()
    ZJHGameCommon.MAX_COUNT = 3
    self.tableLayer = ZJHTableLayer:create(self.root)
    self:addChild(self.tableLayer)
    self.tableLayer:initUI()
    self.tableLayer:updateGameState(ZJHGameCommon.GameState_Init)
    self.isRunningActions = false
    self.userMsgArray = {} --消息缓存

    local regionSound = cc.UserDefault:getInstance():getFloatForKey('volumeSelect', 1) 
    if regionSound ~= nil and regionSound == 0 then
        ZJHGameCommon.regionSound = 0
    else
        ZJHGameCommon.regionSound = 1
    end
    --ZJHGameCommon.regionSound = 0
    
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
        uiButton_Invitation:setVisible(false)
    end
    self:loadingPlayback()
end

function GameLayer:loadingPlayback()
    if ZJHGameCommon.tableConfig.nTableType ~= TableType_Playback then
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
    if ZJHGameCommon.playbackData == nil then
        return
    end
    local luaFunc = require("common.Serialize"):create("",0)
    for key, var in pairs(ZJHGameCommon.playbackData) do
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
            ZJHGameCommon.player[wChairID].bReady = true
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
                _tagMsg.pBuffer.tScoreInfo[i].player = ZJHGameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
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
            _tagMsg.pBuffer.tableConfig = ZJHGameCommon.tableConfig
            _tagMsg.pBuffer.gameConfig = ZJHGameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(ZJHGameCommon.tableConfig.wKindID,ZJHGameCommon.gameConfig,ZJHGameCommon.tableConfig)
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
				_tagMsg.pBuffer.tScoreInfo[i].player = ZJHGameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
				_tagMsg.pBuffer.tScoreInfo[i].totalScore = luaFunc:readRecvLong()       --用户总积分
                print("+++++++++++++~~~~~~",i,_tagMsg.pBuffer.tScoreInfo[i].totalScore)
                for j=1,16 do
                    _tagMsg.pBuffer.statistics[i][j] = luaFunc:readRecvByte()        --用户ID
                end

			end
			_tagMsg.pBuffer.dwTableOwnerID = luaFunc:readRecvDWORD()                    --房主ID
			_tagMsg.pBuffer.szOwnerName = luaFunc:readRecvString(32)                    --房主名字
            _tagMsg.pBuffer.szGameID = luaFunc:readRecvString(32)                    --结算唯一标志
            _tagMsg.pBuffer.ZJHGameCommon = ZJHGameCommon
			_tagMsg.pBuffer.tableConfig = ZJHGameCommon.tableConfig
			_tagMsg.pBuffer.gameConfig = ZJHGameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(ZJHGameCommon.tableConfig.wKindID, ZJHGameCommon.gameConfig, ZJHGameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因

        elseif subCmdID == NetMsgId.SUB_GR_USER_CONNECT then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            ZJHGameCommon.player[wChairID].cbOnline = 0
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_OFFLINE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            ZJHGameCommon.player[wChairID].cbOnline = 0x06
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_LEAVE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            if ZJHGameCommon.dwUserID == dwUserID then
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            else
                ZJHGameCommon.player[wChairID] = nil
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
            if ZJHGameCommon.player[wChairID] ~= nil then
                ZJHGameCommon.player[wChairID].location = location
            end
            return true
                
        elseif subCmdID == NetMsgId.SUB_GR_TABLE_STATUS then 
            ZJHGameCommon.tableConfig.wTableNumber = luaFunc:readRecvWORD()       --房间局数
            ZJHGameCommon.tableConfig.wCurrentNumber = luaFunc:readRecvWORD()    --当前局数
            -- ZJHGameCommon.mJiangChiCount = 0 
            local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
            uiText_title:setString(string.format("%s 房间号:%d 局数:%d/%d",StaticData.Games[ZJHGameCommon.tableConfig.wKindID].name,ZJHGameCommon.tableConfig.wTbaleID,ZJHGameCommon.tableConfig.wCurrentNumber,ZJHGameCommon.tableConfig.wTableNumber))
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_SUCCESS then
            if ZJHGameCommon.gameState ~= ZJHGameCommon.GameState_Init then
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
            require("common.DissolutionLayer"):create(ZJHGameCommon.player,data)
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
            ZJHGameCommon.player[data.wChairID] = data
            if data.dwUserID == ZJHGameCommon.dwUserID or ZJHGameCommon.meChairID == nil then
                ZJHGameCommon.meChairID = data.wChairID
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
            ZJHGameCommon.gameConfig = require("common.GameConfig"):getParameter(ZJHGameCommon.tableConfig.wKindID,luaFunc)
            local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
            uiText_desc:setString(GameDesc:getGameDesc(ZJHGameCommon.tableConfig.wKindID,ZJHGameCommon.gameConfig,ZJHGameCommon.tableConfig))
            self:showPlayerPosition()
            return true
			
        -- elseif subCmdID == NetMsgId.SUB_S_GAME_START_PDK then 
        -- elseif subCmdID == NetMsgId.SUB_C_START_GAME then 
        elseif subCmdID == NetMsgId.REC_SUB_S_GONGPU_RESULT then 
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD() 
            ZJHGameCommon.player[_tagMsg.pBuffer.wChairID].bReady = true
            print("接受下局消息",_tagMsg.pBuffer.wChairID)
            self:updatePlayerNext()
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        elseif subCmdID == NetMsgId.REC_SUB_S_UPDATE_BANKER then
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbGrabBanker = {}
            for i = 0, 7 do
                _tagMsg.pBuffer.cbGrabBanker[i] = luaFunc:readRecvByte()
            end
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SEND_CARD_ZJH then	--发牌消息
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()     --单元下注
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()	--庄家用户
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()   --当前玩家
            _tagMsg.pBuffer.lTableScore = {}
            for i= 0,7 do
                _tagMsg.pBuffer.lTableScore[i] = luaFunc:readRecvLong()     --下注分数
            end 
            _tagMsg.pBuffer.lAllTableScore = luaFunc:readRecvLong()     --总共下注分数

            _tagMsg.pBuffer.wCurrentCount = luaFunc:readRecvWORD()      --当前轮数
            _tagMsg.pBuffer.wAllCount = luaFunc:readRecvWORD()          --总轮数
            _tagMsg.pBuffer.wBlindCount = luaFunc:readRecvWORD()        --当前闷数
            _tagMsg.pBuffer.wMustBlindCount = luaFunc:readRecvWORD()    --比闷次数
            -- _tagMsg.pBuffer.cbCardData = {}
            -- for i = 1, 3 do
            --     _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            -- end
            -- _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()

            -- _tagMsg.pBuffer.mJiangChiData = luaFunc:readRecvLong()       
            
            -- _tagMsg.pBuffer.mCardNum = luaFunc:readRecvByte()                   --手牌点数						
        elseif subCmdID == NetMsgId.SUB_S_ADD_SCORE then				--加注结果--（下分协议）
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --当前用户
            _tagMsg.pBuffer.wAddScoreUser = luaFunc:readRecvWORD()      --加注用户       
            _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()	        --单元下注
            _tagMsg.pBuffer.lAddScoreCount = luaFunc:readRecvLong()	    --加注数目       
            _tagMsg.pBuffer.lTableScore = luaFunc:readRecvLong()	    --下注分数 
            _tagMsg.pBuffer.lAllTableScore = luaFunc:readRecvLong()	    --总共下注分数 
            _tagMsg.pBuffer.wCurrentCount = luaFunc:readRecvWORD()      --当前轮数
            _tagMsg.pBuffer.wAllCount = luaFunc:readRecvWORD()          --总轮数
            _tagMsg.pBuffer.wBlindCount = luaFunc:readRecvWORD()        --当前闷数
            _tagMsg.pBuffer.wMustBlindCount = luaFunc:readRecvWORD()    --比闷次数

        elseif subCmdID == NetMsgId.SUB_S_GIVE_UP_ZJH then              --放弃跟注

            print("++++++++++++++++++弃牌动画及其效果++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            _tagMsg.pBuffer.wGiveUpUser = luaFunc:readRecvWORD()        --放弃用户

            _tagMsg.pBuffer.cbHandCardData = {}
            for i = 1 , 3 do 
                _tagMsg.pBuffer.cbHandCardData[i] = luaFunc:readRecvByte()             --扑克数据
            end 

        elseif subCmdID == NetMsgId.SUB_S_COMPARE_CARD then             --比牌跟注

            -- _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --当前用户
            _tagMsg.pBuffer.wCompareUser = {}
            for i = 1, 2 do
                _tagMsg.pBuffer.wCompareUser[i] = luaFunc:readRecvWORD()       --比牌用户
            end 
            _tagMsg.pBuffer.wLostUser = luaFunc:readRecvWORD()       --输牌用户

            _tagMsg.pBuffer.cbHandCardData = {}
            for i = 1 , 3 do 
                _tagMsg.pBuffer.cbHandCardData[i] = luaFunc:readRecvByte()             --扑克数据
            end 

        elseif subCmdID == NetMsgId.SUB_S_LOOK_CARD then             --看牌跟注
            print("++++++++++++++++++看牌动画及其效果++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")
            print("++++++++++++++++++++++++++++++++++++++++++++++++")

            _tagMsg.pBuffer.wLookCardUser = luaFunc:readRecvWORD()       --看牌用户
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1, 3 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()       --用户扑克
            end 
        
            
        -- elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD then
        --     _tagMsg.pBuffer.cbCardData = {}
        --     for i = 1, 5 do
        --         _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
        --     end
        --     _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING_HSP then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()       --当前押注玩家
            _tagMsg.pBuffer.cbBettingOne = luaFunc:readRecvByte()   --押注起始1值
            _tagMsg.pBuffer.cbBettingTwo = luaFunc:readRecvByte()   --押注起始2值
            _tagMsg.pBuffer.cbBettingThree = luaFunc:readRecvByte() --押注起始3值
            _tagMsg.pBuffer.cbGenZhu = luaFunc:readRecvByte()       --跟注
            _tagMsg.pBuffer.cbJiaZhuOne = luaFunc:readRecvByte()    --加注1  
            _tagMsg.pBuffer.cbJiaZhuTwo = luaFunc:readRecvByte()    --加注2  
            _tagMsg.pBuffer.cbBettingType = luaFunc:readRecvByte()   --提示客户端    1.当前轮首次押注  2.跟注+加注   3.跟注<平衡各家下注分>

        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING_RESULT then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbBetting = luaFunc:readRecvByte()

        -- elseif subCmdID == NetMsgId.REC_SUB_S_YAZHU_RETURN then
        --     _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()       --当前押注操作玩家         
        --     _tagMsg.pBuffer.mYaZhuScore = luaFunc:readRecvLong()    --输赢得分
        --     _tagMsg.pBuffer.mYaZhuType = luaFunc:readRecvByte()     --押注类型

        --     _tagMsg.pBuffer.mJiangChiCount = luaFunc:readRecvLong()    --奖池

        --     _tagMsg.pBuffer.mJiaZhuCount = {}
        --     for i = 0, 7 do
        --         _tagMsg.pBuffer.mJiaZhuCount[i] = luaFunc:readRecvLong()    --每轮下注总数(当前)
        --         print("每轮下注总数(当前)",i,_tagMsg.pBuffer.mJiaZhuCount[i] )
        --     end
        --     _tagMsg.pBuffer.mClientYaZhuScore = luaFunc:readRecvLong()    --客户端展现押注分
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bMultiple = luaFunc:readRecvByte() 
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.bMultiple = luaFunc:readRecvByte() 
        
        elseif subCmdID == NetMsgId.REC_SUB_S_GAME_END then
            -- _tagMsg.pBuffer.lGameScore = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong()  
            -- end
            -- _tagMsg.pBuffer.mWiner = luaFunc:readRecvWORD()   --  -1   
            -- _tagMsg.pBuffer.mUserCardNum = {}                 --  游戏结束手牌点数
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.mUserCardNum[i] = luaFunc:readRecvByte() 
            -- end
            _tagMsg.pBuffer.lGameScore = {}                         --输赢得分
            for i = 0, 7 do
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong()  
            end

            _tagMsg.pBuffer.cbCardData = {}	--用户扑克
            for i = 0, 7 do
                _tagMsg.pBuffer.cbCardData[i] = {}
                for j = 1, 3 do
                    _tagMsg.pBuffer.cbCardData[i][j] = luaFunc:readRecvByte() 
                end
            end
            _tagMsg.pBuffer.mWiner = luaFunc:readRecvWORD()   --  -1   

            local a  = 1 
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_RESULT_HSP then
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1, 3 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()          --手牌
                print("手牌",i,_tagMsg.pBuffer.cbCardData[i],_tagMsg.pBuffer.wChairID)
            end   
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_SHOW_RESULT_HSP,_tagMsg.pBuffer)
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

            --加注信息
            _tagMsg.pBuffer.lMaxCellScore = luaFunc:readRecvLong()          --单元上限
            _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()             --单元下注

            --状态信息
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()                    --庄家用户
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()                   --当前玩家
            _tagMsg.pBuffer.cbPlayStatus = {}
            for i = 0 , 7  do 
                _tagMsg.pBuffer.cbPlayStatus[i] = luaFunc:readRecvByte()            --游戏状态
            end 
            _tagMsg.pBuffer.bMingZhu = {}
            for i = 0 , 7 do 
                _tagMsg.pBuffer.bMingZhu[i] = luaFunc:readRecvBool()                --看牌状态
            end 

            _tagMsg.pBuffer.lTableScore = {}
            for i = 0 , 7 do 
                _tagMsg.pBuffer.lTableScore[i] = luaFunc:readRecvLong()             --下注数目
            end 

            _tagMsg.pBuffer.lAllTableScore = luaFunc:readRecvLong()                 --总共下注分数
            _tagMsg.pBuffer.wCurrentCount = luaFunc:readRecvWORD()                  --当前轮数
            _tagMsg.pBuffer.wAllCount = luaFunc:readRecvWORD()                      --总轮数
            _tagMsg.pBuffer.wBlindCount = luaFunc:readRecvWORD()                    --当前闷数
            _tagMsg.pBuffer.wMustBlindCount = luaFunc:readRecvWORD()                --比闷次数
            _tagMsg.pBuffer.cbHandCardData = {}
            for i = 1 , 3 do 
                _tagMsg.pBuffer.cbHandCardData[i] = luaFunc:readRecvByte()             --扑克数据
            end 
            local a = 0 
            -- _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()                    --庄家用户
            -- _tagMsg.pBuffer.wPushChairID = luaFunc:readRecvWORD()                    --推注用户
            -- _tagMsg.pBuffer.isGameStart = luaFunc:readRecvBool()                    --游戏是否开始
            -- _tagMsg.pBuffer.cbWaitType = luaFunc:readRecvByte()
            -- _tagMsg.pBuffer.cbPlayingCount = luaFunc:readRecvByte()
            -- _tagMsg.pBuffer.cbPlaying = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.cbPlaying[i] = luaFunc:readRecvBool()                  --亮牌
            -- end
            -- _tagMsg.pBuffer.cbBetting = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.cbBetting[i] = luaFunc:readRecvByte()               --玩家押注
            -- end
            -- _tagMsg.pBuffer.cbGrabBanker = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.cbGrabBanker[i] = luaFunc:readRecvByte()            --抢庄
            -- end
            -- _tagMsg.pBuffer.cbShow = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.cbShow[i] = luaFunc:readRecvBool()                  --亮牌
            -- end
            -- _tagMsg.pBuffer.bCardData = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.bCardData[i] ={}
            --     for j = 1, 3 do
            --         _tagMsg.pBuffer.bCardData[i][j] = luaFunc:readRecvByte()        --扑克
            --     end                    
            -- end
            -- _tagMsg.pBuffer.stuCompareCard = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.stuCompareCard[i] = {}
            --     _tagMsg.pBuffer.stuCompareCard[i].cbCardData = {}
            --     for j = 1, 3 do
            --         _tagMsg.pBuffer.stuCompareCard[i].cbCardData[j] = luaFunc:readRecvByte()
            --     end
            --     _tagMsg.pBuffer.stuCompareCard[i].wChairID = luaFunc:readRecvWORD()
            --     _tagMsg.pBuffer.stuCompareCard[i].cbValueType = luaFunc:readRecvByte()
            --     _tagMsg.pBuffer.stuCompareCard[i].cbMaxValue = luaFunc:readRecvByte()
            --     _tagMsg.pBuffer.stuCompareCard[i].cbFanBei = luaFunc:readRecvByte()
            -- end   

            -- _tagMsg.pBuffer.mStatusCurUserYaZhuType = luaFunc:readRecvByte()         --//当前玩家押注状态		1.首次 2.跟注/加注 3.跟注	<验证以及断线重连>
            -- _tagMsg.pBuffer.mStatusCurUserYaZhuCount= {}
            -- for i = 0, 5 do
            --     _tagMsg.pBuffer.mStatusCurUserYaZhuCount[i] = luaFunc:readRecvLong() --0~2:表示首次压牌    3：跟注值   4~5：加注值       <验证以及断线重连>
            -- end
            -- _tagMsg.pBuffer.mStatusNextAddUser = luaFunc:readRecvWORD()              --	玩家		<验证以及断线重连>	
            -- _tagMsg.pBuffer.mJiangChiCount = luaFunc:readRecvLong()    --奖池

            -- _tagMsg.pBuffer.mJiaZhuCount = {}
            -- for i = 0, 7 do
            --     _tagMsg.pBuffer.mJiaZhuCount[i] = luaFunc:readRecvLong()    --每轮下注总数(当前)
            -- end

            -- _tagMsg.pBuffer.mCardNum = luaFunc:readRecvByte()                   --手牌点数				

		
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
    --     if subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
    --         self:removeAllChildren()
    --         local layer = require("common.FriendsRoomEndLayer"):create(pBuffer)
    --         self:addChild(layer)
    --     else
    --         return print("error, not found this :",mainCmdID, subCmdID)
    --     end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        -- if subCmdID == NetMsgId.SUB_S_GAME_START_PDK then
        --     print("+++++++++++++++++++++++游戏开始")
        --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        -- else
        if subCmdID == NetMsgId.REC_SUB_S_UPDATE_BANKER then
            ZJHGameCommon.wBankerUser = pBuffer.wBankerUser
            local time = 0
            if ZJHGameCommon.gameConfig.bBankerType == 1 then
                time = 2
            elseif ZJHGameCommon.gameConfig.bBankerType == 2 and (ZJHGameCommon.gameConfig ~= nil and ZJHGameCommon.tableConfig.wCurrentNumber == 1) then
                time = 2
            end
            self:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        elseif subCmdID == NetMsgId.REC_SUB_S_SEND_CARD_ZJH then
            self.tableLayer:updateGameState(ZJHGameCommon.GameState_Start)  
            ZJHGameCommon.wOKlookCard = false
            for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
                if ZJHGameCommon.player[i] ~= nil then  
                    ZJHGameCommon.player[i].lTableScore = pBuffer.lTableScore[i]
                    ZJHGameCommon.player[i].wLookCardUser = false
                    ZJHGameCommon.player[i].wGiveUpUser = false
                end 
            end             
            ZJHGameCommon.lCellScore = pBuffer.lCellScore
            ZJHGameCommon.wBankerUser = pBuffer.wBankerUser
            ZJHGameCommon.lAllTableScore = pBuffer.lAllTableScore
            ZJHGameCommon.wCurrentCount = pBuffer.wCurrentCount
            ZJHGameCommon.wAllCount = pBuffer.wAllCount
            ZJHGameCommon.wBlindCount = pBuffer.wBlindCount
            ZJHGameCommon.wMustBlindCount = pBuffer.wMustBlindCount
            self:updateJCscore()
            self.tableLayer:changeNote()
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_SEND_CARD_ZJH,pBuffer)
      
        elseif subCmdID == NetMsgId.SUB_S_ADD_SCORE then				--加注结果
            -- _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --当前用户
            -- _tagMsg.pBuffer.wAddScoreUser = luaFunc:readRecvWORD()      --加注用户
            -- _tagMsg.pBuffer.lAddScoreCount = luaFunc:readRecvLong()	    --加注数目 

            ZJHGameCommon.lCellScore =  pBuffer.lCellScore
            ZJHGameCommon.player[pBuffer.wAddScoreUser].lTableScore = pBuffer.lTableScore           --下注分数 
            ZJHGameCommon.lAllTableScore = pBuffer.lAllTableScore                                   --总共下注分数
            ZJHGameCommon.wCurrentCount = pBuffer.wCurrentCount                                     --当前轮数
            ZJHGameCommon.wAllCount = pBuffer.wAllCount                                             --总轮数
            ZJHGameCommon.wBlindCount = pBuffer.wBlindCount                                         --当前闷数
            ZJHGameCommon.wMustBlindCount = pBuffer.wMustBlindCount                                 --比闷次数
            self:updateJCscore()
            self.tableLayer:changeNote()
            self.tableLayer:doAction(NetMsgId.SUB_S_ADD_SCORE,pBuffer) 

        elseif subCmdID == NetMsgId.SUB_S_COMPARE_CARD then
            ZJHGameCommon.player[pBuffer.wLostUser].wGiveUpUser = true
            self.tableLayer:changeMatch()
            self.tableLayer:doAction(NetMsgId.SUB_S_COMPARE_CARD,pBuffer)
        elseif subCmdID == NetMsgId.SUB_S_LOOK_CARD then
            self.tableLayer:doAction(NetMsgId.SUB_S_LOOK_CARD,pBuffer)
        elseif subCmdID == NetMsgId.SUB_S_GIVE_UP_ZJH then  
            self.tableLayer:changeMatch()     
            ZJHGameCommon.player[pBuffer.wGiveUpUser].wGiveUpUser = true
            self.tableLayer:doAction(NetMsgId.SUB_S_GIVE_UP_ZJH,pBuffer)
        -- elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD then
        --     self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER_SEND_CARD,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING_HSP then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_BETTING_HSP,pBuffer)
        
        elseif subCmdID == NetMsgId.REC_SUB_S_BETTING_RESULT then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_BETTING_RESULT,pBuffer)

        -- elseif subCmdID == NetMsgId.REC_SUB_S_YAZHU_RETURN then 
        --     -- local data = pBuffer.mJiangChiCount

        --     -- ZJHGameCommon.mJiangChiCount = pBuffer.mJiangChiCount
        --     self:updateJCscore(pBuffer)

        --     if ZJHGameCommon.player[pBuffer.wChairID] ~= nil then
        --         print("反应压注结果++++++++++",pBuffer.mYaZhuScore,pBuffer.wChairID,pBuffer.mClientYaZhuScore)
        --         -- ZJHGameCommon.player[pBuffer.wChairID].lScore = ZJHGameCommon.player[pBuffer.wChairID].lScore - pBuffer.mYaZhuScore
        --         self.tableLayer:doAction(NetMsgId.REC_SUB_S_YAZHU_RETURN,{wChairID = pBuffer.wChairID, lGameScore = pBuffer.mClientYaZhuScore,mYaZhuType = pBuffer.mYaZhuType})
        --     end
        --     -- self:updatePlayerlScore()
        --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER,pBuffer)
            
        elseif subCmdID == NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_GRAB_BANKER_RESULT,pBuffer)
                    
        elseif subCmdID == NetMsgId.REC_SUB_S_GAME_END then
            for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
                if ZJHGameCommon.player[i] ~= nil then
                    ZJHGameCommon.player[i].lScore = ZJHGameCommon.player[i].lScore + pBuffer.lGameScore[i]
                    self.tableLayer:doAction(NetMsgId.REC_SUB_S_GAME_END,{wChairID = i, lGameScore = pBuffer.lGameScore[i],cbCardData = pBuffer.cbCardData })
                    if ZJHGameCommon.tableConfig.nTableType == TableType_GoldRoom then
                        ZJHGameCommon.player[i].lScore = ZJHGameCommon.player[i].lScore - ZJHGameCommon.tableConfig.wCellScore/2
                        if ZJHGameCommon.player[i].lScore < 0 then
                            ZJHGameCommon.player[i].lScore = 0
                        end
                    end
                end
            end
            self:updatePlayerlScore()
            self.tableLayer:updateGameState(ZJHGameCommon.GameState_Over)
            local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            uiPanel_end:setVisible(true)
            uiPanel_end:stopAllActions()
            if ZJHGameCommon.regionSound == 0 then
                if pBuffer.mWiner == -1 then 
                    require("common.Common"):playEffect("puke/sound_fsp/common/pinju.mp3")
                end
            else
                if pBuffer.mWiner == -1 then 
                    require("common.Common"):playEffect("puke/sound_fsp/place/pinju.mp3")
                end
            end 

            if ZJHGameCommon.tableConfig.nTableType ~= TableType_Playback then
                local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
                uiButton_continue:setVisible(true)
                Common:addTouchEventListener(uiButton_continue,function() 
                    uiPanel_end:stopAllActions()
                    if pBuffer.mWiner == -1 then 
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_GONGPU,"w",ZJHGameCommon:getRoleChairID())
                    else
                        if ZJHGameCommon.tableConfig.wTableNumber == ZJHGameCommon.tableConfig.wCurrentNumber then
                            EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                        else
                            ZJHGameCommon:ContinueGame(ZJHGameCommon.tableConfig.cbLevel)
                        end
                    end
                    
                end)
            end 

            uiPanel_end:stopAllActions()
            uiPanel_end:runAction(cc.Sequence:create(
                cc.CallFunc:create(function(sender,event) 
                    if ZJHGameCommon.tableConfig.nTableType == TableType_SportsRoom then
                        pBuffer.wKindID =ZJHGameCommon.tableConfig.wKindID
                        uiPanel_end:addChild(require("common.SportsGameEndLayer"):create(pBuffer))  
                    end 
                end),
                cc.DelayTime:create(4),
                cc.CallFunc:create(function(sender,event)                    
                    if ZJHGameCommon.tableConfig.nTableType > TableType_GoldRoom then
                        if pBuffer.mWiner ~= -1 then 
                            if ZJHGameCommon.tableConfig.wTableNumber == ZJHGameCommon.tableConfig.wCurrentNumber then
                                EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                            else
                                ZJHGameCommon:ContinueGame(ZJHGameCommon.tableConfig.cbLevel)
                            end
                        else
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_GONGPU,"w",ZJHGameCommon:getRoleChairID())
                        end
                    else
                        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                    end                   
                end)))
            

            
        elseif subCmdID == NetMsgId.REC_SUB_S_SHOW_TIPS then
            self.tableLayer:doAction(NetMsgId.REC_SUB_S_SHOW_TIPS,pBuffer)
                                    
        else 
            return print("error, not found this :",mainCmdID, subCmdID)
        end

    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then
            -- ZJHGameCommon.mJiangChiCount = pBuffer.mJiangChiCount            
            self.tableLayer:showCountDown(ZJHGameCommon.gameConfig.wQuitTimer)
           
            ZJHGameCommon.lCellScore = pBuffer.lCellScore
            ZJHGameCommon.wBankerUser = pBuffer.wBankerUser
            ZJHGameCommon.lAllTableScore = pBuffer.lAllTableScore
            ZJHGameCommon.wCurrentCount = pBuffer.wCurrentCount
            ZJHGameCommon.wAllCount = pBuffer.wAllCount
            ZJHGameCommon.wBlindCount = pBuffer.wBlindCount
            ZJHGameCommon.wMustBlindCount = pBuffer.wMustBlindCount

            for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
                if ZJHGameCommon.player[i] ~= nil then  
                    ZJHGameCommon.player[i].lTableScore = pBuffer.lTableScore[i]
                    ZJHGameCommon.player[i].wLookCardUser = pBuffer.bMingZhu[i]
                    if pBuffer.cbPlayStatus[i] == 1 then 
                        ZJHGameCommon.player[i].wGiveUpUser = false
                    else
                        ZJHGameCommon.player[i].wGiveUpUser = true
                    end 
                end 
            end  
            self.tableLayer:changeMatch()              
            self.tableLayer:changeNote(pBuffer.wCurrentUser)
            if pBuffer.wCurrentUser ~= -1 then
                pBuffer.wChairID = pBuffer.wCurrentUser
                self.tableLayer:updateGameState(ZJHGameCommon.GameState_Start)  
            end
            self:updateJCscore(pBuffer.wCurrentUser)
            self.tableLayer:showOperation(pBuffer)
            for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
                if ZJHGameCommon.player[i] ~= nil then
                    local viewID = ZJHGameCommon:getViewIDByChairID(i)
                    if ZJHGameCommon.player[i].wLookCardUser == false or viewID ~= 1 then                     
                            -- ZJHGameCommon.player[i].lTableScore = pBuffer.lTableScore[i]
                        self.tableLayer:showHandPBCard(i,3)                  
                    else 
                        self.tableLayer:setHandCard(i,pBuffer.cbHandCardData)
                        self.tableLayer:showHandCard(i,2)
                    end 
                end 
            end 
            -- --加注信息
            -- _tagMsg.pBuffer.lMaxCellScore = luaFunc:readRecvLong()          --单元上限
            -- _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()             --单元下注       
            -- --状态信息
            -- _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()                    --庄家用户
            -- _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()                   --当前玩家
            -- _tagMsg.pBuffer.cbPlayStatus = {}
            -- for i = 0 , 7  do 
            --     _tagMsg.pBuffer.cbPlayStatus[i] = luaFunc:readRecvByte()            --游戏状态
            -- end 
            -- _tagMsg.pBuffer.bMingZhu = {}
            -- for i = 0 , 7 do 
            --     _tagMsg.pBuffer.bMingZhu[i] = luaFunc:readRecvBool()                --看牌状态
            -- end 

            -- _tagMsg.pBuffer.lTableScore = {}
            -- for i = 0 , 7 do 
            --     _tagMsg.pBuffer.lTableScore[i] = luaFunc:readRecvLong()             --下注数目
            -- end 

            -- _tagMsg.pBuffer.lAllTableScore = luaFunc:readRecvLong()                 --总共下注分数
            -- _tagMsg.pBuffer.wCurrentCount = luaFunc:readRecvWORD()                  --当前轮数
            -- _tagMsg.pBuffer.wAllCount = luaFunc:readRecvWORD()                      --总轮数
            -- _tagMsg.pBuffer.wBlindCount = luaFunc:readRecvWORD()                    --当前闷数
            -- _tagMsg.pBuffer.wMustBlindCount = luaFunc:readRecvWORD()                --比闷次数
            -- _tagMsg.pBuffer.cbHandCardData = {}
            -- for i = 1 , 3 do 
            --     _tagMsg.pBuffer.cbHandCardData[i] = luaFunc:readRecvByte()             --扑克数据
            -- end 

            -- --游戏重连
            -- local wChairID = ZJHGameCommon:getRoleChairID()
            -- if pBuffer.cbPlaying[wChairID] == true then 
            --     if pBuffer.cbWaitType ~= 0 then
            --         self.tableLayer:updateGameState(ZJHGameCommon.GameState_Start)
            --     end
                
            --     ZJHGameCommon.wBankerUser = pBuffer.wBankerUser
            --     self.tableLayer:showCountDown(pBuffer.cbWaitType)
            --     if pBuffer.cbWaitType == 2 then
            --         -- --押注
            --         for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do

            --             if pBuffer.bCardData[i][1] ~= 0 or pBuffer.bCardData[i][2] ~= 0  then
            --                 self.tableLayer:setHandCard(i,pBuffer.bCardData[i])
            --                 self.tableLayer:showHandCard(i,0)
            --             end 
            --         end 
            --         local viewID = ZJHGameCommon:getViewIDByChairID(pBuffer.wBankerUser)
            --         local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            --         -- if pBuffer.cbBetting[wChairID] == 0 then
            --         --     self.tableLayer:doAction(NetMsgId.REC_SUB_S_BETTING_HSP, {wChairID = pBuffer.wPushChairID, bBettingType = ZJHGameCommon.gameConfig.bBettingType})
            --         --     return
            --         -- end            
            --     elseif pBuffer.cbWaitType == 3 then
            --         --亮牌
            --         for i = 0, ZJHGameCommon.gameConfig.bPlayerCount-1 do
            --             if pBuffer.cbBetting[i] > 0 then
            --                 local viewID = ZJHGameCommon:getViewIDByChairID(i)
            --                 local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            --                 local uiImage_betting = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_betting")
            --                 uiImage_betting:setVisible(true)
            --                 uiImage_betting:loadTexture(string.format("puke/table/pukenew_score_%d.png",pBuffer.cbBetting[i]))
            --             end
            --             if pBuffer.cbShow[i] == true then
            --                 self.tableLayer:setHandCard(i,pBuffer.stuCompareCard[i].cbCardData)
            --                 self.tableLayer:showHandCard(i,2,pBuffer.stuCompareCard[i].cbValueType)
            --                 ZJHGameCommon:playAnimation(self.root,pBuffer.stuCompareCard[i].cbValueType,i)
            --             end
            --         end
            --         if pBuffer.cbShow[wChairID] == false then
            --             self.tableLayer:setHandCard(wChairID,pBuffer.bCardData[wChairID])
            --             self.tableLayer:showHandCard(wChairID,0)
            --             self.tableLayer:doAction(NetMsgId.REC_SUB_S_SHOW_TIPS)
            --             return
            --         end
            --     else
            --         -- 亮牌
            --         for i = 0 , ZJHGameCommon.gameConfig.bPlayerCount-1 do
            --             if pBuffer.bCardData[i][1] ~= 0 or pBuffer.bCardData[i][2] ~= 0  then
            --                 self.tableLayer:setHandCard(i,pBuffer.bCardData[i])
            --                 self.tableLayer:showHandCard(i,0)
            --             end 
            --         end 
            --         if pBuffer.cbWaitType == 4 then
            --             NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_GONGPU,"w",ZJHGameCommon:getRoleChairID())
            --         end 
            --         -- local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            --         -- uiPanel_end:setVisible(true)
            --     end
            -- end
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
    if ZJHGameCommon.gameConfig == nil then
        return
    end
    if wNewChairID == nil then
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
        uiPanel_player:setVisible(true)
        for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
            local wChairID = i - 1
            local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            if ZJHGameCommon.player == nil or ZJHGameCommon.player[wChairID] == nil then
                local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
                uiPanel_playerInfo:setVisible(false)
                uiPanel_player:setVisible(false)
            else
                uiPanel_player:setVisible(true)
                print(wChairID, viewID,ZJHGameCommon.player[wChairID].szNickName)
                local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
                uiPanel_playerInfo:setVisible(true)
                local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
                Common:requestUserAvatar(ZJHGameCommon.player[wChairID].dwUserID,ZJHGameCommon.player[wChairID].szPto,uiImage_avatar,"img")
                local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
                uiText_name:setString(ZJHGameCommon.player[wChairID].szNickName)
                local Text_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score") 
                --个人添加
                local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
                local dwGold = Common:itemNumberToString(ZJHGameCommon.player[wChairID].lScore)
            	uiText_score:setString(tostring(dwGold))             
            end
        end
    else
        local wChairID = wNewChairID
        local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        if ZJHGameCommon.player == nil or ZJHGameCommon.player[wChairID] == nil then
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(false)
            uiPanel_player:setVisible(false)
        else
            uiPanel_player:setVisible(true)
            print(wChairID, viewID,ZJHGameCommon.player[wChairID].szNickName)
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(ZJHGameCommon.player[wChairID].dwUserID,ZJHGameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setString(ZJHGameCommon.player[wChairID].szNickName)
            local Text_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score") 
            --个人添加
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(ZJHGameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))             
        end
    end
end

function GameLayer:updatePlayerlScore()
    if ZJHGameCommon.gameConfig == nil then
        return
    end
    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if ZJHGameCommon.player[wChairID] then
            local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(ZJHGameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))   
        end
    end
end

function GameLayer:updatePlayerReady()
    if ZJHGameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if ZJHGameCommon.player ~= nil and ZJHGameCommon.player[wChairID] ~= nil then
            local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
            if ZJHGameCommon.player[wChairID].bReady == true then
                uiImage_ready:setVisible(true)
                print("准备用户",wChairID,viewID,ZJHGameCommon.player[wChairID].bReady,ZJHGameCommon:getRoleChairID()) 
                if wChairID == ZJHGameCommon:getRoleChairID() then
                    uiButton_ready:setVisible(false)
                end 
            end          
        end     
    end
    local wChairID = ZJHGameCommon:getRoleChairID() --and ZJHGameCommon.tableConfig.wCurrentNumber == 0
    if ZJHGameCommon.gameConfig ~= nil and ZJHGameCommon.player ~= nil and ZJHGameCommon.player[wChairID] ~= nil and ZJHGameCommon.player[wChairID].bReady == true then
        local uiButton_start = ccui.Helper:seekWidgetByName(self.root,"Button_start")
        uiButton_start:setVisible(true)
    end
end

function GameLayer:updatePlayerNext()
    if ZJHGameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if ZJHGameCommon.player ~= nil and ZJHGameCommon.player[wChairID] ~= nil then
            local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
            if ZJHGameCommon.player[wChairID].bReady == true then
                uiImage_ready:setVisible(true)
                if wChairID == ZJHGameCommon:getRoleChairID() then
                    uiButton_continue:setVisible(false)
                end 
            end          
        end     
    end
end

function GameLayer:updatePlayerOnline()
    if ZJHGameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if ZJHGameCommon.player ~= nil and ZJHGameCommon.player[wChairID] ~= nil then
            local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_offline = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_offline")
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            if ZJHGameCommon.player[wChairID].cbOnline == 0x06 then
                uiImage_offline:setVisible(true)
                uiImage_avatar:setColor(cc.c3b(170,170,170))
            else
                uiImage_offline:setVisible(false)
                uiImage_avatar:setColor(cc.c3b(255,255,255))
            end
        end     
    end
end

function GameLayer:updateJCscore(wChairID)
    local uiPanel_PZscore = ccui.Helper:seekWidgetByName(self.root,"Panel_PZscore")
    uiPanel_PZscore:setVisible(true)
    local uiImage_PZscore = ccui.Helper:seekWidgetByName(self.root,"Image_PZscore")
    uiImage_PZscore:setVisible(true)
    local  uiText_JCscore = ccui.Helper:seekWidgetByName(self.root,"Text_JCscore")
    uiText_JCscore:setString(string.format("%d",ZJHGameCommon.lAllTableScore))
  
    local  uiText_LS = ccui.Helper:seekWidgetByName(self.root,"Text_LS")
    uiText_LS:setString(string.format("轮数:%d/%d",ZJHGameCommon.wCurrentCount,ZJHGameCommon.wAllCount))
    if  ZJHGameCommon.wBlindCount > ZJHGameCommon.wMustBlindCount or ZJHGameCommon.wMustBlindCount == 0 then 
        ZJHGameCommon.wBlindCount = ZJHGameCommon.wMustBlindCount
        ZJHGameCommon.wOKlookCard = true
    end 
    local  uiText_MS = ccui.Helper:seekWidgetByName(self.root,"Text_MS")
    uiText_MS:setString(string.format("闷数:%d/%d",ZJHGameCommon.wBlindCount,ZJHGameCommon.wMustBlindCount))

    local  uiText_DZ = ccui.Helper:seekWidgetByName(self.root,"Text_DZ")
    uiText_DZ:setString(string.format("单注:%d",ZJHGameCommon.lCellScore))
    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
        if ZJHGameCommon.player ~= nil and ZJHGameCommon.player[wChairID] ~= nil then
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiText_BLscore = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_BLscore")
            if ZJHGameCommon.player[wChairID] == nil or ZJHGameCommon.player[wChairID].lTableScore == nil   then 
                uiText_BLscore:setString("0")
            else
                uiText_BLscore:setString(string.format("%d",ZJHGameCommon.player[wChairID].lTableScore))
            end 
        end 
    end 
end 
-- function GameLayer:showPoints(event,wChairID)
--     if wChairID ~= nil then 
--         local viewID = ZJHGameCommon:getViewIDByChairID(wChairID)
--         if viewID ~= 1 then 
--             return
--         end 
--     end 
--     local uiImage_Points = ccui.Helper:seekWidgetByName(self.root,"Image_Points")

--     local uiText_Points = ccui.Helper:seekWidgetByName(self.root,"Text_Points")

--     if event == 0 or event  then 
--         uiImage_Points:setVisible(false)
--         return
--     else
--         uiImage_Points:setVisible(true)
--         print("获取点数++++++++++++",event)
--         uiText_Points:setString(string.format("%d点",event))
--     end 
-- end


local Playerposition = {
    [1] = { [6] = { cc.p(667.00, 96.23), cc.p(667.00, 555.00), cc.p(13.34, 258.75), cc.p(1320.66, 258.75), cc.p(413.54, 522.08), cc.p(920.46, 522.08),}, 
            [8] = { cc.p(667.00, 96.23), cc.p(667.00, 555.00), cc.p(13.34, 225.00), cc.p(1320.66, 225.00), cc.p(200.10, 450.00), cc.p(1133.90, 450.00), cc.p(466.90, 552.08), cc.p(867.10, 552.08),}
    },
    [2] = { [6] = { cc.p(667.00, 60.00), cc.p(667.00, 540.00), cc.p(120.06, 240.00), cc.p(1213.94, 240.00), cc.p(333.50, 510.00), cc.p(1000.50, 510.00),}, 
            [8] = { cc.p(667.00, 60.00), cc.p(667.00, 540.00), cc.p(120.06, 225.00), cc.p(1213.94, 225.00), cc.p(120.06, 442.50), cc.p(1213.94, 442.50), cc.p(373.52, 540.00), cc.p(960.48, 540.00),}
    },
    [3] = { [6] = { cc.p(667.00, 202.50), cc.p(667.00, 495.00), cc.p(106.72, 202.50), cc.p(1227.28, 202.50), cc.p(306.82, 465.00), cc.p(1013.84, 465.00),}, 
            [8] = { cc.p(667.00, 202.50), cc.p(667.00, 495.00), cc.p(106.72, 180.00), cc.p(1227.28, 180.00), cc.p(106.72, 397.50), cc.p(1227.28, 397.50), cc.p(400.20, 495.00), cc.p(933.80, 495.00),}
    },
    [4] = { [6] = { cc.p(15.47, 41.85), cc.p(667.00, 682.50), cc.p(11.87, 359.70), cc.p(1322.13, 359.70), cc.p(320.16, 652.50), cc.p(1013.84, 652.50),}, 
            [8] = { cc.p(15.47, 41.85), cc.p(667.00, 682.50), cc.p(11.87, 322.20), cc.p(1322.13, 322.20), cc.p(106.45, 585.00), cc.p(1226.21, 585.00), cc.p(360.18, 682.50), cc.p(973.82, 682.50),}
    },
    [5] = { [6] = { cc.p(15.47, 41.85), cc.p(666.00, 652.00), cc.p(103.50, 358.00), cc.p(1228.00, 358.00), cc.p(320.00, 623.00), cc.p(1014.00, 623.00),}, 
            [8] = { cc.p(15.47, 41.85), cc.p(666.00, 652.00), cc.p(103.50, 321.00), cc.p(1228.00, 321.00), cc.p(107.00, 556.00), cc.p(1227.00, 556.00), cc.p(360.00, 652.00), cc.p(975.00, 652.00),}
    },
}



function GameLayer:showPlayerPosition()
    if ZJHGameCommon.gameConfig == nil then 
        return
    end 
    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",i))
        uiPanel_handCard:setPosition(Playerposition[1][ZJHGameCommon.gameConfig.bPlayerCount][i])
    end 

    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local uiPanel_tipsCardPosUser = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",i))
        uiPanel_tipsCardPosUser:setPosition(Playerposition[2][ZJHGameCommon.gameConfig.bPlayerCount][i])
    end 

    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local uiPanel_scorePos = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_scorePos%d",i))
        uiPanel_scorePos:setPosition(Playerposition[3][ZJHGameCommon.gameConfig.bPlayerCount][i])
    end 

    for i = 1 , ZJHGameCommon.gameConfig.bPlayerCount do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        uiPanel_player:setPosition(Playerposition[4][ZJHGameCommon.gameConfig.bPlayerCount][i])
    end 

    for i = 2 , ZJHGameCommon.gameConfig.bPlayerCount do
        local uiButton_Match = ccui.Helper:seekWidgetByName(self.root,string.format("Button_Match%d",i))
        uiButton_Match:setPosition(Playerposition[5][ZJHGameCommon.gameConfig.bPlayerCount][i])
    end
end 

return GameLayer


