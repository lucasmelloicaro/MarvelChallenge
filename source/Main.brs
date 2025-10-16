sub Main()
    print "======================================"
    print "Starting Marvel Comics Roku App"
    print "======================================"
    
    'Indicate this is a Roku SceneGraph application'
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    'Create Marvel Comics scene'
    print "Creating Marvel Comics scene..."
    scene = screen.CreateScene("MarvelComicsScene")
    
    if scene = invalid
        print "ERROR: Failed to create Marvel Comics scene"
        return
    end if
    
    print "Scene created successfully, showing screen..."
    screen.show()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() 
                print "Screen closed, exiting app"
                return
            end if
        end if
    end while
end sub

