hs.alert("Hammerspoon configuration loaded")

local modifiers = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0
hs.alert.defaultStyle.fadeInDuration = 0
hs.alert.defaultStyle.fadeOutDuration = 0

hs.hotkey.bind(modifiers, "return", function() hs.reload() end)
hs.hotkey.bind(modifiers, ",",
               function() hs.execute([[code ~/.hammerspoon]], true) end)
hs.hotkey.bind(modifiers, "space", function() hs.toggleConsole() end)
hs.hotkey.bind(modifiers, "escape", function()
    hs.osascript.applescript("beep")
    hs.sound.getByName("Submarine"):play()
end)

hs.hotkey.bind(modifiers, "W", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 2 / 2, h = 1 / 2})
end)
hs.hotkey.bind(modifiers, "E", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 0 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(modifiers, "D", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 0 / 2, w = 1 / 2, h = 2 / 2})
end)
hs.hotkey.bind(modifiers, "C", function()
    hs.window.focusedWindow():move({x = 1 / 2, y = 1 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(modifiers, "X", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 1 / 2, w = 2 / 2, h = 1 / 2})
end)
hs.hotkey.bind(modifiers, "Z", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 1 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(modifiers, "A", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 1 / 2, h = 2 / 2})
end)
hs.hotkey.bind(modifiers, "Q", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 1 / 2, h = 1 / 2})
end)
hs.hotkey.bind(modifiers, "S", function()
    hs.window.focusedWindow():move({x = 0 / 2, y = 0 / 2, w = 2 / 2, h = 2 / 2})
end)
hs.hotkey.bind(modifiers, "tab", function()
    local window = hs.window.focusedWindow()
    window:moveToScreen(window:screen():next())
end)

local recording = {
    configuration = {
        modal = hs.hotkey.modal.new({"⌘", "⇧"}, "2"),
        modifiers = hs.fnutils.concat({"⌘"}, modifiers),
        paths = {
            videos = hs.fs.pathToAbsolute("~/Videos"),
            events = hs.fs.pathToAbsolute("~/Videos") .. "/events.json",
            template = hs.fs.pathToAbsolute("~/Videos/TEMPLATE"),
            camera = "/Volumes/EOS_DIGITAL/DCIM/100CANON"
        },
        frames = {
            recording = {w = 1280, h = 720, scale = 2},
            regular = {w = 1280, h = 800, scale = 2}
        },
        overlayPadding = 3,
        cameraDuration = hs.timer.minutes(27),
        frameRate = 25
    },
    state = nil
}
function recording.configuration.modal:entered()
    local builtInOutput = hs.audiodevice.findOutputByName("Built-in Output")
    builtInOutput:setOutputMuted(false)
    builtInOutput:setOutputVolume(20)
    hs.audiodevice.findOutputByName("Built-in Output + BlackHole 16ch"):setDefaultOutputDevice()
    hs.screen.primaryScreen():setMode(
        recording.configuration.frames.recording.w,
        recording.configuration.frames.recording.h,
        recording.configuration.frames.recording.scale)

    recording.state = {
        events = {
            start = nil,
            stop = nil,
            cameras = {},
            scenes = {},
            edits = {}
        },
        overlays = {
            [1] = hs.canvas.new({
                x = 0,
                y = 0,
                w = recording.configuration.frames.recording.w,
                h = recording.configuration.frames.recording.h
            }):appendElements({
                type = "rectangle",
                action = "fill",
                frame = {
                    x = recording.configuration.frames.recording.w * 3 / 4 +
                        recording.configuration.overlayPadding,
                    y = recording.configuration.frames.recording.h * 0 / 4 +
                        recording.configuration.overlayPadding,
                    w = recording.configuration.frames.recording.w * 1 / 4 -
                        recording.configuration.overlayPadding * 2,
                    h = recording.configuration.frames.recording.h * 1 / 4 -
                        recording.configuration.overlayPadding * 2
                },
                fillColor = {alpha = 0.5},
                roundedRectRadii = {
                    xRadius = roundedCornerRadius,
                    yRadius = roundedCornerRadius
                }
            }):behavior({"canJoinAllSpaces", "stationary"}),
            [2] = hs.canvas.new({
                x = 0,
                y = 0,
                w = recording.configuration.frames.recording.w,
                h = recording.configuration.frames.recording.h
            }):appendElements({
                type = "rectangle",
                action = "fill",
                fillColor = {alpha = 0.5}
            }):behavior({"canJoinAllSpaces", "stationary"})
        },
        cameraTimer = nil
    }

    hs.application.open("OBS")
    hs.dialog.blockAlert("🚪 🗄 🪟 💡 🎧 🎤 🔈 💻 🎥", "",
                         "Click me as you start recording on the camera")
    recording.startCamera()
    hs.execute([[npx obs-cli StartRecording]], true)
    hs.timer.doAfter(3, function()
        recording.updateEvents(function(time)
            hs.alert("🎬")
            recording.state.events.start = time - 30
            table.insert(recording.state.events.edits, time)
        end)
        hs.timer.doAfter(2, function()
            hs.application.open("OBS"):mainWindow():minimize()
            recording.switchToScene(2)
        end)
    end)

    hs.audiodevice.watcher.setCallback(function(event)
        if event == "dev#" then
            hs.dialog.blockAlert(
                "An audio device was connected or disconnected.", "")
        end
    end)
    hs.audiodevice.watcher.start()
end
function recording.updateEvents(updater)
    updater(hs.timer.secondsSinceEpoch())
    hs.json.write(recording.state.events, recording.configuration.paths.events,
                  true, true)
end
function recording.startCamera()
    recording.updateEvents(function(time)
        hs.alert("💻 🎥 👏")
        table.insert(recording.state.events.cameras, time)
        table.insert(recording.state.events.edits, time)
    end)
    hs.fnutils.each(recording.state.overlays, function(overlay)
        hs.fnutils.each(overlay, function(element)
            element.fillColor.red = 0
        end)
    end)
    if recording.state.cameraTimer ~= nil then
        recording.state.cameraTimer:stop()
    end
    recording.state.cameraTimer = hs.timer.doAfter(
                                      recording.configuration.cameraDuration,
                                      function()
            hs.fnutils.each(recording.state.overlays, function(overlay)
                hs.fnutils.each(overlay,
                                function(element)
                    element.fillColor.red = 1
                end)
            end)
        end)
end
function recording.switchToScene(scene)
    hs.fnutils.each(recording.state.overlays,
                    function(overlay) overlay:hide() end)
    hs.timer.doAfter(0.1, function()
        recording.updateEvents(function(time)
            table.insert(recording.state.events.scenes,
                         {start = time, scene = scene})
        end)
        hs.timer.doAfter(0.1, function()
            local overlay = recording.state.overlays[scene]
            if overlay ~= nil then overlay:show() end
        end)
    end)
end
recording.configuration.modal:bind(recording.configuration.modifiers, "Z",
                                   function() recording.switchToScene(2) end)
recording.configuration.modal:bind(recording.configuration.modifiers, "A",
                                   function() recording.switchToScene(1) end)
recording.configuration.modal:bind(recording.configuration.modifiers, "Q",
                                   function() recording.switchToScene(3) end)
recording.configuration.modal:bind(recording.configuration.modifiers, "S",
                                   function()
    hs.window.focusedWindow():move({
        x = 0 / 4 * recording.configuration.frames.recording.w,
        y = 0 / 4 * recording.configuration.frames.recording.h,
        w = 3 / 4 * recording.configuration.frames.recording.w,
        h = 4 / 4 * recording.configuration.frames.recording.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "X",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frames.recording.w,
        y = 1 / 4 * recording.configuration.frames.recording.h,
        w = 1 / 4 * recording.configuration.frames.recording.w,
        h = 3 / 4 * recording.configuration.frames.recording.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "E",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frames.recording.w,
        y = 1 / 4 * recording.configuration.frames.recording.h,
        w = 1 / 4 * recording.configuration.frames.recording.w,
        h = 1 / 4 * recording.configuration.frames.recording.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "D",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frames.recording.w,
        y = 2 / 4 * recording.configuration.frames.recording.h,
        w = 1 / 4 * recording.configuration.frames.recording.w,
        h = 1 / 4 * recording.configuration.frames.recording.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "C",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frames.recording.w,
        y = 3 / 4 * recording.configuration.frames.recording.h,
        w = 1 / 4 * recording.configuration.frames.recording.w,
        h = 1 / 4 * recording.configuration.frames.recording.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "space",
                                   function()
    recording.updateEvents(function(time)
        hs.alert("✂️", {}, hs.screen.mainScreen(), 0.1)
        table.insert(recording.state.events.edits, time)
    end)
end)
recording.configuration.modal:bind(modifiers, "return", function()
    local option = hs.dialog.blockAlert(
                       "Currently recording, do you really want to reload the Hammerspoon configuration?",
                       "", "No", "Yes")
    if option == "Yes" then hs.reload() end
end)
recording.configuration.modal:bind({"⌘", "⇧"}, "2", function()
    local option = hs.dialog.blockAlert("", "",
                                        "Click me as you restart recording on the camera",
                                        "Click me as you stop recording on the camera")
    if option == "Click me as you restart recording on the camera" then
        recording.startCamera()
    elseif option == "Click me as you stop recording on the camera" then
        recording.configuration.modal:exit()
    end
end)
function recording.configuration.modal:exited()
    recording.updateEvents(function(time) recording.state.events.stop = time end)

    hs.audiodevice.watcher.stop()

    recording.state.cameraTimer:stop()
    hs.fnutils.each(recording.state.overlays,
                    function(overlay) overlay:delete() end)

    hs.execute([[npx obs-cli StopRecording]], true)
    hs.application.open("OBS"):kill()

    hs.screen.primaryScreen():setMode(recording.configuration.frames.regular.w,
                                      recording.configuration.frames.regular.h,
                                      recording.configuration.frames.regular
                                          .scale)
    hs.audiodevice.findOutputByName("Built-in Output"):setDefaultOutputDevice()

    ::projectPrompt::
    local option, projectName = hs.dialog.textPrompt("Name:", "", "",
                                                     "Create Project", "Cancel")
    if option == "Cancel" then return end
    local projectDirectory = recording.configuration.paths.videos .. "/" ..
                                 projectName
    local projectFile = projectDirectory .. "/" .. projectName .. ".RPP"
    if hs.execute([[ls "]] .. projectDirectory .. [["]]) ~= "" then
        hs.dialog.blockAlert("Error", "Directory already exists: ‘" ..
                                 projectDirectory .. "’.")
        goto projectPrompt
    end

    hs.execute([[mkdir "]] .. projectDirectory .. [["]])

    local templateFileHandle = io.open(
                                   recording.configuration.paths.template ..
                                       "/TEMPLATE.RPP", "r")
    local projectRPP = templateFileHandle:read("*all")
    templateFileHandle:close()

    projectRPP = string.gsub(projectRPP, "LENGTH %d+", "LENGTH " ..
                                 recording.timeAbsoluteToRelative(
                                     recording.state.events.stop))

    local cameraItems = {}
    for index, start in ipairs(recording.state.events.cameras) do
        table.insert(cameraItems, [[
            <ITEM
                POSITION ]] .. recording.timeAbsoluteToRelative(start) .. [[

                LENGTH ]] ..
                         (recording.timeAbsoluteToRelative(
                             index < #recording.state.events.cameras and
                                 recording.state.events.cameras[index + 1] or
                                 recording.state.events.stop) -
                             recording.timeAbsoluteToRelative(start)) .. [[

                <SOURCE VIDEO
                    FILE "camera--]] .. index .. [[.mp4"
                >
            >
        ]])
    end
    projectRPP = string.gsub(projectRPP, "NAME Camera",
                             "%0\n" .. table.concat(cameraItems, "\n") .. "\n")

    local sceneItems = {}
    for index, scene in ipairs(recording.state.events.scenes) do
        table.insert(sceneItems, [[
            <ITEM
                NAME ]] .. scene.scene .. [[

                POSITION ]] .. recording.timeAbsoluteToRelative(scene.start) ..
                         [[

                LENGTH ]] ..
                         (recording.timeAbsoluteToRelative(
                             index < #recording.state.events.scenes and
                                 recording.state.events.scenes[index + 1].start or
                                 recording.state.events.stop) -
                             recording.timeAbsoluteToRelative(scene.start)) ..
                         [[

                <SOURCE VIDEOEFFECT
                    <CODE
                        | 
                    >
                >
            >
        ]])
    end
    projectRPP = string.gsub(projectRPP, "NAME Video",
                             "%0\n" .. table.concat(sceneItems, "\n") .. "\n")

    projectRPP = string.gsub(projectRPP, ">%s*$",
                             table.concat(
                                 hs.fnutils.map(recording.state.events.edits,
                                                function(position)
            return
                [[MARKER 0 ]] .. recording.timeAbsoluteToRelative(position) ..
                    [[ ""]]
        end), "\n") .. "\n%0")

    local projectFileHandle = io.open(projectFile, "w")
    projectFileHandle:write(projectRPP)
    projectFileHandle:close()

    hs.execute([[mv "]] .. recording.configuration.paths.events .. [[" "]] ..
                   projectDirectory .. [[/"]])
    hs.execute([[cp "]] .. recording.configuration.paths.template ..
                   [[/rounded-corners.png" "]] .. projectDirectory .. [[/"]])

    ::beforeRecordingFile::
    local recordingFile = string.gsub(hs.execute(
                                          [[ls "]] ..
                                              recording.configuration.paths
                                                  .videos ..
                                              [["/*.mkv | tail -n 1]]), "%s*$",
                                      "")
    if recordingFile == "" then
        local option = hs.dialog.blockAlert("Error",
                                            "Failed to find recording file: ‘" ..
                                                recording.configuration.paths
                                                    .videos .. "/*.mkv’.",
                                            "Retry", "Skip")
        if option == "Retry" then
            goto beforeRecordingFile
        elseif option == "Skip" then
            goto afterRecordingFile
        end
    end
    hs.execute([["]] .. recording.configuration.paths.template ..
                   [[/ffmpeg" -i "]] .. recordingFile ..
                   [[" -map 0:0 -c copy "]] .. projectDirectory ..
                   [[/computer.mp4" -map_channel 0.1.0 "]] .. projectDirectory ..
                   [[/microphone.wav" -map 0:2 "]] .. projectDirectory ..
                   [[/computer.wav" && mv "]] .. recordingFile .. [[" ~/.Trash]])
    ::afterRecordingFile::

    local cameraFiles
    local option = hs.dialog.blockAlert("", "",
                                        "Connect the camera SD card and then click me",
                                        "Skip")
    if option == "Skip" then goto afterCameraFiles end
    ::beforeCameraFiles::
    cameraFiles = hs.fnutils.split(string.gsub(
                                       hs.execute(
                                           [[ls "]] ..
                                               recording.configuration.paths
                                                   .camera ..
                                               [["/MVI_*.MP4 | tail -n ]] ..
                                               #recording.state.events.cameras),
                                       "%s*$", ""), "\n")
    if #cameraFiles ~= #recording.state.events.cameras then
        local option = hs.dialog.blockAlert("Error",
                                            "The number of files in the camera SD card (" ..
                                                #cameraFiles ..
                                                ") is different from the number of camera events (" ..
                                                #recording.state.events.cameras ..
                                                ").", "Retry", "Skip")
        if option == "Retry" then
            goto beforeCameraFiles
        elseif option == "Skip" then
            goto afterCameraFiles
        end
    end
    for index, file in ipairs(cameraFiles) do
        hs.execute([[cp "]] .. file .. [[" "]] .. projectDirectory ..
                       [[/camera--]] .. index .. [[.mp4"]])
    end
    ::afterCameraFiles::

    hs.open(projectFile)
end
function recording.timeAbsoluteToRelative(absolute)
    return math.floor((absolute - recording.state.events.start) *
                          recording.configuration.frameRate) /
               recording.configuration.frameRate
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

hs.hotkey.bind(modifiers, "P", function()
    hs.dialog.blockAlert("", [[
Font smoothing in Big Sur (https://tonsky.me/blog/monitors/):
$ defaults -currentHost write -g AppleFontSmoothing -int 0

Reinstall Command Line Tools (https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md#i-did-all-that-and-the-acid-test-still-does-not-pass--):
$ sudo rm -rf $(xcode-select -print-path) && sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --reset && xcode-select --install
]])
end)
