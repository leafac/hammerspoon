hs.alert("Hammerspoon configuration loaded")

local modifiers = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0

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
            template = hs.fs.pathToAbsolute("~/Videos/TEMPLATE"),
            camera = "/Volumes/EOS_DIGITAL/DCIM/100CANON"
        },
        frames = {
            recording = {w = 1280, h = 720, scale = 2},
            regular = {w = 1280, h = 800, scale = 2}
        },
        overlayPadding = 3,
        cameraDuration = hs.timer.minutes(27)
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
        overlays = nil,
        cameraTimer = nil
    }

    hs.application.open("OBS")
    repeat
        hs.dialog.blockAlert("🚪 🗄 🪟 💡 🎧 🎤 🔈 💻 🎥", "",
                             "Click me when your next click will be to “Start Recording” in OBS")
        local startRecordingTap
        startRecordingTap = hs.eventtap.new(
                                {hs.eventtap.event.types.leftMouseUp},
                                function()
                recording.updateEvents(function(time)
                    recording.state.events.start = time
                end)
                startRecordingTap:stop()
                hs.alert("“Start Recording” captured")
            end):start()
    until hs.dialog.blockAlert("", "",
                               "Click me after you have clicked on “Start Recording” in OBS",
                               "Retry") ==
        "Click me after you have clicked on “Start Recording” in OBS"
    hs.application.open("OBS"):mainWindow():minimize()

    hs.audiodevice.watcher.setCallback(function(event)
        if event == "dev#" then
            hs.dialog.blockAlert(
                "An audio device was connected or disconnected.", "")
        end
    end)
    hs.audiodevice.watcher.start()

    recording.state.overlays = {
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
    }

    recording.startCamera()
    recording.switchToScene(2)
end
function recording.updateEvents(updater)
    updater(hs.timer.secondsSinceEpoch())
    hs.json.write(recording.state.events,
                  recording.configuration.paths.videos .. "/events.json", true,
                  true)
end
function recording.startCamera()
    hs.dialog.blockAlert("", "",
                         "Click me right as you start recording on the camera")
    recording.updateEvents(function(time)
        table.insert(recording.state.events.cameras, time)
    end)
    hs.alert("💻 🎥 👏")
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
    recording.updateEvents(function(time)
        table.insert(recording.state.events.scenes,
                     {start = time, scene = scene})
    end)
    hs.fnutils.each(recording.state.overlays,
                    function(overlay) overlay:hide() end)
    local overlay = recording.state.overlays[scene]
    if overlay ~= nil then overlay:show() end
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
        table.insert(recording.state.events.edits, time)
    end)
    hs.alert("✂️", {}, hs.screen.mainScreen(), 0.1)
end)
recording.configuration.modal:bind(modifiers, "return", function()
    local option = hs.dialog.blockAlert(
                       "Currently recording, do you really want to reload the Hammerspoon configuration?",
                       "", "No", "Yes")
    if option == "Yes" then hs.reload() end
end)
recording.configuration.modal:bind({"⌘", "⇧"}, "2", function()
    local option = hs.dialog.blockAlert("Stop recording on the camera", "",
                                        "Continue Recording", "Stop Recording")
    if option == "Continue Recording" then
        recording.startCamera()
    elseif option == "Stop Recording" then
        recording.configuration.modal:exit()
    end
end)
function recording.configuration.modal:exited()
    recording.updateEvents(function(time) recording.state.events.stop = time end)

    recording.state.cameraTimer:stop()

    hs.fnutils.each(recording.state.overlays,
                    function(overlay) overlay:delete() end)

    hs.audiodevice.watcher.stop()

    hs.application.open("OBS")
    hs.dialog.blockAlert("", "",
                         "Click me after you have clicked on “Stop Recording” in OBS")
    hs.application.open("OBS"):kill()

    hs.screen.primaryScreen():setMode(recording.configuration.frames.regular.w,
                                      recording.configuration.frames.regular.h,
                                      recording.configuration.frames.regular
                                          .scale)
    hs.audiodevice.findOutputByName("Built-in Output"):setDefaultOutputDevice()

    local projectName, projectDirectory
    repeat
        local option
        option, projectName = hs.dialog.textPrompt("Project Name:", "", "",
                                                   "Create Project", "Cancel")
        if option == "Cancel" then return end
        projectDirectory = recording.configuration.paths.videos .. "/" ..
                               projectName
        if hs.execute([[ls "]] .. projectDirectory .. [["]]) == "" then
            break
        elseif hs.dialog.blockAlert("Error", "Project already exists: ‘" ..
                                        projectDirectory .. "’.", "Retry",
                                    "Cancel") == "Cancel" then
            return
        end
    until false
    hs.execute([[mkdir "]] .. projectDirectory .. [["]])
    hs.execute([[cp "]] .. recording.configuration.paths.template ..
                   [[/rounded-corners.png" "]] .. projectDirectory .. [[/"]])
    hs.execute([[mv "]] .. recording.configuration.paths.videos ..
                   [[/events.json" "]] .. projectDirectory .. [[/"]])

    local templateFileHandle = io.open(
                                   recording.configuration.paths.template ..
                                       "/TEMPLATE.RPP", "r")
    local projectText = templateFileHandle:read("*all")
    templateFileHandle:close()

    projectText = string.gsub(projectText, "LENGTH %d+", "LENGTH " ..
                                  (recording.state.events.stop -
                                      recording.state.events.start))

    local cameraItems = {}
    local cameraMarkers = {}
    for index, start in ipairs(recording.state.events.cameras) do
        table.insert(cameraItems, [[
            <ITEM
                POSITION ]] .. (start - recording.state.events.start) .. [[

                LENGTH ]] .. ((index < #recording.state.events.cameras and
                         recording.state.events.cameras[index + 1] or
                         recording.state.events.stop) - start) .. [[

                <SOURCE VIDEO
                    FILE "camera--]] .. index .. [[.mp4"
                >
            >
        ]])
        table.insert(cameraMarkers,
                     [[MARKER 0 ]] .. (start - recording.state.events.start) ..
                         [[ "Camera ]] .. index .. [["]])
    end
    projectText = string.gsub(projectText, "NAME Camera",
                              "%0\n" .. table.concat(cameraItems, "\n") .. "\n")
    projectText = string.gsub(projectText, ">%s*$",
                              table.concat(cameraMarkers, "\n") .. "\n%0")

    local sceneItems = {}
    local sceneMarkers = {}
    for index, scene in ipairs(recording.state.events.scenes) do
        table.insert(sceneItems, [[
            <ITEM
                NAME ]] .. scene.scene .. [[

                POSITION ]] .. (scene.start - recording.state.events.start) ..
                         [[

                LENGTH ]] .. ((index < #recording.state.events.scenes and
                         recording.state.events.scenes[index + 1].start or
                         recording.state.events.stop) - scene.start) .. [[

                <SOURCE VIDEOEFFECT
                    <CODE
                        | 
                    >
                >
            >
        ]])
        table.insert(sceneMarkers,
                     [[MARKER 0 ]] ..
                         (scene.start - recording.state.events.start) ..
                         [[ "Scene ]] .. scene.scene .. [["]])
    end
    projectText = string.gsub(projectText, "NAME Video",
                              "%0\n" .. table.concat(sceneItems, "\n") .. "\n")
    projectText = string.gsub(projectText, ">%s*$",
                              table.concat(sceneMarkers, "\n") .. "\n%0")

    projectText = string.gsub(projectText, ">%s*$",
                              table.concat(
                                  hs.fnutils.map(recording.state.events.edits,
                                                 function(edit)
            return [[MARKER 0 ]] ..
                       (edit - recording.state.events.start .. [[ ""]])
        end), "\n") .. "\n%0")

    local projectFile = projectDirectory .. "/" .. projectName .. ".RPP"
    local projectFileHandle = io.open(projectFile, "w")
    projectFileHandle:write(projectText)
    projectFileHandle:close()

    local recordingFile
    repeat
        recordingFile = string.gsub(hs.execute(
                                        [[ls "]] ..
                                            recording.configuration.paths.videos ..
                                            [["/*.mkv | tail -n 1]]), "%s*$", "")
        if recordingFile ~= "" then
            break
        elseif hs.dialog.blockAlert("Error",
                                    "No recording file: ‘" ..
                                        recording.configuration.paths.videos ..
                                        "/*.mkv’.", "Retry", "Cancel") ==
            "Cancel" then
            return
        end
    until false
    hs.execute([["]] .. recording.configuration.paths.template ..
                   [[/ffmpeg" -i "]] .. recordingFile ..
                   [[" -map 0:0 -c copy "]] .. projectDirectory ..
                   [[/computer.mp4" -map 0:1 -c copy "]] .. projectDirectory ..
                   [[/microphone.aac" -map 0:2 -c copy "]] .. projectDirectory ..
                   [[/computer.aac" && mv "]] .. recordingFile .. [[" ~/.Trash]])

    local cameraFiles
    repeat
        hs.dialog.blockAlert("", "",
                             "Click me after having connected the camera SD card")
        cameraFiles = hs.fnutils.split(string.gsub(
                                           hs.execute(
                                               [[ls "]] ..
                                                   recording.configuration.paths
                                                       .camera ..
                                                   [["/MVI_*.MP4 | tail -n ]] ..
                                                   #recording.state.events
                                                       .cameras), "%s*$", ""),
                                       "\n")
        if #cameraFiles == #recording.state.events.cameras then
            break
        elseif hs.dialog.blockAlert("Error",
                                    "The number of files in the camera SD card (" ..
                                        #cameraFiles ..
                                        ") doesn’t match the number of camera events (" ..
                                        #recording.state.events.cameras .. ").",
                                    "Retry", "Cancel") == "Cancel" then
            return
        end
    until false
    for index, file in ipairs(cameraFiles) do
        hs.execute([[cp "]] .. file .. [[" "]] .. projectDirectory ..
                       [[/camera--]] .. index .. [[.mp4"]])
    end

    hs.open(projectFile)
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
