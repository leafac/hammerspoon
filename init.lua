hs.alert("Hammerspoon configuration loaded")

local mods = {"⌥", "⌃"}
local roundedCornerRadius = 10
hs.window.animationDuration = 0

hs.hotkey.bind(mods, "return", function() hs.reload() end)
hs.hotkey
    .bind(mods, ",", function() hs.execute("code ~/.hammerspoon", true) end)
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
    modal = hs.hotkey.modal.new({"⌘", "⇧"}, "2"),
    usbWatcher = nil,
    events = {start = nil, stop = nil, camera = nil}
    -- cameraOverlay = {canvas = nil, timer = nil}
}
function recording.modal:entered()
    hs.dialog.blockAlert("", [[
1. Doors.
2. Lights.
3. Windows.
4. Audio interface.
5. Camera.
6. Headphones.
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
    hs.dialog.blockAlert("OBS", [[
1. Microphone.
2. Computer audio.
3. Screen.
]], "Click me when your next click will be to “Start Recording”")
    local tap
    tap = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown},
                          function(event)
        recording.events.start = hs.timer.secondsSinceEpoch()
        hs.alert("“Start Recording” captured")
        tap:stop()
    end):start()
    hs.dialog.blockAlert("", "", "Click me right as you start the camera")
    hs.application.open("OBS"):mainWindow():minimize()
    recording.events.camera = {
        {start = hs.timer.secondsSinceEpoch(), stop = nil}
    }
    hs.json.write(recording.events, "~/Videos/events-backup.json", true, true)

    -- local frame = {w = 1280, h = 720}
    -- local padding = 3
    -- recording.cameraOverlay.canvas = hs.canvas.new(
    --                                      {
    --         x = frame.w * 3 / 4,
    --         y = frame.h * 0 / 4,
    --         w = frame.w * 1 / 4,
    --         h = frame.h * 1 / 4
    --     }):appendElements({
    --     type = "rectangle",
    --     action = "fill",
    --     frame = {
    --         x = padding,
    --         y = padding,
    --         w = frame.w * 1 / 4 - padding * 2,
    --         h = frame.h * 1 / 4 - padding * 2
    --     },
    --     fillColor = {alpha = 0.5},
    --     roundedRectRadii = {
    --         xRadius = roundedCornerRadius,
    --         yRadius = roundedCornerRadius
    --     }
    -- }):behavior({"canJoinAllSpaces", "stationary"}):show()
    -- recording.cameraOverlay.restart()
end
recording.modal:bind({"⌘", "⇧"}, "2", function()
    recording.events.camera[#recording.events.camera].stop =
        hs.timer.secondsSinceEpoch()
    local option = hs.dialog.blockAlert("Stop the camera", "",
                                        "Click me right as you restart camera",
                                        "Stop Recording")
    if option == "Click me right as you restart camera" then
        table.insert(recording.events.camera,
                     {start = hs.timer.secondsSinceEpoch(), stop = nil})
        hs.json.write(recording.events, "~/Videos/events-backup.json", true,
                      true)
    elseif option == "Stop Recording" then
        recording.modal:exit()
    end
end)
recording.modal:bind(mods, "return", function()
    local option = hs.dialog.blockAlert(
                       "Currently recording, do you really want to reload Hammerspoon configuration?",
                       "", "No", "Yes")
    if option == "Yes" then hs.reload() end
end)
function recording.modal:exited()
    recording.events.stop = hs.timer.secondsSinceEpoch()
    hs.json.write(recording.events, "~/Videos/events-backup.json", true, true)

    -- recording.cameraOverlay.timer:stop()
    -- recording.cameraOverlay.canvas:delete()

    hs.application.open("OBS")
    hs.dialog.blockAlert("", "",
                         [[Click me after having clicked on “Stop Recording”]])
    hs.application.open("OBS"):kill()

    hs.screen.primaryScreen():setMode(1280, 800, 2)

    hs.audiodevice.findOutputByName("Built-in Output"):setDefaultOutputDevice()

    recording.usbWatcher:stop()

    local projectOption, projectName = hs.dialog.textPrompt("Project name:", "",
                                                            "",
                                                            "Create Project",
                                                            "Cancel")
    if projectOption == "Cancel" then return end

    local projectsDirectory = hs.fs.pathToAbsolute("~/Videos")
    local projectDirectory = projectsDirectory .. "/" .. projectName
    hs.execute([[mkdir "]] .. projectDirectory .. [["]])

    local recordingFile = string.gsub(hs.execute(
                                          [[ls "]] .. projectsDirectory ..
                                              [["/*.mkv | tail -n 1]]), "%s*$",
                                      "")
    hs.execute([[~/Videos/TEMPLATE/ffmpeg -i "]] .. recordingFile ..
                   [[" -map 0:0 -c copy "]] .. projectDirectory ..
                   [[/computer.mp4" -map 0:1 -c copy "]] .. projectDirectory ..
                   [[/microphone.aac" -map 0:2 -c copy "]] .. projectDirectory ..
                   [[/computer.aac" && mv "]] .. recordingFile .. [[" ~/.Trash]])

    hs.dialog.blockAlert("", "",
                         "Click me when the recordings from the camera have been transferred to the computer")
    local cameraRecordings = hs.fnutils.split(
                                 string.gsub(
                                     hs.execute(
                                         [[ls "]] .. projectsDirectory ..
                                             [["/MVI_*.MP4 | tail -n ]] ..
                                             #recording.events.camera), "%s*$",
                                     ""), "\n")
    for index, cameraRecording in ipairs(cameraRecordings) do
        hs.execute([[mv "]] .. cameraRecording .. [[" "]] .. projectDirectory ..
                       [[/camera--]] .. index .. [[.mp4"]])
    end

    local templateDirectory = projectsDirectory .. "/TEMPLATE"
    local templateFileHandle =
        io.open(templateDirectory .. "/TEMPLATE.RPP", "r")
    local project = templateFileHandle:read("*all")
    templateFileHandle:close()
    project = string.gsub(project, "LENGTH 5", "LENGTH " ..
                              recording.events.stop - recording.events.start)
    for index, event in ipairs(recording.events.camera) do
        project = string.gsub(project, "NAME Camera", [[
%0
<ITEM
  POSITION ]] .. event.start - recording.events.start .. [[

  LENGTH ]] .. event.stop - event.start .. [[

  <SOURCE VIDEO
    FILE "camera--]] .. index .. [[.mp4"
  >
>
]])
        project = string.gsub(project, ">%s*$", [[
MARKER 0 ]] .. event.start - recording.events.start .. [[ ""
%0
]])
    end
    local projectFile = projectDirectory .. "/" .. projectName .. ".RPP"
    local projectFileHandle = io.open(projectFile, "w")
    projectFileHandle:write(project)
    projectFileHandle:close()
    hs.execute([[mv ~/Videos/events-backup.json ~/.Trash]])

    hs.execute([[cp "]] .. templateDirectory .. [[/rounded-corners.png" "]] ..
                   projectDirectory .. [["]])

    hs.execute([[open "]] .. projectFile .. [["]])
end
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

local screenBrightnessHack = {brightness = 100, canvases = {}}
hs.hotkey.bind(mods, "up", function()
    screenBrightnessHack.brightness = math.min(100,
                                               screenBrightnessHack.brightness +
                                                   10)
    screenBrightnessHack.update()
end)
hs.hotkey.bind(mods, "down", function()
    screenBrightnessHack.brightness = math.max(0,
                                               screenBrightnessHack.brightness -
                                                   10)
    screenBrightnessHack.update()
end)
function screenBrightnessHack.update()
    hs.alert("Brightness hack: " .. screenBrightnessHack.brightness)
    hs.fnutils.each(screenBrightnessHack.canvases,
                    function(canvas) canvas:delete() end)
    screenBrightnessHack.canvases = hs.fnutils.map(hs.screen.allScreens(),
                                                   function(screen)
        return hs.canvas.new(screen:fullFrame()):appendElements(
                   {
                type = "rectangle",
                action = "fill",
                fillColor = {
                    alpha = (100 - screenBrightnessHack.brightness) / 100
                }
            }):behavior({"canJoinAllSpaces", "stationary"}):show()
    end)
end

hs.hotkey.bind(mods, "P", function()
    hs.dialog.blockAlert("", [[
Font smoothing in Big Sur (https://tonsky.me/blog/monitors/):
$ defaults -currentHost write -g AppleFontSmoothing -int 0

Reinstall Command Line Tools (https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md#i-did-all-that-and-the-acid-test-still-does-not-pass--):
$ sudo rm -rf $(xcode-select -print-path) && sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --reset && xcode-select --install
]])
end)
