-----------------------------------------------------------------------------------------------
-- Instructions
-----------------------------------------------------------------------------------------------
-- This script is a Smart Thermostat, that needs 4 device types for each group. It can manage
-- multiple groups, e.g. Living Room, Kitchen, Bath Room. Group names must not contain the
-- character '_'.
-- 1. A physical temperature sensor, named 'T-groupname', e.g. 'T-Kitchen'.
-- 2. A virtual switch to turn the heating on or off, named 'H-groupname', e.g. 'H-Kitchen'.
-- 3. A virtual setpoint device to set the target temperature, named 'S-groupname', e.g.
--    'S-Kitchen'.
-- 4. Up to nine physical radiator switches, that can be inverted or not (useful in France for
--    'fil pilote' command of radiators), named 'R1-groupname' to 'R9-groupname', or
--    'R1i-groupname' to 'R9i-groupname' for inverted switches. Ordinary and inverted switches
--    can be mixed, e.g. 'R1-Kitchen', 'R2i-Kitchen' and 'R3-Kitchen'.
-- 5. A User Variable 'Debug', Integer and set to 1 or 0 to show or hide entries in the log.

-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
--  Define a delay between command switches, to prevent multiple quick changes
local commanddelay = 120 -- 2 minutes
--  Define a delay between two repeat commands, for devices without return receipt
local repeatdelay = 600 -- 10 minutes



-----------------------------------------------------------------------------------------------
-- NOTHING SHOULD NEED TO CHANGE BELOW THIS LINE
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------------------------------

commandArray = {}

function debuglog (s)
	if uservariables['Debug'] == 1 then print('Thermostat '..gn..': '.. s) end
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
      elseif(order == 'Off') then
        commandArray[rt[i]] = 'On'
      end
    end
    debuglog(rt[i]..' switching '..order)
    i = i+1
  end
  return true
end

-----------------------------------------------------------------------------------------------
-- Thermostat algorithm
-----------------------------------------------------------------------------------------------

local dc=next(devicechanged)
local dcs=tostring(dc) -- device changed string

if (dcs:sub(1,1) == 'T') then -- if device changed is a temperature sensor
  local l -- length to obtain device changed name
  if (dcs:find('_') == nil) then l=dcs:len() else l=dcs:find('_')-1 end
  local tcn=dcs:sub(1,l) -- temperature changed name
  local vc=otherdevices_svalues[tcn] -- value changed
  local vcs=tostring(vc) -- value changed string

  gn=tcn:sub(3) -- group name

  local hd='H-'..gn -- heating device
  local sd='S-'..gn -- setpoint device
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

  if (otherdevices[hd]~=nil and otherdevices[sd]~=nil and n>0) then -- check if all devices needed for thermostat are present
    debuglog('HD and SD and RD OK')
    local st = tonumber(otherdevices_svalues[sd]) -- setpoint temperature
    local ct = tonumber(vcs:sub(1,4)) -- current temperature
    debuglog('Setpoint = ' .. tostring(st) .. ' - Current = ' .. tostring(ct))
    if ((otherdevices[hd]=='On') and (ct < st)) then -- conditions for turning radiators On
      debuglog('Heating On')
      if (state(rd,'Off')) then -- if radiators are Off, switch to On according to delay
        if( timedifference(otherdevices_lastupdate[rd[1]]) > commanddelay ) then -- check to see if command delay is OK
          debuglog('Enough time since last change: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. commanddelay .. 's')
          debuglog('Turning Radiator On')
          switch(rd,'On')
        else
          debuglog('Not enough time since last change: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. commanddelay .. 's')
        end
      else -- if radiators are On, repeat On command according to delay
        if( timedifference(otherdevices_lastupdate[rd[1]]) > repeatdelay) then -- check to see if repeat delay is OK
          debuglog('Enough time since last change: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. repeatdelay .. 's')
          debuglog('Repeating Radiator On')
          switch(rd,'On')
        else
          debuglog('Not enough time before repeat command: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. repeatdelay .. 's')
        end
      end
    else -- turning radiators Off
      debuglog('Heating Off')
      if (state(rd,'On')) then -- if radiators are On, switch to Off according to delay
        if( timedifference(otherdevices_lastupdate[rd[1]]) > commanddelay ) then -- check to see if command delay is OK
          debuglog('Enough time since last change: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. commanddelay .. 's')
          debuglog('Turning Radiator Off')
          switch(rd,'Off')
        else
          debuglog('Not enough time since last change: '.. timedifference(otherdevices_lastupdate[rd[1]]) .. 's out of ' .. commanddelay .. 's')
        end
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
    debuglog('HD or SD or RD missing') -- no action
  end
end
