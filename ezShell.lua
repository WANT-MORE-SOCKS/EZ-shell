if not fs.exists("/basalt.lua") then
    term.setTextColour(colors.red)
    print("This program requires the Basalt UI Framework.")
    term.setTextColour(colors.yellow)
    print("Do you wish to install the latest version? [y/n]")
    local answer = read()
    term.setTextColour(colors.white)
    if answer == "yes" or answer == "y" then
        shell.run("wget run https://basalt.madefor.cc/install.lua packed")
    else
        error("Goodbye")
    end
end

local programPaths = {}
programPaths["worm.lua"] = "/rom/programs/fun/worm.lua"
programPaths["falling.lua"] = "/rom/programs/pocket/falling.lua"
programPaths["shell.lua"] = "/rom/programs/shell.lua"
for _, v in pairs(fs.list("/")) do
    if fs.isDir(v) then
        for _, v in pairs(fs.find(fs.combine(v, "*.lua"))) do programPaths[fs.getName(v)] = v end
    end
    for _, v in pairs(fs.find("/*.lua")) do programPaths[fs.getName(v)] = v end
end
programPaths["basalt.lua"] = nil
programPaths["startup.lua"] = nil
programPaths["ezShell.lua"] = nil

local basalt = require("basalt")

local main = basalt.createFrame()

local bottomBar = main:addMenubar():setPosition(1, "{parent.h - 1}"):setSize("{parent.w - 1}", 1)
    :setBackground(colors.orange)
    :setSelectionColor(colors.blue, colors.white)
local processes = {
    main:addFrame():setSize("{parent.w}", "{parent.h - 2}")
    :setBackground(colors.black)
}

bottomBar:addItem("Apps")
    processes[1]:addPane():setSize("{parent.w}", 1)
        :setBackground(colors.lightGray)
    local clockLabel = processes[1]:addLabel():setText(string.char(169).." "..textutils.formatTime(os.time(), true))
    local sleepLabel = processes[1]:addLabel():setText("["..string.rep(string.char(2), 3).."]"):setPosition(9, 1)
    processes[1]:onEvent(function(_, event, id)
        if event == "closeTab" and id == "Apps" then
            basalt.stop()
        end
    end)

    local clockTimer = processes[1]:addTimer():setTime(0.3, 2^52)
        :onCall(function()
            local time = os.time()
            clockLabel:setText(string.char(169).." "..textutils.formatTime(time, true))
            if time > 18.5 or time < 5.5 then sleepLabel:setText("[ZZZ]")
            else sleepLabel:setText("["..string.rep(string.char(2), 3).."]") end
        end)
    clockTimer:start()

local appList = processes[1]:addList():setSize("{parent.w - 2}", "{parent.h - 5}"):setPosition(1, 2)
:setBackground(colors.black)
:setForeground(colors.white)
:setSelectionColor(colors.blue, colors.white)
for k in pairs(programPaths) do appList:addItem(k) end

local function openProgram(path, title)
    local pId = title
    local f = main:addFrame()
        :setSize("{parent.w}", "{parent.h - 2}")
        :setPosition(1, 1)
        :hide()
    local p = f:addProgram()
        :setSize("{parent.w - 2}", "{parent.h - 1}")
        :setPosition(1, 1)
        :execute(path)
        :onDone(function()
            f:remove()
            processes[pId] = nil
        end)
        :onError(function()
            f:remove()
            processes[pId] = nil
        end)
    f:onEvent(function(_, event, id)
        if event == "closeTab" and id == title then
            p:injectEvent("terminate")
            f:remove()
            processes[pId] = nil
        end
    end)
    processes[pId] = f
    bottomBar:addItem(title)
    return f
end

local launchButton = processes[1]:addButton():setPosition(8, "{parent.h - 3}"):hide()
    :setBackground(colors.green)
    :setForeground(colors.white)
    :setText("Launch")
local selectedApp
appList:onSelect(function(_, _, item)
    launchButton:show()
    selectedApp = item.text
end)

launchButton:onClick(function()
    openProgram(programPaths[selectedApp], selectedApp)
end)

local function openSubFrame(id)
    if(processes[id]~=nil)then
        for _,v in pairs(processes)do
            v:hide()
        end
        processes[id]:show()
    end
end

local currentTab = "Apps"

bottomBar:onSelect(function(_, _, item)
    if item.text ~= "Apps" then openSubFrame(item.text)
    else openSubFrame(1) end
    currentTab = item
end)

local closeButton = main:addButton():setPosition("{parent.w - 1}", "{parent.h - 1}"):setSize(1, 1)
    :setText("X")
    closeButton:setBackground(colors.black)
    closeButton:setForeground(colors.red)

closeButton:onClick(function()
    os.queueEvent("closeTab", currentTab.text)
    bottomBar:removeItem(currentTab)
end)

bottomBar:selectItem(1)

basalt.autoUpdate()