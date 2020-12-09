::configuration::
local configuration
do
    hs.alert("Hammerspoon configuration loaded")

    configuration = {modifiers = {"⌥", "⌃"}, roundedCornerRadius = 10}
    preventGarbageCollection = {}
    hs.window.animationDuration = 0

    hs.hotkey
        .bind(configuration.modifiers, "return", function() hs.reload() end)
    hs.hotkey.bind(configuration.modifiers, ",",
                   function() hs.execute([[code ~/.hammerspoon]], true) end)
    hs.hotkey.bind(configuration.modifiers, "space",
                   function() hs.toggleConsole() end)
    hs.hotkey.bind(configuration.modifiers, "escape", function()
        hs.osascript.applescript("beep")
        hs.sound.getByName("Submarine"):play()
    end)
end
::endConfiguration::

::windowManagement::
do
    hs.hotkey.bind(configuration.modifiers, "W", function()
        hs.window.focusedWindow():move({
            x = 0 / 2,
            y = 0 / 2,
            w = 2 / 2,
            h = 1 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "E", function()
        hs.window.focusedWindow():move({
            x = 1 / 2,
            y = 0 / 2,
            w = 1 / 2,
            h = 1 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "D", function()
        hs.window.focusedWindow():move({
            x = 1 / 2,
            y = 0 / 2,
            w = 1 / 2,
            h = 2 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "C", function()
        hs.window.focusedWindow():move({
            x = 1 / 2,
            y = 1 / 2,
            w = 1 / 2,
            h = 1 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "X", function()
        hs.window.focusedWindow():move({
            x = 0 / 2,
            y = 1 / 2,
            w = 2 / 2,
            h = 1 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "Z", function()
        hs.window.focusedWindow():move({
            x = 0 / 2,
            y = 1 / 2,
            w = 1 / 2,
            h = 1 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "A", function()
        hs.window.focusedWindow():move({
            x = 0 / 2,
            y = 0 / 2,
            w = 1 / 2,
            h = 2 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "Q", function()
        hs.window.focusedWindow():move({
            x = 0 / 2,
            y = 0 / 2,
            w = 1 / 2,
            h = 1 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "S", function()
        hs.window.focusedWindow():move({
            x = 0 / 2,
            y = 0 / 2,
            w = 2 / 2,
            h = 2 / 2
        })
    end)
    hs.hotkey.bind(configuration.modifiers, "tab", function()
        local window = hs.window.focusedWindow()
        window:moveToScreen(window:screen():next())
    end)
end
::endWindowManagement::

::dateMenubar::
local dateMenubar
do
    dateMenubar = hs.menubar.new():setClickCallback(
                      function() hs.application.open("Calendar") end)
    preventGarbageCollection.dateMenubarTimer =
        hs.timer.doEvery(1, function()
            dateMenubar:setTitle(os.date("%Y-%m-%d  %H:%M  %A"))
        end):fire()
end
::endDateMenubar::

::screenRoundedCorners::
do
    local canvases = {}
    local function start()
        for _, canvas in pairs(canvases) do canvas:delete() end
        canvases = {}
        for _, screen in pairs(hs.screen.allScreens()) do
            table.insert(canvases,
                         hs.canvas.new(screen:fullFrame()):appendElements(
                             {
                    type = "rectangle",
                    action = "fill",
                    fillColor = {hex = "#000"}
                }, {
                    type = "rectangle",
                    action = "fill",
                    compositeRule = "sourceOut",
                    roundedRectRadii = {
                        xRadius = configuration.roundedCornerRadius,
                        yRadius = configuration.roundedCornerRadius
                    }
                }):behavior({"canJoinAllSpaces", "stationary"}):show())
        end
    end
    start()
    preventGarbageCollection.screenRoundedCornersScreenWatcher =
        hs.screen.watcher.new(function() start() end):start()
end
::endScreenRoundedCorners::

::commands::
do
    hs.hotkey.bind(configuration.modifiers, "P", function()
        hs.dialog.blockAlert("", [[
Font smoothing in Big Sur (https://tonsky.me/blog/monitors/):
$ defaults -currentHost write -g AppleFontSmoothing -int 0

Reinstall Command Line Tools (https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md#i-did-all-that-and-the-acid-test-still-does-not-pass--):
$ sudo rm -rf $(xcode-select -print-path) && sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --reset && xcode-select --install
]])
    end)
end
::endCommands::

::recording::
do
    ::recordingConfiguration::
    local recording
    do
        recording = {
            configuration = {
                modal = hs.hotkey.modal.new({"⌘", "⇧"}, "2"),
                modifiers = {"⌘", "⌥", "⌃"},
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
    end
    ::endRecordingConfiguration::

    function recording.configuration.modal:entered()
        ::state::
        do
            recording.state = {
                events = {
                    cameraStarts = {},
                    multicamTransitions = {},
                    markers = {},
                    stop = nil
                },
                overlays = nil,
                cameraTimer = nil
            }
        end
        ::endState::

        ::hardware::
        do
            local builtInOutput = hs.audiodevice.findOutputByName(
                                      "Built-in Output")
            builtInOutput:setOutputMuted(false)
            builtInOutput:setOutputVolume(20)
            hs.audiodevice.findOutputByName("Recording"):setDefaultOutputDevice()
            hs.screen.primaryScreen():setMode(
                recording.configuration.frames.recording.w,
                recording.configuration.frames.recording.h,
                recording.configuration.frames.recording.scale)
            dateMenubar:removeFromMenuBar()
        end
        ::endHardware::

        ::overlays::
        do
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
                        xRadius = configuration.roundedCornerRadius,
                        yRadius = configuration.roundedCornerRadius
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
        end
        ::endOverlays::

        ::recording::
        do
            hs.application.open("OBS")
            hs.dialog.blockAlert("🚪 🗄 🪟 💡 🎧 🎤 🔈 💻 🎥",
                                 "", "Start Recording")
            hs.application.open("OBS"):mainWindow():minimize()
            hs.execute([[npx obs-cli StartRecording]], true)
            recording.startCamera()
            recording.multicamTransition(2)
            hs.audiodevice.watcher.setCallback(
                function(event)
                    if event == "dev#" then
                        hs.dialog.blockAlert(
                            "An audio device was connected or disconnected.", "")
                    end
                end)
            hs.audiodevice.watcher.start()
        end
        ::endRecording::
    end

    ::events::
    do
        function recording.startCamera()
            hs.dialog
                .blockAlert("", "", "Start/Restart Recording on the Camera")
            recording.updateEvents(function(time)
                hs.alert("💻 🎥 👏")
                table.insert(recording.state.events.cameraStarts, time)
                table.insert(recording.state.events.markers, time)
            end)
            if recording.state.cameraTimer ~= nil then
                recording.state.cameraTimer:stop()
            end
            for _, overlay in pairs(recording.state.overlays) do
                for _, element in pairs(overlay) do
                    element.fillColor.red = 0
                end
            end
            recording.state.cameraTimer =
                hs.timer.doAfter(recording.configuration.cameraDuration,
                                 function()
                    for _, overlay in pairs(recording.state.overlays) do
                        for _, element in pairs(overlay) do
                            element.fillColor.red = 1
                        end
                    end
                end)
        end

        function recording.multicamTransition(camera)
            for _, overlay in pairs(recording.state.overlays) do
                overlay:hide()
            end
            hs.timer.doAfter(0.1, function()
                recording.updateEvents(function(time)
                    table.insert(recording.state.events.multicamTransitions,
                                 {position = time, camera = camera})
                end)
                hs.timer.doAfter(0.1, function()
                    local overlay = recording.state.overlays[camera]
                    if overlay ~= nil then overlay:show() end
                end)
            end)
        end
    end
    ::endEvents::

    ::multicamTransitions::
    do
        for camera = 1, 5 do
            recording.configuration.modal:bind(configuration.modifiers,
                                               tostring(camera), function()
                recording.multicamTransition(camera)
            end)
        end
    end
    ::endMulticamTransitions::

    ::recordingWindowManagement::
    do
        recording.configuration.modal:bind(recording.configuration.modifiers,
                                           "A", function()
            hs.window.focusedWindow():move(
                {
                    x = 0 / 4 * recording.configuration.frames.recording.w,
                    y = 0 / 4 * recording.configuration.frames.recording.h,
                    w = 3 / 4 * recording.configuration.frames.recording.w,
                    h = 4 / 4 * recording.configuration.frames.recording.h
                })
        end)
        recording.configuration.modal:bind(recording.configuration.modifiers,
                                           "S", function()
            hs.window.focusedWindow():move(
                {
                    x = 3 / 4 * recording.configuration.frames.recording.w,
                    y = 1 / 4 * recording.configuration.frames.recording.h,
                    w = 1 / 4 * recording.configuration.frames.recording.w,
                    h = 3 / 4 * recording.configuration.frames.recording.h
                })
        end)
        recording.configuration.modal:bind(recording.configuration.modifiers,
                                           "E", function()
            hs.window.focusedWindow():move(
                {
                    x = 3 / 4 * recording.configuration.frames.recording.w,
                    y = 1 / 4 * recording.configuration.frames.recording.h,
                    w = 1 / 4 * recording.configuration.frames.recording.w,
                    h = 1 / 4 * recording.configuration.frames.recording.h
                })
        end)
        recording.configuration.modal:bind(recording.configuration.modifiers,
                                           "D", function()
            hs.window.focusedWindow():move(
                {
                    x = 3 / 4 * recording.configuration.frames.recording.w,
                    y = 2 / 4 * recording.configuration.frames.recording.h,
                    w = 1 / 4 * recording.configuration.frames.recording.w,
                    h = 1 / 4 * recording.configuration.frames.recording.h
                })
        end)
        recording.configuration.modal:bind(recording.configuration.modifiers,
                                           "C", function()
            hs.window.focusedWindow():move(
                {
                    x = 3 / 4 * recording.configuration.frames.recording.w,
                    y = 3 / 4 * recording.configuration.frames.recording.h,
                    w = 1 / 4 * recording.configuration.frames.recording.w,
                    h = 1 / 4 * recording.configuration.frames.recording.h
                })
        end)
    end
    ::endRecordingWindowManagement::

    ::actions::
    do
        recording.configuration.modal:bind(recording.configuration.modifiers,
                                           "space", function()
            recording.updateEvents(function(time)
                hs.alert("✂️", {}, hs.screen.mainScreen(), 0.2)
                table.insert(recording.state.events.markers, time)
            end)
        end)

        recording.configuration.modal:bind(configuration.modifiers, "return",
                                           function()
            local option = hs.dialog.blockAlert(
                               "Currently recording, do you really want to reload the Hammerspoon configuration?",
                               "", "No", "Yes")
            if option == "Yes" then hs.reload() end
        end)

        recording.configuration.modal:bind({"⌘", "⇧"}, "2", function()
            local option = hs.dialog.blockAlert("Stop recording on the camera",
                                                "", "Continue Recording",
                                                "Stop Recording")
            if option == "Continue Recording" then
                recording.startCamera()
            elseif option == "Stop Recording" then
                recording.configuration.modal:exit()
            end
        end)
    end
    ::endActions::

    function recording.configuration.modal:exited()
        ::recording::
        do
            recording.updateEvents(function(time)
                recording.state.events.stop = time
            end)
            hs.audiodevice.watcher.stop()
            recording.state.cameraTimer:stop()
            hs.execute([[npx obs-cli StopRecording]], true)
            hs.application.open("OBS"):kill()
        end
        ::endRecording::

        ::overlays::
        do
            for _, overlay in pairs(recording.state.overlays) do
                overlay:delete()
            end
        end
        ::endOverlays::

        ::hardware::
        do
            dateMenubar:returnToMenuBar()
            hs.screen.primaryScreen():setMode(
                recording.configuration.frames.regular.w,
                recording.configuration.frames.regular.h,
                recording.configuration.frames.regular.scale)
            hs.audiodevice.findOutputByName("Built-in Output"):setDefaultOutputDevice()
        end
        ::endHardware::

        ::project::
        do
            ::name::
            local projectDirectory, projectFile
            do
                local option, name = hs.dialog.textPrompt("Name:", "", "",
                                                          "Create Project",
                                                          "Cancel")
                if option == "Cancel" then goto endProject end
                projectDirectory =
                    recording.configuration.paths.videos .. "/" .. name
                projectFile = projectDirectory .. "/" .. name .. ".RPP"
                if hs.execute([[ls "]] .. projectDirectory .. [["]]) ~= "" then
                    hs.dialog.blockAlert("Error",
                                         "Directory already exists: ‘" ..
                                             projectDirectory .. "’.")
                    goto name
                end
            end
            ::endName::

            ::projectDirectory::
            do hs.execute([[mkdir "]] .. projectDirectory .. [["]]) end
            ::endProjectDirectory::

            ::REAPER::
            do
                local project
                ::readTemplate::
                do
                    local fileHandle = assert(
                                           io.open(
                                               recording.configuration.paths
                                                   .template .. "/TEMPLATE.RPP",
                                               "r"))
                    project = fileHandle:read("a")
                    fileHandle:close()
                end
                ::endReadTemplate::

                ::templateItemslengths::
                do
                    project = string.gsub(project, "LENGTH %d+", "LENGTH " ..
                                              recording.state.events.stop)
                end
                ::endTemplateItemsLengths::

                ::cameraStarts::
                do
                    local items = ""
                    for index, position in
                        ipairs(recording.state.events.cameraStarts) do
                        items = items .. [[
                            <ITEM
                                POSITION ]] .. position .. [[

                                LENGTH ]] ..
                                    ((index <
                                        #recording.state.events.cameraStarts and
                                        recording.state.events.cameraStarts[index +
                                            1] or recording.state.events.stop) -
                                        position) .. [[

                                <SOURCE VIDEO
                                    FILE "camera--]] .. index .. [[.mp4"
                                >
                            >
                        ]]
                    end
                    project = string.gsub(project, "NAME Camera", items .. "%0")
                end
                ::endCameraStarts::

                ::multicamTransitions::
                do
                    local items = ""
                    for index, multicamTransition in
                        ipairs(recording.state.events.multicamTransitions) do
                        items = items .. [[
                            <ITEM
                                NAME ]] .. multicamTransition.camera .. [[

                                POSITION ]] .. multicamTransition.position .. [[

                                LENGTH ]] ..
                                    ((index <
                                        #recording.state.events
                                            .multicamTransitions and
                                        recording.state.events
                                            .multicamTransitions[index + 1]
                                            .position or
                                        recording.state.events.stop) -
                                        multicamTransition.position) .. [[

                                <SOURCE VIDEOEFFECT
                                    <CODE
                                        | 
                                    >
                                >
                            >
                        ]]
                    end
                    project = string.gsub(project, "NAME Video", items .. "%0")
                end
                ::endMulticamTransitions::

                ::markers::
                do
                    local markers = ""
                    for index, position in
                        ipairs(recording.state.events.markers) do
                        markers = markers .. [[MARKER ]] .. index .. [[ ]] ..
                                      position .. [[ ""]] .. "\n"
                    end
                    project = string.gsub(project, ">%s*$", markers .. "%0")
                end
                ::endMarkers::

                ::writeProject::
                do
                    local fileHandle = assert(io.open(projectFile, "w"))
                    fileHandle:write(project)
                    fileHandle:close()
                end
                ::endWriteProject::
            end
            ::endREAPER::

            ::staticFiles::
            do
                hs.execute([[mv "]] .. recording.configuration.paths.events ..
                               [[" "]] .. projectDirectory .. [[/"]])
                hs.execute([[cp "]] .. recording.configuration.paths.template ..
                               [[/rounded-corners.png" "]] .. projectDirectory ..
                               [[/"]])
            end
            ::endStaticFiles::

            ::remuxRecording::
            do
                local recordingFile = string.match(
                                          hs.execute(
                                              [[ls "]] ..
                                                  recording.configuration.paths
                                                      .videos ..
                                                  [["/*.mkv | tail -n 1]]),
                                          "[^\n]+")
                if recordingFile == "" then
                    local option = hs.dialog.blockAlert("Error",
                                                        "Failed to find recording file: ‘" ..
                                                            recording.configuration
                                                                .paths.videos ..
                                                            "/*.mkv’.",
                                                        "Retry", "Skip")
                    if option == "Retry" then
                        goto remuxRecording
                    elseif option == "Skip" then
                        goto endRemuxRecording
                    end
                end
                hs.execute([["]] .. recording.configuration.paths.template ..
                               [[/ffmpeg" -i "]] .. recordingFile ..
                               [[" -map 0:0 -c copy "]] .. projectDirectory ..
                               [[/computer.mp4" -map_channel 0.1.0 "]] ..
                               projectDirectory ..
                               [[/microphone.wav" -map 0:2 "]] ..
                               projectDirectory .. [[/computer.wav" && mv "]] ..
                               recordingFile .. [[" ~/.Trash]])
            end
            ::endRemuxRecording::

            ::cameraFiles::
            do
                local option = hs.dialog.blockAlert("", "",
                                                    "Connect the camera SD card and then click me",
                                                    "Skip")
                if option == "Skip" then goto endCameraFiles end
                ::retry::
                local cameraFiles = {}
                for cameraFile in string.gmatch(
                                      hs.execute(
                                          [[ls "]] ..
                                              recording.configuration.paths
                                                  .camera ..
                                              [["/MVI_*.MP4 | tail -n ]] ..
                                              #recording.state.events
                                                  .cameraStarts), "[^\n]+") do
                    table.insert(cameraFiles, cameraFile)
                end
                if #cameraFiles ~= #recording.state.events.cameraStarts then
                    local option = hs.dialog.blockAlert("Error",
                                                        "The number of files in the camera SD card (" ..
                                                            #cameraFiles ..
                                                            ") is different from the number of camera start events (" ..
                                                            #recording.state
                                                                .events
                                                                .cameraStarts ..
                                                            ").", "Retry",
                                                        "Skip")
                    if option == "Retry" then
                        goto retry
                    elseif option == "Skip" then
                        goto endCameraFiles
                    end
                end
                for index, file in ipairs(cameraFiles) do
                    hs.execute(
                        [[cp "]] .. file .. [[" "]] .. projectDirectory ..
                            [[/camera--]] .. index .. [[.mp4"]])
                end
            end
            ::endCameraFiles::

            ::openProject::
            do hs.open(projectFile) end
            ::endOpenProject::
        end
        ::endProject::
    end

    ::auxiliaryFunctions::
    do
        function recording.updateEvents(updater)
            local streamingStatus = hs.execute(
                                        [[npx obs-cli GetStreamingStatus]], true)
            local hours, minutes, seconds, milliseconds =
                string.match(hs.json.decode(streamingStatus).recTimecode,
                             "(%d%d):(%d%d):(%d%d).(%d%d%d)")
            updater(math.floor((hours * 60 * 60 + minutes * 60 + seconds +
                                   milliseconds / 1000) *
                                   recording.configuration.frameRate) /
                        recording.configuration.frameRate)
            hs.json.write(recording.state.events,
                          recording.configuration.paths.events, true, true)
        end
    end
    ::endAuxiliaryFunctions::
end
::endRecording::
