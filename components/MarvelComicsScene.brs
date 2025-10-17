function init()
    ' Get UI elements
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.comicsGrid = m.top.findNode("comicsGrid")
    
    ' Get focused comic detail elements
    m.comicDetailsGroup = m.top.findNode("comicDetailsGroup")
    m.comicTitle = m.top.findNode("comicTitle")
    m.comicDescription = m.top.findNode("comicDescription")
    m.focusedComicImage = m.top.findNode("focusedComicImage")
    
    ' Set the font size and color for loading label
    m.loadingLabel.font.size = 32
    m.loadingLabel.color = "0x72D7EEFF"
    
    ' Initialize Marvel API credentials
    m.publicKey = "b63e4263edd3da6685fa48d540bee87a"
    m.privateKey = "74ca4a19dd8adbfcca521f42d0ab3d4072433d88"
    
    ' Set up RowList event handling
    m.comicsGrid.observeField("rowItemSelected", "onComicSelected")
    m.comicsGrid.observeField("rowItemFocused", "onComicFocused")
    
    ' Fetch Marvel Comics data
    fetchMarvelComics()
end function

function showComicsGrid()
    ' Always show the grid after comics are created
    m.loadingLabel.visible = false
    m.comicsGrid.visible = true
    
    ' Set focus on the RowList
    m.comicsGrid.setFocus(true)
    
    ' Show details for the first comic (index 0)
    updateFocusedComicDetails(0)
end function



' Marvel Comics Collection API using Task (proper threading)
function fetchMarvelComics()
    print "Fetching Marvel Comics..."
    
    ' Create timestamp for API authentication
    dateTime = CreateObject("roDateTime")
    ts = dateTime.AsSeconds().toStr()
    
    ' Create hash for Marvel API authentication (md5(ts + privateKey + publicKey))
    hashString = ts + m.privateKey + m.publicKey
    
    ' Create MD5 hash
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(hashString)
    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    apiHash = digest.Process(ba)
    
    ' Build Marvel Comics Collection API URL
    baseUrl = "https://gateway.marvel.com/v1/public/comics"
    params = ""
    params += "&limit=10"                    
    params += "&format=comic"               
    params += "&formatType=comic"           
    params += "&orderBy=-onsaleDate"        
    params += "&dateDescriptor=lastWeek"    
    params += "&hasDigitalIssue=true"       
    
    ' Complete API URL with authentication
    apiUrl = baseUrl + "?ts=" + ts + "&apikey=" + m.publicKey + "&hash=" + apiHash + params
    
    ' Create and configure the API task from api folder
    m.apiTask = CreateObject("roSGNode", "MarvelApiTask")
    m.apiTask.url = apiUrl
    m.apiTask.observeField("response", "onMarvelApiResponse")
    
    ' Update UI to show loading
    m.loadingLabel.text = "Fetching Marvel Comics..."
    
    ' Start the task
    m.apiTask.control = "RUN"
end function

function onMarvelApiResponse(event as Object)
    
    response = event.GetData()
    
    if response <> invalid and response.code = 200 and response.body <> ""
        parseMarvelData(response.body)
    else if response <> invalid and response.code <> invalid
        errorMsg = "Marvel API Error - Code: " + response.code.toStr()
        print errorMsg
        if response.body <> ""
            print "Error response body: "; response.body
        end if
        m.loadingLabel.text = errorMsg + chr(10) + "Check console for details"
    else
        errorMsg = "Marvel API Task failed"
        print errorMsg
        m.loadingLabel.text = errorMsg
    end if
end function

function parseMarvelData(responseString as String)
    
    json = ParseJson(responseString)
    
    if json <> invalid and json.data <> invalid and json.data.results <> invalid
        comics = json.data.results
        print "Successfully loaded " + comics.Count().toStr() + " comics"
        
        ' Create grid content for the comics
        createComicsGrid(comics)
        
        ' Show the grid
        showComicsGrid()
        
    else
        print "ERROR: Failed to parse Marvel API response"
        
        m.loadingLabel.text = "Failed to parse Marvel API response - check debug console"
    end if
end function

function createComicsGrid(comics as Object)
    
    ' Create content node for RowList
    content = createObject("roSGNode", "ContentNode")
    
    ' Create a single row
    rowContent = createObject("roSGNode", "ContentNode")
    rowContent.title = "Marvel Comics"
    
    ' Add each comic as a content node to the row
    for i = 0 to comics.Count() - 1
        comic = comics[i]
        
        ' Create content for this comic
        itemContent = createObject("roSGNode", "ContentNode")
        itemContent.title = comic.title
        
        ' Set thumbnail URL using base image without size variant
        if comic.thumbnail <> invalid
            imageUrl = comic.thumbnail.path + "." + comic.thumbnail.extension
            itemContent.HDPosterUrl = imageUrl
            itemContent.FHDPosterUrl = imageUrl
            itemContent.SDPosterUrl = imageUrl
        end if
        
        ' Add other useful fields
        if comic.description <> invalid and comic.description <> ""
            itemContent.description = comic.description
        else
            itemContent.description = "No description available"
        end if
        
        if comic.id <> invalid
            itemContent.id = comic.id.toStr()
        end if
        
        ' Store full images array for detailed view
        if comic.images <> invalid and comic.images.Count() > 0
            ' Use the first full-size image for detail view
            fullImage = comic.images[0]
            detailImageUrl = fullImage.path + "." + fullImage.extension
            itemContent.addField("detailImageUrl", "string", false)
            itemContent.detailImageUrl = detailImageUrl
        else
            ' Fallback to thumbnail if no full images
            if comic.thumbnail <> invalid
                detailImageUrl = comic.thumbnail.path + "." + comic.thumbnail.extension
                itemContent.addField("detailImageUrl", "string", false)
                itemContent.detailImageUrl = detailImageUrl
            end if
        end if
        
        ' Add to row
        rowContent.appendChild(itemContent)
    end for
    
    ' Add row to content
    content.appendChild(rowContent)
    
    ' Set content to RowList
    m.comicsGrid.content = content
end function

function onComicSelected(event as Object)
    selection = event.GetData()
    itemIndex = extractItemIndex(selection)
    
    if itemIndex >= 0 and m.comicsGrid.content <> invalid
        rowNode = m.comicsGrid.content.getChild(0)
        if rowNode <> invalid
            comicNode = rowNode.getChild(itemIndex)
            if comicNode <> invalid
                print "Selected Comic: " + comicNode.title
                if comicNode.id <> invalid
                    print "Navigating to character details for comic ID: " + comicNode.id
                    navigateToCharacterDetails(comicNode.id, comicNode.title)
                end if
            end if
        end if
    end if
end function

function navigateToCharacterDetails(comicId as String, comicTitle as String)
    print "Creating character details scene for comic: " + comicTitle + " (ID: " + comicId + ")"
    
    ' Create character details scene as a child
    characterScene = CreateObject("roSGNode", "CharacterDetailsScene")
    
    ' Add character scene to this scene first
    m.top.appendChild(characterScene)
    
    ' Now set the comic data via interface field (this should trigger the API call)
    characterScene.comicData = {comicId: comicId, comicTitle: comicTitle}
    
    ' Hide current UI elements
    m.comicsGrid.visible = false
    m.comicDetailsGroup.visible = false
    m.loadingLabel.visible = false
    
    ' Set focus on character scene
    characterScene.setFocus(true)
    
    ' Store reference for back navigation
    m.characterScene = characterScene
    
    ' Observe back navigation
    characterScene.observeField("navigateToComics", "onNavigateBackToComics")
    
    print "Character details scene created and comic data set"
end function

function onNavigateBackToComics()
    print "onNavigateBackToComics() called"
    
    ' Remove character scene
    if m.characterScene <> invalid
        print "Removing character scene"
        m.top.removeChild(m.characterScene)
        m.characterScene = invalid
    end if
    
    ' Show comics UI again
    m.comicsGrid.visible = true
    m.comicDetailsGroup.visible = true
    
    ' Set focus back to comics grid
    m.comicsGrid.setFocus(true)
    
    print "Back to comics - UI restored and focus set"
end function

function extractItemIndex(selection as Object) as Integer
    if type(selection) = "roArray" and selection.Count() = 2
        return selection[1]  ' itemIndex
    else if type(selection) = "roInt"
        return selection
    end if
    return -1
end function

function onComicFocused(event as Object)
    selection = event.GetData()
    itemIndex = extractItemIndex(selection)
    
    if itemIndex >= 0
        updateFocusedComicDetails(itemIndex)
    end if
end function

function updateFocusedComicDetails(itemIndex as Integer)
    if m.comicsGrid.content <> invalid
        rowNode = m.comicsGrid.content.getChild(0)
        if rowNode <> invalid
            comicNode = rowNode.getChild(itemIndex)
            if comicNode <> invalid
                ' Update title
                if comicNode.title <> invalid
                    m.comicTitle.text = comicNode.title
                else
                    m.comicTitle.text = "Unknown Title"
                end if
                
                ' Update description
                if comicNode.description <> invalid
                    m.comicDescription.text = comicNode.description
                else
                    m.comicDescription.text = "No description available"
                end if
                
                ' Update detail image
                if comicNode.detailImageUrl <> invalid
                    m.focusedComicImage.uri = comicNode.detailImageUrl
                    m.focusedComicImage.visible = true
                else
                    m.focusedComicImage.visible = false
                end if
                
                ' Show the details group
                m.comicDetailsGroup.visible = true
            end if
        end if
    end if
end function

function onKey(key as String, press as Boolean) as Boolean
    print "MarvelComicsScene.onKey() called - key: " + key + ", press: " + press.toStr()
    
    if press
        if key = "back"
            print "BACK key detected in MarvelComicsScene"
            
            ' Check if we have child scenes visible
            if m.characterScene <> invalid and m.characterScene.visible = true
                ' Child scene is visible, don't handle back here
                print "Child scene is visible, not handling back"
                return false
            else
                ' We're at the main comics level - prevent app exit
                print "At main comics level - CONSUMING back key to prevent app exit"
                ' Return true to indicate we handled the key and prevent further processing
                return true
            end if
        end if
    end if
    
    ' Let other keys pass through
    return false
end function