hs.alert("Hammerspoon configuration loaded")

local mods = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0

hs.hotkey.bind(mods, "return", function() hs.reload() end)
hs.hotkey.bind(mods, ",",
               function() hs.execute([[code ~/.hammerspoon]], true) end)
hs.hotkey.bind(mods, "space", function() hs.toggleConsole() end)
hs.hotkey.bind(mods, "escape", function()
    hs.osascript.applescript("beep")
    hs.sound.getByName("Submarine"):play()
end)

hs.hotkey.bind(mods, "W", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 2 / 2, h = 1 / 2})
end)
hs.hotkey.bind(mods, "E", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 0 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(mods, "D", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 0 / 2, w = 1 / 2, h = 2 / 2})
end)
hs.hotkey.bind(mods, "C", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 1 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(mods, "X", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 1 / 2, w = 2 / 2, h = 1 / 2})
end)
hs.hotkey.bind(mods, "Z", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 1 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(mods, "A", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 1 / 2, h = 2 / 2})
end)
hs.hotkey.bind(mods, "Q", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(mods, "S", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 2 / 2, h = 2 / 2})
end)
hs.hotkey.bind(mods, "tab", function()
    hs.window.focusedWindow():moveToScreen(
        hs.window.focusedWindow():screen():next())
end)

local recording = {
    modal = hs.hotkey.modal.new({"⌘", "⇧"}, "2"),
    mods = hs.fnutils.concat({"⌘"}, mods),
    menubar = {
        menubar = nil,
        timer = nil,
        state = {
            heartbeat = false,
            h5 = false,
            reaper = false,
            obs = false,
            camera = {camera = false, timer = nil}
        }
    },
    scenes = {overlays = nil}
}
function recording.modal:entered()
    local _, projectName = hs.dialog.textPrompt("🚪 🪟 💡 🎧 🎤 🎥",
                                                "Project Name:", "",
                                                "Create Project")
    local projectsDirectory = hs.fs.pathToAbsolute("~/Videos")
    local projectDirectory = projectsDirectory .. "/" .. projectName
    local projectFile = projectDirectory .. "/" .. projectName .. ".RPP"
    local templateDirectory = projectsDirectory .. "/TEMPLATE"
    hs.execute([[mkdir "]] .. projectDirectory .. [["]])
    hs.execute([[cp "]] .. templateDirectory .. [[/TEMPLATE.RPP" "]] ..
                   projectFile .. [["]])
    hs.execute([[cp "]] .. templateDirectory .. [[/rounded-corners.png" "]] ..
                   projectDirectory .. [["]])

    hs.screen.primaryScreen():setMode(1280, 720, 2)

    hs.open(projectFile)
    hs.application.open("OBS")
    hs.dialog.blockAlert("", [[
REAPER: 🎤 🔈
OBS: 🎤 🔈 💻
]], "Click me right as you start recording on the camera")
    hs.http.get("http://localhost:4445/_/1013")
    hs.execute([[npx obs-cli SetRecordingFolder '{ \"rec-folder\": \"]] ..
                   projectDirectory .. [[\" }']], true)
    hs.execute([[npx obs-cli StartRecording]], true)
    recording.menubar.state.camera.start()

    recording.menubar.menubar = hs.menubar.new():setMenu(
                                    function()
            return {
                {title = "H5", checked = recording.menubar.state.h5},
                {title = "REAPER", checked = recording.menubar.state.reaper},
                {title = "OBS", checked = recording.menubar.state.obs},
                {
                    title = "Camera",
                    checked = recording.menubar.state.camera.camera
                }
            }
        end)
    recording.menubar.timer = hs.timer.doEvery(10, function()
        recording.menubar.state.heartbeat =
            not recording.menubar.state.heartbeat
        if hs.audiodevice.findOutputByName("H5") ~= nil then
            recording.menubar.state.h5 = true
        end
        local reaperStatus, reaperBody =
            hs.http.get("http://localhost:4445/_/TRANSPORT")
        recording.menubar.state.reaper =
            reaperStatus == 200 and hs.fnutils.split(reaperBody, "\t")[2] == "5"
        local obsOutput, obsStatus = hs.execute(
                                         [[npx obs-cli GetStreamingStatus]],
                                         true)
        recording.menubar.state.obs = obsStatus and
                                          hs.json.decode(obsOutput).recording
        local title = "🟥"
        if recording.menubar.state.h5 and recording.menubar.state.obs and
            recording.menubar.state.reaper and
            recording.menubar.state.camera.camera then
            title = recording.menubar.state.heartbeat and "○" or "●"
        end
        recording.menubar.menubar:setTitle(title)
    end):fire()

    local frame = {w = 1280, h = 720}
    local padding = 3
    recording.scenes.overlays = {
        ["camera"] = hs.canvas.new({x = 0, y = 0, w = frame.w, h = frame.h}):appendElements(
            {type = "rectangle", action = "fill", fillColor = {alpha = 0.5}})
            :behavior({"canJoinAllSpaces", "stationary"}),
        ["picture-in-picture"] = hs.canvas.new(
            {x = 0, y = 0, w = frame.w, h = frame.h}):appendElements(
            {
                type = "rectangle",
                action = "fill",
                frame = {
                    x = frame.w * 3 / 4 + padding,
                    y = frame.h * 0 / 4 + padding,
                    w = frame.w * 1 / 4 - padding * 2,
                    h = frame.h * 1 / 4 - padding * 2
                },
                fillColor = {alpha = 0.5},
                roundedRectRadii = {
                    xRadius = roundedCornerRadius,
                    yRadius = roundedCornerRadius
                }
            }):behavior({"canJoinAllSpaces", "stationary"}),
        hs.canvas.new({x = 0, y = 0, w = frame.w, h = frame.h}):appendElements()
            :behavior({"canJoinAllSpaces", "stationary"})
    }
    recording.scenes.switch("camera")
end
function recording.menubar.state.camera.start()
    hs.alert("🟥 🎥 👏")
    recording.menubar.state.camera.camera = true
    if recording.menubar.state.camera.timer ~= nil then
        recording.menubar.state.camera.timer:stop()
    end
    if recording.menubar.timer ~= nil and recording.menubar.timer:running() then
        recording.menubar.timer:fire()
    end
    recording.menubar.state.camera.timer =
        hs.timer.doAfter(hs.timer.minutes(27), function()
            recording.menubar.state.camera.camera = false
        end)
end
function recording.scenes.switch(identifier)
    hs.fnutils.each(recording.scenes.overlays,
                    function(overlay) overlay:hide() end)
    local overlay = recording.scenes.overlays[identifier]
    if overlay ~= nil then overlay:show() end
end
recording.modal:bind(recording.mods, "Z",
                     function() recording.scenes.switch("camera") end)
recording.modal:bind(recording.mods, "A", function()
    recording.scenes.switch("picture-in-picture")
end)
recording.modal:bind(recording.mods, "Q",
                     function() recording.scenes.switch("computer") end)
recording.modal:bind(recording.mods, "S", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 0 / 4 * fullFrame.w,
        y = 0 / 4 * fullFrame.h,
        w = 3 / 4 * fullFrame.w,
        h = 4 / 4 * fullFrame.h
    })
end)
recording.modal:bind(recording.mods, "X", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 1 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 3 / 4 * fullFrame.h
    })
end)
recording.modal:bind(recording.mods, "E", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 1 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 1 / 4 * fullFrame.h
    })
end)
recording.modal:bind(recording.mods, "D", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 2 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 1 / 4 * fullFrame.h
    })
end)
recording.modal:bind(recording.mods, "C", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 3 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 1 / 4 * fullFrame.h
    })
end)
-- hs.hotkey.bind(mods, "V", function()
--     if not recording.isRecording then return end
--     local canvas = recording.cameraOverlay.canvas
--     if canvas:isShowing() then
--         canvas:hide()
--     else
--         canvas:show()
--     end
-- end)
-- hs.hotkey.bind(hs.fnutils.concat({"⇧"}, mods), "V", function()
--     if not recording.isRecording then return end
--     recording.cameraOverlay.restart()
-- end)
-- function recording.cameraOverlay.restart()
--     hs.dialog.blockAlert("", [[
-- 1. Microphone.
-- 2. Computer audio.
-- 3. OBS.
-- 4. Camera.
-- 5. CLAP!
-- ]])
--     if recording.cameraOverlay.timer then
--         recording.cameraOverlay.timer:stop()
--     end
--     recording.cameraOverlay.canvas[1].fillColor.red = 0
--     recording.cameraOverlay.timer = hs.timer.doAfter(hs.timer.minutes(27),
--                                                      function()
--         recording.cameraOverlay.canvas[1].fillColor.red = 1
--     end)
-- end
recording.modal:bind(recording.mods, "space", function()
    hs.http.get("http://localhost:4445/_/40157")
    hs.alert("✂️")
end)
recording.modal:bind(mods, "return", function()
    local option = hs.dialog.blockAlert(
                       "Currently recording, do you really want to reload the Hammerspoon configuration?",
                       "", "No", "Yes")
    if option == "Yes" then hs.reload() end
end)
recording.modal:bind({"⌘", "⇧"}, "2", function()
    local option = hs.dialog.blockAlert("", "",
                                        "Click me right as you RESTART recording on the camera",
                                        "Click me right as you STOP recording on the camera")
    if option == "Click me right as you RESTART recording on the camera" then
        hs.http.get("http://localhost:4445/_/40157")
        recording.menubar.state.camera.start()
    elseif option == "Click me right as you STOP recording on the camera" then
        recording.modal:exit()
    end
end)
function recording.modal:exited()
    recording.menubar.timer:stop()
    recording.menubar.menubar:delete()

    recording.menubar.state.camera.timer:stop()
    hs.execute([[npx obs-cli StopRecording]], true)
    hs.execute([[npx obs-cli SetRecordingFolder '{ \"rec-folder\": \"]] ..
                   hs.fs.pathToAbsolute("~/Videos") .. [[\" }']], true)
    hs.application.open("OBS"):kill()
    hs.http.get("http://localhost:4445/_/1016")
    hs.application.open("REAPER")

    hs.screen.primaryScreen():setMode(1280, 800, 2)
end

local dateAndTime = hs.menubar.new():setClickCallback(
                        function() hs.application.open("Calendar") end)
globalDateAndTimeTimerToPreventGarbageCollection =
    hs.timer.doEvery(1, function()
        dateAndTime:setTitle(os.date("%Y-%m-%d  %H:%M  %A"))
    end):fire()

local screenRoundedCorners = {canvases = {}}
function screenRoundedCorners.start()
    hs.fnutils.each(screenRoundedCorners.canvases,
                    function(canvas) canvas:delete() end)
    screenRoundedCorners.canvases = hs.fnutils.map(hs.screen.allScreens(),
                                                   function(screen)
        return hs.canvas.new(screen:fullFrame()):appendElements(
                   {
                type = "rectangle",
                action = "fill",
                fillColor = {hex = "#000"}
            }, {
                type = "rectangle",
                action = "fill",
                compositeRule = "sourceOut",
                roundedRectRadii = {
                    xRadius = roundedCornerRadius,
                    yRadius = roundedCornerRadius
                }
            }):behavior({"canJoinAllSpaces", "stationary"}):show()
    end)
end
screenRoundedCorners.start()
globalScreenRoundedCornersWatcherToPreventGarbageCollection =
    hs.screen.watcher.new(function() screenRoundedCorners.start() end):start()

globalVolumeEventTapToPreventGarbageCollection =
    hs.eventtap.new({hs.eventtap.event.types.NSSystemDefined}, function(event)
        local systemKey = event:systemKey()
        if not systemKey.down or next(event:getFlags()) ~= nil then
            return
        end
        local builtInOutput = hs.audiodevice.findOutputByName("Built-in Output")
        local maximum = 100
        local levels = 16
        local level = math.floor(
                          builtInOutput:outputVolume() / maximum * levels + 0.5)
        local muted = builtInOutput:outputMuted()
        if systemKey.key == "MUTE" then
            if level == 0 then
                level = level + 1
                muted = false
            else
                muted = not muted
            end
        elseif systemKey.key == "SOUND_DOWN" then
            level = math.max(0, level - 1)
            muted = level == 0
        elseif systemKey.key == "SOUND_UP" then
            level = math.min(levels, level + 1)
            muted = false
        else
            return
        end
        builtInOutput:setOutputVolume(level / levels * maximum)
        builtInOutput:setOutputMuted(muted)
        hs.alert((muted and "🔇" or "🔊") .. " " ..
                     string.rep("⬛︎", level) ..
                     string.rep("⬜︎", levels - level))
        return true
    end):start()

hs.hotkey.bind(mods, "P", function()
    hs.dialog.blockAlert("", [[
Font smoothing in Big Sur (https://tonsky.me/blog/monitors/):
$ defaults -currentHost write -g AppleFontSmoothing -int 0

Reinstall Command Line Tools (https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md#i-did-all-that-and-the-acid-test-still-does-not-pass--):
$ sudo rm -rf $(xcode-select -print-path) && sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --reset && xcode-select --install
]])
end)
