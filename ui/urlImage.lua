-- urlImage.lua

local loadingAnim = '60057/60057_10'

local loading_url_pool = {}

local function onPurge()
	for _, list in pairs(loading_url_pool) do
		for _, obj in ipairs(list) do
			if toCCNode(obj) then 
				obj:release()
			end
		end
	end
	loading_url_pool = {}
end

addPurgeSceneCallBackFunc( onPurge )

UrlImage = class('UrlImage', function() return CCSprite:create() end)

function UrlImage.create(url)
	local pRet = UrlImage.new()
	if pRet:initWithUrl(url) then
		return pRet
	else
		return nil
	end
end

function UrlImage:ctor()
end

function UrlImage:dtor()
end

function UrlImage:loadImage(url, tex_file_name, tex_full_path)
	os.remove(tex_full_path)

    local node_loading = createMovieClipWithName(loadingAnim)
    node_loading:play(0, -1, -1)
    self:addChild(node_loading)

    self:retain()
    if not loading_url_pool[url] then
    	loading_url_pool[url] = {}
        table.insert(loading_url_pool[url], self)

        TLHttpClient:sharedHttpClient():requestFile( url, '', function( content_data, http_code, error_code, error_msg )
        	if not loading_url_pool[url] then return end 
        	local executelist = loading_url_pool[url]
        	loading_url_pool[url] = nil
			if http_code == 200 then 
            	local file, err_msg = io.open( tex_full_path, 'wb' )
            	assert( file, tostring( err_msg ) .. ' - file open failed ' .. tex_full_path )
            	file:write( content_data )
            	file:close()

            	for _, image in ipairs(executelist) do
            		image:onLoadComplete()
            	end
            else
            	for _, image in ipairs(executelist) do
            		image:onLoadFaild(http_code)
            	end
            end
        end)
    else
        table.insert(loading_url_pool[url], self)
    end

    self.request_url    = url
    self.tex_file_name = tex_file_name
    self.tex_full_path = tex_full_path

    return true
end

function UrlImage:initWithUrl(url)
    local parts = url:split( '/' )
    local tex_file_name = parts[#parts]
    local tex_full_path = get_external_path() .. tex_file_name

    if CCFileUtils:sharedFileUtils():checkFileExists( tex_full_path, 0 ) then
		local frame = MCLoader:sharedMCLoader():loadSpriteFrame( tex_full_path )
		if frame then 
			self:setDisplayFrame(frame)
		else
			return self:loadImage(url, tex_file_name, tex_full_path)
		end
	else
		return self:loadImage(url, tex_file_name, tex_full_path)
	end

    return true
end

function UrlImage:onLoadComplete()
	if not toCCNode(self) then return end
	if self:retainCount() <= 1 then
		self:release()
	else
		--schedule_once( function()
			self:removeAllChildrenWithCleanup( true )
			local frame = MCLoader:sharedMCLoader():loadSpriteFrame( self.tex_full_path )
			if frame then
				self:setDisplayFrame(frame)
			else
				self:loadImage(self.request_url, self.tex_file_name, self.tex_full_path)
			end
			self:release()
		--end)
	end
end

function UrlImage:onLoadFaild()
	if not toCCNode(self) then return end
	self:release()
end
