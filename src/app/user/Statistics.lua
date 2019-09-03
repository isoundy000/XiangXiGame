---------统计----------
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local Statistics = {}

function Statistics:onEnter( ... )
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Statistics:onExit( ... )
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Statistics:EVENT_TYPE_NET_RECV_MESSAGE( event )
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIN then
        netInstance = NetMgr:getLoginInstance()
    elseif netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end

    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    --返回亲友圈统计个人
    if  netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MYSELF then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwDayTime = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MYSELF,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MYSELF_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MYSELF_FINISH,data)
    --返回亲友圈统计成员
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MEMBER then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)                     --玩家昵称
        data.szLogoInfo = luaFunc:readRecvString(256) --用户头像
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MEMBER,data)
    --返回亲友圈统计成员
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwDayTime = luaFunc:readRecvDWORD()
        data.dwPlayGameCount1 = luaFunc:readRecvDWORD()
        data.dwPlayGameCount2 = luaFunc:readRecvDWORD()
        data.dwPlayGameCount3 = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwRoomCard = luaFunc:readRecvDWORD()
        data.dwDAU = luaFunc:readRecvDWORD()
        data.dwDNU = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_ALL then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwMemberCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwRoomCard = luaFunc:readRecvDWORD()
        data.dwDNU = luaFunc:readRecvDWORD()
        data.dwNewUserGameCount = luaFunc:readRecvDWORD()
        data.dwAllPeopleCount = luaFunc:readRecvDWORD()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_ALL,data)
    --//返回亲友圈统计成员
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MEMBER_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MEMBER_FINISH,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_FINISH,data)

    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_FATIGUE_STATISTICS then
        --亲友圈疲劳值统计
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.cbOffice = luaFunc:readRecvByte()
        data.lFatigue = luaFunc:readRecvLong() / 100
        data.lClubSellFatigue = luaFunc:readRecvLong() / 100
        data.lClubConsumeFatigue = luaFunc:readRecvLong() / 100
        data.lSurplusFatigue = luaFunc:readRecvLong() / 100
        EventMgr:dispatch(EventType.RET_GET_CLUB_FATIGUE_STATISTICS,data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_FATIGUE_DETAILS then
        --亲友圈疲劳值详情
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.cbType = luaFunc:readRecvByte()
        data.lOldFatigue = luaFunc:readRecvLong() / 100
        data.lFatigue = luaFunc:readRecvLong() / 100
        data.lNewFatigue = luaFunc:readRecvLong() / 100
        data.dwOperTime = luaFunc:readRecvDWORD()
        data.szDesc = luaFunc:readRecvString(64)
        data.dwOriginID = luaFunc:readRecvDWORD()
        data.szOriginNickName = luaFunc:readRecvString(32)
        data.szOriginLogoInfo = luaFunc:readRecvString(256)
        data.isFinish = luaFunc:readRecvBool()
        data.isAllFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_FATIGUE_DETAILS, data)

    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_GET_GAME_RECORD then
        --赞战绩详情
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.cbType = luaFunc:readRecvByte()                    --类型    0个人普通房战绩    1个人俱乐部战绩 2个人所在俱乐部战绩 3俱乐部战绩
        data.szMainGameID = luaFunc:readRecvString(32)                --战绩唯一标志
        data.dwChannelID = luaFunc:readRecvDWORD()                    --渠道ID
        data.wKindID = luaFunc:readRecvWORD()                         --游戏ID
        data.wServerID = luaFunc:readRecvWORD()                       --服务器ID      
        data.wGameCount = luaFunc:readRecvWORD()                      --游戏总局数
        data.wCurrentGameCount = luaFunc:readRecvWORD()               --当前局数
        data.isComplete = luaFunc:readRecvBool()                      --是否为完成场次
        data.dwTableID = luaFunc:readRecvDWORD()                      --桌子ID
        data.nTableType = luaFunc:readRecvInt()                       --桌子类型
        data.dwTableOwnerID = luaFunc:readRecvDWORD()                 --房主 
        data.dwRoomCard = luaFunc:readRecvDWORD()                     --房卡数
        data.dwClubID = luaFunc:readRecvDWORD()                       --俱乐部ID
        data.dwPlayID = luaFunc:readRecvDWORD()                       --玩法ID
        data.dwStartData = luaFunc:readRecvDWORD()                    --开始时间
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()                --游戏时长   
        data.bPlayerCount = luaFunc:readRecvByte()                    --玩家人数  
        data.dwLike = luaFunc:readRecvDWORD()                   --次数   
        data.tUser = {}
        for i=1,8 do
            data.tUser[i]={}   
            data.tUser[i].dwUserID = luaFunc:readRecvDWORD()                    --玩家ID
            data.tUser[i].bChairID = luaFunc:readRecvByte()                     --座位号ID
            data.tUser[i].szNickName = luaFunc:readRecvString(32)                       --玩家昵称
            data.tUser[i].lScore = luaFunc:readRecvLong()                       --玩家总积分
            data.tUser[i].bBigWinner = luaFunc:readRecvByte()                   --大赢家
        end 

        data.tSub = {}
        for i=1,20 do
            data.tSub[i]={}   
            data.tSub[i].szSubID = luaFunc:readRecvString(32)                   --战绩小局唯一标志
            data.tSub[i].dwPlayTimeStart = luaFunc:readRecvDWORD()              --开始时间
            data.tSub[i].dwPlayTimeCount = luaFunc:readRecvDWORD()              --游戏时长
            data.tSub[i].bBankerUser = luaFunc:readRecvByte()                   --庄家
            data.tSub[i].lScore = {}
            for j=1,8 do
                data.tSub[i].lScore[j] = luaFunc:readRecvLong()                 --小局积分
            end 
        end 
        local a = 1 
        -- data.cbType = luaFunc:readRecvByte()                    --类型   
        EventMgr:dispatch(EventType.RET_GET_GAME_RECORD, data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_GET_GAME_RECORD_FINISH then
        --赞战绩结束
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.cbType = luaFunc:readRecvByte()                    --类型    0个人普通房战绩    1个人俱乐部战绩 2个人所在俱乐部战绩 3俱乐部战绩
        data.lRet = luaFunc:readRecvLong()                      --结果
        data.isFinish = luaFunc:readRecvBool()                  --是否完成
        EventMgr:dispatch(EventType.RET_GET_GAME_RECORD_FINISH, data)  
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_LIKE_GAME_RECORD then    
        --点赞结束
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.lRet = luaFunc:readRecvLong()                      --结果
        data.szSignID = luaFunc:readRecvString(32)                  --战绩唯一标志
        EventMgr:dispatch(EventType.RET_LIKE_GAME_RECORD, data)  
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_GET_3DAYS_GAME_RECORD then 

    end
end

--请求俱乐部个人统计
function Statistics:req_statisticsMyself(dwClubID,dwDayTime,dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_MYSELF,"ddd",dwClubID,dwDayTime,dwUserID)
end

--请求亲友圈统计成员
function Statistics:req_statisticsMember(dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_MEMBER,"dddwd",dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore)
end

--请求管理员统计
function Statistics:req_statisticsManager(dwClubID,dwBeganTime,dwEndTime)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_ALL,"ddd",dwClubID,dwBeganTime,dwEndTime)
end

--每日统计REQ_GET_CLUB_STATISTICS
function Statistics:req_dayManager(dwClubID,dwBeganTime,dwEndTime,wPage )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS,"dddw",dwClubID,dwBeganTime,dwEndTime,wPage )
end

--玩家统计REQ_GET_CLUB_STATISTICS_MEMBER //0大赢家 1全部场次 2完整场次 3分数	
function Statistics:req_playerManager(dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore,bSortMode )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_MEMBER,"dddwdb",dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore,bSortMode)
end

function Statistics:req_fatigueStatistics(dwClubID,dwBeganTime,dwEndTime)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_FATIGUE_STATISTICS,"ddd",dwClubID,dwBeganTime,dwEndTime)
end

--请求亲友圈疲劳值详情
function Statistics:getClubFatigueDetatls(dwClubID, dwUserID, dwBeganTime, dwEndTime, wPage)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_FATIGUE_DETAILS, "ddddw", dwClubID, dwUserID, dwBeganTime, dwEndTime, wPage)
end

--请求含赞战绩大局消息 REQ_GET_GAME_RECORD REQ_GET_GAME_RECORD
function Statistics:req_getGameRecord(cbType, dwClubID, dwUserID, dwBeganTime,dwEndTime,dwMinWinnerScore,dePage)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_GET_GAME_RECORD,"bdddddd",cbType, dwClubID,dwUserID, dwBeganTime, dwEndTime, dwMinWinnerScore, dePage)
    print("战绩发生")
end

--请求点赞  REQ_LIKE_GAME_RECORD
function Statistics:req_likeGameRecord(dwUserID,szSignID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD,NetMsgId.REQ_LIKE_GAME_RECORD, "dns", dwUserID, 32, szSignID)
end

--请求三天战绩  REQ_GET_3DAYS_GAME_RECORD
function Statistics:req_get3DaysGameRecord(cbType,dwClubID,dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD,NetMsgId.REQ_GET_3DAYS_GAME_RECORD, "bdd", cbType, dwClubID, dwUserID)
end

return Statistics