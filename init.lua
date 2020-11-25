hs.alert("Hammerspoon configuration loaded")

local mods = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0

hs.hotkey.bind(mods, "return", function() hs.reload() end)
hs.hotkey
    .bind(mods, ",", function() hs.execute("code ~/.hammerspoon", true) end)
hs.hotkey.bind(mods, "space", function() hs.toggleConsole() end)
hs.hotkey.bind(mods, "escape", function() hs.osascript.applescript("beep") end)

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

hs.hotkey.bind(mods, "R", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 0 / 4 * fullFrame.w,
        y = 0 / 4 * fullFrame.h,
        w = 3 / 4 * fullFrame.w,
        h = 4 / 4 * fullFrame.h
    })
end)
hs.hotkey.bind(mods, "F", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 1 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 3 / 4 * fullFrame.h
    })
end)
hs.hotkey.bind(mods, "T", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 1 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 1 / 4 * fullFrame.h
    })
end)
hs.hotkey.bind(mods, "G", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 2 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 1 / 4 * fullFrame.h
    })
end)
hs.hotkey.bind(mods, "B", function()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    hs.window.focusedWindow():move({
        x = 3 / 4 * fullFrame.w,
        y = 3 / 4 * fullFrame.h,
        w = 1 / 4 * fullFrame.w,
        h = 1 / 4 * fullFrame.h
    })
end)

local recording = {
    isRecording = false,
    usbWatcher = nil,
    events = {start = nil, stop = nil, camera = nil},
    cameraOverlay = {canvas = nil, timer = nil}
}
hs.hotkey.bind({"⌘", "⇧"}, "2", function()
    if not recording.isRecording then
        recording.start()
    else
        recording.stop()
    end
    recording.isRecording = not recording.isRecording
end)
hs.hotkey.bind(mods, "V", function()
    if not recording.isRecording then return end
    local canvas = recording.cameraOverlay.canvas
    if canvas:isShowing() then
        canvas:hide()
    else
        canvas:show()
    end
end)
hs.hotkey.bind(hs.fnutils.concat({"⇧"}, mods), "V", function()
    if not recording.isRecording then return end
    recording.cameraOverlay.restart()
end)
function recording.start()
    hs.dialog.blockAlert("", [[
1. Prepare recording space:
• Doors.
• Lights.
• Windows.
2. Connect recording devices:
• Audio interface.
• Camera.
• Headphones.
]])

    recording.usbWatcher = hs.usb.watcher.new(
                               function(event)
            hs.dialog.blockAlert("", hs.json.encode(event, true))
        end):start()

    local builtInOutput = hs.audiodevice.findOutputByName("Built-in Output")
    builtInOutput:setOutputMuted(false)
    builtInOutput:setOutputVolume(15)
    hs.audiodevice.findOutputByName("Built-in Output + BlackHole 16ch"):setDefaultOutputDevice()

    hs.screen.primaryScreen():setMode(1280, 720, 2)

    hs.application.open("OBS")
    hs.dialog.blockAlert("", "",
                         "Click me when your next click will be to “Start Recording” in OBS")
    local startTap
    startTap = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown},
                               function(event)
        recording.events.start = hs.timer.secondsSinceEpoch()
        hs.json.write(recording.events, "~/Videos/events.json", true, true)
        hs.alert("Started recording in OBS")
        startTap:stop()
    end):start()
    hs.dialog.blockAlert("", "", "Click me after started recording in OBS")

    recording.events.camera = {}
    hs.application.open("EOS Utility 3")
    hs.dialog.blockAlert("", "",
                         "Click me when your next click will be to start recording in the camera")
    local cameraStartTap
    cameraStartTap = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown},
                                     function(event)
        table.insert(recording.events.camera,
                     {start = hs.timer.secondsSinceEpoch(), stop = nil})
        hs.json.write(recording.events, "~/Videos/events.json", true, true)
        hs.alert("Started recording in the camera")
        cameraStartTap:stop()
    end):start()
    hs.dialog.blockAlert("", "",
                         "Click me after started recording in the camera")

    local frame = {w = 1280, h = 720}
    local padding = 3
    recording.cameraOverlay.canvas = hs.canvas.new(
                                         {
            x = frame.w * 3 / 4,
            y = frame.h * 0 / 4,
            w = frame.w * 1 / 4,
            h = frame.h * 1 / 4
        }):appendElements({
        type = "rectangle",
        action = "fill",
        frame = {
            x = padding,
            y = padding,
            w = frame.w * 1 / 4 - padding * 2,
            h = frame.h * 1 / 4 - padding * 2
        },
        fillColor = {alpha = 0.5},
        roundedRectRadii = {
            xRadius = roundedCornerRadius,
            yRadius = roundedCornerRadius
        }
    }):behavior({"canJoinAllSpaces", "stationary"}):show()
    recording.cameraOverlay.restart()
end
function recording.stop()
    recording.cameraOverlay.timer:stop()
    recording.cameraOverlay.canvas:delete()

    hs.application.open("EOS Utility 3")
    hs.dialog.blockAlert("", "",
                         "Click me when your next click will be to stop recording in the camera")
    local cameraStopTap
    cameraStopTap = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown},
                                    function(event)
        recording.events.camera[#recording.events.camera].stop =
            hs.timer.secondsSinceEpoch()
        hs.json.write(recording.events, "~/Videos/events.json", true, true)
        hs.alert("Stopped recording in the camera")
        cameraStopTap:stop()
    end):start()
    hs.dialog.blockAlert("", "",
                         "Click me after stopped recording in the camera")

    hs.application.open("OBS")
    hs.dialog.blockAlert("", "",
                         "Click me when your next click will be to Stop Recording” in OBS")
    local stopTap
    stopTap = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown},
                              function(event)
        recording.events.stop = hs.timer.secondsSinceEpoch()
        hs.json.write(recording.events, "~/Videos/events.json", true, true)
        hs.alert("Stopped recording in OBS")
        stopTap:stop()
    end):start()
    hs.dialog.blockAlert("", "", "Click me after stopped recording in OBS")

    hs.screen.primaryScreen():setMode(1280, 800, 2)

    hs.audiodevice.findOutputByName("Built-in Output"):setDefaultOutputDevice()

    recording.usbWatcher:stop()

    local projectOption, projectName = hs.dialog.textPrompt("Project name:", "",
                                                            "",
                                                            "Create Project",
                                                            "Cancel")
    if projectOption == "Cancel" then return end

    local projectDirectory = [[~/Videos/"]] .. projectName .. [["]]
    hs.execute([[mkdir ]] .. projectDirectory)

    local recordingFile = [["]] ..
                              string.gsub(
                                  hs.execute([[ls ~/Videos/*.mkv | tail -n 1]]),
                                  "%s*$", "") .. [["]]
    hs.execute([[~/Videos/TEMPLATE/ffmpeg -i ]] .. recordingFile ..
                   [[ -map 0:0 -c copy ]] .. projectDirectory ..
                   [[/computer.mp4 -map 0:1 -c copy ]] .. projectDirectory ..
                   [[/microphone.aac -map 0:2 -c copy ]] .. projectDirectory ..
                   [[/computer.aac && mv ]] .. recordingFile .. [[ ~/.Trash]])

    hs.dialog.blockAlert("", "",
                         "Click me when the recordings from the camera have been transferred to the computer")
    local cameraRecordings = hs.fnutils.split(
                                 string.gsub(
                                     hs.execute(
                                         [[ls ~/Videos/MVI_*.MP4 | tail -n ]] ..
                                             #recording.events.camera), "%s*$",
                                     ""), "\n")
    for index, cameraRecording in ipairs(cameraRecordings) do
        hs.execute([[mv ]] .. cameraRecording .. [[ ]] .. projectDirectory ..
                       [[/camera--]] .. index .. [[.mp4]])
    end

    local projectFile = projectDirectory .. [[/"]] .. projectName .. [[".RPP]]
    hs.execute([[cp ~/Videos/TEMPLATE/TEMPLATE.RPP ]] .. projectFile)
    -- hs.execute([[rm ~/Videos/events.json]])

    hs.execute([[cp ~/Videos/TEMPLATE/rounded-corners.png ]] .. projectDirectory)

    hs.application.get("EOS Utility 3"):kill()
    hs.application.get("OBS"):kill()

    hs.execute([[open ]] .. projectFile)
end
function recording.cameraOverlay.restart()
    hs.dialog.blockAlert("", [[
1. Microphone.
2. Computer audio.
3. OBS.
4. Camera.
5. CLAP!
]])
    if recording.cameraOverlay.timer then
        recording.cameraOverlay.timer:stop()
    end
    recording.cameraOverlay.canvas[1].fillColor.red = 0
    recording.cameraOverlay.timer = hs.timer.doAfter(hs.timer.minutes(27),
                                                     function()
        recording.cameraOverlay.canvas[1].fillColor.red = 1
    end)
end

local dateAndTime = hs.menubar.new():setClickCallback(
                        function() hs.application.open("Calendar") end)
globalDateAndTimeTimerToPreventGarbageCollection =
    hs.timer.doEvery(1, function()
        dateAndTime:setTitle(os.date("%Y-%m-%d  %H:%M  %A"))
    end)

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

local screenBrightnessHack = {canvases = {}}
hs.hotkey.bind(mods, "up", function()
    hs.fnutils.each(screenBrightnessHack.canvases, function(canvas)
        local newAlpha = math.max(0, canvas[1].fillColor.alpha - 0.1)
        hs.alert(
            "Brightness hack: " .. math.floor((1 - newAlpha) * 100 + 0.5) .. "%")
        canvas[1].fillColor.alpha = newAlpha
    end)
end)
hs.hotkey.bind(mods, "down", function()
    hs.fnutils.each(screenBrightnessHack.canvases, function(canvas)
        local newAlpha = math.min(1, canvas[1].fillColor.alpha + 0.1)
        hs.alert(
            "Brightness hack: " .. math.floor((1 - newAlpha) * 100 + 0.5) .. "%")
        canvas[1].fillColor.alpha = newAlpha
    end)
end)
function screenBrightnessHack.start()
    hs.fnutils.each(screenBrightnessHack.canvases,
                    function(canvas) canvas:delete() end)
    screenBrightnessHack.canvases = hs.fnutils.map(hs.screen.allScreens(),
                                                   function(screen)
        return hs.canvas.new(screen:fullFrame()):appendElements(
                   {
                type = "rectangle",
                action = "fill",
                fillColor = {alpha = 0}
            }):behavior({"canJoinAllSpaces", "stationary"}):show()
    end)
end
screenBrightnessHack.start()
globalScreenBrightnessHackWatcherToPreventGarbageCollection =
    hs.screen.watcher.new(function() screenBrightnessHack.start() end):start()

-- defaults -currentHost write -g AppleFontSmoothing -int 0 (https://tonsky.me/blog/monitors/)
-- sudo rm -rf $(xcode-select -print-path) && sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --reset && xcode-select --install (https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md#i-did-all-that-and-the-acid-test-still-does-not-pass--)
