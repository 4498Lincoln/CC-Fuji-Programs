---- CONFIGURATION ----
-- Side to use for modem
networkSide = "top"
-----------------------

-- This program requires the qtext API of the
-- CC-Fuji-APIs repo in order to function.

if not fs.exists("/fujiAPIs/qtext.lua") then
    error("You need the qtext API installed and in /fujiAPIs!")
end

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
    elseif msg ~= "s"
        rednet.close(networkSide)
        error('Received unsatisfactory message during download"' .. msg .. '" from ID ' .. sid)
    end
end

f.close()
rednet.close(networkSide)
