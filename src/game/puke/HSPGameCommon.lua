local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local Default = require("common.Default")
local LocationSystem = require("common.LocationSystem")

local HSPGameCommon = 
{
    GameState_Init = 0,
    GameState_Start = 1,
    GameState_Over = 2,
    gameState = 0,
    
    EARTH_RADIUS = 6371.004 ,                     --地球半径  
        
    MAX_COUNT = 15,
    CardType_error          = 0,    --错误牌型
    CardType_single         = 1,    --单牌
    CardType_pair           = 2,    --对子
    CardType_straight       = 3,    --顺子
    CardType_straightPair   = 4,    --连对 
    CardType_3Add2          = 5,    --三带二
    CardType_airplane       = 6,    --飞机
    CardType_4Add3          = 7,    --四带三
    CardType_bomb           = 8,    --炸弹
        
    dwUserID = 0,
    wBankerUser = 0,
    palyer = nil,
    serverData = nil,
    gameConfig = nil,
    playbackData = nil,
    meChairID = 0,

    mJiangChiCount = 0,  --奖池分数
    
    --双十类型
    NiuType_NULL = 0,       --散牌
    NiuType_1 = 1,          --1
    NiuType_2 = 2,          --2
    NiuType_3 = 3,          --3
    NiuType_4 = 4,          --4
    NiuType_5 = 5,          --5
    NiuType_6 = 6,          --6
    NiuType_7 = 7,          --7
    NiuType_8 = 8,          --8
    NiuType_9 = 9,          --9
    NiuType_Niu = 10,       --双十
    NiuType_Silver = 20,    --银花
    NiuType_Gold = 30,      --金花
    NiuType_Gourd = 40,     --葫芦
    NiuType_Bomb = 50,      --炸弹
    NiuType_Niu5 = 60,      --五小
    NiuType_Flush = 70,     --同花顺
    
    --三公类型
    SanType_NULL = 0,       --无点
    SanType_1 = 1,          --1点
    SanType_2 = 2,          --2点
    SanType_3 = 3,          --3点
    SanType_4 = 4,          --4点
    SanType_5 = 5,          --5点
    SanType_6 = 6,          --6点
    SanType_7 = 7,          --7点
    SanType_8 = 8,          --8点
    SanType_9 = 9,          --9点
    SanType_Mix = 10,       --混三公
    SanType_Large = 20,     --小三公
    SanType_Small = 30,     --大三公   
    NiuType_ZZSG   = 40,    --至尊三公   
    
    DistanceAlarm = 1 ,                 -- 距离判断（0：没有判断多，需要判断。1：判断过或不需要判断）
}

function HSPGameCommon:init()
    self.gameState = 0
end

function HSPGameCommon:getViewIDByChairID(wChairID)
    local location = 1          --主角位置
    local wPlayerCount = self.gameConfig.bPlayerCount      --玩家人数
    local meChairID = self:getRoleChairID()     --主角的座位号
    local viewID = (wChairID + wPlayerCount - meChairID)%wPlayerCount+1
    return viewID
end

function HSPGameCommon:getRoleChairID()
    return self.meChairID
end

function HSPGameCommon:ContinueGame(cbLevel)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SET_POSITION,"aad",LocationSystem.pos.x, LocationSystem.pos.y, HSPGameCommon.dwUserID)
    if HSPGameCommon.tableConfig.nTableType == TableType_FriendRoom or HSPGameCommon.tableConfig.nTableType == TableType_ClubRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_NEXT_GAME,"")
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"")
    elseif HSPGameCommon.tableConfig.nTableType == TableType_GoldRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_CONTINUE_GAME,"b",cbLevel)
    elseif HSPGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_CONTINUE_REDENVELOPE,"b",cbLevel)
    end
end

function HSPGameCommon:GetReward(cbLevel)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GET_REDENVELOPE_REWARD,"b",cbLevel)
end 

function HSPGameCommon:getUserInfo(charID)
    for key, var in pairs(self.player) do
        if var.wChairID == charID then
            return clone(var)
        end
    end
    local var = {}
    var.cbSex = 0
    return var
end

function HSPGameCommon:getUserInfoByUserID(dwUserID)
    for key, var in pairs(self.player) do
        if var.dwUserID == dwUserID then
            return var
        end
    end
    return nil
end

function HSPGameCommon:rad(d)
    return d* math.pi / 180.0;
end 

function HSPGameCommon:GetDistance(lat1,lat2)
    local radLat1 = self:rad(lat1.x)
    local radLat2 = self:rad(lat2.x)
    local a = radLat1 - radLat2
    local b = self:rad(lat1.y) - self:rad(lat2.y)
    local s = 2 * math.asin(math.sqrt(math.pow(math.sin(a/2),2) +math.cos(radLat1)*math.cos(radLat2)*math.pow(math.sin(b/2),2)))
    s = s * self.EARTH_RADIUS*1000
    --   s = math.round(s * 10000) / 10000  
    return s;
end 

--牌资源
function HSPGameCommon:getCardNode(data)
 
    local cardIndex = cc.UserDefault:getInstance():getIntegerForKey('PDKSize',0) 
    
    local cardBgIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_PukeCardBg,0)
 
    if data == 0 or data == nil then
        if cardBgIndex == 0 then 
            return ccui.ImageView:create("puke/table/puke_bg0.png")
        elseif cardBgIndex == 1 then 
            return ccui.ImageView:create("puke/table/puke_bg1.png")
        elseif cardBgIndex == 2 then 
            return ccui.ImageView:create("puke/table/puke_bg2.png")
        end 
    end
    local value = Bit:_and(data,0x0F)
    local color = Bit:_rshift(Bit:_and(data,0xF0),4)    
    local card = nil

    if value == 14 then 
        value = 1
    elseif  value == 15 then 
        value = 2
    end
    if data == 1 then 
        value = 16 
        color = 4
    elseif data == 17 then 
        value = 17 
        color = 4
    elseif data == 33 then 
        value = 15 
        color = 5
    end 
    -- if cardIndex ~= 1 then
    card = ccui.ImageView:create(string.format("puke/card/card0/puke_%d_%d.png",color,value))

        if HSPGameCommon.gameConfig.bFKSLaiZi == 1 and  value == 3 and color == 3  then 
            local tipsImage = ccui.ImageView:create('puke/table/ok_ui_f_laizi.png')   
            card:addChild(tipsImage)
            tipsImage:setPosition(47,41)      
        end 
    -- else
    --     card = ccui.ImageView:create(string.format("puke/card/card1/puke_%d_%d.png",color,value))
    -- end
    return card
end

function HSPGameCommon:playAnimation(root,id, wChairID)
    local Animation = require("game.puke.AnimationHSP")
    if Animation[id] == nil then
        return
    end
    local AnimationData = Animation[id][HSPGameCommon.regionSound]
    if AnimationData == nil then
        return
    end
    local soundFile = ""
    if wChairID ~= nil then
        soundFile = AnimationData.sound[HSPGameCommon.player[wChairID].cbSex]
    else
        soundFile = AnimationData.sound[0]
    end
    if soundFile ~= "" then
        require("common.Common"):playEffect(AnimationData.sound[HSPGameCommon.player[wChairID].cbSex])
    end
    if (id == "我赢啦" or id == "赢")and( CHANNEL_ID == 6 or CHANNEL_ID == 7)  then 
        require("common.Common"):playEffect("common/win.mp3")
    end 
end

return HSPGameCommon