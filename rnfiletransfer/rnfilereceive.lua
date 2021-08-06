---- CONFIGURATION ----
-- Side to use for modem
networkSide = "top"
-----------------------

-- This is part of the qtext API, but
-- it needs to be defined here first.
local function emPrint(tex, monit)
    local term = monit or term
    term.write(tex)
    local oX, oY = term.getCursorPos()
    local sX, sY = term.getSize()
    if sY == oY then
        term.scroll(1)
        term.setCursorPos(1, oY)
    else
        term.setCursorPos(1, oY + 1) 
    end
end

local qtext = {
    cursorOffset = function(x, y, monit)
        local term = monit or term
        local oX, oY = term.getCursorPos()
        term.setCursorPos(oX + x, oY + y)
    end,
    
    setCursorX = function(x, monit)
        local term = monit or term
        local oX, oY = term.getCursorPos()
        term.setCursorPos(x, oY)
    end,
    
    tlit = function(tex, color, pri, monit)
        local term = monit or term
        local oldColor = term.getTextColor()
        term.setTextColor(color)
        if pri then
            emPrint(tex, term)
	        print("")
        else
            emPrint(tex, term)
        end
        term.setTextColor(oldColor)
    end
}

-- Network on this side
rednet.open(networkSide)

-- Intro
term.clear()
term.setCursorPos(1, 1)
qtext.tlit("RedNet ", colors.red)
term.write("File Receiver")
qtext.cursorOffset(0, 2)
qtext.setCursorX(1)

-- Set file path
term.write("File path: ")
local fPath = io.read()

-- Set hostname
do
    term.write("Hostname: ")
    local usin = io.read()
    rednet.host("rnfsend", usin)
    print("Registered hostname " .. usin)
end

print("Waiting for message...")

local sid, msg = rednet.receive("rnfsend")
if msg == "s" then
    print("Received file from ID " .. sid)
    print("Downloading...")
else
    rednet.close(networkSide)
    error('Received unsatisfactory initial message "' .. msg .. '" from ID ' .. sid)
end

local f = fs.open(fPath, "w")

while true do
    local _, msg = rednet.receive("rnfsend")
    f.writeLine(msg)
    rednet.send(sid, "r", "rnfsend")
    local _, msg = rednet.receive("rnfsend")
    if msg == "f" then
        print("Finished download from " .. sid)
        print("Find the file in " .. fPath)
        break
    elseif msg ~= "s" then
        error('Received unsatisfactory message "' .. msg .. '" from ID ' .. sid)
    end
end

f.close()
rednet.close(networkSide)
