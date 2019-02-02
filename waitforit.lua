_addon.name    = 'waitforit'
_addon.author  = 'Mujihina'
_addon.version = '1.0'
_addon.command = 'waitforit'
_addon.commands = {'wfi'}

require ('luau')
texts = require ('texts')
days = require('resources').days

local enable_mode = false
local wait_type = nil
local wait_day = nil
local wait_min = nil
local wait_timer = nil
local text_object = nil


function load()
	create_time_object()
end

-- Show syntax
function show_syntax()
	print('wfi: Syntax is:')
	print('    wfi status: Show status')
	print('    wfi stop: Stop waiting.')
	print('    wfi tomorrow: alert when day changes')
	print('    wfi day <DAY>: alert when specific day happens')
	print('    wfi timer <mins>: alert after <min> minutes')
end

function alert(msg)
	msg = msg or ''
	windower.send_command('input /p %s <call10>':format(msg))
end

function create_time_object()
	local settings = {
		pos = { x=(windower.get_windower_settings().ui_x_res / 2) - 50, y=300},
		text = { font='Consolas', size=15, alpha=255, red=255, green=0, blue=255},
		bg = { alpha=200, red=0, green=0, blue=0, visible=true },
		flags = { draggable=true, bold=true},
	}
	text_object = texts.new("${mins|0|%.2d}mins ${secs|0|%.2d}secs", settings)
	text_object:hide()
end

function get_min_secs()
	local mins = 0
	local secs = 0
	if wait_timer then
		local diff = wait_timer - os.time()
		mins = diff / 60
		secs = diff % 60
	end
	return {mins=mins, secs=secs}
end

function tick()
	if enable_mode and wait_type == 'timer' then
		local now = os.time()
		if now >= wait_timer then
			enable_mode = false
			wait_type = nil
			text_object:hide()
			alert("It's been at least %d mins since my last cookie!!!":format(wait_min))
			return
		end
		text_object:update(get_min_secs())
	end
end

function day_change(new, old)
	if enable_mode then
		if wait_type == 'next_day' then
			enable_mode = false
			wait_type = nil
			alert('Tomorrow is no longer a day away!!')
		end
		if wait_type == 'weekday' and new == wait_day then
			enable_mode = false
			wait_type = nil
			alert("It's finally %s!!!!":format(days[wait_day].name))
		end
	end
end

function wfi_command (cmd, args)
    if (not cmd or cmd == 'help' or cmd == 'h') then
        show_syntax()
        return
    end    
    if cmd == 'stop' then
        print ("wfi: Stopping")
        enable_mode = false
        return
    end    
	if cmd == 'status' then
		if not enable_mode then
			print('wfi: Currently not enabled')
			return
		end
		if wait_type == 'next_day' then
			print('wfi: Alert is set for next day')
		elseif wait_type == 'timer' then
			print('wfi: Alert is set for %d minutes':format(wait_min))
			local diff = get_min_secs()
			print('wfi: Time remaining is %s':format(diff.mins, diff.secs))
		elseif wait_type == 'weekday' then
			print('wfi: Alert is set for %s':format(days[wait_day].name))
		end
		return
	end
    if cmd == 'tomorrow' then
    	if wait_type then
    		print('wfi: replacing existing alert')
    		text_object:hide()
    	end
    	print('wfi: setting alert for next day')
        wait_type = 'next_day'
        enable_mode = true
        return
    end
        
    -- Need more args from here on
    if (not args or args:length() < 1) then
        show_syntax()
        return
    end
    
    local input = args:lower():spaces_collapse()
    
    if cmd == 'timer' then
    	if not windower.regex.match(input, "^[0-9]+$") then
    		print('wfi: invalid timer input! Use numbers!')
    		return
    	end
    	input = tonumber(input)
    	if input < 1 then
  			print('wfi: timer input must be greater than zero')
  			return
  		end
    	if wait_type then
    		print('wfi: replacing existing alert')
    		text_object:hide()
    	end
    	print('wfi: setting alert for %d minutes':format(tonumber(input)))
    	wait_min = input
    	wait_type = 'timer'
    	wait_timer = os.time() + (input * 60)
		text_object:update(get_min_secs())
		text_object:show()
    	enable_mode = true
    	return
    end
    
    if cmd == 'day' then
    	for _, day in ipairs(days) do
    		if input == day.name:lower() then
		    	if wait_type then
    				print('wfi: replacing existing alert')
    				text_object:hide()
    			end
    			wait_type = 'weekday'
    			wait_day = day.id
    			enable_mode = true
    			print('wfi: setting alert for %s':format(day.name))
    			return
    		end
    	end
    	print('wfi: bogus day of the week provided')
    	return
    end
    
    show_syntax()
end


-- Register callbacks
windower.register_event ('load', load)
windower.register_event('addon command', wfi_command)
windower.register_event('time change', tick)
windower.register_event('day change', day_change)
