-----------------------------------------------------------------------------------------------
-- Instructions
-----------------------------------------------------------------------------------------------
-- This script works with Smart Thermostat. It is a time script (Domoticz runs it every
-- minute) that checks if the temperature sensor signals are being received. If no signal is
-- received for a certain group, it turns off all radiator devices of that group. This
-- prevents radiators staying on because of the temperature sensor failing.

-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
-- Define the lost signal delay
local lostsignaldelay = 1200 -- 20 minutes
-- Define a delay between two repeat commands, for devices without return receipt
local repeatdelay = 600 -- 10 minutes



-----------------------------------------------------------------------------------------------
-- NOTHING SHOULD NEED TO CHANGE BELOW THIS LINE
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------------------------------

commandArray = {}

function debuglog (s)
	if uservariables['Debug'] == 1 then print('Lost Signal '..gn..': '.. s) end
	return true
end

function timedifference (s)
	year = string.sub(s, 1, 4)
	month = string.sub(s, 6, 7)
	day = string.sub(s, 9, 10)
	hour = string.sub(s, 12, 13)
	minutes = string.sub(s, 15, 16)
	seconds = string.sub(s, 18, 19)
	t1 = os.time()
	t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
	difference = os.difftime (t1, t2)
	return difference
end

function state (rt,ref) -- compare first radiator device state with a reference (On or Off)
    if(rt[1]:sub(3,3)~='i') then
        return otherdevices[rt[1]]==ref
    else
        return otherdevices[rt[1]]~=ref
    end
end

function switch (rt,order) -- switches all radiator devices in table according to order (On or Off)
    local i=1
    while i  <= n do
        if(rt[i]:sub(3,3)~='i') then
            commandArray[rt[i]] = order
        else
            if(order == 'On') then
                commandArray[rt[i]] = 'Off'
            else
                if (order == 'Off') then
                    commandArray[rt[i]] = 'On'
                end
            end
        end
        debuglog(rt[i]..' switching '..order)
        i = i+1
    end
    return true
end

-----------------------------------------------------------------------------------------------
-- Lost Signal algorithm
-----------------------------------------------------------------------------------------------

local dc
local vc

for dc, vc in pairs(otherdevices) do
    local dcs=tostring(dc)
    if (dcs:sub(1,1) == 'T') then -- if device changed is a temperature sensor
        local l -- length to obtain device changed name
        if (dcs:find('_') == nil) then l=dcs:len() else l=dcs:find('_')-1 end
        local tcn=dcs:sub(1,l) -- temperature changed name

        gn=tcn:sub(3) -- group name
    
        local rd = {} -- radiator devices (table)
        n = 1
        while n  < 10 do -- check the number or radiators and their status (normal or inverted) - maximum 9 devices (1 digit)
            rd[n]='R'..n..'-'..gn
            if(otherdevices[rd[n]]~=nil) then
                n = n+1
            else
                rd[n]='R'..n..'i-'..gn
                if(otherdevices[rd[n]]~=nil) then
                    n = n+1
                else
                    n = n-1
                    break
                end
            end
        end

        if (n>0) then -- check if radiator devices are present
            debuglog('RD present')
            if( timedifference(otherdevices_lastupdate[dc]) > lostsignaldelay ) then -- check to see if command delay is OK
                debuglog('Temperature signal lost since '..timedifference(otherdevices_lastupdate[dc])..'s')
                debuglog('Turning Radiator Off')
                if (state(rd,'On')) then -- if radiators are On, switch to Off according to delay
                    debuglog('Turning Radiator Off')
                    switch(rd,'Off')
                else -- if radiators are Off, repeat Off command according to delay
                    if( timedifference(otherdevices_lastupdate[rd[1]]) > repeatdelay) then -- check to see if repeat delay is OK
                        debuglog('Repeating Radiator Off')
                        switch(rd,'Off')
                    else
                        debuglog('Not enough time before repeat command: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. repeatdelay .. 's')
                    end
                end
            end
        else
            debuglog('RD missing') -- no action
        end
    end
end
