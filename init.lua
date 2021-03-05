hs.alert("Hammerspoon configuration loaded")

hs.hotkey.bind({"⌥", "⌃"}, "return", function() hs.reload() end)
hs.hotkey.bind({"⌥", "⌃"}, ",",
               function() hs.execute([[code ~/.hammerspoon]], true) end)
hs.hotkey.bind({"⌥", "⌃"}, "space", function() hs.toggleConsole() end)
hs.hotkey.bind({"⌥", "⌃"}, "escape", function()
    hs.osascript.applescript("beep")
    hs.sound.getByName("Submarine"):play()
end)

hs.window.animationDuration = 0
hs.hotkey.bind({"⌥", "⌃"}, "W", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 2 / 2, h = 1 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "E", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 0 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "D", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 0 / 2, w = 1 / 2, h = 2 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "C", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 1 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "X", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 1 / 2, w = 2 / 2, h = 1 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "Z", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 1 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "A", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 1 / 2, h = 2 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "Q", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "S", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 2 / 2, h = 2 / 2})
end)
hs.hotkey.bind({"⌥", "⌃"}, "tab", function()
    local window = hs.window.focusedWindow()
    window:moveToScreen(window:screen():next())
end)

local dateMenubar = hs.menubar.new():setClickCallback(
                        function() hs.application.open("Calendar") end)
_G.preventGarbageCollectionOfDateMenubarTimer =
    hs.timer.doEvery(1, function()
        dateMenubar:setTitle(os.date("%Y-%m-%d  %H:%M  %A"))
    end):fire()

local screenRoundedCornersCanvases = {}
local function startScreenRoundedCorners()
    for _, canvas in pairs(screenRoundedCornersCanvases) do canvas:delete() end
    screenRoundedCornersCanvases = {}
    for _, screen in pairs(hs.screen.allScreens()) do
        table.insert(screenRoundedCornersCanvases,
                     hs.canvas.new(screen:fullFrame()):appendElements(
                         {
                type = "rectangle",
                action = "fill",
                fillColor = {hex = "#000"}
            }, {
                type = "rectangle",
                action = "fill",
                compositeRule = "sourceOut",
                roundedRectRadii = {xRadius = 10, yRadius = 10}
            }):behavior({"canJoinAllSpaces", "stationary"}):show())
    end
end
startScreenRoundedCorners()
_G.preventGarbageCollectionOfScreenRoundedCornersWatcher =
    hs.screen.watcher.new(function() startScreenRoundedCorners() end):start()

local recording = hs.hotkey.modal.new({"⌘", "⇧"}, "2")

function recording:entered()
    while true do
        local option, identifier = hs.dialog.textPrompt("🏠 💡 🎧 🎤",
                                                        "Identifier:", "",
                                                        "Create Project",
                                                        "Cancel")
        if option == "Cancel" then return hs.reload() end
        if hs.execute([[ls ~/Videos/']] .. identifier .. [[']]) ~= "" then
            hs.dialog.blockAlert("Error", "Project already exists")
        else
            recording.identifier = identifier
            break
        end
    end

    hs.execute([[cp -r ~/Videos/TEMPLATE ~/Videos/']] .. recording.identifier ..
                   [[']])
    hs.execute([[mv ~/Videos/']] .. recording.identifier .. [['/{TEMPLATE,']] ..
                   recording.identifier .. [['}.RPP]])

    local builtInOutput = hs.audiodevice.findOutputByName("Built-in Output")
    builtInOutput:setOutputMuted(false)
    builtInOutput:setOutputVolume(20)
    local blackhole = hs.audiodevice.findOutputByName("BlackHole 2ch")
    blackhole:setDefaultOutputDevice()
    blackhole:setOutputMuted(false)
    blackhole:setOutputVolume(100)
    hs.audiodevice.watcher.setCallback(function(event)
        if event == "dev#" then
            hs.dialog.blockAlert(
                "An audio device was connected or disconnected.", "")
        end
    end)
    hs.audiodevice.watcher.start()
    hs.screen.primaryScreen():setMode(1280, 720, 2, 0, 8)
    dateMenubar:removeFromMenuBar()

    recording.overlays = {
        [1] = hs.canvas.new({x = 0, y = 0, w = 1280, h = 720}):appendElements(
            {
                type = "rectangle",
                action = "fill",
                frame = {
                    x = 1280 * 3 / 4 + 3,
                    y = 720 * 0 / 4 + 3,
                    w = 1280 * 1 / 4 - 3 * 2,
                    h = 720 * 1 / 4 - 3 * 2
                },
                fillColor = {alpha = 0.5},
                roundedRectRadii = {xRadius = 10, yRadius = 10}
            }):behavior({"canJoinAllSpaces", "stationary"}),
        [2] = hs.canvas.new({x = 0, y = 0, w = 1280, h = 720}):appendElements(
            {type = "rectangle", action = "fill", fillColor = {alpha = 0.5}})
            :behavior({"canJoinAllSpaces", "stationary"})
    }

    hs.application.open("OBS")
    hs.dialog.blockAlert("🎤 🔈 💻", "")
    hs.application.open("OBS"):mainWindow():minimize()
    hs.execute([[open ~/Videos/']] .. recording.identifier .. [['/']] ..
                   recording.identifier .. [['.RPP]])
    hs.dialog.blockAlert("🎤 🔈 🎥", "",
                         "Click me as you start recording on the camera")
    hs.http.get(
        "http://localhost:4445/_/_RSa8097198b5ba34eafff45805c1727ed4e42baeb6") -- Script: leafac_OBS - Start recording.lua

    recording.cameraSegments = 0
    recording.startCamera()
    recording.multicamSwitch(2)
end

function recording.startCamera()
    recording.cameraSegments = recording.cameraSegments + 1
    hs.http.get("http://localhost:4445/_/40157") -- Markers: Insert marker at current position
    hs.alert("REAPER OBS 🎥 👏")
    if recording.cameraTimer ~= nil then recording.cameraTimer:stop() end
    for _, overlay in pairs(recording.overlays) do
        for _, element in pairs(overlay) do element.fillColor.red = 0 end
    end
    recording.cameraTimer = hs.timer.doAfter(hs.timer.minutes(27), function()
        for _, overlay in pairs(recording.overlays) do
            for _, element in pairs(overlay) do
                element.fillColor.red = 1
            end
        end
    end)
end

function recording.multicamSwitch(camera)
    for _, overlay in pairs(recording.overlays) do overlay:hide() end
    hs.timer.doAfter(5 / 25, function()
        hs.http.get("http://localhost:4445/_/" .. ({
            "_RS0ef00f2c7fa13a89a670ae0ceebab188f76bdb39",
            "_RS03c9eeea5a76cf51ebdf036cfc01c627d8814dbf",
            "_RS309d84519b55ca7bf4054c61375ddc0c9af0c7d2",
            "_RSd61147b2cb175b462459e920c43c47922bcbeaf5",
            "_RSf7a6434cba550ccea54620a8eb54f8fe8b15fb4a"
        })[camera]) -- Script: leafac_Multicam - Insert camera switch marker to camera at current position.lua
        hs.timer.doAfter(5 / 25, function()
            local overlay = recording.overlays[camera]
            if overlay ~= nil then overlay:show() end
        end)
    end)
end

for camera = 1, 5 do
    recording:bind({"⌥", "⌃"}, tostring(camera),
                   function() recording.multicamSwitch(camera) end)
end

recording:bind({"⌥", "⌃"}, "F", function()
    hs.window.focusedWindow():move({
        x = 0 / 4 * 1280,
        y = 0 / 4 * 720,
        w = 3 / 4 * 1280,
        h = 4 / 4 * 720
    })
end)
recording:bind({"⌥", "⌃"}, "V", function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * 1280,
        y = 1 / 4 * 720,
        w = 1 / 4 * 1280,
        h = 3 / 4 * 720
    })
end)
recording:bind({"⌥", "⌃"}, "T", function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * 1280,
        y = 1 / 4 * 720,
        w = 1 / 4 * 1280,
        h = 1 / 4 * 720
    })
end)
recording:bind({"⌥", "⌃"}, "G", function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * 1280,
        y = 2 / 4 * 720,
        w = 1 / 4 * 1280,
        h = 1 / 4 * 720
    })
end)
recording:bind({"⌥", "⌃"}, "B", function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * 1280,
        y = 3 / 4 * 720,
        w = 1 / 4 * 1280,
        h = 1 / 4 * 720
    })
end)

recording:bind({"⌥", "⌃"}, "M", function()
    hs.http.get("http://localhost:4445/_/40157") -- Markers: Insert marker at current position
    hs.alert("✂️", {}, hs.screen.mainScreen(), 0.2)
end)

recording:bind({"⌥", "⌃"}, "return", function()
    if hs.dialog.blockAlert(
        "Currently recording, do you really want to reload the Hammerspoon configuration?",
        "", "No", "Yes") == "Yes" then hs.reload() end
end)

recording:bind({"⌘", "⇧"}, "2", function()
    if hs.dialog.blockAlert("👏", "",
                            "Click me as you restart recording on the camera",
                            "Stop Recording") ==
        "Click me as you restart recording on the camera" then
        recording.startCamera()
    else
        recording:exit()
    end
end)

function recording:exited()
    recording.cameraTimer:stop()
    recording.cameraTimer = nil
    hs.http.get(
        "http://localhost:4445/_/_RS40031326265963e3606b3fd8fc73993a6243a2da") -- Script: leafac_OBS - Stop recording.lua
    hs.application.open("OBS"):kill()
    hs.execute([[open ~/Videos/']] .. recording.identifier .. [['/']] ..
                   recording.identifier .. [['.RPP]])

    for _, overlay in pairs(recording.overlays) do overlay:delete() end
    recording.overlays = nil

    dateMenubar:returnToMenuBar()
    hs.screen.primaryScreen():setMode(1280, 800, 2, 0, 8)
    -- FIXME
    hs.audiodevice.watcher.setCallback(function(event) end)
    hs.audiodevice.watcher.stop()
    hs.audiodevice.findOutputByName("Built-in Output"):setDefaultOutputDevice()

    while true do
        local files = {}
        if hs.dialog.blockAlert("", "",
                                "Connect the camera SD card and then click me",
                                "Skip") == "Skip" then break end
        for file in string.gmatch(hs.execute(
                                      [[ls /Volumes/EOS_DIGITAL/DCIM/100CANON/MVI_*.MP4 | tail -n ]] ..
                                          recording.cameraSegments), "[^\n]+") do
            table.insert(files, file)
        end
        if #files ~= recording.cameraSegments then
            hs.dialog.blockAlert("Error", "Failed to find files in SD card")
        else
            for index, file in ipairs(files) do
                hs.execute([[cp ']] .. file .. [[' ~/Videos/']] ..
                               recording.identifier .. [['/camera--]] .. index ..
                               [[.mp4]])
            end
            hs.fs.volume.eject("/Volumes/EOS_DIGITAL")
            break
        end
    end

    hs.http.get(
        "http://localhost:4445/_/_RSf6a2bc13045b9dc07fb82fa9c3e86f9f93ee4b9d") -- Script: leafac_TEMPLATE.lua

    recording.cameraSegments = nil
    recording.identifier = nil
end
