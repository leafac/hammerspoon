hs.alert("Hammerspoon configuration loaded")

local mods = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0

local cantReloadHammerspoonConfigurationReason = nil
hs.hotkey.bind(mods, "return", function()
    if not cantReloadHammerspoonConfigurationReason then
        hs.reload()
    else
        hs.alert("ERROR: Can’t reload Hammerspoon configuration: " ..
                     cantReloadHammerspoonConfigurationReason)
    end
end)
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

local RECORDING_STATES = {
    NOT_RECORDING = 1,
    STARTING = 2,
    RECORDING = 3,
    STOPPING = 4
}
local recording = {
    state = RECORDING_STATES.NOT_RECORDING,
    originalDefaultAudioDevices = {
        input = {device = nil, muted = nil, volume = nil},
        output = {device = nil, muted = nil, volume = nil}
    },
    frame = {w = 1280, h = 720},
    originalFrame = nil,
    applications = {cameraLive = nil, obs = nil},
    cameraOverlay = {padding = 3, canvas = nil},
    usbWatcher = nil
}
hs.hotkey.bind({"⌘", "⇧"}, "2", function()
    if recording.state == RECORDING_STATES.NOT_RECORDING then
        cantReloadHammerspoonConfigurationReason = "Recording."
        recording.state = RECORDING_STATES.STARTING
        recording.start()
        recording.state = RECORDING_STATES.RECORDING
    elseif recording.state == RECORDING_STATES.STARTING then
        hs.alert(
            "ERROR: Failed to start recording: Recording is already starting.")
    elseif recording.state == RECORDING_STATES.RECORDING then
        recording.state = RECORDING_STATES.STOPPING
        recording.stop()
        recording.state = RECORDING_STATES.NOT_RECORDING
        cantReloadHammerspoonConfigurationReason = nil
    elseif recording.state == RECORDING_STATES.STOPPING then
        hs.alert(
            "ERROR: Failed to stop recording: Recording is already stopping.")
    end
end)
function recording.start()
    hs.dialog.blockAlert("", [[
1. Turn on the room lights.
2. Turn on the recording lights.
3. Close the window.
4. Plug in headphones.
5. Plug in audio interface:
• Audio Interface.
• Multi Track.
• PC/Mac (Bus Powered).
• Effects disabled.
• 48kHz.
• Microphone plugged in.
• Gain: 5.
• Track armed for recording.
6. Check unplugged camera settings:
• Mode: Movie manual exp.
• Shutter speed: 1/50.
• Aperture: F2.0.
• ISO speed: 250.
• Exposure comp.: 0.
• Sound recording: Auto.
• Picture Style: Portrait.
• Color temp.: K5000.
• WB correction: 0, 0.
• Auto Lighting Optimizer: Off.
• AF method: AF Face Tracking.
• Wind filter: Auto.
• Attenuator (ATT): Auto.
• Movie rec. size: FHD 25.00P (1920x1080).
• Battery: Charged.
• Wireless communication: Off.
• Image stabilization: Off.
• Servo AF: On.
• Miniature effect movie: Off.
• Frame.
7. Plug in camera.
]])

    local originalDefaultOutputDevice = hs.audiodevice.defaultOutputDevice()
    recording.originalDefaultAudioDevices.output.device =
        originalDefaultOutputDevice
    recording.originalDefaultAudioDevices.output.muted =
        originalDefaultOutputDevice:outputMuted()
    recording.originalDefaultAudioDevices.output.volume =
        originalDefaultOutputDevice:outputVolume()
    local builtInOutput = hs.audiodevice.findOutputByName("Built-in Output")
    builtInOutput:setOutputMuted(false)
    builtInOutput:setOutputVolume(15)
    local blackHole = hs.audiodevice.findOutputByName("BlackHole 16ch")
    blackHole:setInputMuted(false)
    blackHole:setInputVolume(100)
    blackHole:setOutputMuted(false)
    blackHole:setOutputVolume(100)
    hs.audiodevice.findOutputByName("Built-in Output + BlackHole 16ch"):setDefaultOutputDevice()
    local originalDefaultInputDevice = hs.audiodevice.defaultInputDevice()
    recording.originalDefaultAudioDevices.input.device =
        originalDefaultInputDevice
    recording.originalDefaultAudioDevices.input.muted =
        originalDefaultInputDevice:inputMuted()
    recording.originalDefaultAudioDevices.input.volume =
        originalDefaultInputDevice:inputVolume()
    local h5 = hs.audiodevice.findInputByName("H5")
    h5:setInputMuted(false)
    h5:setDefaultInputDevice()
    local audioMIDISetup = hs.application.open("Audio MIDI Setup")
    hs.dialog.blockAlert("", "Check that audio devices are running at 48kHz.")
    audioMIDISetup:kill()

    recording.originalFrame = hs.screen.primaryScreen():fullFrame()
    hs.screen.primaryScreen():setMode(recording.frame.w, recording.frame.h, 2)

    recording.applications.cameraLive = hs.application.open("Camera Live")
    recording.applications.obs = hs.application.open("OBS")
    hs.dialog.blockAlert("", [[
1. Check:
• Microphone.
• Computer sound.
• Screen.
• Camera.
2. Start recording.
]])

    recording.cameraOverlay.canvas = hs.canvas.new(
                                         {
            x = recording.frame.w * 3 / 4,
            y = recording.frame.h * 0 / 4,
            w = recording.frame.w * 1 / 4,
            h = recording.frame.h * 1 / 4
        }):appendElements({
        type = "rectangle",
        action = "fill",
        frame = {
            x = recording.cameraOverlay.padding,
            y = recording.cameraOverlay.padding,
            w = recording.frame.w * 1 / 4 - recording.cameraOverlay.padding * 2,
            h = recording.frame.h * 1 / 4 - recording.cameraOverlay.padding * 2
        },
        fillColor = {alpha = 0.5},
        roundedRectRadii = {
            xRadius = roundedCornerRadius,
            yRadius = roundedCornerRadius
        }
    }):behavior({"canJoinAllSpaces", "stationary"}):show()

    recording.usbWatcher = hs.usb.watcher.new(
                               function(event)
            hs.dialog.blockAlert("", hs.inspect(event))
        end):start()
end
function recording.stop()
    recording.usbWatcher:stop()

    recording.cameraOverlay.canvas:delete()

    hs.dialog.blockAlert("", [[
1. Stop recording.
2. Turn off camera.
3. Put camera battery on charger.
4. Turn off audio interface.
5. Open the window.
6. Turn off the recording lights.
]])

    recording.applications.cameraLive:kill()
    recording.applications.obs:kill()

    local originalFrame = recording.originalFrame
    hs.screen.primaryScreen():setMode(originalFrame.w, originalFrame.h, 2)

    local originalDefaultInputDevice = recording.originalDefaultAudioDevices
                                           .input.device
    originalInputDevice:setDefaultInputDevice()
    originalInputDevice:setInputMuted(recording.originalDefaultAudioDevices
                                          .input.muted)
    originalInputDevice:setInputVolume(recording.originalDefaultAudioDevices
                                           .input.volume)
    local originalDefaultOutputDevice = recording.originalDefaultAudioDevices
                                            .output.device
    originalOutputDevice:setDefaultOutputDevice()
    originalOutputDevice:setOutputMuted(recording.originalDefaultAudioDevices
                                            .output.muted)
    originalOutputDevice:setOutputVolume(
        recording.originalDefaultAudioDevices.output.volume)

    local projectOption, projectName = hs.dialog.textPrompt("Project name:", "",
                                                            "",
                                                            "Create Project",
                                                            "Cancel")
    if projectOption ~= "Cancel" then
        local projectPath = [[~/Videos/"]] .. projectName .. [["]]
        local recordingFullPath = string.gsub(
                                      hs.execute(
                                          [[ls ~/Videos/*.mkv | tail -n 1]]),
                                      "%s*$", "")
        if recordingFullPath ~= "" then
            hs.execute([[mkdir ]] .. projectPath ..
                           [[ && cp ~/Videos/TEMPLATE/TEMPLATE.RPP ]] ..
                           projectPath .. [[/"]] .. projectName ..
                           [[".RPP && ~/Videos/TEMPLATE/ffmpeg -i "]] ..
                           recordingFullPath .. [[" -map 0:0 -c copy ]] ..
                           projectPath .. [[/video.mp4 -map 0:1 -c copy ]] ..
                           projectPath .. [[/microphone.aac -map 0:2 -c copy ]] ..
                           projectPath .. [[/computer.aac && mv ]] ..
                           recordingFullPath .. [[ ~/.Trash]])
        else
            hs.alert(
                "ERROR: Failed to create project because couldn’t find a recording.")
        end
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
