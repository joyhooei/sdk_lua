-- ./launch/device_linux.lua
CLIENT_DIRECTORY = os.getenv('CLIENT_DIRECTORY') or '../win32_client/'

local device_base_obj = require 'launch.device_base'
local __device_linux = class( 'device_linux', device_base_obj )
function __device_linux:ctor()
    device_base_obj.ctor( self )
end

function __device_linux:push_notification(index)
end

function __device_linux:remove_all_notification()
end


function __device_linux:init()
    device_base_obj.init( self )

    --[[
    local winSize = CCDirector:sharedDirector():getWinSize()
    local layer_color = CCLayerColor:create( ccc4( 255, 255, 255, 255 ), winSize.width, winSize.height )
    self.root_scene_node:addChild( layer_color, 100 )

    local c_x, c_y = self:getCenterPos()

    local label = TLLabelRichTex:create( '10086xxyu', 50 )
    local r_size = label:getRealSize()
    label:setPosition( c_x - r_size.width / 2, c_y - r_size.height / 2 )
    layer_color:addChild( label )

    local label_2 = TLLabelRichTex:create( '思考积分垃圾法拉解放路', 50 )
    local r_size_2 = label_2:getRealSize()
    label_2:setPosition( c_x - r_size_2.width / 2, c_y - r_size_2.height / 2 - 60 )
    layer_color:addChild( label_2 )
    --]]
end

function __device_linux:setSearchPath()
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY )
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY .. 'images/' )
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY .. 'images/word/' )
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY .. 'images/icon/' )
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY .. 'images/body/' )
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY .. 'particles/textures/' )
    AssetsManager:sharedAssetsManager():addSearchPath( CLIENT_DIRECTORY .. 'mc/' )
end

function __device_linux:initBootCheckList( boot_check_name )
    for file_name in lfs.dir( CLIENT_DIRECTORY .. 'login/' ) do
        if string.find( file_name, 'boot_check' ) and get_extension( file_name ) == 'lua' then
            local require_file_name = 'login' .. '.' .. strip_extension( file_name )
            table.insert( boot_check_name, require_file_name )
        end
    end
end

function __device_linux:run()
    device_base_obj.run(self)
end

return __device_linux
