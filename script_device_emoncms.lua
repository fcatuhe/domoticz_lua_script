-- Instructions
-----------------------------------------------------------------------------------------------
-- This script sends temperature sensor information to EmonCMS using the json API

-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
-- Define the EmonCMS write API key
apikey = 'your_api_key_here'



-----------------------------------------------------------------------------------------------
-- NOTHING SHOULD NEED TO CHANGE BELOW THIS LINE
-----------------------------------------------------------------------------------------------

commandArray = {}

function debuglog (s)
	if uservariables['Debug'] == 1 then print('emoncms: '.. s) end
	return true
end

dc=next(devicechanged)
dcs=tostring(dc)

if (dcs:sub(1,1) == 'T' or dcs:sub(1,1) == 'W') then
    if (dcs:find("_") == nil) then l=dcs:len() else l=dcs:find("_")-1 end
    dcn=dcs:sub(1,l)
    vc=otherdevices_svalues[dcn]
    debuglog(vc)

    if (dcs:sub(1,1) == 'T') then
        temp, hum = vc:match("([^;]*);([^;]+)")
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-T:'..temp..'}&apikey='..apikey)
        commandArray = {}
        commandArray[1]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-T:'..temp..'}&apikey='..apikey}
        if(hum ~= nil) then
            debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-H:'..hum..'}&apikey='..apikey)
            commandArray[2]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-H:'..hum..'}&apikey='..apikey}
        end

    elseif (dcs:sub(1,2) == 'WS') then
        temp, hum, uv, pres, uv2 = vc:match("([^;]+);([^;]+);([^;]+);([^;]+);([^;]+)")
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-T:'..temp..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-H:'..hum..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-U:'..uv..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-P:'..pres..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-U2:'..uv2..'}&apikey='..apikey)

        commandArray = {}
        commandArray[1]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-T:'..temp..'}&apikey='..apikey}
        commandArray[2]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-H:'..hum..'}&apikey='..apikey}
        commandArray[3]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-U:'..uv..'}&apikey='..apikey}
        commandArray[4]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-P:'..pres..'}&apikey='..apikey}
        commandArray[5]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-U2:'..uv2..'}&apikey='..apikey}

    elseif (dcs:sub(1,2) == 'WW') then
        wdirdeg, wdir, wspeed, wgust, wtemp, wfeel = vc:match("([^;]+);([^;]+);([^;]+);([^;]+);([^;]+);([^;]+)")
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WD:'..wdirdeg..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WS:'..wspeed..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WG:'..wgust..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WT:'..wtemp..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WF:'..wfeel..'}&apikey='..apikey)

        commandArray = {}
        commandArray[1]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WD:'..wdirdeg..'}&apikey='..apikey}
        commandArray[2]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WS:'..wspeed..'}&apikey='..apikey}
        commandArray[3]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WG:'..wgust..'}&apikey='..apikey}
        commandArray[4]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WT:'..wtemp..'}&apikey='..apikey}
        commandArray[5]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-WF:'..wfeel..'}&apikey='..apikey}

    elseif (dcs:sub(1,2) == 'WR') then
        rcurrent, rtotal = vc:match("([^;]+);([^;]+)")
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-RC:'..rcurrent..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-RT:'..rtotal..'}&apikey='..apikey)

        commandArray = {}
        commandArray[1]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-RC:'..rcurrent..'}&apikey='..apikey}
        commandArray[2]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-RT:'..rtotal..'}&apikey='..apikey}

    elseif (dcs:sub(1,2) == 'WU') then
        uv, solarradiation = vc:match("([^;]+);([^;]+)")
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-UV:'..uv..'}&apikey='..apikey)
        debuglog('http://emoncms.org/input/post.json?node=2&json={'..dcn..'-SR:'..solarradiation..'}&apikey='..apikey)

        commandArray = {}
        commandArray[1]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-UV:'..uv..'}&apikey='..apikey}
        commandArray[2]={['OpenURL']='http://emoncms.org/input/post.json?node=2&json={'..dcn..'-SR:'..solarradiation..'}&apikey='..apikey}

    end
end

return commandArray
