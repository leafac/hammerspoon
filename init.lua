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
    hs.window.focusedWindow():moveToScreen(
        hs.window.focusedWindow():screen():next())
end)

local recording = {
    configuration = {
        modal = hs.hotkey.modal.new({"⌘", "⇧"}, "2"),
        modifiers = hs.fnutils.concat({"⌘"}, modifiers),
        paths = {
            videos = hs.fs.pathToAbsolute("~/Videos"),
            template = hs.fs.pathToAbsolute("~/Videos/TEMPLATE")
        },
        frame = {w = 1280, h = 720},
        overlayPadding = 3
    },
    state = nil
}
function recording.configuration.modal:entered()
    recording.state = {
        overlays = nil,
        events = {start = nil, stop = nil, camera = {}, scenes = {}, edits = {}},
        cameraTimer = nil
    }

    local builtInOutput = hs.audiodevice.findOutputByName("Built-in Output")
    builtInOutput:setOutputMuted(false)
    builtInOutput:setOutputVolume(20)
    hs.audiodevice.findOutputByName("Built-in Output + BlackHole 16ch"):setDefaultOutputDevice()
    hs.audiodevice.watcher.setCallback(function(event)
        if event == "dev#" then
            hs.dialog.blockAlert(
                "An audio device was connected or disconnected.", "")
        end
    end)
    hs.audiodevice.watcher.start()

    hs.screen.primaryScreen():setMode(recording.configuration.frame.w,
                                      recording.configuration.frame.h, 2)
    recording.state.overlays = {
        [1] = hs.canvas.new({
            x = 0,
            y = 0,
            w = recording.configuration.frame.w,
            h = recording.configuration.frame.h
        }):appendElements({
            type = "rectangle",
            action = "fill",
            frame = {
                x = recording.configuration.frame.w * 3 / 4 +
                    recording.configuration.overlayPadding,
                y = recording.configuration.frame.h * 0 / 4 +
                    recording.configuration.overlayPadding,
                w = recording.configuration.frame.w * 1 / 4 -
                    recording.configuration.overlayPadding * 2,
                h = recording.configuration.frame.h * 1 / 4 -
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
            w = recording.configuration.frame.w,
            h = recording.configuration.frame.h
        }):appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = {alpha = 0.5}
        }):behavior({"canJoinAllSpaces", "stationary"})
    }

    hs.application.open("OBS")
    hs.dialog.blockAlert("", "🚪 🪟 💡 🎧 🎤 🔈 💻 🎥",
                         "Click me when your next click will be to “Start Recording” in OBS and on the camera at the same time")
    local startRecordingTap
    startRecordingTap = hs.eventtap({hs.eventtap.event.types.leftMouseDown}, function()
        startRecordingTap:stop()
        hs.alert("“Start Recording” captured")
        recording.updateEvents(function(time)
            recording.state.events.start = time
        end)
        recording.startCameraTimer()
        recording.scenes.switch(1)
    end):start()
end
function recording.startCameraTimer()
    hs.dialog.blockAlert("💻 🎥 👏", tostring(
                             hs.timer.secondsSinceEpoch() -
                                 recording.state.events.start))
end
function recording.updateEvents(updater)
    updater(hs.timer.secondsSinceEpoch())
    hs.json.write(recording.state.events,
                  recording.configuration.paths.videos .. "/events.json")
end
function recording.scenes.start()
    hs.fnutils.each(recording.state.overlays, function(overlay)
        for _, element in pairs(overlay) do element.fillColor.red = 0 end
    end)
    if recording.scenes.timer ~= nil then recording.scenes.timer:stop() end
    recording.scenes.timer = hs.timer.doAfter(hs.timer.minutes(27), function()
        hs.fnutils.each(recording.state.overlays, function(overlay)
            for _, element in pairs(overlay) do
                element.fillColor.red = 1
            end
        end)
    end)
    hs.application.open("REAPER")
    hs.dialog.blockAlert("REAPER", "🔴")
    hs.application.open("OBS")
    hs.dialog.blockAlert("OBS", "🔴")
    hs.dialog.blockAlert("🎥 👏", "")
end
function recording.scenes.switch(identifier)
    hs.http.get("http://localhost:4445/_/" .. ({
        [1] = "_RSb05e5059d9f46f784496241c368683e104496408",
        [2] = "_RS5a192aa77f307656aa8b7322aa253f24a28ee6cb",
        [3] = "_RS166e0af08557fa557a9e1e4938f7b06718daa334"
    })[identifier])
    hs.fnutils.each(recording.state.overlays,
                    function(overlay) overlay:hide() end)
    local overlay = recording.state.overlays[identifier]
    if overlay ~= nil then overlay:show() end
end
recording.configuration.modal:bind(recording.configuration.modifiers, "Z",
                                   function() recording.scenes.switch(2) end)
recording.configuration.modal:bind(recording.configuration.modifiers, "A",
                                   function() recording.scenes.switch(1) end)
recording.configuration.modal:bind(recording.configuration.modifiers, "Q",
                                   function() recording.scenes.switch(3) end)
recording.configuration.modal:bind(recording.configuration.modifiers, "S",
                                   function()
    hs.window.focusedWindow():move({
        x = 0 / 4 * recording.configuration.frame.w,
        y = 0 / 4 * recording.configuration.frame.h,
        w = 3 / 4 * recording.configuration.frame.w,
        h = 4 / 4 * recording.configuration.frame.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "X",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frame.w,
        y = 1 / 4 * recording.configuration.frame.h,
        w = 1 / 4 * recording.configuration.frame.w,
        h = 3 / 4 * recording.configuration.frame.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "E",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frame.w,
        y = 1 / 4 * recording.configuration.frame.h,
        w = 1 / 4 * recording.configuration.frame.w,
        h = 1 / 4 * recording.configuration.frame.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "D",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frame.w,
        y = 2 / 4 * recording.configuration.frame.h,
        w = 1 / 4 * recording.configuration.frame.w,
        h = 1 / 4 * recording.configuration.frame.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "C",
                                   function()
    hs.window.focusedWindow():move({
        x = 3 / 4 * recording.configuration.frame.w,
        y = 3 / 4 * recording.configuration.frame.h,
        w = 1 / 4 * recording.configuration.frame.w,
        h = 1 / 4 * recording.configuration.frame.h
    })
end)
recording.configuration.modal:bind(recording.configuration.modifiers, "space",
                                   function()
    hs.http.get("http://localhost:4445/_/40157")
    hs.alert("✂️")
end)
recording.configuration.modal:bind(modifiers, "return", function()
    local option = hs.dialog.blockAlert(
                       "Currently recording, do you really want to reload the Hammerspoon configuration?",
                       "", "No", "Yes")
    if option == "Yes" then hs.reload() end
end)
recording.configuration.modal:bind({"⌘", "⇧"}, "2", function()
    local option = hs.dialog.blockAlert("", "",
                                        "Click me right as you RESTART recording on the camera",
                                        "Click me right as you STOP recording on the camera")
    if option == "Click me right as you RESTART recording on the camera" then
        hs.http.get("http://localhost:4445/_/40157")
        recording.scenes.start()
    elseif option == "Click me right as you STOP recording on the camera" then
        recording.configuration.modal:exit()
    end
end)
function recording.configuration.modal:exited()
    -- recording.state.events = 
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

    hs.open(projectFile)
    hs.dialog.blockAlert("REAPER", "🎤 🔈")

    recording.scenes.timer:stop()
    hs.fnutils.each(recording.state.overlays,
                    function(overlay) overlay:delete() end)

    hs.execute([[npx obs-cli StopRecording]], true)
    hs.execute([[npx obs-cli SetRecordingFolder '{ \"rec-folder\": \"]] ..
                   hs.fs.pathToAbsolute("~/Videos") .. [[\" }']], true)
    hs.application.open("OBS"):kill()
    hs.http.get("http://localhost:4445/_/1016")
    hs.application.open("REAPER")

    hs.screen.primaryScreen():setMode(1280, 800, 2)

    hs.audiodevice.watcher.stop()
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
