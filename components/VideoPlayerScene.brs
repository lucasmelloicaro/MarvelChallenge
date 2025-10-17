function init()
    print "VideoPlayerScene.init() called"
    
    ' Get UI elements
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.characterNameLabel = m.top.findNode("characterNameLabel")
    m.videoInfoLabel = m.top.findNode("videoInfoLabel")
    m.infoBackground = m.top.findNode("infoBackground")
    
    ' Set up video player
    setupVideoPlayer()
    
    ' Observe character data field
    m.top.observeField("characterData", "onCharacterDataSet")
    
    ' Set focus on video player
    m.top.setFocus(true)
    
    ' Set up key handling
    m.top.observeField("focusedChild", "onFocusChanged")
    
    ' Set up timer to hide info overlay after 5 seconds
    m.timer = CreateObject("roSGNode", "Timer")
    m.timer.duration = 5.0
    m.timer.observeField("fire", "hideInfoOverlay")
    m.timer.control = "start"
    
    print "VideoPlayerScene initialized successfully"
end function

function setupVideoPlayer()
    ' Create video content
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    videoContent.title = "Big Buck Bunny"
    videoContent.description = "Sample video for character demonstration"
    videoContent.streamFormat = "mp4"
    
    ' Set content to video player
    m.videoPlayer.content = videoContent
    
    ' Observe video player events
    m.videoPlayer.observeField("state", "onVideoStateChanged")
    m.videoPlayer.observeField("position", "onVideoPositionChanged")
    
    print "Video player configured with URL: " + videoContent.url
end function

function onCharacterDataSet()
    data = m.top.characterData
    if data <> invalid
        ' Update character name in overlay
        if data.name <> invalid
            m.characterNameLabel.text = data.name + " - Character Video"
            print "Playing video for character: " + data.name
        end if
        
        ' Start playing video automatically
        m.videoPlayer.control = "play"
    end if
end function

function onVideoStateChanged()
    state = m.videoPlayer.state
    print "Video player state changed to: " + state
    
    if state = "error"
        print "Video playback error"
        m.videoInfoLabel.text = "Video playback error - Press BACK to return"
    else if state = "finished"
        print "Video playback finished"
        m.videoInfoLabel.text = "Video finished - Press BACK to return"
    else if state = "playing"
        print "Video is now playing"
    else if state = "paused"
        print "Video is paused"
    end if
end function

function onVideoPositionChanged()
    ' Optional: Handle position changes if needed
    ' position = m.videoPlayer.position
end function

function hideInfoOverlay()
    ' Hide the info overlay after timer fires
    m.infoBackground.visible = false
    m.characterNameLabel.visible = false
    m.videoInfoLabel.visible = false
end function

function showInfoOverlay()
    ' Show the info overlay (called on user interaction)
    m.infoBackground.visible = true
    m.characterNameLabel.visible = true
    m.videoInfoLabel.visible = true
    
    ' Reset timer
    m.timer.control = "stop"
    m.timer.control = "start"
end function

function onKey(key as String, press as Boolean) as Boolean
    if press
        if key = "back"
            ' Stop video and navigate back
            m.videoPlayer.control = "stop"
            m.top.navigateToCharacters = true
            return true
        else if key = "OK" or key = "play" or key = "pause"
            ' Toggle play/pause
            if m.videoPlayer.state = "playing"
                m.videoPlayer.control = "pause"
            else
                m.videoPlayer.control = "play"
            end if
            showInfoOverlay()
            return true
        else if key = "up" or key = "down" or key = "left" or key = "right"
            ' Show overlay on navigation
            showInfoOverlay()
            return true
        end if
    end if
    return false
end function