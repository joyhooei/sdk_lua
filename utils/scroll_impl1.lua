--./utils/scroll_impl1.lua
-- 滚动算法
function scroll_impl()
    local bounceheight = 50.0
    local translatedmousedownpoint
    local currentmousepoint
    local velocity = 0
    local position = 0
    local returntobaseconst = 3.0
    local decelerationconst = 1000.0
    local bouncedecelerationconst = 3500.0
    local range_min = 0
    local range_max = 0
    local targetpoint

    local obj = {
        start_animation = nil,  -- 注册update
        stop_animation = nil,   -- 取消注册
        set_position = nil,     -- 设置容器位置
        isEnable = true,
        mousedownpoint = nil,
    }

	function obj.getPosition() 
		return position
	end

	function obj.setPosition(pos)
		position = pos
	end

    -- 运行时调整边界
    function obj:set_range(min, max)
        range_min = min
        range_max = max
        if position > range_max+bounceheight then
            position = range_max
        elseif position < range_min-bounceheight then
            position = range_min
        end
    end
    function obj.update(animationtimestep)
        if animationtimestep==0 then
            return
        end
        local oldvelocity = velocity;

        -- If mouse is still down, just scroll instantly to point
        if obj.mousedownpoint~=nil then
            -- First assume not beyond limits

            local displacement = currentmousepoint - translatedmousedownpoint;
            velocity = 0.2*oldvelocity + 0.8*(displacement / animationtimestep);
            translatedmousedownpoint = currentmousepoint;

            -- If scrolled beyond top or bottom, dampen velocity to prevent going 
            -- beyond bounce height
            if (position > range_max and velocity > 0) or ( position < range_min and velocity < 0) then
                local displace = position > range_max and position-range_max or range_min-position
                if displace > bounceheight then
                    displace = bounceheight
                end
                velocity = velocity * (1.0 - displace/bounceheight);
            end
        else
            if targetpoint~=nil then
                if math.abs(position-targetpoint)<1 and math.abs(velocity)<1 then
                    targetpoint = nil
                    velocity = 0
                elseif (position > targetpoint and velocity>0) or (position < targetpoint and velocity<0) then
                    -- Slow down in order to turn around
                    local displace = math.abs(position-targetpoint)
                    if displace > bounceheight then
                        displace = bounceheight
                    end
                    velocity = velocity * (1.0 - displace/bounceheight);
                else
                    -- return to target position
                    velocity = returntobaseconst * (targetpoint - position)
                end
            elseif position > range_max+1 then
                targetpoint = range_max
            elseif position < range_min-1 then
                targetpoint = range_min
            else
                -- Free scrolling. Decelerate gradually.
                local changevelocity = decelerationconst * animationtimestep;
                if changevelocity > math.abs(velocity) then
                    velocity = 0;
                    obj:stop_animation();
                else
                    velocity = velocity - (velocity > 0 and 1 or -1) * changevelocity;
                end
            end
        end

        -- Update position
        local delta = velocity * animationtimestep
        position = position + delta;
        if math.abs(delta)<0.1 then
            velocity = 0
        end

        obj:set_position(position)
    end

    function obj:free_scroll_target()
        return position+velocity
    end

    function obj.touchbegin(p)
        targetpoint = nil
        obj.mousedownpoint = p
        currentmousepoint = obj.mousedownpoint
        translatedmousedownpoint = obj.mousedownpoint
        obj:stop_animation()
        obj:start_animation()
    end
    function obj.touchend(p)
        obj.scrollto(obj:free_scroll_target())
    end
    function obj.touchmove(p)
        if obj.mousedownpoint==nil then
            return
        end
        currentmousepoint = p
    end
    function obj.scrollto(p)
        if p>range_max then
            targetpoint = range_max
        elseif p<range_min then
            targetpoint = range_min
        else
            targetpoint = p
        end
        obj.mousedownpoint = nil
        currentmousepoint = nil
        translatedmousedownpoint = nil
    end
    function obj:reset_position(p)
        position = p
    end
    function obj:get_velocity()
        return velocity
    end
    return obj
end
