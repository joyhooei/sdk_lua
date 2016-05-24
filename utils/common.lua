--./utils/common.lua
require 'utils.string'
require 'utils.table'
require 'utils.purge'


local all_circle_handles = {}

function getAllCircleHandleCount() return table.len( all_circle_handles ) end

function noop()
end

function getRenderTexture(node, size)
    local inTexture = CCRenderTexture:create(size.width, size.height)
    inTexture:begin()
    local scaleY = node:getScaleY()
    local x,y = node:getPosition()
    node:setPosition(x + size.width * 0.5,y + size.height * 0.5)
    node:setScaleY(-scaleY)
    node:visit()
    node:setPosition(x,y)
    node:setScaleY(scaleY)
    inTexture:endToLua()
    local tex = inTexture:getSprite():getTexture()
    tex:setAntiAliasTexParameters()
    return tex
end

loginout_show_notice = false

if CCDirector ~= nil then
    scheduler_type = {
        NORMAL = {
            schedule_handlers = {},
            scheduler = CCDirector:sharedDirector():getScheduler(),
        },
        PAUSE = {
            schedule_handlers = {},
            scheduler = CCDirector:sharedDirector():getPauseScheduler(),
        },
    }
end

local function get_scheduler_info_by_type( s_type )
    s_type = s_type or 'NORMAL'
    return scheduler_type[s_type]
end

-- 定义一个执行一次的定时器
function schedule_once( fn, s_type )
    return schedule_frames( 1, fn, s_type )
end

-- 定义一个延时执行一次的定时器
function schedule_once_time( time, fn, s_type )
    local scheduler_info = get_scheduler_info_by_type( s_type )

    local oneTimeFunction
    oneTimeFunction = scheduler_info.scheduler:scheduleScriptFunc( function()
        scheduler_info.scheduler:unscheduleScriptEntry(oneTimeFunction)
        scheduler_info.schedule_handlers[oneTimeFunction] = nil
		fn()
    end, time, false)
    scheduler_info.schedule_handlers[oneTimeFunction] = 0
    return oneTimeFunction
end

-- 定义一个可停止的循环定时器
function schedule_frames( n, fn, s_type )
    if n < 1 then return end

    local scheduler_info = get_scheduler_info_by_type( s_type )

    local oneTimeFunction
    oneTimeFunction = scheduler_info.scheduler:scheduleScriptFunc(function()
        if n==1 then
            scheduler_info.scheduler:unscheduleScriptEntry(oneTimeFunction)
            fn()
            all_circle_handles[oneTimeFunction] = nil
            scheduler_info.schedule_handlers[oneTimeFunction] = nil
        else
            n = n-1
        end
    end, 0, false)
    --all_circle_handles[oneTimeFunction] = debug.traceback()
    all_circle_handles[oneTimeFunction] = 1
    scheduler_info.schedule_handlers[oneTimeFunction] = 0
    return oneTimeFunction
end

-- 定义一个循环执行的定时器
function schedule_circle( time, fn, s_type, execute_immediately )
    local scheduler_info = get_scheduler_info_by_type( s_type )
    local oneTimeFunction = scheduler_info.scheduler:scheduleScriptFunc( fn, time, false )
    --all_circle_handles[oneTimeFunction] = debug.traceback()
    all_circle_handles[oneTimeFunction] = 1
    scheduler_info.schedule_handlers[oneTimeFunction] = 0
    if execute_immediately then fn() end
    return oneTimeFunction
end


-- 定义一个取消普通定时器的方法
function unCommonSchedule( handler, s_type )
    if not handler then return end

    local scheduler_info = get_scheduler_info_by_type( s_type )

    if not scheduler_info.schedule_handlers[handler] then return end

    scheduler_info.scheduler:unscheduleScriptEntry(handler)
    all_circle_handles[handler] = nil
    scheduler_info.schedule_handlers[handler] = nil
end

-- 定义一个释放普通定时器集合的方法
function releaseCommonSHandlers()
    for _,scheduler_info in pairs( scheduler_type ) do
        for oneTimeFunction,_ in pairs( scheduler_info.schedule_handlers ) do
            scheduler_info.scheduler:unscheduleScriptEntry(oneTimeFunction)
            all_circle_handles[oneTimeFunction] = nil
            scheduler_info.schedule_handlers[oneTimeFunction] = nil
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------
function animationtimerManager()
    local animationtimers = {}
    return {
        getAll = function()
            return animationtimers
        end,
        add = function(ani)
            animationtimers[ani] = 1
        end,
        delete = function(ani)
            animationtimers[ani] = nil
        end,
    }
end

animationtimerMgr = animationtimerManager()
function stopAllScroller()
    for ani ,_ in pairs(animationtimerMgr.getAll()) do
		local scheduler = CCDirector:sharedDirector():getPauseScheduler()
        scheduler:unscheduleScriptEntry(ani)
        animationtimerMgr.delete(ani) 
    end
end
------------------------------------------------------------------------------------------------------------------------------------------

-- 获取文件的扩展名
function get_extension( file_name )
    return file_name:match( '.+%.(%w+)$' )
end

function strip_extension( file_name )
    local idx = file_name:match( '.+()%.%w+$' )
    if idx then
        return file_name:sub( 1, idx - 1 )
    else
        return file_name
    end
end

function get_external_path()
    local storage = SystemConfig.getStorage()
    if storage == 'sdcard' then
        local sdcard = getSDCardPath()
        if sdcard ~= '' then return sdcard end
    end
    return CCFileUtils:sharedFileUtils():getWritablePath()
end

local LISTFILE = "filelist"
function load_file_list()
    local content_data = getExternalData( LISTFILE, 'rb' )
    if content_data then
        local file_list = protobuf.decode( 'config.FileList', content_data )
        --return file_list
        if file_list and file_list.pkg_version and file_list.pkg_version == getPackageVersion() then return file_list end
    end

    content_data = getPackageData( LISTFILE, 'rb' )
    if content_data then return protobuf.decode( 'config.FileList', content_data ) end
end

function write_file_list( file_data )
    local root = get_external_path()

    local temp_file_name = root .. LISTFILE .. '.tmp'

    local file = io.open( temp_file_name, 'wb' )
    file:write( protobuf.encode( 'config.FileList', file_data ) )
    file:close()

    os.rename( temp_file_name, root .. LISTFILE )
end

function get_device_id()
    if GameSettings.devicesID then return GameSettings.devicesID end
    return getDeviceId()
end

function getResourceVersionLua()
    local res_version = getResourceVersion()
    if res_version == '' then res_version = 'lol' end
    return res_version
end

-- 显示版本信息
function show_version(v)
    if getDeployPlatform()=='nd91' then
        return string.format('%.1f', v/100000)
    else
        if getDeployPlatform() == 'poem' then
            return getMetaData('CFBundleVersion')
        else
            return string.format('%.5f', v/100000)
        end
    end
end

function getVersion()
    if GameSettings.GameVersion then return GameSettings.GameVersion end
    local assetsManager = AssetsManager:sharedAssetsManager()
    return assetsManager:getVersion()
end

-- 获得部署的平台
function getDeployPlatform()
    local pkg = getPackageName()
    local parts = pkg:split('.')
    return parts[#parts]
end

-- 獲取增量文件list後綴
function getIncrementalFileSuffix() 
    local pkg = getPackageName()
    local parts = pkg:split('.')
    local suffix_str = parts[#parts]
    local format = tostring(getMetaData('YYGAME_FILE_FORMAT') or '')
    if format and format ~= '' then
        suffix_str = suffix_str ..'_' .. format
    end 
    return suffix_str
end


-- 判断是否是qq平台
function isQQPlatform()
    local plf = getDeployPlatform()
    return plf == 'qq' or plf == 'qqalone' or plf == 'qzone' or plf == 'qzonealone'
end


function md5_file_path(md5, url)
    local parts = url:split('/')
    local filename = parts[#parts]
    local parts = filename:split('.')
    local ext
    if #parts>1 then
        ext = parts[#parts]
    end
    local result = string.sub(md5, 1, 2) .. '/' .. string.sub(md5, 3)
    if ext then 
        result = result .. '.' .. ext
    end
    return result
end

function copy_point(p)
    return CCPoint(p.x, p.y)
end

function copy_rect(r)
    return CCRect(r.origin.x, r.origin.y, r.size.width, r.size.height)
end

function setbound(a, min, max)
    if a > max then
        return max
    elseif a < min then
        return min
    else
        return a
    end
end

-- 获取子窗体
function getChildWindow(p, i)
    local children = p:GetChildWindow()
    if children then
        return tolua.cast(children:objectAtIndex(i), 'TLWindow')
    end
end

-- 获取子node
function getChildNode(p, i)
    local children = p:getChildren()
    if children then
        return tolua.cast(children:objectAtIndex(i), 'CCNode')
    end
end

-- 转换成窗体
function toTLWindow(o)
    return tolua.cast(o, "TLWindow")
end

function toCCNode(o)
    return tolua.cast(o, "CCNode")
end

function toCCObject(o)
    return tolua.cast(o, "CCObject")
end

function toTLMoveObject(o)
	return tolua.cast(o, "TLMoveObject")
end

function toCCSprite(o)
	return tolua.cast(o, "CCSprite")
end

-- 先检查外部目录，再返回包里的目录
function getFullPath(url)
    local p = AssetsManager:sharedAssetsManager():getRealPath(url)
    local pp = CCFileUtils:sharedFileUtils():getWritablePath() .. p
    if CCFileUtils:sharedFileUtils():checkFileExists(pp, 0) then
        return pp
    else
        return CCFileUtils:sharedFileUtils():fullPathForFilename(p)
    end
end

local _current_music
local _bMusicMute = nil
local _bEffectMute = nil

-- 设置音乐路径
function set_music( path, bloop )
    if path == _current_music then return end

    if path then		
        _current_music = path
        if not _bMusicMute then
            setAlterMusicPlayer( false )
            SimpleAudioEngine:sharedEngine():playBackgroundMusic( getFullPath( path ), bloop )
        end
    end
end

-- 停止播放音乐
function stop_music()
    _current_music = nil
    setAlterMusicPlayer( false )
    SimpleAudioEngine:sharedEngine():stopBackgroundMusic( true )
end

function pause_music()
    setAlterMusicPlayer( false )
    SimpleAudioEngine:sharedEngine():pauseBackgroundMusic()
    setAlterMusicPlayer( true )
    SimpleAudioEngine:sharedEngine():pauseBackgroundMusic()
end

function resume_music()
    if not _bMusicMute then
        setAlterMusicPlayer( false )
        SimpleAudioEngine:sharedEngine():resumeBackgroundMusic()
        setAlterMusicPlayer( true )
        SimpleAudioEngine:sharedEngine():resumeBackgroundMusic()
    end
end

function play_long_effect( path, loop )
    if getPlatform() == 'android' or getPlatform() == 'ios' then
        if not _bEffectMute then
            setAlterMusicPlayer( true )
            SimpleAudioEngine:sharedEngine():playBackgroundMusic( getFullPath( path ), loop or false )
            return path
        end
    else
        return play_effect( path, loop )
    end
end

function stop_long_effect( handle )
    if getPlatform() == 'android' or getPlatform() == 'ios' then
        setAlterMusicPlayer( true )
        SimpleAudioEngine:sharedEngine():stopBackgroundMusic( true )
    else
        stop_effect( handle )
    end
end

-- 播放音效 path表示路径，loop是循环次数
function play_effect( path, loop )
    if not _bEffectMute then
        return SimpleAudioEngine:sharedEngine():playEffect( getFullPath( path ), loop or false )
    end
end

-- 停止音效
function stop_effect( handle )
    SimpleAudioEngine:sharedEngine():stopEffect( handle )
end

function stop_all_effect()
    SimpleAudioEngine:sharedEngine():stopAllEffects()

    setAlterMusicPlayer( true )
    SimpleAudioEngine:sharedEngine():stopBackgroundMusic( true )
end

-- 设置音量大小
function set_music_volume( value )
    setAlterMusicPlayer( false )
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume( value )
end

-- 设置音效大小
function set_effect_volume( value )
    setAlterMusicPlayer( true )
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume( value )

    SimpleAudioEngine:sharedEngine():setEffectsVolume( value )
end

-- 设置音乐开关
function set_music_mute( bMute )
	if _bMusicMute == bMute then return end

	_bMusicMute = bMute
    SystemConfig.setBGMusic( _bMusicMute )

    setAlterMusicPlayer( false )
	if bMute then
		SimpleAudioEngine:sharedEngine():stopBackgroundMusic()
	else
		if _current_music then SimpleAudioEngine:sharedEngine():playBackgroundMusic( getFullPath( _current_music ), true ) end
	end
end

function get_music_mute()
    return _bMusicMute
end

-- 设置音效开关
function set_effect_mute( bMute )
	if _bEffectMute == bMute then return end

	_bEffectMute = bMute
	SystemConfig.setSoundEffect( _bEffectMute )

	if bMute then stop_all_effect() end
end

function get_effect_mute()
    return _bEffectMute
end

-- 获得日，时分秒
function getDayHourMinSecondByTime( time )
    if not time or time <= 0 then 
        return 0,0,0,0
    end
    local day = math.floor( time/24/3600 )
    local hour = math.floor( (time - day * 24*3600)/ 3600 )
    local temp = time - day*24*3600 - 3600*hour
    local min = math.floor( temp / 60 )
    local second = math.floor( time % 60 )

    return day,hour,min,second
end

-- 获得日，时分秒字符串
function getDayHourMinSecondByTimeStr( time )
	if not time then return "" end
    local day = math.floor( time/24/3600 )
	if day > 0 then return day.._YYTEXT('天') end
    local hour = math.floor( (time - day * 24*3600)/ 3600 )
	if hour > 0 then return hour.._YYTEXT('小时') end
    local temp = time - day*24*3600 - 3600*hour
    local min = math.floor( temp / 60 )
	if min > 0 then return min.._YYTEXT('分钟') end
    local second = math.floor( time % 60 )
	if second > 0 then return second.._YYTEXT('秒') end
    return ""
end
function getDayHourMinSecondByTimeStr1( time )
	if not time then return "" end
    local day = math.floor( time/24/3600 )
	if day > 0 then return day.._YYTEXT('天') end
    local hour = math.floor( (time - day * 24*3600)/ 3600 )
	if hour > 0 then return hour.._YYTEXT('小时') end
    local temp = time - day*24*3600 - 3600*hour
    local min = math.floor( temp / 60 )
	if min > 0 then return min.._YYTEXT('分钟') end
    local second = math.floor( time % 60 )
	if second > 0 then return _YYTEXT('<1分钟') end
    return ""
end

-- 获得时分秒
function getHourMinSecondByTime( time )
    local second = math.floor( time % 60 )
    local hour = math.floor( time / 3600 )
    local temp = time - 3600 * hour
    local min = math.floor( temp / 60 )

    return hour,min,second
end

-- 获得时分秒 通过系统时间
function getHourMinSecondByOSTime(ostime)
    local hour = os.date("%H",ostime)
    local min = os.date("%M",ostime)
    local sec = os.date("%S",ostime)
    return hour,min,sec
end


local artNumberSpriteResName = {
    ['pvp']       = 'word_uu0',
}

local function getStr2pngIndex(chr)
    if chr == '-' then return '10' end
    if chr == '+' then return '11' end
    if chr == 'x' then return '12' end
    if chr == '.' then return '13' end
    return '0'.. chr
end

function getArtNumberString( str, type, scale, shader_name )
    local scale_text = scale and string.format( ',scale=%f', scale ) or ''
    local shader_text = shader_name and string.format( ',shader_name="%s"', shader_name ) or ''

    local typeName = artNumberSpriteResName[type] or ''

    local ret = ''
    for _,s in ipairs( string.toArray( str ) or {} ) do
        local sprite_text = string.format( 'fileName="%s.png"', typeName .. getStr2pngIndex( s ) )
        ret = ret .. string.format( '[sprite:%s%s%s]', sprite_text, scale_text, shader_text )
    end

    return ret
end

function removeUnusedTextures( enforce )
    -- 强制清理的话，就一定会清理
    -- 不强制的话，只要当前可用内存大于 100 M，就不会执行清理
    if enforce then
        ParticleSystemManager:sharedParticleSystemManager():cleanupCache()
        CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
        CCTextureCache:sharedTextureCache():removeUnusedTextures()

        return
    end

    if getAvailMemory and tonumber( getAvailMemory() ) >= 100 then return end

    ParticleSystemManager:sharedParticleSystemManager():cleanupCache()
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
    CCTextureCache:sharedTextureCache():removeUnusedTextures()
end


function dumpall(msg)
    CCLuaLog( 'dump:' .. tostring( msg ) )
    dump_rusage()
    dump_texture()
    CCLuaLog('lua:'..collectgarbage('count'))
end

function show_money(v)
    local text = ''
    if v > 10000 then
        local temp = math.floor( v / 10000 )
        text = temp .. _YYTEXT('万')
    else
        text = '' .. v
    end
    return text
end

-- 获取国际移动用户识别码
function get_imsi()
    if getIMSI then
        return getIMSI()
    else
        return ''
    end
end

if getSDCardPath==nil then
    function getSDCardPath()
        return ''
    end
end

-- 向量相加
function pointAdd(p1, p2)
    local p = {x = p1.x + p2.x, y = p1.y + p2.y}
    return p
end

-- 向量相减
function pointDec(p1, p2)
    local p = {x = p1.x - p2.x, y = p1.y - p2.y}
    return p
end

-- 向量缩放
function pointScale(p, scale)
    local r = {x = p.x * scale, 
               y = p.y * scale}
    return r
end

function pointClone(p)
    local r = {x = p.x, y=p.y}
    return r
end

-- 获得向量长度
function pointLen(p)
    return math.sqrt(p.x * p.x + p.y * p.y)
end

-- 返回单位向量
function pointNormalize(p)
    local vlen = pointLen(p)
    if vlen == 0 then return {x=0, y=1} end
    return {
        x = p.x / vlen,
        y = p.y / vlen,
    }
end

-- 向量点乘
function pointDot(p1, p2)
    return p1.x * p2.x + p1.y * p2.y
end

-- 向量叉乘
function pointCross(p1, p2)
    return p1.x * p2.y - p1.y * p2.x
end

--- 判断向量2是否是在向量1的左边 (向量平行都算右边)(右手法制)
-- @param v1 向量1 格式 {x=,y=}
-- @param v2 向量2 格式 {x=,y=}
-- @return bool 是否是左边
function getVectorIsLeft(v1, v2)
    return pointCross(v1, v2) > 0
end

--- 获得向量1的与向量2的夹角, 正数表示向右转, 负数表示向左转 (夹角单位:角度[-180,180])
-- @param v1 向量1
-- @param v2 向量2
-- @param 返回角度 [-180,180]
function getVectorAngle(v1, v2)
    local n1 = pointNormalize(v1)
    local n2 = pointNormalize(v2)
    local cosV = pointDot(n1,n2)  -- 点乘求得cos(夹角)
    local angleV = math.acos(cosV)    -- 这里返回的是弧度
    angleV = angleV / math.pi * 180 -- 转换成角度

    if getVectorIsLeft(v1, v2) then
        angleV = -angleV
    end
    return angleV
end

--带回调的异步载入贴图
--@param: resid     贴图资源ID
--@param: type      贴图类型，位置枚举
--@param: callback  回调，回调时可获得异步加载贴图的size
function loadIcon( resid, type , callback )
    local m = {
		icon = 'icon/%d.png',
		bust = 'bust/%d.png',
		head = 'head/%d.png',
		body = 'body/%d.png',
		none = '%s.png',
	}
	local name = string.format( m[type] or "icon/%d.png", resid )
    return MCLoader:sharedMCLoader():loadSpriteAsyncCallback( name, callback or function() end )
end

function GetSdkTypeLua()
    if GameSettings.sdkType ~= nil then return GameSettings.sdkType end
    return GetSdkType()
end

-- 金钱转文字
function moneyTransformToString( count )
    if count >= 10000 then
        local temp = math.floor( count / 10000 )
        return temp .. 'w'
    else
        return tostring( count )
    end
end

function getWinRealSize()
    local width, height, _, scale = g_device_obj:getDesignSize()

    return {
        width = width/scale,
        height = height/scale,
    }
end

-- 简单的震屏
local zuni_param = 0.4
local shake_speed = 51.1
local attenuation_speed = 0.9
--[[
local shock_info = {
    zuni_param = 0.4,
    shake_speed = 51.1,
    attenuation_speed = 0.9,
    time = 0.5,
    amplitude_x = 20,
    amplitude_y = 25,
}
--]]
function simple_shock( shock_info, update_call_back_func )
    local shock_handle = nil

    local start_time = TLWindowManager:SharedTLWindowManager():getWorldTime()
    local current_angle = 0
    local current_zuni = shock_info.zuni_param or zuni_param
    shock_handle = schedule_circle( 0, function()
        local t = TLWindowManager:SharedTLWindowManager():getWorldTime() - start_time
        if t >= ( shock_info.time or 0.5 ) then
            unCommonSchedule( shock_handle )

            update_call_back_func( 0, 0, true )

            return
        end

        local sin_param = math.sin( current_angle )
        local offset_x = sin_param * ( shock_info.amplitude_x or 20 ) * current_zuni
        local offset_y = sin_param * ( shock_info.amplitude_y or 25 ) * current_zuni
        update_call_back_func( offset_x, offset_y, false )

        if t >= 0.08 then current_zuni = current_zuni * ( shock_info.attenuation_speed or attenuation_speed ) end

        current_angle = t * ( shock_info.shake_speed or shake_speed )
    end)

    return shock_handle
end

function node_simple_shock( node, shock_info, update_call_back_func )
    local node_shock_handle = nil

    local start_time = TLWindowManager:SharedTLWindowManager():getWorldTime()
    local current_angle = 0
    local current_zuni = shock_info.zuni_param or zuni_param
    node_shock_handle = node:tweenFromTo( LINEAR_IN, NODE_PRO_CUSTOM, 0, 1000000, 0, 0, 1, -1, nil, function( value )
        local t = TLWindowManager:SharedTLWindowManager():getWorldTime() - start_time
        if t >= ( shock_info.time or 0.5 ) then
            node:removeTween( node_shock_handle )

            update_call_back_func( 0, 0, true )

            return
        end

        local sin_param = math.sin( current_angle )
        local offset_x = sin_param * ( shock_info.amplitude_x or 20 ) * current_zuni
        local offset_y = sin_param * ( shock_info.amplitude_y or 25 ) * current_zuni
        update_call_back_func( offset_x, offset_y, false )

        if t >= 0.08 then current_zuni = current_zuni * ( shock_info.attenuation_speed or attenuation_speed ) end

        current_angle = t * ( shock_info.shake_speed or shake_speed )
    end)

    return node_shock_handle
end

function pairsConfigWithSlices(config, cmpfunc)
    local allSlices = config:getAllSlices()
    local tbl = {}
    local i = 0
    local cmpfunc = cmpfunc or function(a, b)
        return a.key < b.key
    end
    for _, slice in pairs(allSlices or {}) do
        table.foreach(slice, function(k, v) return table.insert(tbl, {key = k, value = v}) end)
    end
    table.sort(tbl, cmpfunc)
    return function()
        i = i + 1
        if i > #tbl then return end
        return tbl[i].key, tbl[i].value
    end
end

function getLenOfConfigWithSlices(config)
    local allSlices = config:getAllSlices()
    local len = 0
    for _, slice in pairs(allSlices or {}) do
        len = len + table.len(slice)
    end
    return len
end

function _YYTEXT( s )
    return s
end
