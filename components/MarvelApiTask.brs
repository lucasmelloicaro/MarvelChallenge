sub init()
    m.top.functionName = "fetchData"
end sub

sub fetchData()
    print "========================================="
    print "MARVEL COMICS API TASK - Starting..."
    print "========================================="
    
    ' Get the URL from the scene
    apiUrl = m.top.url
    
    if apiUrl = invalid or apiUrl = ""
        print "ERROR: No API URL provided to task"
        m.top.response = { "error": "No URL provided" }
        return
    end if
    
    print "Making HTTP request to: "; apiUrl
    
    ' Create HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(apiUrl)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("Accept", "application/json")
    request.AddHeader("User-Agent", "RokuMarvelApp/1.0")
    
    ' Set up message port for async request
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    
    ' Make async request
    if request.AsyncGetToString()
        print "Async request started, waiting for response..."
        
        ' Wait for response (timeout after 15 seconds)
        msg = wait(15000, port)
        
        if msg <> invalid
            responseCode = msg.GetResponseCode()
            responseString = msg.GetString()
            
            print "Response Code: "; responseCode
            print "Response Length: "; Len(responseString); " characters"
            
            ' Return response to scene
            if responseCode = 200 and responseString <> ""
                print "SUCCESS: API response received"
                print "First 200 chars: "; Left(responseString, 200)
                m.top.response = {
                    "code": responseCode,
                    "body": responseString
                }
            else
                print "ERROR: API request failed with code "; responseCode
                if responseString <> ""
                    print "Error response: "; responseString
                end if
                m.top.response = {
                    "code": responseCode,
                    "body": responseString,
                    "error": "Request failed"
                }
            end if
        else
            print "ERROR: Request timeout (15 seconds)"
            m.top.response = {
                "code": 0,
                "body": "",
                "error": "Request timeout"
            }
        end if
    else
        print "ERROR: Failed to start async request"
        m.top.response = {
            "code": 0,
            "body": "",
            "error": "Failed to start request"
        }
    end if
    
    print "Marvel API Task completed"
end sub