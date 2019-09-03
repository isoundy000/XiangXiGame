--[[
*名称:NewClubParnterAddMemLayer
*描述:添加合伙人成员
*作者:admin
*创建日期:2018-11-20 11:30:52
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local Log               = require("common.Log")

local NewClubParnterAddMemLayer = class("NewClubParnterAddMemLayer", cc.load("mvc").ViewBase)

function NewClubParnterAddMemLayer:onConfig()
    self.widget         = {
        {"Image_inputFrame"},
        {"Button_addMem", "onAddMem"},
    }
end

function NewClubParnterAddMemLayer:onEnter()
    EventMgr:registListener(EventType.RET_CLUB_GROUP_INVITE ,self,self.RET_CLUB_GROUP_INVITE)
end

function NewClubParnterAddMemLayer:onExit()
    EventMgr:unregistListener(EventType.RET_CLUB_GROUP_INVITE ,self,self.RET_CLUB_GROUP_INVITE)
end

function NewClubParnterAddMemLayer:onCreate(param)
	self.clubData = param[1]
    self.isMegeClub = param[2]
	self:initNumberArea()
	Common:registerScriptMask(self.Image_inputFrame, function()
		self:removeFromParent()
	end)
end

function NewClubParnterAddMemLayer:onAddMem()
	local roomNumber = ""
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            if self.isMegeClub then
                require("common.MsgBoxLayer"):create(0,nil,"输入亲友圈ID不正确")
            else
                require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID不正确")
            end
            return
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end

    if self.isMegeClub then
        UserData.Guild:sendClubGroupInvite(self.clubData.dwClubID, UserData.User.userID, tonumber(roomNumber))
    else
        UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
    end
	self:resetNumber()
end

function NewClubParnterAddMemLayer:RET_CLUB_GROUP_INVITE(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈不存在")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"目标亲友圈不存在")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"权限不足")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"不能重复邀请")
        else
            require("common.MsgBoxLayer"):create(0,nil,"合群发起失败")
        end
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"合群发起成功")
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function NewClubParnterAddMemLayer:initNumberArea()
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
function NewClubParnterAddMemLayer:resetNumber()
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
end

--输入数字
function NewClubParnterAddMemLayer:inputNumber(num)
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
function NewClubParnterAddMemLayer:deleteNumber()
    for i = 6 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            break
        end
    end
end


return NewClubParnterAddMemLayer