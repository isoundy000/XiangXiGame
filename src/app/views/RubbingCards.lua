local Bit = require("common.Bit")
local moveVertSource =
[[           
    attribute vec2 a_position;
    attribute vec2 a_texCoord;
    uniform float ratio; 
    uniform float radius; 
    uniform float width;
    uniform float height;
    uniform float offx;
    uniform float offy;
    uniform float rotation;
    varying vec2 v_texCoord;

    void main()
    {
       vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);
       tmp_pos = vec4(a_position.x, a_position.y, 0.0, 1.0);

       float halfPeri = radius * 3.14159; 
       float hr = height * ratio * 1.0;
       if(tmp_pos.x < 0.0 || tmp_pos.x > width || tmp_pos.y < 0.0 || tmp_pos.y > height)
       {
            tmp_pos.x = 0.0;
            tmp_pos.y = 0.0;
       }
       if(hr > 0.0 && hr <= halfPeri){
             if(tmp_pos.y < hr){
                   float rad = hr/ 3.14159;
                   float arc = (hr-tmp_pos.y)/rad;
                   tmp_pos.y = hr - sin(arc)*rad;
                   tmp_pos.z = rad * (1.0-cos(arc)); 
              }
       }
       if(hr > halfPeri){
            float straight = (hr - halfPeri)/2.0;
            if(tmp_pos.y < straight){
                tmp_pos.y = hr  - tmp_pos.y;
                tmp_pos.z = radius * 2.0; 
            }
            else if(tmp_pos.y < (straight + halfPeri)) {
                float dy = halfPeri - (tmp_pos.y - straight);
                float arc = dy/radius;
                tmp_pos.y = hr - straight - sin(arc)*radius;
                tmp_pos.z = radius * (1.0-cos(arc)); 
            }
        }
        float y1 = tmp_pos.y;
        float z1 = tmp_pos.z;
        float y2 = height;
        float z2 = 0.0;
        float sinRat = sin(rotation);
        float cosRat = cos(rotation);
        tmp_pos.y=(y1-y2)*cosRat-(z1-z2)*sinRat+y2;
        tmp_pos.z=(z1-z2)*cosRat+(y1-y2)*sinRat+z2;
        tmp_pos.y = tmp_pos.y - height/2.0*(1.0-cosRat);
        tmp_pos += vec4(offx, offy, 0.0, 0.0);
        gl_Position = CC_MVPMatrix * tmp_pos;
        v_texCoord = a_texCoord;

        v_texCoord.y = 1.0-v_texCoord.y;
    }
]]

local smoothVertSource =
[[
     attribute vec2 a_position; 
     attribute vec2 a_texCoord; 
     uniform float width; 
     uniform float height; 
     uniform float offx; 
     uniform float offy; 
     uniform float rotation; 
     varying vec2 v_texCoord; 

     void main() 
     { 
        vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0); 
        tmp_pos = vec4(a_position.x, a_position.y, 0.0, 1.0); 
        tmp_pos.x = width - tmp_pos.x; 
         if(tmp_pos.x < 0.0 || tmp_pos.x > width || tmp_pos.y < 0.0 || tmp_pos.y > height)
         { 
            tmp_pos.x = 0.0;
            tmp_pos.y = 0.0;
        } 
         float cl = height/5.0; 
         float sl = (height - cl)/2.0; 
         float radii = (cl/rotation)/2.0; 
         float sinRot = sin(rotation); 
         float cosRot = cos(rotation); 
         float distance = radii*sinRot; 
         float centerY = height/2.0; 
         float poxY1 = centerY - distance;
         float poxY2 = centerY + distance;
         float posZ = sl*sinRot;
         if(tmp_pos.y <= sl){ 
            float length = sl - tmp_pos.y;
            tmp_pos.y = poxY1 - length*cosRot;
            tmp_pos.z = posZ - length*sinRot;
         } 
         else if(tmp_pos.y < (sl+cl)){ 
            float el = tmp_pos.y - sl;
            float rotation2 = -el/radii; 
            float x1 = poxY1;
            float y1 = posZ;
            float x2 = centerY;
            float y2 = posZ - radii*cosRot;
            float sinRot2 = sin(rotation2);
            float cosRot2 = cos(rotation2);
            tmp_pos.y=(x1-x2)*cosRot2-(y1-y2)*sinRot2+x2;
            tmp_pos.z=(y1-y2)*cosRot2+(x1-x2)*sinRot2+y2;
         } 
         else if(tmp_pos.y <= height){ 
             float length = tmp_pos.y - cl - sl;
             tmp_pos.y = poxY2 + length*cosRot;
             tmp_pos.z = posZ - length*sinRot;
         } 
         tmp_pos += vec4(offx, offy, 0.0, 0.0); 
         gl_Position = CC_MVPMatrix * tmp_pos;
         v_texCoord = vec2(a_texCoord.x, a_texCoord.y);

         v_texCoord = a_texCoord;
         v_texCoord.x = 1.0 - v_texCoord.x;
     }
]]

local endVertSource =
[[
     attribute vec2 a_position; 
     attribute vec2 a_texCoord; 
     uniform float width; 
     uniform float height; 
     uniform float offx; 
     uniform float offy; 
     varying vec2 v_texCoord; 

     void main() 
     { 
        vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0); 
        tmp_pos = vec4(a_position.x, a_position.y , 0.0, 1.0); 
        tmp_pos.x = width - tmp_pos.x; 
        if(tmp_pos.x < 0.0 || tmp_pos.x > width || tmp_pos.y < 0.0 || tmp_pos.y > height){ 
            tmp_pos.x = 0.0;
            tmp_pos.y = 0.0;
        } 
         tmp_pos += vec4(offx, offy, 0.0, 0.0); 
         gl_Position = CC_MVPMatrix * tmp_pos; 
         v_texCoord = vec2(a_texCoord.x,a_texCoord.y); 

         v_texCoord = a_texCoord;

         v_texCoord.x = 1.0 - v_texCoord.x;
     }
]]

local strFragSource =
[[
    varying vec2 v_texCoord; 
     void main() 
     { 
        //TODO, 这里可以做些片段着色特效 
        gl_FragColor = texture2D(CC_Texture0, v_texCoord);
     }
]]


local RubbingCards = class("RubbingCards",cc.Node)

function RubbingCards:ctor(params)
    self.pokerHeight = 0 --扑克高
    self.pokerWidth = 0 --扑克宽
    self.posX = 0
    self.posY = 0
    self.ratioVal = 0
    self.radiusVal = 0
    local RubCardLayer_Pai = 3.141592
    self.RubCardLayer_State_Move = 0
    self.RubCardLayer_State_Smooth = 1
    self.RubCardLayer_RotationFrame = 10
    self.RubCardLayer_RotationAnger = RubCardLayer_Pai / 3
    self.RubCardLayer_SmoothFrame = 10
    self.RubCardLayer_SmoothAnger = RubCardLayer_Pai / 6
    self.state = self.RubCardLayer_State_Move
    self.showEndCall = params.showEndCall
    self:__setPrograms(params)
end

--
-- local params = {
--     frontPath = '', 前景
--     backPath = '', 背景
--     childPath = '', 牌值
--      childColor = ''，花色
--     pos = '',          位置信息
--     showEndCall = '' 结束回调
-- }

--设置参数
function RubbingCards:__setPrograms( params)
    self.layer = cc.LayerColor:create(cc.c4b(1, 14/255,14/255,14/255))
    local function onNodeEvent(event)
		if "exit" == event then
			self:destroy()
		end
    end
    self.posX = params.pos.x
    self.posY = params.pos.y
    self.frontPath = params.frontPath
    self.childPath = params.childPath
    self.childColor = params.childColor
    self.layer:registerScriptHandler(onNodeEvent)
    self:addChild(self.layer)
    self:__createTextures(self.frontPath,params.backPath,params.pos)
    self:__initTexAndPos(true)
    self:__initTexAndPos(false)
    self:__createGlNode(params.pos)
    self:__createAllProgram()
    self:__registTouchEvent()
end

--创建纹理
function RubbingCards:__createTextures( frontPath,backPath,pos )
    local Director = cc.Director:getInstance()

    local textureCache = Director:getTextureCache()
    local frontSprite = textureCache:addImage(frontPath .. '.png')
    local backSprite = textureCache:addImage(backPath .. '.png')

    self.pokerWidth = backSprite:getPixelsWide()
    self.pokerHeight = backSprite:getPixelsHigh()

    self.offx = self.posX - self.pokerWidth / 2
    self.offy = self.posY - self.pokerHeight / 2

    self.backSpriteId = backSprite:getName()
    self.frontSpriteId = frontSprite:getName()

	local WinSize = Director:getWinSize()
    self.touchStartY = WinSize.height / 2 + self.posY - self.pokerHeight / 2
    self.radiusVal = self.pokerHeight / 10 

    self.rect = cc.rect(pos.x-self.pokerWidth/2,pos.y - self.pokerHeight / 2,self.pokerWidth,self.pokerHeight)
end

function RubbingCards:__drawArrays(pos, tex)
    gl.glEnableVertexAttribs(Bit:_or(cc.VERTEX_ATTRIB_FLAG_TEX_COORDS, cc.VERTEX_ATTRIB_FLAG_POSITION))
    gl.bindBuffer(gl.ARRAY_BUFFER, pos)
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION, 2, gl.FLOAT, false, 0, 0)
    gl.bindBuffer(gl.ARRAY_BUFFER, tex)
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_TEX_COORD, 2, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.TRIANGLES, 0, self.posTexNum)
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)
end


function RubbingCards:__initTexAndPos(isBack)
    local nDiv = 100 --将宽分成100份
    local verts = {}--位置坐标
    local texs = {} --纹理坐标
    local dh = self.pokerHeight / nDiv
    local dw = self.pokerWidth

    --计算顶点位置
    for c=1,nDiv do
        local x = 0
        local y = (c - 1) * dh
        local quad = {}
        if isBack then
			quad = {x, y, x+dw, y, x, y+dh, x+dw, y, x+dw, y+dh, x, y+dh}
		else
            quad = {x, y, x, y+dh, x+dw, y, x+dw, y, x, y+dh, x+dw, y+dh}
		end

        for i=1,6 do
            local quadX = quad[i * 2-1]
            local quadY = quad[i * 2]
            local numX = 1-quadY / self.pokerHeight
            local numY = quadX / self.pokerWidth
           
            table.insert( texs, math.max(0, numY))
            table.insert( texs, math.max(0, numX))
        end

        for _,v in ipairs(quad) do
            table.insert(verts,v)
        end
    end

    local posBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, posBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, table.getn(verts),verts, gl.STATIC_DRAW)
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)

    local texBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, texBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, table.getn(texs),texs, gl.STATIC_DRAW)
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)

    self.posTexNum = table.getn(verts) / 2
    if isBack then
        self.backPosBuffer = posBuffer.buffer_id
        self.backTexBuffer = texBuffer.buffer_id
    else 
        self.frontPosBuffer = posBuffer.buffer_id
        self.frontTexBuffer = texBuffer.buffer_id
    end
end

function RubbingCards:isCanTouch(pos)
    -- local p = self.layer:convertToNodeSpace(pos)
    -- if cc.rectContainsPoint(self.rect, p) then
    --     return true
    -- end
    if self._isopen then
        return false
    end
    return true
end

--创建触摸层
function RubbingCards:__registTouchEvent( )
    local function touchBegin(touch, event)
        local Director = cc.Director:getInstance()
	    local WinSize = Director:getWinSize()
        local posNow = touch:getLocation()
        self.touchStartY = posNow.y
		return true
	end
    local function touchMove(touch, event)
        local location = touch:getLocation()

        if not self:isCanTouch(location) then
            return true
        end
        self.ratioVal = (location.y - self.touchStartY) / self.pokerHeight
        self.ratioVal = math.max(0, self.ratioVal)
        --self.ratioVal = math.min(1, self.ratioVal)
        if self.ratioVal >= 1.1 then
            self.state = self.RubCardLayer_State_Smooth
        end

		return true
	end
    local function touchEnd(touch, event)
        local location = touch:getLocation()

        if not self:isCanTouch(location) then
            return true
        end
        if self.ratioVal >= 1.1 then
            self.state = self.RubCardLayer_State_Smooth
        else
            self.state = self.RubCardLayer_State_Move
            self.ratioVal = 0
            self.radiusVal = 0
            self.smoothFrame = 1
        end
		return true
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(touchBegin, cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(touchMove, cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(touchEnd, cc.Handler.EVENT_TOUCH_ENDED )
	listener:setSwallowTouches(false)
	local eventDispatcher = self.layer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.layer)
end

function RubbingCards:__createGlNode(pos)
    gl.clear(gl.COLOR_BUFFER_BIT)
	gl.clear(gl.DEPTH_BUFFER_BIT)
    local glnode = gl.glNodeCreate()
    self.layer:addChild(glnode,100)
    self.glnode = glnode;
    self.smoothFrame = 1;
    self.isCreateNum = false;
    local function draw( transform, transformUpdated )

        if (self.state == self.RubCardLayer_State_Move) then
            self:__drawByMoveProgram(0,transform)
        elseif (self.state == self.RubCardLayer_State_Smooth) then
            if (self.smoothFrame <= self.RubCardLayer_RotationFrame) then
                self:__drawByMoveProgram(-self.RubCardLayer_RotationAnger * self.smoothFrame / self.RubCardLayer_RotationFrame,transform)
            elseif (self.smoothFrame < (self.RubCardLayer_RotationFrame + self.RubCardLayer_SmoothFrame)) then
                local scale = (self.smoothFrame - self.RubCardLayer_RotationFrame) / self.RubCardLayer_SmoothFrame
                self:__drawBySmoothProgram(math.max(0.1, self.RubCardLayer_SmoothAnger * (1 - scale)),transform)
            else 
                self:__drawByEndProgram(transform)
                if (not self._isopen) then
                    self._isopen = true
                    self:showOpenCard()
                end
            end
            self.smoothFrame = self.smoothFrame + 1
        end
    end
    glnode:registerScriptDrawHandler(draw)
end

function RubbingCards:__createProgram(vsource,fsource)
    local glProgram = cc.GLProgram:createWithByteArrays(vsource, fsource)
    glProgram:updateUniforms()
    return glProgram
end

function RubbingCards:__createAllProgram( )
    self.moveGlProgram = self:__createProgram(moveVertSource,strFragSource)
    self.smoothGlProgram = self:__createProgram(smoothVertSource,strFragSource)
    self.endGlProgram = self:__createProgram(endVertSource,strFragSource)
    self.moveGlProgram:retain()
    self.endGlProgram:retain()
    self.smoothGlProgram:retain()

    self.moveGlProgram.rotationLc = gl.getUniformLocation(self.moveGlProgram:getProgram(), "rotation")
    self.moveGlProgram.ratio = gl.getUniformLocation(self.moveGlProgram:getProgram(), "ratio")
    self.moveGlProgram.radius = gl.getUniformLocation(self.moveGlProgram:getProgram(), "radius")                                                          
    self.moveGlProgram.offx = gl.getUniformLocation(self.moveGlProgram:getProgram(), "offx")
    self.moveGlProgram.offy = gl.getUniformLocation(self.moveGlProgram:getProgram(), "offy")
    self.moveGlProgram.Height = gl.getUniformLocation(self.moveGlProgram:getProgram(), "height")
    self.moveGlProgram.Width = gl.getUniformLocation(self.moveGlProgram:getProgram(), "width")

    self.smoothGlProgram.rotationLc = gl.getUniformLocation(self.smoothGlProgram:getProgram(), "rotation")
    self.smoothGlProgram.offx = gl.getUniformLocation(self.smoothGlProgram:getProgram(), "offx")
    self.smoothGlProgram.offy = gl.getUniformLocation(self.smoothGlProgram:getProgram(), "offy")
    self.smoothGlProgram.Height = gl.getUniformLocation(self.smoothGlProgram:getProgram(), "height")
    self.smoothGlProgram.Width = gl.getUniformLocation(self.smoothGlProgram:getProgram(), "width")

    self.endGlProgram.offx = gl.getUniformLocation(self.endGlProgram:getProgram(), "offx")
    self.endGlProgram.offy = gl.getUniformLocation(self.endGlProgram:getProgram(), "offy")
    self.endGlProgram.Height = gl.getUniformLocation(self.endGlProgram:getProgram(), "height")
    self.endGlProgram.Width = gl.getUniformLocation(self.endGlProgram:getProgram(), "width")
end


function RubbingCards:__drawBySmoothProgram(rotation,transform)
    local glProgram = self.smoothGlProgram
    glProgram:use();
    glProgram:setUniformsForBuiltins(transform);

    gl.bindTexture(gl.TEXTURE_2D, self.frontSpriteId);
    glProgram:setUniformLocationF32(glProgram.rotationLc, rotation)
    glProgram:setUniformLocationF32(glProgram.offx, self.offx)
    glProgram:setUniformLocationF32(glProgram.offy, self.offy)
    glProgram:setUniformLocationF32(glProgram.Height, self.pokerHeight)
    glProgram:setUniformLocationF32(glProgram.Width, self.pokerWidth);

    self:__drawArrays(self.frontPosBuffer, self.frontTexBuffer)
end

function RubbingCards:__drawByMoveProgram(rotation,transform) 
    local glProgram = self.moveGlProgram
    gl.enable(gl.CULL_FACE)
    glProgram:use()
    glProgram:setUniformsForBuiltins(transform)
    glProgram:setUniformLocationF32(glProgram.rotationLc, rotation);
    glProgram:setUniformLocationF32(glProgram.ratio, self.ratioVal);
    glProgram:setUniformLocationF32(glProgram.radius, self.radiusVal);
    glProgram:setUniformLocationF32(glProgram.offx, self.offx);
    glProgram:setUniformLocationF32(glProgram.offy, self.offy);
    glProgram:setUniformLocationF32(glProgram.Height, self.pokerHeight);
    glProgram:setUniformLocationF32(glProgram.Width, self.pokerWidth);

    gl.bindTexture(gl.TEXTURE_2D, self.backSpriteId)
    self:__drawArrays(self.backPosBuffer, self.backTexBuffer)
    gl.bindTexture(gl.TEXTURE_2D, self.frontSpriteId)
    self:__drawArrays(self.frontPosBuffer, self.frontTexBuffer)
    gl.disable(gl.CULL_FACE)
end

function RubbingCards:__drawByEndProgram(transform) 
    local glProgram = self.endGlProgram
    glProgram:use()
    glProgram:setUniformsForBuiltins(transform)
    gl.bindTexture(gl.TEXTURE_2D, self.frontSpriteId);
    glProgram:setUniformLocationF32(glProgram.offx, self.offx)
    glProgram:setUniformLocationF32(glProgram.offy, self.offy)
    glProgram:setUniformLocationF32(glProgram.Height, self.pokerHeight)
    glProgram:setUniformLocationF32(glProgram.Width, self.pokerWidth)
    self:__drawArrays(self.frontPosBuffer, self.frontTexBuffer)
end

function RubbingCards:showOpenCard()
    --右上 数子
    local width = self.pokerWidth / 2
    local height = self.pokerHeight / 2

    local rf1 = self:createImage(self.childPath)
    rf1:setPosition(cc.p(self.posX + width - 33,self.posY+height - 25))
    rf1:setRotation(90)
    rf1:setScale(0.65)
    rf1:setOpacity(0)
    --右上 花色
    local rf2 = self:createImage(self.childColor)
    rf2:setPosition(cc.p(self.posX + width - 73,self.posY+height - 25))
    rf2:setRotation(90)
    rf2:setScale(0.65)
    rf2:setOpacity(0)

    --左下 数子
    local ld1 = self:createImage(self.childPath)
    ld1:setPosition(cc.p(self.posX -( width - 33),self.posY-(height - 25) ))
    ld1:setRotation(-90)
    ld1:setScale(0.65)
    ld1:setOpacity(0)

    --左下 花色
    local ld2 = self:createImage(self.childColor)
    ld2:setPosition(cc.p(self.posX -( width - 73),self.posY-(height - 25) ))
    ld2:setRotation(-90)
    ld2:setScale(0.65)
    ld2:setOpacity(0)

    rf1:runAction(cc.FadeIn:create(0.3))
    rf2:runAction(cc.FadeIn:create(0.3))
    ld1:runAction(cc.FadeIn:create(0.3))
    ld2:runAction(cc.FadeIn:create(0.3))

    if self.showEndCall then
        self.showEndCall()
    end
end

function RubbingCards:createImage(path)
    local image = ccui.ImageView:create(path .. '.png')
    self.layer:addChild(image,100)
    return image
end

function RubbingCards:destroy(  )
    gl._deleteBuffer(self.backPosBuffer)
    gl._deleteBuffer(self.backTexBuffer)
    gl._deleteBuffer(self.frontPosBuffer)
    gl._deleteBuffer(self.frontTexBuffer)
    self.moveGlProgram:release();
    self.smoothGlProgram:release();
    self.endGlProgram:release();
end

return RubbingCards