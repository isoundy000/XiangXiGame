--[[
*名称:NewClubMemberLayer
*描述:亲友圈成员
*作者:admin
*创建日期:2018-06-19 15:59:55
*修改日期:
]]

local EventMgr              = require("common.EventMgr")
local EventType             = require("common.EventType")
local NetMgr                = require("common.NetMgr")
local NetMsgId              = require("common.NetMsgId")
local StaticData            = require("app.static.StaticData")
local UserData              = require("app.user.UserData")
local Common                = require("common.Common")
local Default               = require("common.Default")
local GameConfig            = require("common.GameConfig")
local Log                   = require("common.Log")

local NewClubMemberLayer    = class("NewClubMemberLayer", cc.load("mvc").ViewBase)
local MEMBER_NUM = 7 --成员每次请求数量
function NewClubMemberLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
        {"Image_memTop", "onMemPage"},
        {"Image_memTopLight"},
        {"Image_partnerTop", "onPartnerPage"},
        {"Image_partnerTopLight"},

        {"Image_memFrame"},
        {"Image_mem", "onSelMem"},
        {"Image_check", "onSelCheck"},
        {"Image_input", "onSelInput"},
        {"Image_fatigue", "onFatigue"},
        {"Panel_mem"},
        {"ListView_mem"},
        {"ListView_find"},
        {"Image_memItem"},
        -- {"Button_exitClub", "onExitClub"},
        {"Panel_check"},
        {"ListView_check"},
        {"Image_checkItem"},
        {"Panel_input"},
        {"Image_noInputTips"},
        {"ListView_input"},
        {"Image_inputItem"},
        {"Image_inputFrame"},
        -- {"Image_findFame"},
        -- {"Text_tips"},
        -- {"Panel_memNumber"},


        {"Image_partnerFrame"},
        {"Image_findFrame"},
        {"Button_memFind", "onMemFind"},
        {"Button_memReturn", "onMemReturn"},
        {"TextField_playerID"},
        {"Text_memNums"},
        {"Button_addMem", "onAddMem"},
        {"ListView_addParnter"},
        {"Image_parnterItem"},

        {"Image_myParnterItem"},
        {"Image_pushParnterItem"},
        {"Image_plzParnterItem"},
        {"ListView_myParnter"},
        {"ListView_findMyParnter"},
        {"ListView_pushParnter"},
        {"ListView_findAddParnter"},

        {"Panel_newEx"},
        {"Image_newItem"},
        {"Panel_fontItem"},
        {"Text_newPeoples"},
        {"TextField_newInputID"},
        {"Button_newFind", "onNewFind"},
        {"Button_newReturn", "onNewReturn"},
        {"ListView_new"},
        {"ListView_newPush"},
        {"ListView_newFind"},
        {"Image_newFindFrame"},

        --合伙人子菜单
        {"Image_myMem", "onMyMem"},
        {"Image_myMemLight"},
        {"Image_countPlayer", "onPlayerCount"},
        {"Image_countPlayerLight"},
        {"Image_addParnter", "onAddParnter"},
        {"Image_addParnterLight"},
        {"Image_myParnter", "onMyParnter"},
        {"Image_myParnterLight"},
        {"Image_countParnter", "onCountParnter"},
        {"Image_countParnterLight"},
        {"Image_partnerSet", "onPartnerSet"},
        {"Image_partnetSetLight"},
        {"Image_leaderGet", "onLeaderGet"},
        {"Image_leaderLight"},
        {"Button_importPlayer", "onImportPlayer"},
        {"Text_importFlag"},

        --合伙人分页
        {"Panel_myPlayer"},
        {"ListView_myPlayer"},
        {"ListView_findMyPlayer"},
        {"ListView_pushPlayer"},
        {"Panel_playerCount"},
        {"Image_playerCountFrame"},
        {"Text_wj_alljt"},
        {"Text_wj_allFatiguesy"},
        {"Text_wj_allYuanBaosy"},
        {"Text_wj_alldyj"},
        {"Text_wj_cynum"},
        {"ListView_playerCount"},
        {"Image_playerCountPushFrame"},
        {"ListView_pushPlayerCount"},
        {"Panel_playerCountItem"},
        {"Panel_playerCountPushItem"},

        {"Panel_addParnter"},
        {"Panel_myParnter"},
        {"Panel_parnterCount"},
        {"Panel_partnetSet"},
        {"Panel_leaderGet"},
        {"Image_leaderFrame"},
        {"Text_sy_allcy"},
        {"Text_sy_allfk"},
        {"Text_sy_allFatigue"},
        {"Text_sy_allYuanbao"},
        {"ListView_sy"},
        {"Panel_leaderItem"},

        --合伙人顶部公共栏
        {"Panel_top"},
        {"Image_allCount"},
        {"Text_playAllJS"},
        {"Text_timeNode"},
        {"Image_left", "onImageLeft"},
        {"Image_right", "onImageRight"},
        {"Button_search", "onSearch"},
        {"Text_day_left"},
        {"Text_day_right"},
        {"Text_dawinSorce"},
        {"TextField_winsorce"},
        {"Image_topPartnerMem"},
        {"TextField_partnermem"},
        {"Button_findPartner", "onFindPartnerMem"},
        {"Image_topFindMem"},
        {"TextField_parnterID"},
        {"Button_parnterFind", "onParnterFind"},
        {"Button_changemem"},
        {"Panel_partnerCount"},
        {"Image_partnerPageHead"},
        {"Text_partnerPageName"},
        {"Text_partnerPageID"},
        {"Button_partnerPageReturn", "onPartnerPageReturn"},
        {"Text_plztop"},
        {"Text_plznum"},

        {"Image_countFrame"},
        {"Text_allcount_partner"},
        {"Text_allyuanbao_partner"},
        {"Text_allroomcard_partner"},
        {"Text_allFatigue_partner"},
        {"Text_allbigwin_partner"},
        {"ListView_count_partner"},
        {"Image_countPushFrame"},
        {"Panel_countItem"},
        {"Panel_countPushItem"},
        {"ListView_pushCount"},

        --合伙人设置界面
        {"Image_one", "onOnePartner"},
        {"Image_two", "onMorePartner"},
        {"Text_oneValue"},
        {"Button_oneSet", "onOneSet"},
        {"Text_two"},
        {"Text_twoValue"},
        {"Button_twoSet", "onTwoSet"},
        {"Text_three"},
        {"Text_threeValue"},
        {"Button_threeSet", "onThreeSet"},
        {"Image_autoFatigue"},
        {"Image_autoYB"},
        {"Image_kick", "onPartnerKick"},
        {"Image_import", "onPartnerImport"},
        {"Image_leave", "onPartnerLeave"},
        {"Text_jtValue"},
        {"Button_jtSet", "onJTSet"},
        {"Button_save", "onPartnerSave"},


        {"Panel_partnerCount"},
    }
    self.clubData = {}      --亲友圈大厅数据
    self.searchNum = 0
    self.curPartnerIdx = 1
    self.partnerReqState = 0
    self.beganTime = Common:getStampDay(os.time() ,true)
    self.endTime = Common:getStampDay(os.time() ,false)
    self.pCurPage = 1
    self.pReqState = 0
    self.pCurID = 0

    self.notPartnerMemIdx = 1
    self.notPartnerMemState = 0

    self.curSelPage = 1

    self.newPushPage = 1
    self.newPushState = 0
    self.curNewPushID = 0

    self.curPartnerPage = 1

    self.earningsPage = 1
    self.earningsReqState = 0

    self.playerCountPage = 1
    self.playerCountState = 0
    self.playerCountDetailsPage = 1
    self.playerCountDetailsState = 0
    self.curSelLookDetailsPlayer = 0

    self.partnerCountPage = 1
    self.partnerCountState = 0
    self.partnerCountDetailsPage = 1
    self.partnerCountDetailsState = 0
    self.curSelLookDetailsPartner = 0
end

function NewClubMemberLayer:onEnter(param)
    EventMgr:registListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
    EventMgr:registListener(EventType.RET_CLUB_CHECK_LIST,self,self.RET_CLUB_CHECK_LIST)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER,self,self.RET_GET_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_CLUB_CHECK_RESULT,self,self.RET_CLUB_CHECK_RESULT)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_EX,self,self.RET_GET_CLUB_MEMBER_EX)
    EventMgr:registListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_UPDATE_CLUB_INFO,self,self.RET_UPDATE_CLUB_INFO)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FINISH,self,self.RET_GET_CLUB_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_EX_FINISH	,self,self.RET_GET_CLUB_MEMBER_EX_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_MEMBER ,self,self.RET_FIND_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER ,self,self.RET_GET_CLUB_PARTNER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_FINISH ,self,self.RET_GET_CLUB_PARTNER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_MEMBER ,self,self.RET_GET_CLUB_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_FIND_CLUB_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_ALL ,self,self.RET_GET_CLUB_STATISTICS_ALL)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
    EventMgr:registListener(EventType.RET_SETTINGS_CONFIG ,self,self.RET_SETTINGS_CONFIG)
    EventMgr:registListener(EventType.RET_SETTINGS_PAPTNER ,self,self.RET_SETTINGS_PAPTNER)
    EventMgr:registListener(EventType.RET_UPDATE_CLUB_PLAYER_INFO ,self,self.RET_UPDATE_CLUB_PLAYER_INFO)
    EventMgr:registListener(EventType.RET_PARTNER_EARNINGS ,self,self.RET_PARTNER_EARNINGS)
    EventMgr:registListener(EventType.RET_PARTNER_PAGE_EARNINGS ,self,self.RET_PARTNER_PAGE_EARNINGS)
    EventMgr:registListener(EventType.RET_PARTNER_PAGE_EARNINGS_FINISH ,self,self.RET_PARTNER_PAGE_EARNINGS_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_PLAYER_COUNT ,self,self.RET_CLUB_PLAYER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT ,self,self.RET_CLUB_PAGE_PLAYER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PLAYER_COUNT_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS)
    EventMgr:registListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_PARTNER_COUNT ,self,self.RET_CLUB_PARTNER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT ,self,self.RET_CLUB_PAGE_PARTNER_COUNT)
    EventMgr:registListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PARTNER_COUNT_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS)
    EventMgr:registListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH)
    EventMgr:registListener(EventType.RET_CLUB_GROUP_INVITE_LOG ,self,self.RET_CLUB_GROUP_INVITE_LOG)
    EventMgr:registListener(EventType.RET_CLUB_GROUP_INVITE_REPLY ,self,self.RET_CLUB_GROUP_INVITE_REPLY)
    EventMgr:registListener(EventType.RET_CLUB_MEMBER_INFO ,self,self.RET_CLUB_MEMBER_INFO)
    EventMgr:registListener(EventType.RET_CLUB_MEMBER_INFO_FINISH ,self,self.RET_CLUB_MEMBER_INFO_FINISH)
end

function NewClubMemberLayer:onExit()
    EventMgr:unregistListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
    EventMgr:unregistListener(EventType.RET_CLUB_CHECK_LIST,self,self.RET_CLUB_CHECK_LIST)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER,self,self.RET_GET_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER) 
    EventMgr:unregistListener(EventType.RET_CLUB_CHECK_RESULT,self,self.RET_CLUB_CHECK_RESULT)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_EX,self,self.RET_GET_CLUB_MEMBER_EX)
    EventMgr:unregistListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_UPDATE_CLUB_INFO,self,self.RET_UPDATE_CLUB_INFO)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FINISH,self,self.RET_GET_CLUB_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_EX_FINISH,self,self.RET_GET_CLUB_MEMBER_EX_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_MEMBER ,self,self.RET_FIND_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER ,self,self.RET_GET_CLUB_PARTNER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_FINISH ,self,self.RET_GET_CLUB_PARTNER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_MEMBER ,self,self.RET_GET_CLUB_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_ALL ,self,self.RET_GET_CLUB_STATISTICS_ALL)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CONFIG ,self,self.RET_SETTINGS_CONFIG)
    EventMgr:unregistListener(EventType.RET_SETTINGS_PAPTNER ,self,self.RET_SETTINGS_PAPTNER)
    EventMgr:unregistListener(EventType.RET_UPDATE_CLUB_PLAYER_INFO ,self,self.RET_UPDATE_CLUB_PLAYER_INFO)
    EventMgr:unregistListener(EventType.RET_PARTNER_EARNINGS ,self,self.RET_PARTNER_EARNINGS)
    EventMgr:unregistListener(EventType.RET_PARTNER_PAGE_EARNINGS ,self,self.RET_PARTNER_PAGE_EARNINGS)
    EventMgr:unregistListener(EventType.RET_PARTNER_PAGE_EARNINGS_FINISH ,self,self.RET_PARTNER_PAGE_EARNINGS_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_PLAYER_COUNT ,self,self.RET_CLUB_PLAYER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT ,self,self.RET_CLUB_PAGE_PLAYER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PLAYER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PLAYER_COUNT_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS)
    EventMgr:unregistListener(EventType.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PLAYER_COUNT_DETAILS_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_PARTNER_COUNT ,self,self.RET_CLUB_PARTNER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT ,self,self.RET_CLUB_PAGE_PARTNER_COUNT)
    EventMgr:unregistListener(EventType.RET_CLUB_PAGE_PARTNER_COUNT_FINISH ,self,self.RET_CLUB_PAGE_PARTNER_COUNT_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS)
    EventMgr:unregistListener(EventType.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH ,self,self.RET_CLUB_PARTNER_COUNT_DETAILS_FINISH)
    EventMgr:unregistListener(EventType.RET_CLUB_GROUP_INVITE_LOG ,self,self.RET_CLUB_GROUP_INVITE_LOG)
    EventMgr:unregistListener(EventType.RET_CLUB_GROUP_INVITE_REPLY ,self,self.RET_CLUB_GROUP_INVITE_REPLY)
    EventMgr:unregistListener(EventType.RET_CLUB_MEMBER_INFO ,self,self.RET_CLUB_MEMBER_INFO)
    EventMgr:unregistListener(EventType.RET_CLUB_MEMBER_INFO_FINISH ,self,self.RET_CLUB_MEMBER_INFO_FINISH)

    --审核红点操作
    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        local parentNode = self:getParent()
        if parentNode and parentNode.Image_checkRedPoint then
            parentNode.Image_checkRedPoint:setVisible(false)
            UserData.Guild:getClubCheckList(self.clubData.dwClubID)
        end
    end
end

function NewClubMemberLayer:onCreate(param)
    self:initUI(param)
end

function NewClubMemberLayer:onClose()
    self:removeFromParent()
end

function NewClubMemberLayer:onSelMem()
    self:switchPage(1)
end

function NewClubMemberLayer:onSelCheck()
    self:switchPage(2)
end

function NewClubMemberLayer:onSelInput()
    self:switchPage(3)
end

function NewClubMemberLayer:onFatigue()
    self:switchPage(4)
end

function NewClubMemberLayer:onExitClub()
    if self.clubData.dwUserID ~= UserData.User.userID then
        require("common.MsgBoxLayer"):create(1,nil,"您确定要退出亲友圈？",function() 
            UserData.Guild:quitClub(self.clubData.dwClubID)
        end)
    else
        require("common.MsgBoxLayer"):create(0,nil,"群主不能退出亲友圈")
    end
end

function NewClubMemberLayer:onMemFind()
    local playerid = tonumber(self.TextField_playerID:getString())
    if playerid then
        -- UserData.Guild:findClubMemInfo(self.clubData.dwClubID, playerid)
        if self:isHasAdmin() then
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 0, playerid, 1)
        else
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 2, playerid, 1)
        end
    else
        require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID错误!")
    end
end

function NewClubMemberLayer:onMemReturn()
    self.ListView_mem:setVisible(true)
    self.ListView_find:setVisible(false)
    self.Image_findFrame:setVisible(true)
    self.Button_memFind:setVisible(true)
    self.Button_memReturn:setVisible(false)
end

function NewClubMemberLayer:onNewFind()
    local playerid = tonumber(self.TextField_newInputID:getString())
    if playerid then
        -- UserData.Guild:findClubMemInfo(self.clubData.dwClubID, playerid)
        if self:isHasAdmin() then
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 0, playerid, 1)
        else
            UserData.Guild:reqClubMemberInfo(self.clubData.dwClubID, UserData.User.userID, 2, playerid, 1)
        end
    else
        require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID错误!")
    end
end

function NewClubMemberLayer:onNewReturn()
    self.ListView_new:setVisible(true)
    self.ListView_newPush:setVisible(false)
    self.ListView_newFind:setVisible(false)
    self.Image_newFindFrame:setVisible(true)
    self.Button_newFind:setVisible(true)
    self.Button_newReturn:setVisible(false)
end

function NewClubMemberLayer:onAddMem()
    local roomNumber = ""
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID不正确")
            return
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
    UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
end

function NewClubMemberLayer:onMemPage()
    local lightBtn = self.Image_memTop:getChildren()[1]
    if not lightBtn:isVisible() then
        lightBtn:setVisible(true)
        self.Image_partnerTop:getChildren()[1]:setVisible(false)
        self.Image_memFrame:setVisible(true)
        self.Image_partnerFrame:setVisible(false)
        -- self.ListView_mem:removeAllItems()
        -- self.memberReqState = 0
        -- self.curClubIndex = 0
        -- self:reqClubMember()
        self:switchPage(1)
    end
end

function NewClubMemberLayer:isHasAdmin()
    return (self.clubData.dwUserID == UserData.User.userID) or self:isAdmin(UserData.User.userID)
end

function NewClubMemberLayer:onPartnerPage()
    if self.clubData.dwUserID == UserData.User.userID then
        --群主
    elseif self:isAdmin(UserData.User.userID) then
        --管理员
    else
        if self.userOffice == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"您还不是合伙人!")
            return
        end

        --合伙人
        self.Image_partnerSet:setVisible(false)
    end

    self.Image_memTop:getChildren()[1]:setVisible(false)
    self.Image_partnerTop:getChildren()[1]:setVisible(true)
    self.Image_memFrame:setVisible(false)
    self.Image_partnerFrame:setVisible(true)
    self.Text_plznum:setString(self.userFatigueValue)
    self:switchParnterPage(1)
end

function NewClubMemberLayer:onMyMem()
    self:switchParnterPage(1)
end

function NewClubMemberLayer:onPlayerCount()
    self:switchParnterPage(2)
end

function NewClubMemberLayer:onLeaderGet()
    if self:isAdmin(UserData.User.userID) then
        require("common.MsgBoxLayer"):create(0,self,"权限不足！")
        return
    end
    self:switchParnterPage(3)
end

function NewClubMemberLayer:onMyParnter()
    self:switchParnterPage(4)
end

function NewClubMemberLayer:onCountParnter()
    self:switchParnterPage(5)
end

function NewClubMemberLayer:onAddParnter()
    self:switchParnterPage(6)
end

function NewClubMemberLayer:onPartnerSet()
    self:switchParnterPage(7)
end

function NewClubMemberLayer:onImportPlayer()
    local isMegeClub = false
    if self:isHasAdmin() then
        isMegeClub = true
    end
    local node = require("app.MyApp"):create(self.clubData, isMegeClub):createView("NewClubParnterAddMemLayer")
    self:addChild(node)
end

function NewClubMemberLayer:onImageLeft()
    local timeNode = require("app.MyApp"):create(self.beganTime,handler(self,self.leftNodeChange)):createView("TimeNode")
    self.Image_left:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubMemberLayer:onImageRight()
    local timeNode = require("app.MyApp"):create(self.endTime,handler(self,self.rightNodeChange)):createView("TimeNode")
    self.Image_right:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubMemberLayer:leftNodeChange( time,stampMin,stampMax )
    self.Text_day_left:setString(time)
    self.beganTime = stampMin

    if self.ListView_myParnter:isVisible() then
        self.ListView_myParnter:removeAllChildren()
    end
    if self.ListView_pushParnter:isVisible() then
        self.ListView_pushParnter:removeAllChildren()
    end
end

function NewClubMemberLayer:rightNodeChange( time,stampMin,stampMax )
    self.Text_day_right:setString(time)
    self.endTime = stampMax

    if self.ListView_myParnter:isVisible() then
        self.ListView_myParnter:removeAllChildren()
    end
    if self.ListView_pushParnter:isVisible() then
        self.ListView_pushParnter:removeAllChildren()
    end
end

function NewClubMemberLayer:onSearch()
    if self.searchNum == 0 then
        self.searchNum = 5
        --查询
        self:research()
        schedule(self.Button_search,function()
            self.searchNum = self.searchNum - 1
            if self.searchNum <= 0 then
                self.searchNum = 0
                self.Button_search:stopAllActions()
            end
        end,1)
    else
        require("common.MsgBoxLayer"):create(0,self,self.searchNum .. "秒之后查询")
    end
end

function NewClubMemberLayer:research()
    if self.curPartnerPage == 1 then
        self.ListView_myPlayer:removeAllItems()
        self.pCurID = UserData.User.userID
        self.pCurPage = 1
        self:reqClubPartner(self.pCurID)
    
    elseif self.curPartnerPage == 2 then
        self.Text_wj_alljt:setString(0)
        self.Text_wj_allFatiguesy:setString(0)
        self.Text_wj_allYuanBaosy:setString(0)
        self.Text_wj_alldyj:setString(0)
        self.Text_wj_cynum:setString(0)
        self.ListView_playerCount:removeAllItems()
        UserData.Guild:getClubAllPlayerCount(UserData.User.userID, self.clubData.dwClubID, self.beganTime, self.endTime)

    elseif self.curPartnerPage == 3 then
        self.ListView_sy:removeAllItems()
        UserData.Guild:getPartnerAllEarnings(UserData.User.userID, self.clubData.dwClubID, self.beganTime, self.endTime)

    elseif self.curPartnerPage == 4 then
        if self.ListView_myParnter:isVisible() then
            --我的合伙人 
            self.ListView_myParnter:removeAllItems()
            self.partnerReqState = 0
            self.curPartnerIdx = 1
            self:reqClubPartner()
        else
            --具体某个合伙人展开
            self.ListView_pushParnter:removeAllItems()
            self.curPartnerIdx = 1
            self:reqClubPartner(self.pCurID)
        end

    elseif self.curPartnerPage == 5 then
        self.Text_allcount_partner:setString(0)
        self.Text_allyuanbao_partner:setString(0)
        self.Text_allroomcard_partner:setString(0)
        self.Text_allFatigue_partner:setString(0)
        self.Text_allbigwin_partner:setString(0)
        self.ListView_count_partner:removeAllItems()
        if self:isHasAdmin() then
            UserData.Guild:getClubAllPartnerCount(0, self.clubData.dwClubID, self.beganTime, self.endTime)
        else
            UserData.Guild:getClubAllPartnerCount(UserData.User.userID, self.clubData.dwClubID, self.beganTime, self.endTime)
        end
    end
end

function NewClubMemberLayer:onParnterFind()
    if not self.ListView_addParnter:isVisible() then
        return
    end
    local dwUserID = self.TextField_parnterID:getString()
    if dwUserID ~= "" then
        UserData.Guild:findClubNotPartnerMember(self.clubData.dwClubID, tonumber(dwUserID))
    end
end

function NewClubMemberLayer:onPartnerPageReturn()
    if self.curPartnerPage == 2 then
        self.Image_playerCountFrame:setVisible(true)
        self.Image_playerCountPushFrame:setVisible(false)
        self.Text_timeNode:setVisible(true)
        self.Panel_partnerCount:setVisible(false)
    elseif self.curPartnerPage == 5 then
        self.Image_countFrame:setVisible(true)
        self.Image_countPushFrame:setVisible(false)
        self.Text_timeNode:setVisible(true)
        self.Panel_partnerCount:setVisible(false)
    end
end

function NewClubMemberLayer:onFindPartnerMem()
    if self.curPartnerPage == 1 then
        local dwUserID = tonumber(self.TextField_partnermem:getString())
        if dwUserID then
            local dwMinWinnerScore = tonumber(self.TextField_winsorce:getString()) or 0
            UserData.Guild:findPartnerMember(self.clubData.dwClubID,self.pCurID,dwUserID,self.beganTime,self.endTime,dwMinWinnerScore)
            print('onFindPartnerMem::',self.clubData.dwClubID,self.pCurID,dwUserID,self.beganTime,self.endTime,dwMinWinnerScore)
        else
            require("common.MsgBoxLayer"):create(0,nil,"输入格式错误！")
        end
    end
end

function NewClubMemberLayer:onOnePartner()
    self.Image_one:getChildByName('Image_light'):setVisible(true)
    self.Image_two:getChildByName('Image_light'):setVisible(false)
    self.Text_two:setVisible(false)
    self.Text_three:setVisible(false)
end

function NewClubMemberLayer:onMorePartner()
    self.Image_one:getChildByName('Image_light'):setVisible(false)
    self.Image_two:getChildByName('Image_light'):setVisible(true)
    self.Text_two:setVisible(true)
    self.Text_three:setVisible(true)
end

function NewClubMemberLayer:onOneSet()
    local node = require("app.MyApp"):create(0, 3, function(value)
        local twoStr = self.Text_twoValue:getString()
        local twoLen = string.len(twoStr)
        local threeStr = self.Text_threeValue:getString()
        local threeLen = string.len(threeStr)
        local twoValue = tonumber(string.sub(twoStr, 1, twoLen-1))
        local threeValue = tonumber(string.sub(threeStr, 1, threeLen-1))
        if value + twoValue + threeValue <= 100 then
            self.Text_oneValue:setString(value .. '%')
        else
            require("common.MsgBoxLayer"):create(0,nil,"总分成比例不能超过100%！")
        end
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubMemberLayer:onTwoSet()
    local node = require("app.MyApp"):create(0, 3, function(value) 
        local oneStr = self.Text_oneValue:getString()
        local oneLen = string.len(oneStr)
        local threeStr = self.Text_threeValue:getString()
        local threeLen = string.len(threeStr)
        local oneValue = tonumber(string.sub(oneStr, 1, oneLen-1))
        local threeValue = tonumber(string.sub(threeStr, 1, threeLen-1))
        if oneValue + value + threeValue <= 100 then
            self.Text_twoValue:setString(value .. '%')
        else
            require("common.MsgBoxLayer"):create(0,nil,"总分成比例不能超过100%！")
        end
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubMemberLayer:onThreeSet()
    local node = require("app.MyApp"):create(0, 3, function(value) 
        local oneStr = self.Text_oneValue:getString()
        local oneLen = string.len(oneStr)
        local twoStr = self.Text_twoValue:getString()
        local twoLen = string.len(twoStr)
        local oneValue = tonumber(string.sub(oneStr, 1, oneLen-1))
        local twoValue = tonumber(string.sub(twoStr, 1, twoLen-1))
        if oneValue + twoValue + value <= 100 then
            self.Text_threeValue:setString(value .. '%')
        else
            require("common.MsgBoxLayer"):create(0,nil,"总分成比例不能超过100%！")
        end
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubMemberLayer:onPartnerKick()
    if self.Image_kick:getChildByName('Image_light'):isVisible() then
        self.Image_kick:getChildByName('Image_light'):setVisible(false)
    else
        self.Image_kick:getChildByName('Image_light'):setVisible(true)
    end
end

function NewClubMemberLayer:onPartnerImport()
    if self.Image_import:getChildByName('Image_light'):isVisible() then
        self.Image_import:getChildByName('Image_light'):setVisible(false)
    else
        self.Image_import:getChildByName('Image_light'):setVisible(true)
    end
end

function NewClubMemberLayer:onPartnerLeave()
    if self.Image_leave:getChildByName('Image_light'):isVisible() then
        self.Image_leave:getChildByName('Image_light'):setVisible(false)
    else
        self.Image_leave:getChildByName('Image_light'):setVisible(true)
    end
end

function NewClubMemberLayer:onJTSet()
    local node = require("app.MyApp"):create(0, 3, function(value) 
        self.Text_jtValue:setString(value)
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubMemberLayer:onPartnerSave()
    local bMode = 0
    if not self.Image_one:getChildByName('Image_light'):isVisible() then
        bMode = 1
    end

    local oneStr = self.Text_oneValue:getString()
    local oneLen = string.len(oneStr)
    local twoStr = self.Text_twoValue:getString()
    local twoLen = string.len(twoStr)
    local threeStr = self.Text_threeValue:getString()
    local threeLen = string.len(threeStr)
    local oneValue = tonumber(string.sub(oneStr, 1, oneLen-1))
    local twoValue = tonumber(string.sub(twoStr, 1, twoLen-1))
    local threeValue = tonumber(string.sub(threeStr, 1, threeLen-1))
    if bMode == 0 then
        twoValue = 0
        threeValue = 0
    end
    
    local isKick = false
    if self.Image_kick:getChildByName('Image_light'):isVisible() then
        isKick = true
    end

    local isImport = false
    if self.Image_import:getChildByName('Image_light'):isVisible() then
        isImport = true
    end

    local isLeave = false
    if self.Image_leave:getChildByName('Image_light'):isVisible() then
        isLeave = true
    end

    local jtValue = tonumber(self.Text_jtValue:getString())

    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_PARTNER, "dbbbboood", 
        self.clubData.dwClubID, bMode, oneValue, twoValue, threeValue, isKick, isImport, isLeave, jtValue)
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
--初始化UI
function NewClubMemberLayer:initUI(param)
    self.Image_memItem:setVisible(false)
    self.Image_checkItem:setVisible(false)
    self.Image_inputItem:setVisible(false)
    self.Image_check:setVisible(false)
    self.Image_input:setVisible(false)
    self.Image_fatigue:setVisible(true)
    self.Image_partnerFrame:setVisible(false)

    local data = param[1]
    if type(data) ~= 'table' then
        printError('enter NewClubMemberLayer data error')
        return
    end
    self.clubData = data
    Log.d(self.clubData)

    --职位
    self.userOffice = param[3]
    printInfo('职位:%d', self.userOffice)

    --用户疲劳值
    self.userFatigueValue = param[4]
    printInfo('用户疲劳值:%0.2f', self.userFatigueValue)

    --时间段初始化、合伙人
    self:updateInputStr()
    self.Image_left:setSwallowTouches(false)
    self.Image_right:setSwallowTouches(false)
    self.Image_topFindMem:setVisible(false)

    if data.dwUserID == UserData.User.userID then
        self.TextField_parnterID:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        local function textFieldEvent(sender, eventType)
            if eventType == ccui.TextFiledEventType.attach_with_ime then
            elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            elseif eventType == ccui.TextFiledEventType.insert_text then
            elseif eventType == ccui.TextFiledEventType.delete_backward then
                self.ListView_addParnter:setVisible(true)
                self.ListView_findAddParnter:setVisible(false)
            end
        end
        self.TextField_parnterID:addEventListener(textFieldEvent)
    end

    self.TextField_winsorce:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self.TextField_partnermem:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
        elseif eventType == ccui.TextFiledEventType.insert_text then
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            self.ListView_pushParnter:setVisible(true)
            self.ListView_findMyParnter:setVisible(false)
        end
    end
    self.TextField_partnermem:addEventListener(textFieldEvent)
    
    --只有群主和管理员有相关权限
    if data.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        self.Image_check:setVisible(true)
        self.Image_input:setVisible(true)
        self.Image_fatigue:setVisible(true)
        self:initNumberArea()

        --导入成员
        self.inputMemberState = 0 --0 请求中 1-请求结束 2--全部请求结束
        self.curInputMemberIndex = 0
        self:reqInputMember()
        self.ListView_input:addScrollViewEventListener(handler(self, self.listViewInputMember)) 
    end

    if param[2] then
        self:switchPage(2)
    else
        self:switchPage()
    end
    
    --分页请求
    self.ListView_mem:addScrollViewEventListener(handler(self, self.listViewClubEventListen))
    self.ListView_new:addScrollViewEventListener(handler(self, self.listViewNewEventListen))
    self.ListView_newPush:addScrollViewEventListener(handler(self, self.listViewPushNewEventListen))

    self.ListView_myPlayer:addScrollViewEventListener(handler(self, self.listViewMyPlayerEventListen))
    self.ListView_addParnter:addScrollViewEventListener(handler(self, self.listViewNotParnterMemberEventListen))
    self.ListView_myParnter:addScrollViewEventListener(handler(self, self.listViewParnterEventListen))
    self.ListView_pushParnter:addScrollViewEventListener(handler(self, self.listViewParnterMemberEventListen))
    self.ListView_sy:addScrollViewEventListener(handler(self, self.listViewEarningsEventListen))
    self.ListView_playerCount:addScrollViewEventListener(handler(self, self.listViewPlayerCountEventListen))
    self.ListView_pushPlayerCount:addScrollViewEventListener(handler(self, self.listViewPlayerDetailsCountEventListen))
    self.ListView_count_partner:addScrollViewEventListener(handler(self, self.listViewPartnerCountEventListen))
    self.ListView_pushCount:addScrollViewEventListener(handler(self, self.listViewPartnerCountDetailsEventListen))

    self.ListView_mem:setBounceEnabled(false)
    self.ListView_myPlayer:setBounceEnabled(false)
    self.ListView_new:setBounceEnabled(false)

    if self.clubData.dwUserID ~= UserData.User.userID then
        self.Button_changemem:setVisible(false)
        -- Common:addTouchEventListener(self.Button_changemem,function()
        --     local node = require("app.MyApp"):create(self.clubData):createView("NewClubParnterAddMemLayer")
        --     self:addChild(node)
        -- end)
    end

    if self:isHasAdmin() then
        self.Text_memNums:setString(self.clubData.dwClubPlayerCount)
        self.Text_newPeoples:setString(self.clubData.dwClubPlayerCount)
        self.Button_memFind:setColor(cc.c3b(255, 255, 255))
        self.Button_memFind:setTouchEnabled(true)
        self.Button_newFind:setColor(cc.c3b(255, 255, 255))
        self.Button_newFind:setTouchEnabled(true)
        self.Text_importFlag:setString('添加亲友圈')
    else
        local allCount = self.clubData.dwClubPlayerCount
        if allCount > 99 then
            allCount = '99+'
        end
        self.Text_memNums:setString(allCount)
        self.Text_newPeoples:setString(allCount)
        self.Button_memFind:setColor(cc.c3b(170, 170, 170))
        self.Button_memFind:setTouchEnabled(false)
        self.Button_newFind:setColor(cc.c3b(170, 170, 170))
        self.Button_newFind:setTouchEnabled(false)
        self.Text_importFlag:setString('添加成员')
    end
    if self.userOffice == 3 then
        self.Button_memFind:setColor(cc.c3b(255, 255, 255))
        self.Button_memFind:setTouchEnabled(true)
        self.Button_newFind:setColor(cc.c3b(255, 255, 255))
        self.Button_newFind:setTouchEnabled(true)
        self.Image_fatigue:setVisible(true)
    end
    if not self.clubData.bIsPartnerImportMember and self.userOffice == 3 then
        self.Button_importPlayer:setVisible(false)
    end

    --合伙人配置设置
    if self.clubData.bDistributionModel ~= 1 and not self:isHasAdmin() then
        self.Image_myParnter:setVisible(false)
        self.Image_countParnter:setVisible(false)
        self.Image_addParnter:setVisible(false)
    end
end

function NewClubMemberLayer:listViewInputMember(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        print('---------->>>>input',self.curInputMemberIndex)
        if self.inputMemberState == 1 then
            self.inputMemberState = 0
            self:reqInputMember()
        end
	end
end

--请求成员
function NewClubMemberLayer:reqClubMember( ... )
    local startPos = self.curClubIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    UserData.Guild:getClubMember(self.clubData.dwClubID,startPos,endPos)
end

--导入成员
function NewClubMemberLayer:reqInputMember( ... )
    local startPos = self.curInputMemberIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    print('-------->>start',startPos,endPos)
    UserData.Guild:getClubExMember(self.clubData.dwClubID, UserData.User.userID,startPos,endPos)
end

--请求亲友圈合伙人
function NewClubMemberLayer:reqClubPartner(dwPartnerID)
    local dwMinWinnerScore = tonumber(self.TextField_winsorce:getString()) or 0
    UserData.Statistics:req_statisticsManager(self.clubData.dwClubID, self.beganTime, self.endTime, dwMinWinnerScore)
    printInfo(os.date("%y/%m/%d/%H/%M/%S",self.beganTime))
    printInfo(os.date("%y/%m/%d/%H/%M/%S",self.endTime))
    dwPartnerID = dwPartnerID or 0
    UserData.Guild:getClubPartner(self.clubData.dwClubID, dwPartnerID, self.beganTime, self.endTime, self.curPartnerIdx, dwMinWinnerScore)
    print('reqClubPartner::',self.clubData.dwClubID, dwPartnerID, self.beganTime, self.endTime, self.curPartnerIdx, dwMinWinnerScore)
end

--请求亲友圈合伙人成员
function NewClubMemberLayer:reqClubPartnerMember()
    local dwMinWinnerScore = tonumber(self.TextField_winsorce:getString()) or 0
    UserData.Guild:getClubPartnerMember(self.clubData.dwClubID, self.pCurID,0, self.beganTime, self.endTime, self.pCurPage, dwMinWinnerScore)
    print('reqClubPartnerMember::',self.clubData.dwClubID, self.pCurID,0, self.beganTime, self.endTime, self.pCurPage, dwMinWinnerScore)
end

--请求亲友圈非合伙人成员
function NewClubMemberLayer:reqNotPartnerMember()
    UserData.Guild:getClubNotPartnerMember(2, self.notPartnerMemIdx, self.clubData.dwClubID)
end

-----------------------------------
--切换UI
function NewClubMemberLayer:switchPage(idx)
    idx = idx or 1
    self.curSelPage = idx
    if idx == 1 then
        self.Panel_mem:setVisible(true)
        self.Panel_check:setVisible(false)
        self.Panel_input:setVisible(false)
        self.Panel_newEx:setVisible(false)
        self.Image_mem:getChildren()[1]:setVisible(true)
        self.Image_check:getChildren()[1]:setVisible(false)
        self.Image_input:getChildren()[1]:setVisible(false)
        self.Image_fatigue:getChildren()[1]:setVisible(false)
        self.ListView_mem:removeAllItems()
        self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
        self.curClubIndex = 0

        if self:isHasAdmin() then
            self:reqClubMember()
        else
            if self.userOffice == 2 then
                --普通成员
                UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
            else
                --合伙人
                self.notPartnerMemState = 0
                self.notPartnerMemIdx = 1
                self:reqNotPartnerMember()
            end
        end
        
    elseif idx == 2 then
        self.Panel_mem:setVisible(false)
        self.Panel_check:setVisible(true)
        self.Panel_input:setVisible(false)
        self.Panel_newEx:setVisible(false)
        self.Image_mem:getChildren()[1]:setVisible(false)
        self.Image_check:getChildren()[1]:setVisible(true)
        self.Image_input:getChildren()[1]:setVisible(false)
        self.Image_fatigue:getChildren()[1]:setVisible(false)
        self.ListView_check:removeAllItems()
        UserData.Guild:getClubCheckList(self.clubData.dwClubID)
        UserData.Guild:sendClubGroupInviteLog(UserData.User.userID, self.clubData.dwClubID)

    elseif idx == 3 then
        self.Panel_mem:setVisible(false)
        self.Panel_check:setVisible(false)
        self.Panel_input:setVisible(true)
        self.Panel_newEx:setVisible(false)
        self.Image_mem:getChildren()[1]:setVisible(false)
        self.Image_check:getChildren()[1]:setVisible(false)
        self.Image_input:getChildren()[1]:setVisible(true)
        self.Image_fatigue:getChildren()[1]:setVisible(false)

    elseif idx == 4 then
        self.Panel_mem:setVisible(false)
        self.Panel_check:setVisible(false)
        self.Panel_input:setVisible(false)
        self.Panel_newEx:setVisible(true)
        self.Image_mem:getChildren()[1]:setVisible(false)
        self.Image_check:getChildren()[1]:setVisible(false)
        self.Image_input:getChildren()[1]:setVisible(false)
        self.Image_fatigue:getChildren()[1]:setVisible(true)
        self.ListView_new:removeAllItems()

        self.notPartnerMemState = 0
        self.notPartnerMemIdx = 1
        if self:isHasAdmin() then
            UserData.Guild:getClubNotPartnerMember(0, self.notPartnerMemIdx, self.clubData.dwClubID, self.clubData.dwUserID)
        else
            if self.userOffice == 2 then
                --普通成员
                UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
            else
                --合伙人
                UserData.Guild:getClubNotPartnerMember(0, self.notPartnerMemIdx, self.clubData.dwClubID)
            end
        end
        
        -- self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
        -- self.curClubIndex = 0
        
        -- if self:isHasAdmin() then
        --     self:reqClubMember()
        -- else
        --     if self.userOffice == 2 then
        --         --普通成员
        --         UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
        --     else
        --         --合伙人
        --         self.notPartnerMemState = 0
        --         self.notPartnerMemIdx = 1
        --         self:reqNotPartnerMember()
        --     end
        -- end
    end
end

--idx 1我的玩家 2玩家统计 3盟主收益/合伙人收益 4我的合伙人 5合伙人统计 6添加合伙人 7合伙人设置
function NewClubMemberLayer:switchParnterPage(idx)
    self.curPartnerPage = idx
    self.Image_myMemLight:setVisible(false)
    self.Image_countPlayerLight:setVisible(false)
    self.Image_addParnterLight:setVisible(false)
    self.Image_myParnterLight:setVisible(false)
    self.Image_countParnterLight:setVisible(false)
    self.Image_partnetSetLight:setVisible(false)
    self.Image_leaderLight:setVisible(false)

    self.Panel_myPlayer:setVisible(false)
    self.Panel_playerCount:setVisible(false)
    self.Panel_addParnter:setVisible(false)
    self.Panel_myParnter:setVisible(false)
    self.Panel_parnterCount:setVisible(false)
    self.Panel_partnetSet:setVisible(false)
    self.Panel_leaderGet:setVisible(false)

    self.Image_allCount:setVisible(true)
    self.Text_timeNode:setVisible(false)
    self.Text_dawinSorce:setVisible(false)
    self.Image_topPartnerMem:setVisible(false)
    self.Image_topFindMem:setVisible(false)
    self.Button_changemem:setVisible(false)
    self.Panel_partnerCount:setVisible(false)
    self.Text_plztop:setVisible(false)

    if idx == 1 then
        self.Image_myMemLight:setVisible(true)
        self.Panel_myPlayer:setVisible(true)
        self.Text_timeNode:setVisible(true)
        self.Image_topPartnerMem:setVisible(true)
        self.Text_plztop:setVisible(true)
    elseif idx == 2 then
        self.Image_countPlayerLight:setVisible(true)
        self.Panel_playerCount:setVisible(true)
        self.Text_timeNode:setVisible(true)
        self.Image_playerCountFrame:setVisible(true)
        self.Image_playerCountPushFrame:setVisible(false)
    elseif idx == 3 then
        self.Image_leaderLight:setVisible(true)
        self.Panel_leaderGet:setVisible(true)
        self.Text_timeNode:setVisible(true)
        if self.clubData.dwUserID == UserData.User.userID then
            --群主
            local Text_2 = self.Image_leaderFrame:getChildByName('Text_2')
            local Text_3 = self.Image_leaderFrame:getChildByName('Text_3')
            local Text_4 = self.Image_leaderFrame:getChildByName('Text_4')
            local Text_5 = self.Image_leaderFrame:getChildByName('Text_5')
            Text_2:setString('亲友圈总\n人次')
            Text_3:setString('亲友圈总\n房卡费用')
            Text_4:setString('疲劳值总收益/合伙人\n总分成/盟主收益')
            Text_5:setString('元宝总收益/合伙人总\n分成/盟主收益')
        end

    elseif idx == 4 then
        self.Image_myParnterLight:setVisible(true)
        self.Panel_myParnter:setVisible(true)
        self.Text_timeNode:setVisible(true)
        self.Text_dawinSorce:setVisible(true)
    elseif idx == 5 then
        self.Image_countParnterLight:setVisible(true)
        self.Panel_parnterCount:setVisible(true)
        self.Text_timeNode:setVisible(true)
        self.Image_countFrame:setVisible(true)
        self.Image_countPushFrame:setVisible(false)
    elseif idx == 6 then
        self.Image_addParnterLight:setVisible(true)
        self.Panel_addParnter:setVisible(true)
        self.Image_topFindMem:setVisible(true)
        self.ListView_addParnter:removeAllItems()
        self.notPartnerMemState = 0
        self.notPartnerMemIdx = 1
        self:reqNotPartnerMember()
    else
        self.Image_partnetSetLight:setVisible(true)
        self.Panel_partnetSet:setVisible(true)
        UserData.Guild:getPartnerConfig(UserData.User.userID, self.clubData.dwClubID)
    end
end

--是否是管理员
function NewClubMemberLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

--移除管理员信息
function NewClubMemberLayer:removeAdminInfo(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            self.clubData.dwAdministratorID[i] = 0
            break
        end
    end
end

--刷新疲劳值
function NewClubMemberLayer:refreshNewList(data, listView)
    if type(data) ~= 'table' then
        printError('NewClubMemberLayer:refreshNewList data error')
        return
    end

    listView = listView or self.ListView_new

    local item = self.Image_newItem:clone()
    item:setVisible(true)
    if data.dwUserID == UserData.User.userID then
        listView:insertCustomItem(item, 0)
    else
        listView:pushBackCustomItem(item)
    end
    listView:refreshView()
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_desTitle = self:seekWidgetByNameEx(item, "Text_desTitle")
    local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
    local Button_modify_add = self:seekWidgetByNameEx(item, "Button_modify_add")
    local Button_modify_sub = self:seekWidgetByNameEx(item, "Button_modify_sub")
    local Button_newPush = self:seekWidgetByNameEx(item, "Button_newPush")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    TextField_des:setColor(cc.c3b(165, 61, 9))
    Text_desTitle:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)

    --if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) or self.userOffice == 3 then
        Text_playerid:setString('ID：' .. data.dwUserID)
        --Text_playerid:setVisible(true)
    --else
        --Text_playerid:setVisible(false)
    --end

    local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
    if data.cbOffice == 0 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m22.png')
    elseif data.cbOffice == 1 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m21.png')
    elseif data.cbOffice == 3 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m23.png')
    else
        Image_memFlag:setVisible(false)
    end

    item:setName('fatigue_' .. data.dwUserID)
    Text_desTitle:setString('疲劳值:')
    TextField_des:setString(data.lFatigueValue)
    TextField_des:setTouchEnabled(false)

    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) or self.userOffice == 3 then
        local userInfo = {
            name = data.szNickName,
            userID = data.dwUserID,
            fatigue = data.lFatigueValue
        }

        local setType = 8
        if self.userOffice == 3 then
            setType = 7
        end

        Common:addTouchEventListener(Button_modify_add,function()
            userInfo.fatigue = tonumber(TextField_des:getString()) or userInfo.fatigue
            local node = require("app.MyApp"):create(userInfo, 1, function(value) 
                

                UserData.Guild:reqSettingsClubMember(setType, data.dwClubID, data.dwUserID,0,"",value)
            end):createView("NewClubInputFatigueLayer")
            self:addChild(node)
        end)

        Common:addTouchEventListener(Button_modify_sub,function()
            local lastFatigue = tonumber(TextField_des:getString()) or 0
            userInfo.fatigue = tonumber(TextField_des:getString()) or userInfo.fatigue
            local node = require("app.MyApp"):create(userInfo, 2, function(value) 
                if lastFatigue < value then
                    require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值错误!")
                else
                    UserData.Guild:reqSettingsClubMember(setType, data.dwClubID, data.dwUserID,0,"",-value)
                end
            end):createView("NewClubInputFatigueLayer")
            self:addChild(node)
        end)
    else
        Button_modify_add:setVisible(false)
        Button_modify_sub:setVisible(false)
    end

    if data.dwUserID == UserData.User.userID and self.userOffice == 3 then
        Button_modify_add:setVisible(false)
        Button_modify_sub:setVisible(false)
    end

    Common:addTouchEventListener(Button_newPush,function() 
        self.ListView_new:setVisible(false)
        self.ListView_newPush:setVisible(true)
        self.ListView_newFind:setVisible(false)
        self.Image_newFindFrame:setVisible(false)
        self.Button_newFind:setVisible(false)
        self.Button_newReturn:setVisible(false)
        self:loadFatiguePage(item, data)
    end)
    
end

--加载疲劳值下拉页
function NewClubMemberLayer:loadFatiguePage(item, data)
    self.ListView_newPush:removeAllItems()
    local item = item:clone()
    self.ListView_newPush:pushBackCustomItem(item)
    local Button_modify_add = self:seekWidgetByNameEx(item, "Button_modify_add")
    local Button_modify_sub = self:seekWidgetByNameEx(item, "Button_modify_sub")
    local Button_newPush = self:seekWidgetByNameEx(item, "Button_newPush")
    Button_modify_add:setVisible(false)
    Button_modify_sub:setVisible(false)
    local path = 'kwxclub/partner_5.png'
    Button_newPush:loadTextures(path, path, path)
    Common:addTouchEventListener(Button_newPush,function() 
        self.ListView_new:setVisible(true)
        self.ListView_newPush:setVisible(false)
        self.ListView_newFind:setVisible(false)
        self.Image_newFindFrame:setVisible(true)
        self.Button_newFind:setVisible(true)
        self.Button_newReturn:setVisible(false)
    end)

    --请求疲劳值记录
    self.curNewPushID = data.dwUserID
    UserData.Guild:getClubFatigueRecord(data.dwClubID,data.dwUserID,1)
end

--刷新成员列表
function NewClubMemberLayer:refreshMemList(data)
    if type(data) ~= 'table' then
        printError('NewClubMemberLayer:refreshMemList data error')
        return
    end

    local item = self.Image_memItem:clone()
    item:setVisible(true)
    self.ListView_mem:pushBackCustomItem(item)
    self.ListView_mem:refreshView()
    item:setName('member_' .. data.dwUserID)
    self:setMemberBaseInfo(item, data)
    self:setMemberMgrFlag(item, data)
    self:setMemberMgrControl(item, data)
end

--设置成员基本信息
function NewClubMemberLayer:setMemberBaseInfo(item, data)
    if not (item and data) then
        return
    end
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_notedes = self:seekWidgetByNameEx(item, "Text_notedes")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_partner = self:seekWidgetByNameEx(item, "Text_partner")
    local Text_joinTime = self:seekWidgetByNameEx(item, "Text_joinTime")
    local Text_lastTime = self:seekWidgetByNameEx(item, "Text_lastTime")
    local Text_stopPlayer = self:seekWidgetByNameEx(item, "Text_stopPlayer")
    Text_stopPlayer:setColor(cc.c3b(255, 0, 0))
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_notedes:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_partner:setColor(cc.c3b(165, 61, 9))
    Text_joinTime:setColor(cc.c3b(165, 61, 9))
    Text_lastTime:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID：' .. data.dwUserID)

    if data.szRemarks == "" or data.szRemarks == " " then
        Text_notedes:setString('备注：暂无')
    else
        Text_notedes:setString('备注：' .. data.szRemarks)
    end

    if data.dwPartnerID ~= 0 then
        Text_partner:setVisible(true)
        Text_partner:setString(string.format('合伙人:%s(%d)', data.szPartnerNickName, data.dwPartnerID))
    else
        Text_partner:setVisible(false)
    end

    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_lastTime:setString(lastTimeStr)

    if data.isProhibit then
        Text_stopPlayer:setVisible(true)
    else
        Text_stopPlayer:setVisible(false)
    end
end

--设置成员不同权限标识
function NewClubMemberLayer:setMemberMgrFlag(item, data)
    if not (item and data) then
        return
    end
    local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
    if data.cbOffice == 0 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m22.png')
    elseif data.cbOffice == 1 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m21.png')
    elseif data.cbOffice == 3 then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m23.png')
    else
        Image_memFlag:setVisible(false)
    end

    local Image_memState = self:seekWidgetByNameEx(item, "Image_memState")
    if data.cbOnlineStatus == 1 then
        Image_memState:loadTexture('kwxclub/qyq_44.png')
    elseif data.cbOnlineStatus == 2 or data.cbOnlineStatus == 0 then
        Image_memState:loadTexture('kwxclub/qyq_45.png')
    elseif data.cbOnlineStatus == 100 then
        Image_memState:loadTexture('kwxclub/qyq_46.png')
    else
        Image_memState:setVisible(false)
    end
end

--设置成员不同权限操作
function NewClubMemberLayer:setMemberMgrControl(item, data)
    local Button_memCotrol = self:seekWidgetByNameEx(item, "Button_memCotrol")
    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) or
        (self.clubData.bIsPartnerRemoveMember and self.userOffice == 3) then
        local callback = function()
            local node = require("app.MyApp"):create(data, self.clubData, self.userOffice):createView("NewClubMemberInfoLayer")
            self:addChild(node)
        end
        Common:addTouchEventListener(Button_memCotrol,callback)
        Button_memCotrol:setVisible(true)
    else
        Button_memCotrol:setVisible(false)
    end
end

--刷新审核列表
function NewClubMemberLayer:refreshCheckList(data)
    if type(data) ~= 'table' then
        return
    end

    local item = self.Image_checkItem:clone()
    item:setVisible(true)
    self.ListView_check:pushBackCustomItem(item)
    item:setName('check_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_tille = self:seekWidgetByNameEx(item, "Text_tille")
    local Text_applytime = self:seekWidgetByNameEx(item, "Text_applytime")
    local Button_yes = self:seekWidgetByNameEx(item, "Button_yes")
    local Button_no = self:seekWidgetByNameEx(item, "Button_no")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_applytime:setColor(cc.c3b(165, 61, 9))
    Text_tille:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_applytime:setString(joinTimeStr)

    if self.clubData.dwUserID ~= UserData.User.userID and not self:isAdmin(UserData.User.userID) then
        Button_yes:setVisible(false)
        Button_no:setVisible(false)
    else
        Button_yes:setVisible(true)
        Button_no:setVisible(true)
        Button_yes:setPressedActionEnabled(true)
        Button_yes:addClickEventListener(function(sender)
            UserData.Guild:checkClubResult(data.dwClubID,data.dwUserID,true)
        end)

        Button_no:setPressedActionEnabled(true)
        Button_no:addClickEventListener(function(sender)
            UserData.Guild:checkClubResult(data.dwClubID,data.dwUserID,false)
        end)
    end
end

--刷新导入列表
function NewClubMemberLayer:refreshInputList(data)
    if type(data) ~= 'table' then
        return
    end

    local item = self.Image_inputItem:clone()
    item:setVisible(true)
    self.ListView_input:pushBackCustomItem(item)
    self.ListView_input:refreshView()
    item:setName('input_' .. data.dwUserID)
    local Image_head     = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name      = self:seekWidgetByNameEx(item, "Text_name")
    local Text_clubID    = self:seekWidgetByNameEx(item, "Text_clubID")
    local Button_input   = self:seekWidgetByNameEx(item, "Button_input")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_clubID:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_clubID:setString('ID:' .. data.dwUserID)

    Button_input:setPressedActionEnabled(true)
    Button_input:addClickEventListener(function(sender)
        UserData.Guild:addClubMember(self.clubData.dwClubID, data.dwUserID, UserData.User.userID)
    end)
end

--添加一个查找玩家
function NewClubMemberLayer:addOnceFindMem(data)
    if type(data) ~= 'table' then
        printError('NewClubMemberLayer:addOnceFindMem data error')
        return
    end
    self.ListView_find:removeAllChildren()
    local item = self.Image_memItem:clone()
    item:setVisible(true)
    self.ListView_find:pushBackCustomItem(item)
    self.ListView_find:refreshView()
    self:setMemberBaseInfo(item, data)
    self:setMemberMgrFlag(item, data)
    self:setMemberMgrControl(item, data)
end

function NewClubMemberLayer:dateChange(stamp,dayChange)
    local year,month,day = Common:getYMDHMS(stamp)
    local time=os.time({year=year, month=month, day=day})+dayChange*86400 --一天86400秒
    return time
end

function NewClubMemberLayer:updateInputStr()
    local leftTime = self:getFrmatYear(self.beganTime)
    local rightTime = self:getFrmatYear(self.endTime)
    self.Text_day_left:setString(leftTime)
    self.Text_day_right:setString(rightTime)    
end

function NewClubMemberLayer:getFrmatYear( time )
    return  (os.date('%Y',time).."-" .. os.date('%m',time).."-"..os.date('%d',time))
end


------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
--退出亲友圈返回
function NewClubMemberLayer:RET_QUIT_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈成功!")
    -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubLayer"))
    require("common.SceneMgr"):switchOperation()
    cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
end

--返回亲友圈成员列表
function NewClubMemberLayer:RET_GET_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if self.Panel_mem:isVisible() then
        self:refreshMemList(data)
    elseif self.Panel_newEx:isVisible() then
        self:refreshNewList(data)
    end
end

--返回剔除成员
function NewClubMemberLayer:RET_REMOVE_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,self,"踢出失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"踢出成功!")
    self:removeAdminInfo(data.dwUserID)
    local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
    if item then
        local index = self.ListView_mem:getIndex(item)
        self.ListView_mem:removeItem(index)
        self.ListView_mem:refreshView()
        local count = self.ListView_mem:getChildrenCount()
        if count == 1 or count == 0 then
            if self.memberReqState == 1 then
                self.memberReqState = 0
                self:reqClubMember()
            end
        end
    end
    -- self:resetMemInputArea()
end

--返回亲友圈审核列表
function NewClubMemberLayer:RET_CLUB_CHECK_LIST(event)
    local data = event._usedata
    Log.d(data)
    self:refreshCheckList(data)
end

function NewClubMemberLayer:RET_CLUB_GROUP_INVITE_LOG(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet ~= 0 or data.dwClubID == 0 then
        return
    end

    local item = self.Image_checkItem:clone()
    item:setVisible(true)
    self.ListView_check:pushBackCustomItem(item)
    item:setName('inviteLog_' .. data.dwClubID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_tille = self:seekWidgetByNameEx(item, "Text_tille")
    local Text_applytime = self:seekWidgetByNameEx(item, "Text_applytime")
    local Button_yes = self:seekWidgetByNameEx(item, "Button_yes")
    local Button_no = self:seekWidgetByNameEx(item, "Button_no")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_applytime:setColor(cc.c3b(165, 61, 9))
    Text_tille:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szClubLogoInfo, Image_head, "img")
    Text_name:setString(data.szClubName)
    Text_playerid:setString('圈ID:' .. data.dwClubID)
    local time = os.date("*t", data.dwCreateData)
    local sendTimeStr = string.format("%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_applytime:setString(sendTimeStr)
    Text_tille:setString('向您发起亲友圈合并')

    if self.clubData.dwUserID ~= UserData.User.userID and not self:isAdmin(UserData.User.userID) then
        Button_yes:setVisible(false)
        Button_no:setVisible(false)
    else
        Button_yes:setVisible(true)
        Button_no:setVisible(true)
        Button_yes:setPressedActionEnabled(true)
        Button_yes:addClickEventListener(function(sender)
            local des = string.format("您确定与(%s:%d)亲友圈合并,所有玩家将为(%s)成员,您将成为(%s)亲友圈的合伙人?", data.szClubName, data.dwTargetClubID, data.szClubName, data.szClubName)
            require("common.MsgBoxLayer"):create(1,nil,des,function() 
                UserData.Guild:sendClubGroupInviteReply(UserData.User.userID, self.clubData.dwClubID, data.dwClubID, true)
            end)
        end)

        Button_no:setPressedActionEnabled(true)
        Button_no:addClickEventListener(function(sender)
            require("common.MsgBoxLayer"):create(1,nil,"您确定要拒绝亲友圈合并？",function() 
                UserData.Guild:sendClubGroupInviteReply(UserData.User.userID, self.clubData.dwClubID, data.dwClubID, false)
            end)
        end)
    end
end

function NewClubMemberLayer:RET_CLUB_GROUP_INVITE_REPLY(event)
    local data = event._usedata
    Log.d(data)
    local item = self.ListView_check:getChildByName('inviteLog_' .. data.dwTargetClubID)
    if item then
        item:removeFromParent()
    end

    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"亲友圈不存在!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,self,"目标亲友圈不存在!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,self,"权限不足!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,self,"没有被邀请过!")
        elseif data.lRet == 5 then
            local des = string.format("两边都有同一合伙人(%s:%d),请先移除合伙人关系!", data.szNickName, data.dwSamePartnerID)
            require("common.MsgBoxLayer"):create(1,nil,des,function()
            end)
        else
            require("common.MsgBoxLayer"):create(0,self,"合群失败!")
        end
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"操作成功！")
end

--审核同意或拒绝返回
function NewClubMemberLayer:RET_CLUB_CHECK_RESULT(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请求失败!")
        end
        return
    end
    if data.isAgree == true then
        require("common.MsgBoxLayer"):create(0,self,"操作成功,请到成员列表查看!")
    else
        require("common.MsgBoxLayer"):create(0,self,"操作成功!")
    end

    local item = self.ListView_check:getChildByName('check_' .. data.dwUserID)
    if item then
        local index = self.ListView_check:getIndex(item)
        self.ListView_check:removeItem(index)
        self.ListView_check:refreshView()
    end
end

--设置、取消管理员返回
function NewClubMemberLayer:RET_SETTINGS_CLUB(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"权限不足!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"非合伙人和非合伙人成员才能设置为管理员!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"管理员人数已达上限!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误!")
        end
        return
    end

    if data.cbSettingsType == 0 then
        --设置管理员
        local item = self.ListView_mem:getChildByName('member_' .. data.dwTargetID)
        if item then
            local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
            Image_memFlag:setVisible(true)
            self.clubData.dwAdministratorID = data.dwAdministratorID
        end
    elseif data.cbSettingsType == 1 then
        --取消管理员
        local item = self.ListView_mem:getChildByName('member_' .. data.dwTargetID)
        if item then
            local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
            Image_memFlag:setVisible(false)
            self.clubData.dwAdministratorID = data.dwAdministratorID
        end
    end
end

--返回亲友圈以外可以导入的成员
function NewClubMemberLayer:RET_GET_CLUB_MEMBER_EX(event)
    local data = event._usedata
    Log.d(data)
    self:refreshInputList(data)
end

--返回添加亲友圈成员
function NewClubMemberLayer:RET_ADD_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"ID输入错误!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,self,"该成员已在亲友圈内，请勿重复操作!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,self,"玩家ID不合法!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,self,"您没有权限导入！")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请升级游戏版本!")
        end
        return
    end

    require("common.MsgBoxLayer"):create(0,self,"导入成功!")
    local item = self.ListView_input:getChildByName('input_' .. data.dwUserID)
    if item then
        local index = self.ListView_input:getIndex(item)
        self.ListView_input:removeItem(index)
        self.ListView_input:refreshView()
        local count = self.ListView_input:getChildrenCount()
        if count == 0 then
            if self.inputMemberState == 1 then
                self.inputMemberState = 0
                self:reqInputMember()
            end
        end
    end

    --合伙人添加成员
    if self.Image_partnerFrame:isVisible() then
        local event = {}
        event._usedata = data
        self:RET_GET_CLUB_PARTNER_MEMBER(event)
    end
end


--更新亲友圈信息
function NewClubMemberLayer:RET_UPDATE_CLUB_INFO(event)
    local data = event._usedata
    Log.d(data)
    -- self:initUI({data})
end

--亲友群是否返回完成
function NewClubMemberLayer:RET_GET_CLUB_MEMBER_FINISH( event )
    local data = event._usedata
    if data.isFinish then
        self.memberReqState = 2
    else
        self.memberReqState = 1
    end
    self.curClubIndex = self.curClubIndex + MEMBER_NUM
end

function NewClubMemberLayer:RET_GET_CLUB_MEMBER_EX_FINISH( event )
    local data = event._usedata
    if data.isFinish then
        self.inputMemberState = 2
    else
        self.inputMemberState = 1
    end
    self.curInputMemberIndex = self.curInputMemberIndex + MEMBER_NUM
    print('------------返回dd',self.inputMemberState,self.curInputMemberIndex)
    if self.ListView_input then
        local isShow =  self.ListView_input:getChildrenCount () <= 0
        print('------xxxxxxxxx--',isShow,self.ListView_input:getChildrenCount ())
        self.Image_noInputTips:setVisible(isShow)
    end
end

--返回查找亲友圈结果
function NewClubMemberLayer:RET_FIND_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then 
        require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员ID输入错误!")
        return
    end

    -- if not self:isHasAdmin() then
    --     if self.Panel_mem:isVisible() then
    --         self:refreshMemList(data)
    --     elseif self.Panel_newEx:isVisible() then
    --         self:refreshNewList(data)
    --     end
    --     return
    -- end

    if self.curSelPage == 1 then
        self.ListView_mem:setVisible(false)
        self.ListView_find:setVisible(true)
        self.Image_findFrame:setVisible(false)
        self.Button_memFind:setVisible(false)
        self.Button_memReturn:setVisible(true)
        self:addOnceFindMem(data)
    elseif self.curSelPage == 4 then
        self.ListView_new:setVisible(false)
        self.ListView_newPush:setVisible(false)
        self.ListView_newFind:setVisible(true)
        self.Image_newFindFrame:setVisible(false)
        self.Button_newFind:setVisible(false)
        self.Button_newReturn:setVisible(true)
        self.ListView_newFind:removeAllItems()
        self:refreshNewList(data, self.ListView_newFind)
    end
end

--返回修改亲友圈成员
function NewClubMemberLayer:RET_SETTINGS_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈不存在!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员不存在!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"亲有圈合伙人已达人数上限!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"普通成员才可以设置为合伙人!")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,nil,"您的权限不足!")
        elseif data.lRet == 100 then
            require("common.MsgBoxLayer"):create(0,nil,"对局中不能修改疲劳值")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误!")
        end
        return
    end

    if data.cbSettingsType == 0 then
        --禁赛
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_stopPlayer = self:seekWidgetByNameEx(item, "Text_stopPlayer")
            Text_stopPlayer:setVisible(true)
        end
    elseif data.cbSettingsType == 1 then
        --恢复
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_stopPlayer = self:seekWidgetByNameEx(item, "Text_stopPlayer")
            Text_stopPlayer:setVisible(false)
        end
    elseif data.cbSettingsType == 2 then
        --修改备注
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_notedes = self:seekWidgetByNameEx(item, "Text_notedes")
            if data.szRemarks == "" or data.szRemarks == " " then
                Text_notedes:setString('备注：暂无')
            else
                Text_notedes:setString('备注：' .. data.szRemarks)
            end
            self:setMemberMgrControl(item, data)
            require("common.MsgBoxLayer"):create(0,nil,"修改备注成功")
        end
    elseif data.cbSettingsType == 3 then
        --设置合伙人
        local item = self.ListView_addParnter:getChildByName('addpartner' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"添加合伙人成功!")
        end
    elseif data.cbSettingsType == 4 then
        --取消合伙人
        local item = self.ListView_myParnter:getChildByName('myparnter' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"取消合伙人成功!")
        end

        --解绑
        local item = self.ListView_pushParnter:getChildByName('pushParnter' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"解绑成员成功!")
            local dwPartnerID = data.dwPartnerID
            if dwPartnerID <= 0 then
                dwPartnerID = self.pCurID
            end
            self:refreshParnterItemPeoples(dwPartnerID, -1)
        end
    elseif data.cbSettingsType == 5 then
        --调配成员
        local event = {}
        event._usedata = data
        self:RET_GET_CLUB_PARTNER_MEMBER(event)
        self:refreshParnterItemPeoples(data.dwPartnerID, 1)

    elseif data.cbSettingsType == 6 or data.cbSettingsType == 8 then
        --疲劳值
        local item = self.ListView_new:getChildByName('fatigue_' .. data.dwUserID)
        if item then
            local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
            TextField_des:setString(data.lFatigueValue)
            require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值成功")
        end

        if data.dwUserID == UserData.User.userID then
            self.userFatigueValue = data.lFatigueValue
        end

    elseif data.cbSettingsType == 7 then
        --合伙人卖疲劳值
        local item = self.ListView_myPlayer:getChildByName('PlzParnterMember' .. data.dwUserID)
        if item then
            local TextField_plz = self:seekWidgetByNameEx(item, "TextField_plz")
            TextField_plz:setString(data.lFatigueValue)
        end

        local item = self.ListView_findMyPlayer:getChildren()[1]
        if item then
            local TextField_plz = self:seekWidgetByNameEx(item, "TextField_plz")
            if TextField_plz then
                TextField_plz:setString(data.lFatigueValue)
            end
        end

        local item = self.ListView_new:getChildByName('fatigue_' .. data.dwUserID)
        if item then
            local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
            TextField_des:setString(data.lFatigueValue)
        end

        require("common.MsgBoxLayer"):create(0,nil,"交易疲劳值成功")
    end
end

function NewClubMemberLayer:insertOncePartnerMember(data)
    local item = self.Image_myParnterItem:clone()
    if self.curPartnerPage == 1 then
        self.ListView_myPlayer:pushBackCustomItem(item)
    elseif self.curPartnerPage == 4 then
        self.ListView_pushParnter:pushBackCustomItem(item)
    end
    
    item:setName('OnceParnter' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_playerCountFlag = ccui.Helper:seekWidgetByName(item, "Text_playerCountFlag")
    local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
    local Text_yuanBaoFlag = ccui.Helper:seekWidgetByName(item, "Text_yuanBaoFlag")
    local Text_yuanBaoCount = ccui.Helper:seekWidgetByName(item, "Text_yuanBaoCount")
    local Button_cancel = ccui.Helper:seekWidgetByName(item, "Button_cancel")
    local Button_push = ccui.Helper:seekWidgetByName(item, "Button_push")
    Button_cancel:setVisible(false)
    Button_push:setVisible(self.curPartnerPage == 4)
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_playerCountFlag:setColor(cc.c3b(165, 61, 9))
    Text_yuanBaoFlag:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_playerCount:setColor(cc.c3b(165, 61, 9))
    Text_yuanBaoCount:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_dyjnum:setString(data.dwWinnerCount)
    Text_jsnum:setString(data.dwGameCount)
    Text_playerCount:setString(data.dwPlayerCount)
    Text_yuanBaoCount:setString(data.lYuanBaoCount)

    local path = 'kwxclub/partner_5.png'
    Button_push:loadTextures(path, path, path)
    Common:addTouchEventListener(Button_push,function()
        if self.curPartnerPage == 1 then
        elseif self.curPartnerPage == 4 then
            self.Button_changemem:setVisible(false)
            self.Image_topPartnerMem:setVisible(false)
            self.Text_dawinSorce:setVisible(true)
            self.ListView_myParnter:setVisible(true)
            self.ListView_pushParnter:setVisible(false)
        end
    end)
end

--我的合伙人
function NewClubMemberLayer:insertMyPartnerItem(data)
    local item = self.Image_myParnterItem:clone()
    if UserData.User.userID ~= data.dwUserID then
        self.ListView_myParnter:pushBackCustomItem(item)
    else
        self.ListView_myParnter:insertCustomItem(item, 0)
    end
    self.ListView_myParnter:refreshView()

    item:setName('myparnter' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_playerCountFlag = ccui.Helper:seekWidgetByName(item, "Text_playerCountFlag")
    local Text_yuanBaoFlag = ccui.Helper:seekWidgetByName(item, "Text_yuanBaoFlag")
    local Text_yuanBaoCount = ccui.Helper:seekWidgetByName(item, "Text_yuanBaoCount")
    local Button_cancel = ccui.Helper:seekWidgetByName(item, "Button_cancel")
    local Button_push = ccui.Helper:seekWidgetByName(item, "Button_push")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_playerCount:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_playerCountFlag:setColor(cc.c3b(165, 61, 9))
    Text_yuanBaoFlag:setColor(cc.c3b(165, 61, 9))
    Text_yuanBaoCount:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_dyjnum:setString(data.dwWinnerCount)
    Text_jsnum:setString(data.dwGameCount)
    Text_playerCount:setString(data.dwPlayerCount)
    Text_yuanBaoCount:setString(data.lYuanBaoCount)

    Button_cancel:setVisible(UserData.User.userID ~= data.dwUserID)

    Common:addTouchEventListener(Button_cancel,function()
        --解除合伙人
        require("common.MsgBoxLayer"):create(1,nil,"您确定要解除合伙人？",function() 
            UserData.Guild:reqSettingsClubMember(4, data.dwClubID, data.dwUserID,0,"")
        end)
    end)

    Common:addTouchEventListener(Button_push,function()
        --展开名下成员
        self.Text_dawinSorce:setVisible(false)
        self.Image_topPartnerMem:setVisible(true)
        self.Button_changemem:setVisible(self:isHasAdmin())
        self.ListView_myParnter:setVisible(false)
        self.ListView_pushParnter:setVisible(true)
        self.ListView_pushParnter:removeAllItems()
        self.pCurID = data.dwUserID
        self.curPartnerIdx = 1
        self:reqClubPartner(self.pCurID)

        --分配成员
        Common:addTouchEventListener(self.Button_changemem,function()
            local node = require("app.MyApp"):create(data):createView("NewClubAllocationLayer")
            self:addChild(node)
        end)
    end)
end

--返回亲友圈合伙人
function NewClubMemberLayer:RET_GET_CLUB_PARTNER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您还不是合伙人!")
        return
    end

    if self.curPartnerPage == 1 then
        self:insertOncePartnerMember(data)
        self.pCurPage = 1
        self.pReqState = 0
        self:reqClubPartnerMember()
    elseif self.curPartnerPage == 4 then
        if self.ListView_pushParnter:isVisible() then
            --合伙人展开
            self:insertOncePartnerMember(data)
            self.pCurPage = 1
            self.pReqState = 0
            self:reqClubPartnerMember()
        else
            --我的合伙人
            self:insertMyPartnerItem(data)
        end
        
    end
end

function NewClubMemberLayer:RET_GET_CLUB_PARTNER_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.partnerReqState = 2
    else
        self.partnerReqState = 1
    end
    self.curPartnerIdx = self.curPartnerIdx + 1
end

function NewClubMemberLayer:setNotParnterMemberItem(item,data)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_note = ccui.Helper:seekWidgetByName(item, "Text_note")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_joinTime = ccui.Helper:seekWidgetByName(item, "Text_joinTime")
    local Text_lastTime = ccui.Helper:seekWidgetByName(item, "Text_lastTime")
    local Button_memCotrol = ccui.Helper:seekWidgetByName(item, "Button_memCotrol")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_note:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_joinTime:setColor(cc.c3b(165, 61, 9))
    Text_lastTime:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    if data.szRemarks == "" or data.szRemarks == " " then
        Text_note:setString('备注:暂无')
    else
        Text_note:setString('备注:' .. data.szRemarks)
    end
    Text_playerid:setString('ID:' .. data.dwUserID)
    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_lastTime:setString(lastTimeStr)

    Common:addTouchEventListener(Button_memCotrol,function()
        --添加合伙人
        require("common.MsgBoxLayer"):create(1,nil,"您确定要添加合伙人？",function() 
            UserData.Guild:reqSettingsClubMember(3, data.dwClubID, data.dwUserID,0,"")
        end)
    end)
end

function NewClubMemberLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    --屏蔽管理员
    -- if self:isAdmin(data.dwUserID) then
    --     return
    -- end

    if self.Image_partnerFrame:isVisible() and self.curPartnerPage == 6 then
        --添加合伙人
        local item = self.Image_parnterItem:clone()
        self.ListView_addParnter:pushBackCustomItem(item)
        item:setName('addpartner' .. data.dwUserID)
        self:setNotParnterMemberItem(item ,data)
    elseif self.Image_memFrame:isVisible() and self.curSelPage == 1 then
        --成员界面
        self:refreshMemList(data)
    elseif self.Image_memFrame:isVisible() and self.curSelPage == 4 then
        --疲劳值界面
        self:refreshNewList(data)
    end
end

function NewClubMemberLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.notPartnerMemState = 2
    else
        self.notPartnerMemState = 1
    end
    self.notPartnerMemIdx = self.notPartnerMemIdx + 1
end

function NewClubMemberLayer:setPartnerMemberItem(item, data)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_jf = ccui.Helper:seekWidgetByName(item, "Text_jf")
    local Text_jfnum = ccui.Helper:seekWidgetByName(item, "Text_jfnum")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_yb = ccui.Helper:seekWidgetByName(item, "Text_yb")
    local Text_ybnum = ccui.Helper:seekWidgetByName(item, "Text_ybnum")
    local Button_noBind = ccui.Helper:seekWidgetByName(item, "Button_noBind")
    Button_noBind:setVisible(self:isHasAdmin() and data.dwUserID ~= data.dwPartnerID and data.dwPartnerID ~= UserData.User.userID)
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_jf:setColor(cc.c3b(165, 61, 9))
    Text_jfnum:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_yb:setColor(cc.c3b(165, 61, 9))
    Text_ybnum:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_jfnum:setString(data.lScore or 0)
    Text_jsnum:setString(data.dwGameCount or 0)
    Text_dyjnum:setString(data.dwWinnerCount or 0)
    Text_ybnum:setString(data.lYuanBaoCount or 0)

    Common:addTouchEventListener(Button_noBind,function()
        --解绑
        require("common.MsgBoxLayer"):create(1,nil,"您确定要解绑成员？",function() 
            UserData.Guild:reqSettingsClubMember(4, data.dwClubID, data.dwUserID, data.dwPartnerID,"")
        end)
    end)
end

function NewClubMemberLayer:setTextField(data, textField, Button_plz_add, Button_plz_sub)
    textField:setTouchEnabled(false)
    local userInfo = {
        name = data.szNickName,
        userID = data.dwUserID,
        fatigue = data.lFatigue
    }

    Common:addTouchEventListener(Button_plz_add,function()
        local allFatigue = tonumber(self.Text_plznum:getString())
        userInfo.fatigue = tonumber(textField:getString()) or userInfo.fatigue
        local node = require("app.MyApp"):create(userInfo, 1, function(value) 
            if allFatigue < value then
                require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值错误!")
            else
                UserData.Guild:reqSettingsClubMember(7, data.dwClubID, data.dwUserID,0,"",value)
            end
        end):createView("NewClubInputFatigueLayer")
        self:addChild(node)
    end)

    Common:addTouchEventListener(Button_plz_sub,function()
        local lastFatigue = tonumber(textField:getString()) or 0
        userInfo.fatigue = tonumber(textField:getString()) or userInfo.fatigue
        local node = require("app.MyApp"):create(userInfo, 2, function(value) 
            if lastFatigue < value then
                require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值错误!")
            else
                UserData.Guild:reqSettingsClubMember(7, data.dwClubID, data.dwUserID,0,"",-value)
            end
        end):createView("NewClubInputFatigueLayer")
        self:addChild(node)
    end)
end

function NewClubMemberLayer:setPlzMemberItem(item, data)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_jf = ccui.Helper:seekWidgetByName(item, "Text_jf")
    local Text_jfnum = ccui.Helper:seekWidgetByName(item, "Text_jfnum")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_plz = ccui.Helper:seekWidgetByName(item, "Text_plz")
    local Text_yb = ccui.Helper:seekWidgetByName(item, "Text_yb")
    local Text_ybnum = ccui.Helper:seekWidgetByName(item, "Text_ybnum")
    local TextField_plz = ccui.Helper:seekWidgetByName(item, "TextField_plz")
    local Button_plz_add = ccui.Helper:seekWidgetByName(item, "Button_plz_add")
    local Button_plz_sub = ccui.Helper:seekWidgetByName(item, "Button_plz_sub")
    local Button_plzPush = ccui.Helper:seekWidgetByName(item, "Button_plzPush")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_jf:setColor(cc.c3b(165, 61, 9))
    Text_jfnum:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_plz:setColor(cc.c3b(165, 61, 9))
    Text_yb:setColor(cc.c3b(165, 61, 9))
    Text_ybnum:setColor(cc.c3b(165, 61, 9))
    TextField_plz:setColor(cc.c3b(165, 61, 9))
    TextField_plz:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    if data.dwUserID == data.dwPartnerID then
        Button_plz_add:setVisible(false)
        Button_plz_sub:setVisible(false)
    end
    -- Text_plz:setVisible(data.dwUserID ~= data.dwPartnerID)
    -- Button_plzPush:setVisible(data.dwUserID ~= data.dwPartnerID)

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_jfnum:setString(data.lScore or 0)
    Text_jsnum:setString(data.dwGameCount or 0)
    Text_dyjnum:setString(data.dwWinnerCount or 0)
    Text_ybnum:setString(data.lYuanBaoCount or 0)
    TextField_plz:setString(data.lFatigue or 0)
    self:setTextField(data, TextField_plz, Button_plz_add, Button_plz_sub)

    Common:addTouchEventListener(Button_plzPush,function()
        --展开
        self.ListView_myPlayer:setVisible(false)
        self.ListView_findMyPlayer:setVisible(false)
        self.ListView_pushPlayer:setVisible(true)
        self:loadFatigueRecord(item, data)
    end)
end

function NewClubMemberLayer:loadFatigueRecord(item, data)
    self.ListView_pushPlayer:removeAllItems()
    local item = item:clone()
    self.ListView_pushPlayer:pushBackCustomItem(item)
    local TextField_plz = ccui.Helper:seekWidgetByName(item, "TextField_plz")
    local Button_plz_add = self:seekWidgetByNameEx(item, "Button_plz_add")
    local Button_plz_sub = self:seekWidgetByNameEx(item, "Button_plz_sub")
    local Button_plzPush = self:seekWidgetByNameEx(item, "Button_plzPush")
    local path = 'kwxclub/partner_5.png'
    Button_plzPush:loadTextures(path, path, path)
    TextField_plz:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    TextField_plz:setTouchEnabled(false)
    Button_plz_add:setVisible(false)
    Button_plz_sub:setVisible(false)
    
    Common:addTouchEventListener(Button_plzPush,function()
        --展开
        if self.ListView_findMyPlayer:isVisible() then
        
        else
            self.ListView_myPlayer:setVisible(true)
            self.ListView_pushPlayer:setVisible(false)
        end
    end)

    --请求买卖疲劳值记录
    self.curNewPushID = data.dwUserID
    UserData.Guild:getClubFatigueRecord(data.dwClubID,data.dwUserID,1)
end

function NewClubMemberLayer:RET_GET_CLUB_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if self.curPartnerPage == 1 then
        local item = self.Image_plzParnterItem:clone()
        if data.dwUserID == data.dwPartnerID then
            self.ListView_myPlayer:insertCustomItem(item, 1)
        else
            self.ListView_myPlayer:pushBackCustomItem(item)
        end
        item:setName('PlzParnterMember' .. data.dwUserID)
        self:setPlzMemberItem(item, data)

    elseif self.curPartnerPage == 4 then
        local item = self.Image_pushParnterItem:clone()
        if data.dwUserID == data.dwPartnerID then
            self.ListView_pushParnter:insertCustomItem(item, 1)
        else
            self.ListView_pushParnter:pushBackCustomItem(item)
        end
        item:setName('pushParnter' .. data.dwUserID)
        self:setPartnerMemberItem(item, data)
    end
end

function NewClubMemberLayer:RET_GET_CLUB_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.pReqState = 2
    else
        self.pReqState = 1
    end
    self.pCurPage = self.pCurPage + 1
end

function NewClubMemberLayer:RET_FIND_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet == 0 then
        self.ListView_addParnter:setVisible(false)
        self.ListView_findAddParnter:setVisible(true)
        self.ListView_findAddParnter:removeAllItems()
        local item = self.Image_parnterItem:clone()
        self.ListView_findAddParnter:pushBackCustomItem(item)
        self:setNotParnterMemberItem(item ,data)
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在")
    end
end

function NewClubMemberLayer:RET_FIND_CLUB_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet == 0 then
        self.ListView_myPlayer:setVisible(false)
        self.ListView_pushPlayer:setVisible(false)
        self.ListView_findMyPlayer:setVisible(true)
        self.ListView_findMyPlayer:removeAllItems()
        local item = self.Image_plzParnterItem:clone()
        self.ListView_findMyPlayer:pushBackCustomItem(item)
        self:setPlzMemberItem(item, data)
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在")
    end
end

function NewClubMemberLayer:RET_GET_CLUB_STATISTICS_ALL(event)
    local data = event._usedata
    Log.d(data)
    self.Text_playAllJS:setString(data.dwAllPeopleCount)
end

function NewClubMemberLayer:refreshParnterItemPeoples(dwUserID, num)
    local item = self.ListView_myParnter:getChildByName('myparnter' .. dwUserID)
    if item then
        local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
        local curnum = tonumber(Text_playerCount:getString())
        curnum = curnum + num
        if curnum < 0 then
            curnum = 0
        end
        Text_playerCount:setString(curnum)
    end

    local item = self.ListView_pushParnter:getChildByName('OnceParnter' .. dwUserID)
    if item then
        local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
        local curnum = tonumber(Text_playerCount:getString())
        curnum = curnum + num
        if curnum < 0 then
            curnum = 0
        end
        Text_playerCount:setString(curnum)
    end
end

function NewClubMemberLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD(event)
    local data = event._usedata
    Log.d(data)

    local listview = self.ListView_newPush
    if self.Image_partnerFrame:isVisible() then
        listview = self.ListView_pushPlayer
    end

    if data.cbType == 0 then
        --设置疲劳值
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local des = string.format(' 管理员设置%d,当前剩余%0.2f.', data.lFatigue, data.lNewFatigue)
        Text_desfont:setString(timeStr .. des)
        listview:refreshView()
    elseif data.cbType == 1 then
        --房费
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local gameName = ""
        if StaticData.Games[data.wKindID] then
            gameName = '(' .. StaticData.Games[data.wKindID].name .. ')'
        end

        if data.lFatigue >= 0 then
            local des = string.format(' %s游戏消耗+%d,当前剩余%0.2f.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' %s游戏消耗%d,当前剩余%0.2f.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        listview:refreshView()
    elseif data.cbType == 2 then
        --对局
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local gameName = ""
        if StaticData.Games[data.wKindID] then
            gameName = '(' .. StaticData.Games[data.wKindID].name .. ')'
        end

        if data.lFatigue >= 0 then
            local des = string.format(' %s游戏对局+%d,当前剩余%0.2f.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' %s游戏对局%d,当前剩余%0.2f.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        listview:refreshView()

    elseif data.cbType == 3 then
        --合伙人买卖疲劳值
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        if data.lFatigue >= 0 then
            local des = string.format(' 给成员%s(%d)增加%d,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,math.abs(data.lFatigue),data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' 给成员%s(%d)减少%d,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,math.abs(data.lFatigue),data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        listview:refreshView()

    elseif data.cbType == 4 then
        --玩家接受买卖疲劳值
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        if data.lFatigue >= 0 then
            local des = string.format(' 合伙人%s(%d)给其增加%d,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,math.abs(data.lFatigue),data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' 合伙人%s(%d)给其减少%d,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,math.abs(data.lFatigue),data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        listview:refreshView()

    elseif data.cbType == 5 then
        --新设置疲劳值
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        if data.lFatigue >= 0 then
            local des = string.format(' 管理员%s(%d)给其增加%d,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,math.abs(data.lFatigue),data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' 管理员%s(%d)给其减少%d,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,math.abs(data.lFatigue),data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        listview:refreshView()

    elseif data.cbType == 6 then
        --疲劳值均摊房费
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local des = string.format(' %s(%d)均摊房费%0.2f,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,data.lFatigue,data.lNewFatigue)
        Text_desfont:setString(timeStr .. des)
        listview:refreshView()
    elseif data.cbType == 7 then
        --疲劳值收益
        local item = self.Panel_fontItem:clone()
        listview:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local des = string.format(' %s(%d)给其带来收益%0.2f,当前剩余%0.2f.', data.szOriginNickName,data.dwOriginID,data.lFatigue,data.lNewFatigue)
        Text_desfont:setString(timeStr .. des)
        listview:refreshView()
    end
end

function NewClubMemberLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.newPushState = 2
    else
        self.newPushState = 1
    end
    self.newPushPage = self.newPushPage + 1
end

function NewClubMemberLayer:RET_SETTINGS_CONFIG(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet ~= 0 then
        self.Panel_partnetSet:setVisible(false)
        require("common.MsgBoxLayer"):create(0,nil,"获取配置信息失败！")
        return 
    end

    -- self.Panel_partnetSet:setVisible(true)
    if data.bDistributionModel == 0 then
        self.Image_one:getChildByName('Image_light'):setVisible(true)
        self.Image_two:getChildByName('Image_light'):setVisible(false)
        self.Text_two:setVisible(false)
        self.Text_three:setVisible(false)
    else
        self.Image_one:getChildByName('Image_light'):setVisible(false)
        self.Image_two:getChildByName('Image_light'):setVisible(true)
        self.Text_two:setVisible(true)
        self.Text_three:setVisible(true)
    end

    self.Text_oneValue:setString(data.bDistributionRatio1 .. '%')
    self.Text_twoValue:setString(data.bDistributionRatio2 .. '%')
    self.Text_threeValue:setString(data.bDistributionRatio3 .. '%')

    self.Image_autoFatigue:setColor(cc.c3b(170, 170, 170))
    self.Image_autoYB:setColor(cc.c3b(170, 170, 170))

    if data.bIsPartnerRemoveMember then
        self.Image_kick:getChildByName('Image_light'):setVisible(true)
    else
        self.Image_kick:getChildByName('Image_light'):setVisible(false)
    end

    if data.bIsPartnerImportMember then
        self.Image_import:getChildByName('Image_light'):setVisible(true)
    else
        self.Image_import:getChildByName('Image_light'):setVisible(false)
    end

    if data.bIsHaveFatigueNotLeave then
        self.Image_leave:getChildByName('Image_light'):setVisible(true)
    else
        self.Image_leave:getChildByName('Image_light'):setVisible(false)
    end

    self.Text_jtValue:setString(data.dwFatigueTip)

end

function NewClubMemberLayer:RET_SETTINGS_PAPTNER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"设置保存失败！")
        return 
    end
    require("common.MsgBoxLayer"):create(0,nil,"设置保存成功！")
end

function NewClubMemberLayer:RET_UPDATE_CLUB_PLAYER_INFO(event)
    local data = event._usedata
    Log.d(data)
    self.Text_plznum:setString(data.lFatigueValue)

    local item = self.ListView_myPlayer:getChildByName('PlzParnterMember' .. data.dwUserID)
    if item then
        local TextField_plz = self:seekWidgetByNameEx(item, "TextField_plz")
        TextField_plz:setString(data.lFatigueValue)
    end

    local item = self.ListView_new:getChildByName('fatigue_' .. data.dwUserID)
    if item then
        local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
        TextField_des:setString(data.lFatigueValue)
    end

    if data.dwUserID == UserData.User.userID then
        self.userFatigueValue = data.lFatigueValue
    end
end

function NewClubMemberLayer:RET_PARTNER_EARNINGS(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取收益统计失败！")
        return 
    end

    if self.clubData.dwUserID == UserData.User.userID then
        self.Text_sy_allcy:setString(data.dwTotalPersonTime)
        self.Text_sy_allfk:setString(data.dwTotalFatigueTip)
        local strFatigue = data.dwTotalFatigueIncome .. '/' .. data.dwTotalFatigueIncome-data.dwFatigueIncome .. '/' .. data.dwFatigueIncome
        local strYuanBao = data.dwTotalYuanBaoIncome .. '/' .. data.dwTotalYuanBaoIncome-data.dwYuanBaoIncome .. '/' .. data.dwYuanBaoIncome
        self.Text_sy_allFatigue:setString(strFatigue)
        self.Text_sy_allYuanbao:setString(strYuanBao)
    else
        self.Text_sy_allcy:setString(data.dwPersonTime)
        self.Text_sy_allfk:setString(data.dwFatigueTip)
        self.Text_sy_allFatigue:setString(data.dwFatigueIncome)
        self.Text_sy_allYuanbao:setString(data.dwYuanBaoIncome)
    end
    UserData.Guild:getPartnerPageEarnings(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, 1)
end

function NewClubMemberLayer:RET_PARTNER_PAGE_EARNINGS(event)
    local data = event._usedata
    Log.d(data)

    local item = self.Panel_leaderItem:clone()
    self.ListView_sy:pushBackCustomItem(item)

    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    local Text_allcount = self:seekWidgetByNameEx(item, "Text_allcount")
    local Text_allRoomCard = self:seekWidgetByNameEx(item, "Text_allRoomCard")
    local Text_allFatigue = self:seekWidgetByNameEx(item, "Text_allFatigue")
    local Text_allYuanbao = self:seekWidgetByNameEx(item, "Text_allYuanbao")
    Text_time:setColor(cc.c3b(0, 0, 0))
    Text_allcount:setColor(cc.c3b(0, 0, 0))
    Text_allRoomCard:setColor(cc.c3b(0, 0, 0))
    Text_allFatigue:setColor(cc.c3b(0, 0, 0))
    Text_allYuanbao:setColor(cc.c3b(0, 0, 0))
    
    if self.clubData.dwUserID == UserData.User.userID then
        Text_time:setString(os.date("%Y-%m-%d",data.dwCreateDate))
        Text_allcount:setString(data.dwTotalPersonTime)
        Text_allRoomCard:setString(data.dwTotalFatigueTip)
        local strFatigue = data.dwTotalFatigueIncome .. '/' .. data.dwTotalFatigueIncome-data.dwFatigueIncome .. '/' .. data.dwFatigueIncome
        local strYuanBao = data.dwTotalYuanBaoIncome .. '/' .. data.dwTotalYuanBaoIncome-data.dwYuanBaoIncome .. '/' .. data.dwYuanBaoIncome
        Text_allFatigue:setString(strFatigue)
        Text_allYuanbao:setString(strYuanBao)
    else
        Text_time:setString(os.date("%Y-%m-%d",data.dwCreateDate))
        Text_allcount:setString(data.dwPersonTime)
        Text_allRoomCard:setString(data.dwFatigueTip)
        Text_allFatigue:setString(data.dwFatigueIncome)
        Text_allYuanbao:setString(data.dwYuanBaoIncome)
    end
end

function NewClubMemberLayer:RET_PARTNER_PAGE_EARNINGS_FINISH(event)
    local data = event._usedata
    Log.d(data)

    if data.isFinish then
        self.earningsReqState = 2
    else
        self.earningsReqState = 1
    end
    self.earningsPage = self.earningsPage + 1
end

function NewClubMemberLayer:RET_CLUB_PLAYER_COUNT(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取我的玩家统计失败！")
        return
    end
    self.Text_wj_alljt:setString(data.dwTargetFatigueTip)
    self.Text_wj_allFatiguesy:setString(data.dwTargetFatigueIncome)
    self.Text_wj_allYuanBaosy:setString(data.dwTargetYuanBaoIncome)
    self.Text_wj_alldyj:setString(data.dwBigWinnerTime)
    self.Text_wj_cynum:setString(data.dwPeopleCount)
    UserData.Guild:getClubPagePlayerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, 1)
end

function NewClubMemberLayer:RET_CLUB_PAGE_PLAYER_COUNT(event)
    local data = event._usedata
    Log.d(data)

    local item = self.Panel_playerCountItem:clone()
    self.ListView_playerCount:pushBackCustomItem(item)

    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_juntan = self:seekWidgetByNameEx(item, "Text_juntan")
    local Text_fatigue_sy = self:seekWidgetByNameEx(item, "Text_fatigue_sy")
    local Text_yuanbao_sy = self:seekWidgetByNameEx(item, "Text_yuanbao_sy")
    local Text_bigwincount = self:seekWidgetByNameEx(item, "Text_bigwincount")
    local Text_playcount = self:seekWidgetByNameEx(item, "Text_playcount")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(0, 0, 0))
    Text_juntan:setColor(cc.c3b(0, 0, 0))
    Text_fatigue_sy:setColor(cc.c3b(0, 0, 0))
    Text_yuanbao_sy:setColor(cc.c3b(0, 0, 0))
    Text_bigwincount:setColor(cc.c3b(0, 0, 0))
    Text_playcount:setColor(cc.c3b(0, 0, 0))

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_juntan:setString(data.dwTargetFatigueTip)
    Text_fatigue_sy:setString(data.dwTargetFatigueIncome)
    Text_yuanbao_sy:setString(data.dwTargetYuanBaoIncome)
    Text_bigwincount:setString(data.dwBigWinnerTime)
    Text_playcount:setString(data.dwPeopleCount)

    Common:addTouchEventListener(Button_push,function()
        self.Image_playerCountFrame:setVisible(false)
        self.Image_playerCountPushFrame:setVisible(true)
        self.Text_timeNode:setVisible(false)
        self.Panel_partnerCount:setVisible(true)
        Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_partnerPageHead, "img")
        self.Text_partnerPageName:setString(data.szNickName)
        self.Text_partnerPageID:setString('ID:' .. data.dwUserID)

        self.ListView_pushPlayerCount:removeAllItems()
        self.curSelLookDetailsPlayer = data.dwUserID
        UserData.Guild:getClubPlayerCountDetails(self.clubData.dwClubID, UserData.User.userID, data.dwUserID, self.beganTime, self.endTime, 1)
    end)
end

function NewClubMemberLayer:RET_CLUB_PAGE_PLAYER_COUNT_FINISH(event)
    local data = event._usedata
    Log.d(data)

    if data.isFinish then
        self.playerCountState = 2
    else
        self.playerCountState = 1
    end
    self.playerCountPage = self.playerCountPage + 1
end

function NewClubMemberLayer:RET_CLUB_PLAYER_COUNT_DETAILS(event)
    local data = event._usedata
    Log.d(data)

    local item = self.Panel_playerCountPushItem:clone()
    self.ListView_pushPlayerCount:pushBackCustomItem(item)

    local Text_room = self:seekWidgetByNameEx(item, "Text_room")
    local Text_playName = self:seekWidgetByNameEx(item, "Text_playName")
    local Text_juntan = self:seekWidgetByNameEx(item, "Text_juntan")
    local Text_fitigueGet = self:seekWidgetByNameEx(item, "Text_fitigueGet")
    local Text_yuanbaoGet = self:seekWidgetByNameEx(item, "Text_yuanbaoGet")
    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    Text_room:setColor(cc.c3b(0, 0, 0))
    Text_playName:setColor(cc.c3b(0, 0, 0))
    Text_juntan:setColor(cc.c3b(0, 0, 0))
    Text_fitigueGet:setColor(cc.c3b(0, 0, 0))
    Text_yuanbaoGet:setColor(cc.c3b(0, 0, 0))
    Text_time:setColor(cc.c3b(0, 0, 0))

    Text_room:setString(data.dwTableID)

    local playwayIdx = self:getPlayerWayIdx(data.dwPlayID)
    if playwayIdx and self.clubData.szParameterName[playwayIdx] then
        Text_playName:setString(self.clubData.szParameterName[playwayIdx])
    else
        Text_playName:setString(StaticData.Games[data.wKindID].name)
    end
    Text_juntan:setString(data.dwTargetFatigueTip)
    Text_fitigueGet:setString(data.dwTargetFatigueIncome)
    Text_yuanbaoGet:setString(data.dwTargetYuanBaoIncome)
    Text_time:setString(os.date("%Y-%m-%d\n%H:%M:%S",data.dwCreateDate))
end

function NewClubMemberLayer:getPlayerWayIdx(dwPlayID)
    for i,v in ipairs(self.clubData.dwPlayID or {}) do
        if v == dwPlayID then
            return i
        end
    end
    return nil;
end

function NewClubMemberLayer:RET_CLUB_PLAYER_COUNT_DETAILS_FINISH(event)
    local data = event._usedata
    Log.d(data)
    
    if data.isFinish then
        self.playerCountDetailsState = 2
    else
        self.playerCountDetailsState = 1
    end
    self.playerCountDetailsPage = self.playerCountDetailsPage + 1
end

function NewClubMemberLayer:RET_CLUB_PARTNER_COUNT(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"获取合伙人统计失败！")
        return
    end
    self.Text_allcount_partner:setString(data.dwPeopleCount)
    self.Text_allyuanbao_partner:setString(data.dwTargetYuanBaoIncome)
    self.Text_allroomcard_partner:setString(data.dwTargetFatigueTip)
    self.Text_allFatigue_partner:setString(data.dwTargetFatigueIncome)
    self.Text_allbigwin_partner:setString(data.dwBigWinnerTime)
    if self:isHasAdmin() then
        UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, 0, self.beganTime, self.endTime, 1)
    else
        UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, 1)
    end
end

function NewClubMemberLayer:RET_CLUB_PAGE_PARTNER_COUNT(event)
    local data = event._usedata
    Log.d(data)

    local item = self.Panel_countItem:clone()
    if data.dwUserID == UserData.User.userID then
        self.ListView_count_partner:insertCustomItem(item, 0)
    else
        self.ListView_count_partner:pushBackCustomItem(item)
    end
    
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_count = self:seekWidgetByNameEx(item, "Text_count")
    local Text_yuanbao = self:seekWidgetByNameEx(item, "Text_yuanbao")
    local Text_roomcard = self:seekWidgetByNameEx(item, "Text_roomcard")
    local Text_fatigue = self:seekWidgetByNameEx(item, "Text_fatigue")
    local Text_bigwin = self:seekWidgetByNameEx(item, "Text_bigwin")
    local Button_push = self:seekWidgetByNameEx(item, "Button_push")
    Text_name:setColor(cc.c3b(0, 0, 0))
    Text_count:setColor(cc.c3b(0, 0, 0))
    Text_yuanbao:setColor(cc.c3b(0, 0, 0))
    Text_roomcard:setColor(cc.c3b(0, 0, 0))
    Text_fatigue:setColor(cc.c3b(0, 0, 0))
    Text_bigwin:setColor(cc.c3b(0, 0, 0))

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_count:setString(data.dwPeopleCount)
    Text_yuanbao:setString(data.dwTargetYuanBaoIncome)
    Text_roomcard:setString(data.dwTargetFatigueTip)
    Text_fatigue:setString(data.dwTargetFatigueIncome)
    Text_bigwin:setString(data.dwBigWinnerTime)

    Common:addTouchEventListener(Button_push,function()
        self.Image_countFrame:setVisible(false)
        self.Image_countPushFrame:setVisible(true)
        self.Text_timeNode:setVisible(false)
        self.Panel_partnerCount:setVisible(true)
        Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_partnerPageHead, "img")
        self.Text_partnerPageName:setString(data.szNickName)
        self.Text_partnerPageID:setString('ID:' .. data.dwUserID)

        self.ListView_pushCount:removeAllItems()
        self.curSelLookDetailsPartner = data.dwUserID
        if self:isHasAdmin() then
            UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, data.dwUserID, 0, self.beganTime, self.endTime, 1)
        else
            UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, UserData.User.userID, data.dwUserID, self.beganTime, self.endTime, 1)
        end
    end)
end

function NewClubMemberLayer:RET_CLUB_PAGE_PARTNER_COUNT_FINISH(event)
    local data = event._usedata
    Log.d(data)

    if data.isFinish then
        self.partnerCountState = 2
    else
        self.partnerCountState = 1
    end
    self.partnerCountPage = self.partnerCountPage + 1
end

function NewClubMemberLayer:RET_CLUB_PARTNER_COUNT_DETAILS(event)
    local data = event._usedata
    Log.d(data)

    local item = self.Panel_countPushItem:clone()
    self.ListView_pushCount:pushBackCustomItem(item)

    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    local Text_count = self:seekWidgetByNameEx(item, "Text_count")
    local Text_yuanbao = self:seekWidgetByNameEx(item, "Text_yuanbao")
    local Text_roomcard = self:seekWidgetByNameEx(item, "Text_roomcard")
    local Text_fatigue = self:seekWidgetByNameEx(item, "Text_fatigue")
    Text_time:setColor(cc.c3b(0, 0, 0))
    Text_count:setColor(cc.c3b(0, 0, 0))
    Text_yuanbao:setColor(cc.c3b(0, 0, 0))
    Text_roomcard:setColor(cc.c3b(0, 0, 0))
    Text_fatigue:setColor(cc.c3b(0, 0, 0))
    Text_time:setString(os.date("%Y-%m-%d",data.dwCreateDate))
    Text_count:setString(data.dwPersonTime)
    Text_yuanbao:setString(data.dwYuanBaoIncome)
    Text_roomcard:setString(data.dwFatigueTip)
    Text_fatigue:setString(data.dwFatigueIncome)
end

function NewClubMemberLayer:RET_CLUB_PARTNER_COUNT_DETAILS_FINISH(event)
    local data = event._usedata
    Log.d(data)

    if data.isFinish then
        self.partnerCountDetailsState = 2
    else
        self.partnerCountDetailsState = 1
    end
    self.partnerCountDetailsPage = self.partnerCountDetailsPage + 1
end

function NewClubMemberLayer:RET_CLUB_MEMBER_INFO(event)
    local data = event._usedata
    Log.d(data)

    if data.dwClubID == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"用户不存在!")
        return
    end
    
    if self.curSelPage == 1 then
        self.ListView_mem:setVisible(false)
        self.ListView_find:setVisible(true)
        self.Image_findFrame:setVisible(false)
        self.Button_memFind:setVisible(false)
        self.Button_memReturn:setVisible(true)
        self:addOnceFindMem(data)
    elseif self.curSelPage == 4 then
        self.ListView_new:setVisible(false)
        self.ListView_newPush:setVisible(false)
        self.ListView_newFind:setVisible(true)
        self.Image_newFindFrame:setVisible(false)
        self.Button_newFind:setVisible(false)
        self.Button_newReturn:setVisible(true)
        self.ListView_newFind:removeAllItems()
        self:refreshNewList(data, self.ListView_newFind)
    end
end

function NewClubMemberLayer:RET_CLUB_MEMBER_INFO_FINISH(event)
     local data = event._usedata
    Log.d(data)
end

------------------------------------------------------------------------
--                            按键区域2                                --
------------------------------------------------------------------------
function NewClubMemberLayer:initNumberArea()
    self:resetNumber()

    local function onEventInput(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local index = sender.index
            if index == 10 then
                self:resetNumber()
            elseif index == 11 then
                self:deleteNumber()
            else
                self:inputNumber(index)
            end
        end
    end

    for i = 0 , 11 do
        local btnName = string.format("Button_num%d", i)
        local Button_num = ccui.Helper:seekWidgetByName(self.Image_inputFrame, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--重置数字
function NewClubMemberLayer:resetNumber()
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
end

--输入数字
function NewClubMemberLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 6 then
                -- UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
end

--删除数字
function NewClubMemberLayer:deleteNumber()
    for i = 6 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            break
        end
    end
end


----------------
--分页请求
function NewClubMemberLayer:listViewClubEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self:isHasAdmin() then
            if self.memberReqState == 1 then
                self.memberReqState = 0
                self:reqClubMember()
            end
        else
            if self.userOffice ~= 2 then
                --合伙人
                if self.notPartnerMemState == 1 then
                    self.notPartnerMemState = 0
                    self:reqNotPartnerMember()
                end
            end
        end
    end
end

function NewClubMemberLayer:listViewNewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.Image_memFrame:isVisible() and self.curSelPage == 4 then
            --疲劳值界面
            if self.notPartnerMemState == 1 then
                self.notPartnerMemState = 0
                if self:isHasAdmin() then
                    UserData.Guild:getClubNotPartnerMember(0, self.notPartnerMemIdx, self.clubData.dwClubID, self.clubData.dwUserID)
                else
                    if self.userOffice == 2 then
                        --普通成员
                        UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
                    else
                        --合伙人
                        UserData.Guild:getClubNotPartnerMember(0, self.notPartnerMemIdx, self.clubData.dwClubID)
                    end
                end
            end
        else
            --成员
            if self.memberReqState == 1 then
                self.memberReqState = 0
                self:reqClubMember()
            end
        end
    end
end

function NewClubMemberLayer:listViewPushNewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.newPushState == 1 then
            self.newPushState = 0
            UserData.Guild:getClubFatigueRecord(self.clubData.dwClubID,self.curNewPushID,self.newPushPage)
        end
    end
end

function NewClubMemberLayer:listViewMyPlayerEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.pReqState == 1 then
            self.pReqState = 0
            self:reqClubPartnerMember()
        end
    end
end

function NewClubMemberLayer:listViewNotParnterMemberEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.notPartnerMemState == 1 then
            self.notPartnerMemState = 0
            self:reqNotPartnerMember()
        end
    end
end

function NewClubMemberLayer:listViewParnterEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerReqState == 1 then
            self.partnerReqState = 0
            self:reqClubPartner()
        end
    end
end

function NewClubMemberLayer:listViewParnterMemberEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.pReqState == 1 then
            self.pReqState = 0
            self:reqClubPartnerMember()
        end
    end
end

function NewClubMemberLayer:listViewEarningsEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.earningsReqState == 1 then
            self.earningsReqState = 0
            UserData.Guild:getPartnerPageEarnings(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.earningsPage)
        end
    end
end

function NewClubMemberLayer:listViewPlayerCountEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.playerCountState == 1 then
            self.playerCountState = 0
            UserData.Guild:getClubPagePlayerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.playerCountPage)
        end
    end
end

function NewClubMemberLayer:listViewPlayerDetailsCountEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.playerCountDetailsState == 1 then
            self.playerCountDetailsState = 0
            UserData.Guild:getClubPlayerCountDetails(self.clubData.dwClubID, UserData.User.userID, self.curSelLookDetailsPlayer, self.beganTime, self.endTime, self.playerCountDetailsPage)
        end
    end
end

function NewClubMemberLayer:listViewPartnerCountEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerCountState == 1 then
            self.partnerCountState = 0
            if self:isHasAdmin() then
                UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, 0, self.beganTime, self.endTime, self.partnerCountPage)
            else
                UserData.Guild:getClubPagePartnerCount(self.clubData.dwClubID, UserData.User.userID, self.beganTime, self.endTime, self.partnerCountPage)
            end
        end
    end
end

function NewClubMemberLayer:listViewPartnerCountDetailsEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerCountDetailsState == 1 then
            self.partnerCountDetailsState = 0
            if self:isHasAdmin() then
                UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, self.curSelLookDetailsPartner, 0, self.beganTime, self.endTime, self.partnerCountDetailsPage)
            else
                UserData.Guild:getClubPartnerCountDetails(self.clubData.dwClubID, UserData.User.userID, self.curSelLookDetailsPartner, self.beganTime, self.endTime, self.partnerCountDetailsPage)
            end
        end
    end
end

return NewClubMemberLayer