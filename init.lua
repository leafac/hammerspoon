hs.alert("Hammerspoon configuration reloaded")

local mods = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0

local cantReloadHammerspoonConfigurationReason = nil
hs.hotkey.bind(mods, "return", function()
    if not cantReloadHammerspoonConfigurationReason then
        hs.reload()
    else
        hs.alert("Failed to reload Hammerspoon configuration: " ..
                     cantReloadHammerspoonConfigurationReason)
    end
end)
hs.hotkey
    .bind(mods, ",", function() hs.execute("code ~/.hammerspoon", true) end)
hs.hotkey.bind(mods, "escape", function() hs.toggleConsole() end)
-- FIXME: Sometimes I take too long; sometimes I don’t work at all!
hs.hotkey.bind(mods, "space", function() hs.sound.getByName("Funk"):play() end)

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

-- FIXME: There seems to be a bug when you start/stop recording multiple times.
local recording = {
    isRecording = false,
    originalDefaultOutputDevice = {device = nil, muted = nil, volume = nil},
    originalFullFrame = nil,
    cameraOverlay = {
        duration = hs.timer.minutes(27),
        padding = 3,
        canvas = nil,
        timer = nil
    }
}
hs.hotkey.bind({"⌘", "⇧"}, "2", function() recording.toggle() end)
hs.hotkey.bind(mods, "V", function() recording.cameraOverlay.toggle() end)
hs.hotkey.bind(hs.fnutils.concat({"⇧"}, mods), "V",
               function() recording.cameraOverlay.restart() end)
function recording.start()
    cantReloadHammerspoonConfigurationReason = "Recording"

    hs.dialog.blockAlert("Connect Audio Recorder", [[1. Check:
• Battery
• SD Card
• WAV48/24
• REC MODE: MULTI FILE
• No effects applied
2. Connect microphone to audio recorder.
3. Connect computer to audio recorder.
4. Connect headphones to audio recorder.
5. Set headphones volume to 30.
6. Set gain to 5 in microphone and computer tracks.
7. Arm microphone and computer tracks for recording.]])
    local originalDefaultOutputDevice = hs.audiodevice.defaultOutputDevice()
    recording.originalDefaultOutputDevice.device = originalDefaultOutputDevice
    recording.originalDefaultOutputDevice.muted =
        originalDefaultOutputDevice:outputMuted()
    recording.originalDefaultOutputDevice.volume =
        originalDefaultOutputDevice:outputVolume()
    local audioRecorder = hs.audiodevice.findOutputByName("Built-in Output")
    audioRecorder:setDefaultOutputDevice()
    audioRecorder:setOutputMuted(false)
    audioRecorder:setOutputVolume(28)
    hs.dialog.blockAlert("Start Audio Recording",
                         [[1. Check levels on microphone and computer (⌥^⎋) tracks.
2. Check that you can hear the computer.
3. Start recording.]])

    hs.dialog.blockAlert("Connect External Display", "")
    recording.originalFullFrame = hs.screen.primaryScreen():fullFrame()
    hs.screen.primaryScreen():setMode(1280, 720, 2)
    hs.application.open("OBS")
    hs.dialog.blockAlert("Start Screen Recording",
                         [[1. Open Kap.
2. Check:
• Microphone: Built-in Microphone
• Preferences: 30 FPS · Everything enabled except for “Start automatically”
• Record Entire Screen
3. Start recording.]])

    hs.dialog.blockAlert("Start Camera", [[1. Check:
• Lights
• Battery
• SD Card
• Mode: Movie recording
• Shooting mode: Movie manual exp.
• Shutter speed: 1/60
• Aperture: F2.0
• ISO speed: 250
• Exposure comp.: 0
• Sound recording: Auto
• Picture Style: Portrait
• Color temp.: K5000
• WB correction: 0, 0
• Auto Lighting Optimizer: Off
• AF method: AF Face Tracking
• Wind filter: Auto
• Attenuator (ATT): Auto
• Movie rec. size: FHD 29.97P (1920x1080)
• Image stabilization: Off
• Servo AF: On
• Miniature effect movie: Off
• Frame
2. Start recording.]])

    recording.cameraOverlay.start()
end
function recording.stop()
    recording.cameraOverlay.stop()

    hs.dialog.blockAlert("Stop Recording", [[1. Stop camera.
2. Stop screen recording.
3. Stop audio recording.
4. Turn off the lights.
5. Put batteries on chargers.]])

    local originalFullFrame = recording.originalFullFrame
    hs.screen.primaryScreen():setMode(originalFullFrame.w, originalFullFrame.h,
                                      2)

    local originalDefaultOutputDevice = recording.originalDefaultOutputDevice
                                            .device
    originalDefaultOutputDevice:setDefaultOutputDevice()
    originalDefaultOutputDevice:setOutputMuted(
        recording.originalDefaultOutputDevice.muted)
    originalDefaultOutputDevice:setOutputVolume(
        recording.originalDefaultOutputDevice.volume)

    cantReloadHammerspoonConfigurationReason = nil
end
function recording.toggle()
    if not recording.isRecording then
        recording.start()
    else
        recording.stop()
    end
    recording.isRecording = not recording.isRecording
end
function recording.cameraOverlay.start()
    local fullFrame = hs.screen.primaryScreen():fullFrame()
    recording.cameraOverlay.canvas = hs.canvas.new(
                                         {
            x = fullFrame.w * 3 / 4,
            y = fullFrame.h * 0 / 4,
            w = fullFrame.w * 1 / 4,
            h = fullFrame.h * 1 / 4
        }):appendElements({
        type = "rectangle",
        action = "fill",
        frame = {
            x = recording.cameraOverlay.padding,
            y = recording.cameraOverlay.padding,
            w = fullFrame.w * 1 / 4 - recording.cameraOverlay.padding * 2,
            h = fullFrame.h * 1 / 4 - recording.cameraOverlay.padding * 2
        },
        fillColor = {alpha = 0.5},
        roundedRectRadii = {
            xRadius = roundedCornerRadius,
            yRadius = roundedCornerRadius
        }
    }):behavior({"canJoinAllSpaces", "stationary"}):show()
    recording.cameraOverlay.timer = hs.timer.doAfter(
                                        recording.cameraOverlay.duration,
                                        function()
            recording.cameraOverlay.canvas[1].fillColor.red = 1
        end)
    hs.dialog.blockAlert("And Action…", [[1. Double-check recording:
• Audio
• Screen
• Camera
2. Add a marker on audio recorder.
3. Clap for the camera.]])
end
function recording.cameraOverlay.stop()
    recording.cameraOverlay.canvas:delete()
    recording.cameraOverlay.canvas = nil
    recording.cameraOverlay.timer:stop()
    recording.cameraOverlay.timer = nil
end
function recording.cameraOverlay.restart()
    if not recording.cameraOverlay.canvas then return end
    recording.cameraOverlay.stop()
    recording.cameraOverlay.start()
end
function recording.cameraOverlay.toggle()
    if not recording.cameraOverlay.canvas then return end
    if recording.cameraOverlay.canvas:isShowing() then
        recording.cameraOverlay.canvas:hide()
    else
        recording.cameraOverlay.canvas:show()
    end
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
