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

-- Integrate necessary qtext API
-- functions into the program
local qtext = {
    cursorOffset = function(x, y, monit)
        local term = monit or term
        local oX, oY = term.getCursorPos()
        term.setCursorPos(oX + x, oY + y)
    end,
    tlit = function(tex, color, pri, monit)
        local term = monit or term
        local oldColor = term.getTextColor()
        term.setTextColor(color)
        if pri then
            emPrint(tex, term)
        else
            term.write(tex, term)
        end
        term.setTextColor(oldColor)
    end
}

-- Integrate necessary redutils API
-- functions into the program
local redutils = {
    sreceive = function(prot, sid)
        while true do
            local senderId, message, protocol = rednet.receive(prot)
            if senderId == sid then
                return senderId, message, protocol
            end
        end
    end
}

-- Modem to use
rednet.open("top")

-- Introduction
term.clear()
term.setCursorPos(1, 1)
qtext.tlit("RedNeT ", colors.red)
print("File Sender")

-- Set a hostname
qtext.cursorOffset(0, 1)
term.write("Hostname: ")
local usinHostname = io.read()
rednet.host("rnfsend", usinHostname)
print("Registered hostname " .. usinHostname)
print("Press any key to begin")
os.pullEvent("key")
os.sleep(0.1)

-- Lookup
term.clear()
term.setCursorPos(1, 1)
term.write("Hostname to send to: ")
local usinHostLookup = io.read()
local recHost = rednet.lookup("rnfsend", usinHostLookup)
if not recHost then
    qtext.tlit("Couldn't establish a connection", colors.red, true)
    error("Didn't find a computer with hostname specified")
end
qtext.tlit("Established connection with " .. recHost, colors.green, true)
term.write("Path of file: ")
local fPath = io.read()
local f = fs.open(fPath, "r")
print("Sending file...")

-- Main loop:
-- 1. Read a line
-- 2. If the line is nil, tell the
-- receiver to finish and then end
-- the program. Otherwise...
-- 3. Tell the receiver to be ready
-- to receive
-- 4. Send the line
while true do
    local fLine = f.readLine()
    if fLine then
        rednet.send(recHost, "s", "rnfsend")
        os.sleep(0.1)
        rednet.send(recHost, fLine, "rnfsend")
    else
        rednet.send(recHost, "f", "rnfsend")
        f.close()
        print("File sent!")
        break
    end
    redutils.sreceive("rnfsend", recHost)
end

rednet.close("top")
