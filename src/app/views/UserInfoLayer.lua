local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")

local UserInfoLayer = class("UserInfoLayer", cc.load("mvc").ViewBase)

function UserInfoLayer:onEnter()
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:registListener(EventType.EVENT_TYPE_OPEN_PHOTO_ALBUM,self,self.EVENT_TYPE_OPEN_PHOTO_ALBUM)
    EventMgr:registListener(EventType.EVENT_TYPE_UPLOAD_ERWEIMA,self,self.EVENT_TYPE_UPLOAD_ERWEIMA)
    EventMgr:registListener(EventType.EVENT_TYPE_XIAN_LIAO_LOGIN,self,self.EVENT_TYPE_XIAN_LIAO_LOGIN)
    EventMgr:registListener(EventType.SUB_CL_SET_USER_INFO,self,self.SUB_CL_SET_USER_INFO)
    EventMgr:registListener(EventType.EVENT_TYPE_BIND_PHONE,self,self.EVENT_TYPE_BIND_PHONE)

    self:updateUserInfo()
end

function UserInfoLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:unregistListener(EventType.EVENT_TYPE_OPEN_PHOTO_ALBUM,self,self.EVENT_TYPE_OPEN_PHOTO_ALBUM)
    EventMgr:unregistListener(EventType.EVENT_TYPE_UPLOAD_ERWEIMA,self,self.EVENT_TYPE_UPLOAD_ERWEIMA)
    EventMgr:unregistListener(EventType.EVENT_TYPE_XIAN_LIAO_LOGIN,self,self.EVENT_TYPE_XIAN_LIAO_LOGIN)
    EventMgr:unregistListener(EventType.SUB_CL_SET_USER_INFO,self,self.SUB_CL_SET_USER_INFO)
    EventMgr:unregistListener(EventType.EVENT_TYPE_BIND_PHONE,self,self.EVENT_TYPE_BIND_PHONE)

end

function UserInfoLayer:onCreate(parames)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("UserInfoLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    local Image_bg = self.root:getChildByName("Image_bg")
    -- local callback = function()
    --     require("common.SceneMgr"):switchOperation()
    -- end
    -- Common:playPopupAnim(Image_bg, nil, callback)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        -- Common:playExitAnim(Image_bg, callback)
        self:removeFromParent()
    end)

    UserData.User:sendMsgUpdateUserInfo(1)

    --明信片修改
    local uiButton_noun = ccui.Helper:seekWidgetByName(self.root,"Button_noun")
    if uiButton_noun~= nil then 
        Common:addTouchEventListener(uiButton_noun,function()                
            UserData.User:openPhotoAlbum()
        end)
    end 

    --实名认证
    local uiButton_RealName  = ccui.Helper:seekWidgetByName(self.root,"Button_RealName")
    if uiButton_RealName ~= nil then 
        Common:addTouchEventListener(uiButton_RealName,function()  
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer"))
        end)
    end 

    --手机绑定
    local uiButton_phone = ccui.Helper:seekWidgetByName(self.root,"Button_phone")
    local uiText_phone = ccui.Helper:seekWidgetByName(self.root,"Text_phone")
    if uiButton_phone ~= nil then
        Common:addTouchEventListener(uiButton_phone,function()  
            local csb = cc.CSLoader:createNode("PhoneBindLayer.csb")
            self:addChild(csb)
            local root = csb:getChildByName("Panel_root")
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(root,"Button_return"),function()
                csb:removeFromParent()
            end)

            local uiTextField_phone = ccui.Helper:seekWidgetByName(root,"TextField_phone")
            local uiTextField_code = ccui.Helper:seekWidgetByName(root,"TextField_code")
            local uiButton_sendCode = ccui.Helper:seekWidgetByName(root,"Button_sendCode")
            Common:addTouchEventListener(uiButton_sendCode,function()
                local text = uiButton_sendCode:getTitleText()
                local szPhone = uiTextField_phone:getString()
                if szPhone == "" then
                    require("common.MsgBoxLayer"):create(0,nil,"手机号码不能为空!")
                elseif string.len(szPhone) ~= 11 or tonumber(szPhone) == nil or tonumber(szPhone) < 10000000000 or tonumber(szPhone) > 99999999999 then
                    require("common.MsgBoxLayer"):create(0,nil,"手机号码错误!")
                elseif szPhone == UserData.User.szPhone then
                    require("common.MsgBoxLayer"):create(0,nil,"不能重复绑定!")
                else
                    uiButton_sendCode:stopAllActions()
                    local time = 60
                    uiButton_sendCode:runAction(cc.RepeatForever:create(cc.Sequence:create(
                        cc.CallFunc:create(function(sender, event)
                            if time <= 0 then
                                uiButton_sendCode:setEnabled(true)
                                uiButton_sendCode:setTitleText("发送验证码")
                                uiButton_sendCode:stopAllActions()
                            else
                                uiButton_sendCode:setEnabled(false)
                                uiButton_sendCode:setTitleText(string.format("%ss重新发送",time))
                            end
                            time = time - 1
                        end),
                        cc.DelayTime:create(1)
                    )))
                    self.phoneData = nil
                    UserData.User:httpPhoneBind(szPhone)
                end
            end)

            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(root,"Button_ok"),function()
                local szPhone = uiTextField_phone:getString()
                local szCode = uiTextField_code:getString()
                if szPhone == "" then
                    require("common.MsgBoxLayer"):create(0,nil,"手机号码不能为空!")
                elseif string.len(szPhone) ~= 11 or tonumber(szPhone) == nil or tonumber(szPhone) < 10000000000 or tonumber(szPhone) > 99999999999 then
                    require("common.MsgBoxLayer"):create(0,nil,"手机号码错误!")
                elseif szPhone == UserData.User.szPhone then
                    require("common.MsgBoxLayer"):create(0,nil,"不能重复绑定!")
                elseif szCode == "" then
                    require("common.MsgBoxLayer"):create(0,nil,"验证码不能为空!")
                elseif self.phoneData == nil then
                    require("common.MsgBoxLayer"):create(0,nil,"请先发送验证码!")
                elseif self.phoneData.szPhone ~= szPhone then
                    require("common.MsgBoxLayer"):create(0,nil,"手机号码错误!!")   
                elseif tonumber(szCode) == nil then
                    require("common.MsgBoxLayer"):create(0,nil,"验证码格式错误!")
                elseif tonumber(szCode) ~= self.phoneData.phone_code then
                    require("common.MsgBoxLayer"):create(0,nil,"验证码错误!")
                else
                    UserData.User:setUserInfo(3,szPhone)
                    csb:removeFromParent()
                end
            end)
           
        end)
    end

    --闲聊绑定
    local uiButton_xianLiao = ccui.Helper:seekWidgetByName(self.root,"Button_xianLiao")
    if uiButton_xianLiao ~= nil then
        Common:addTouchEventListener(uiButton_xianLiao,function()  
            UserData.User:xianLiaoLogin()
        end)
    end

    local uiPanel_Assets = ccui.Helper:seekWidgetByName(self.root,"Panel_Assets")
    uiPanel_Assets:setVisible(false)

    if UserData.User.szRealName == "" then 
        uiButton_RealName:loadTextures("newuser/renzheng_fs8.png","newuser/renzheng_fs8.png","newuser/renzheng_fs8.png")
    end 
    local uiButton_roomCard = ccui.Helper:seekWidgetByName(self.root,"Button_roomCard") 
    Common:addTouchEventListener(uiButton_roomCard,function()             
        --require("app.views.AgentLayer"):create()
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) 
    end) 

    local uiButton_gold = ccui.Helper:seekWidgetByName(self.root,"Button_gold")
    if  uiButton_gold ~= nil then
        Common:addTouchEventListener(uiButton_gold,function()             
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer")) 
        end)    
    end

    --兑换
    local uiButton_money = ccui.Helper:seekWidgetByName(self.root,"Button_money")
    if  uiButton_money ~= nil then
        Common:addTouchEventListener(uiButton_money,function()    
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("ExchangeCenterLayer"))         
            --require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(3):createView("NewXXMallLayer")) 
        end)    
    end

    --公告

    local uiText_notice = ccui.Helper:seekWidgetByName(self.root,"Text_notice")
    uiText_notice:setString("")
    if UserData.Notice.notice ~= nil then
        local data = UserData.Notice.notice.szNoticeInfo
        uiText_notice:setString("   "..data)
        print(uiText_notice:getAutoRenderSize().width)
    end
   

end

--刷新个人信息
function UserInfoLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function UserInfoLayer:updateUserInfo()
    local uiButton_avatar = ccui.Helper:seekWidgetByName(self.root,"Button_avatar")
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiButton_avatar,"btn")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    uiText_name:setString(UserData.User.szNickName)
    local uiText_names = ccui.Helper:seekWidgetByName(self.root,"Text_names")   
    uiText_names:setString(UserData.User.szRealName)
    if UserData.User.szRealName == "" then 
        uiText_names:setString("未认证")
    end 
   -- uiText_name:setString(string.format("昵称:%s",UserData.User.szNickName))
    local uiImage_sex = ccui.Helper:seekWidgetByName(self.root,"Image_sex")
    local uiText_id = ccui.Helper:seekWidgetByName(self.root,"Text_id")
    uiText_id:setString(string.format("ID:%d",UserData.User.userID))

    local uiButton_copy = ccui.Helper:seekWidgetByName(self.root,"Button_copy")    
    Common:addTouchEventListener(uiButton_copy,function()   
        local btnName = string.format("%d",UserData.User.userID)
        UserData.User:copydata(btnName)
        require("common.MsgBoxLayer"):create(0,nil,"复制成功")
    end)

    local uiText_sex = ccui.Helper:seekWidgetByName(self.root,"Text_sex")
    if UserData.User.cbGender == 1 then
        uiText_sex:setString("性别:男")
        uiImage_sex:loadTexture("user/user_b.png")
    else
        uiText_sex:setString("性别:女")
        uiImage_sex:loadTexture("user/user_g.png")
    end
    local addr = UserData.User.city 

    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   

    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   

    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008)))  

    print('刷新名片：', UserData.User.szErWeiMaLogo)
    local uiImage_mp = ccui.Helper:seekWidgetByName(self.root,"Image_mp")
    Common:requestErWeiMaPicture(UserData.User.szErWeiMaLogo, uiImage_mp)

    local uiButton_phone = ccui.Helper:seekWidgetByName(self.root,"Button_phone")
    local uiText_phone = ccui.Helper:seekWidgetByName(self.root,"Text_phone")
    if UserData.User.szPhone == "" then
        uiText_phone:setString("未绑定")
        uiButton_phone:loadTextures("newuser/bind.png","newuser/bind.png","newuser/bind.png")
    else
        uiText_phone:setString(UserData.User.szPhone)
        uiButton_phone:loadTextures("newuser/newuser_genhuan.png","newuser/newuser_genhuan.png","newuser/newuser_genhuan.png")
    end

    local uiButton_xianLiao = ccui.Helper:seekWidgetByName(self.root,"Button_xianLiao")
    local uiText_xianLiao = ccui.Helper:seekWidgetByName(self.root,"Text_xianLiao")
    if UserData.User.szXianLiaoCode == "" then
        uiText_xianLiao:setString("未绑定")
        uiButton_xianLiao:loadTextures("newuser/bind.png","newuser/bind.png","newuser/bind.png")
    else
        uiText_xianLiao:setString("已绑定")
        uiButton_xianLiao:loadTextures("newuser/newuser_genhuan.png","newuser/newuser_genhuan.png","newuser/newuser_genhuan.png")
    end

end

function UserInfoLayer:EVENT_TYPE_OPEN_PHOTO_ALBUM(event)
    local filePath = event._usedata
    local uiImage_mp = ccui.Helper:seekWidgetByName(self.root,"Image_mp")
    uiImage_mp:loadTexture("newuser/upload.png")
    local fp = io.open(filePath,"rb")
    if fp == nil then
        require("common.MsgBoxLayer"):create(0,nil,"上传失败!")
        return
    end
    local fileData = fp:read("*a")
    fp:close()
    
    local data = clone(UserData.Share.tableShareParameter[1])
    data.szShareUrl = string.format(data.szShareUrl,UserData.User.userID)
    UserData.User:requestUploadErWeiMa(data.szShareUrl,fileData)
end

function UserInfoLayer:EVENT_TYPE_UPLOAD_ERWEIMA(event)
    local data = event._usedata
    if data == "1" then
        require("common.MsgBoxLayer"):create(0,nil,"上传成功!")
        UserData.User:sendMsgUpdateUserInfo(1)
    else
        require("common.MsgBoxLayer"):create(0,nil,"上传失败!错误码："..data)
    end
end

--绑定闲聊
function UserInfoLayer:EVENT_TYPE_XIAN_LIAO_LOGIN(event)
    local xianLiaodata = event._usedata
    if xianLiaodata.err_code ~= 0 then
        return require("common.MsgBoxLayer"):create(0,nil,string.format("%s,错误码:%d",xianLiaodata.err_msg,xianLiaodata.err_code))
    end
    UserData.User:setUserInfo(4, xianLiaodata.data.openId)
end

function UserInfoLayer:SUB_CL_SET_USER_INFO(event)
    local data = event._usedata

    if data.wType == 3 then
        if data.wCode == 1000 then
            require("common.MsgBoxLayer"):create(0,nil,"手机绑定成功!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"该手机已被绑定,不能重复绑定!")
        end
    elseif data.wType == 4 then
        if data.wCode == 1000 then
            require("common.MsgBoxLayer"):create(0,nil,"闲聊账号绑定成功!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"该闲聊账号已被绑定,不能重复绑定!")
        end
    else
        require("common.MsgBoxLayer"):create(0,nil,"未知错误!")
    end

    if data.wCode == 1000 then
        UserData.User:sendMsgUpdateUserInfo(1) 
    end
end

function UserInfoLayer:EVENT_TYPE_BIND_PHONE(event)
    local data = event._usedata
    if data.code ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,data.Msg)
        return
    end

    self.phoneData = data
end

return UserInfoLayer
