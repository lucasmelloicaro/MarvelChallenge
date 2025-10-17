function init()
    print "CharacterDetailsScene.init() called"
    
    ' Get UI elements
    m.comicTitleHeader = m.top.findNode("comicTitleHeader")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.charactersList = m.top.findNode("charactersList")
    m.noCharactersLabel = m.top.findNode("noCharactersLabel")
    m.keyHandler = m.top.findNode("keyHandler")
    
    ' Initialize Marvel API credentials
    m.publicKey = "b63e4263edd3da6685fa48d540bee87a"
    m.privateKey = "74ca4a19dd8adbfcca521f42d0ab3d4072433d88"
    
    ' Initialize comic data storage
    m.comicId = ""
    m.comicTitle = ""
    
    ' Observe comic data field
    m.top.observeField("comicData", "onComicDataSet")
    
    ' Set up for focus management
    m.top.setFocus(true)
    
    print "CharacterDetailsScene initialized successfully"
end function

function onCharacterSelected(event as Object)
    selection = event.GetData()
    print "Character selected - Selection type: " + type(selection)
    
    if selection <> invalid and m.charactersList.content <> invalid
        ' Extract row and item indices
        rowIndex = -1
        itemIndex = -1
        
        if type(selection) = "roArray" and selection.Count() = 2
            rowIndex = selection[0]
            itemIndex = selection[1]
        else if type(selection) = "roInt"
            rowIndex = selection
            itemIndex = 0  ' First item in the row
        end if
        
        if rowIndex >= 0
            rowNode = m.charactersList.content.getChild(rowIndex)
            if rowNode <> invalid and rowNode.getChildCount() > itemIndex
                characterNode = rowNode.getChild(itemIndex)
                if characterNode <> invalid
                    print "Selected Character: " + characterNode.title
                    navigateToVideoPlayer(characterNode)
                end if
            end if
        end if
    end if
end function

function navigateToVideoPlayer(characterNode as Object)
    print "Navigating to video player for character: " + characterNode.title
    
    ' Create video player scene as a child
    videoScene = CreateObject("roSGNode", "VideoPlayerScene")
    
    ' Add video scene to this scene
    m.top.appendChild(videoScene)
    
    ' Set character data
    characterData = {
        name: characterNode.title,
        description: characterNode.description,
        id: characterNode.id
    }
    videoScene.characterData = characterData
    
    ' Hide characters UI elements
    m.charactersList.visible = false
    m.comicTitleHeader.visible = false
    m.loadingLabel.visible = false
    m.noCharactersLabel.visible = false
    
    ' Set focus on video scene
    videoScene.setFocus(true)
    
    ' Store reference for back navigation
    m.videoScene = videoScene
    
    ' Observe back navigation
    videoScene.observeField("navigateToCharacters", "onNavigateBackFromVideo")
end function

function onNavigateBackFromVideo()
    ' Remove video scene
    if m.videoScene <> invalid
        m.top.removeChild(m.videoScene)
        m.videoScene = invalid
    end if
    
    ' Show characters UI again
    m.charactersList.visible = true
    m.comicTitleHeader.visible = true
    
    ' Set focus back to characters list
    m.charactersList.setFocus(true)
end function

function onComicDataSet()
    data = m.top.comicData
    if data <> invalid
        setComicData(data)
    end if
end function

function setComicData(data as Object)
    ' Set comic data and start fetching characters
    print "CharacterDetailsScene.setComicData() called with data: " + formatJson(data)
    
    if data.comicId <> invalid
        m.comicId = data.comicId
        print "Setting comicId: " + m.comicId
        fetchCharactersForComic(m.comicId)
    end if
    
    if data.comicTitle <> invalid
        m.comicTitle = data.comicTitle
        m.comicTitleHeader.text = m.comicTitle + " - Characters"
        print "Setting comic title: " + m.comicTitle
    end if
end function

function onKey(key as String, press as Boolean) as Boolean
    if press
        if key = "back"
            ' Navigate back to comics scene
            m.top.navigateToComics = true
            return true
        end if
    end if
    return false
end function



function fetchCharactersForComic(comicId as String)
    print "========================================="
    print "FETCHING CHARACTERS FOR COMIC ID: " + comicId
    print "========================================="
    
    ' Create timestamp for API authentication
    dateTime = CreateObject("roDateTime")
    ts = dateTime.AsSeconds().toStr()
    
    ' Create hash for Marvel API authentication
    hashString = ts + m.privateKey + m.publicKey
    
    ' Create MD5 hash
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(hashString)
    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    apiHash = digest.Process(ba)
    
    ' Build Characters API URL for specific comic
    baseUrl = "https://gateway.marvel.com/v1/public/comics/" + comicId + "/characters"
    
    ' Complete API URL with authentication
    apiUrl = baseUrl + "?ts=" + ts + "&apikey=" + m.publicKey + "&hash=" + apiHash
    
    print "Characters API URL: " + apiUrl
    
    ' Create and configure the API task
    m.apiTask = CreateObject("roSGNode", "MarvelApiTask")
    m.apiTask.url = apiUrl
    m.apiTask.observeField("response", "onCharactersApiResponse")
    
    ' Start the task
    m.apiTask.control = "RUN"
end function

function onCharactersApiResponse(event as Object)
    print "========================================="
    print "CHARACTERS API RESPONSE RECEIVED"
    print "========================================="
    
    response = event.GetData()
    
    if response <> invalid and response.code = 200 and response.body <> ""
        print "SUCCESS: Processing Characters data"
        parseCharactersData(response.body)
    else if response <> invalid and response.code <> invalid
        errorMsg = "Characters API Error - Code: " + response.code.toStr()
        print errorMsg
        if response.body <> ""
            print "Error response body: "; response.body
        end if
        m.loadingLabel.text = "Failed to load characters"
        m.noCharactersLabel.visible = true
    else
        print "Characters API Task failed"
        m.loadingLabel.text = "Failed to load characters"
        m.noCharactersLabel.visible = true
    end if
end function

function parseCharactersData(responseString as String)
    json = ParseJson(responseString)
    
    if json <> invalid and json.data <> invalid and json.data.results <> invalid
        characters = json.data.results
        
        if characters.Count() > 0
            print "Successfully loaded " + characters.Count().toStr() + " characters"
            createCharactersList(characters)
            showCharactersList()
        else
            print "No characters found for this comic"
            m.loadingLabel.visible = false
            m.noCharactersLabel.visible = true
        end if
    else
        print "ERROR: Failed to parse Characters API response"
        m.loadingLabel.text = "Failed to parse characters data"
        m.noCharactersLabel.visible = true
    end if
end function

function createCharactersList(characters as Object)
    ' Create content node for RowList
    content = createObject("roSGNode", "ContentNode")
    
    ' Create separate rows for each character (vertical list)
    for i = 0 to characters.Count() - 1
        character = characters[i]
        
        ' Create a row for this character
        rowContent = createObject("roSGNode", "ContentNode")
        rowContent.title = "Character " + (i+1).toStr()
        
        ' Create content for this character
        itemContent = createObject("roSGNode", "ContentNode")
        itemContent.title = character.name
        
        ' Set description
        if character.description <> invalid and character.description <> ""
            itemContent.description = character.description
        else
            itemContent.description = "No description available"
        end if
        
        ' Set character ID
        if character.id <> invalid
            itemContent.id = character.id.toStr()
        end if
        
        ' Set thumbnail image
        if character.thumbnail <> invalid
            imageUrl = character.thumbnail.path + "." + character.thumbnail.extension
            itemContent.HDPosterUrl = imageUrl
            itemContent.FHDPosterUrl = imageUrl
            itemContent.SDPosterUrl = imageUrl
        end if
        
        ' Add character to its row
        rowContent.appendChild(itemContent)
        
        ' Add row to content
        content.appendChild(rowContent)
    end for
    
    ' Set content to RowList
    m.charactersList.content = content
    
    print "Created character list with " + characters.Count().toStr() + " rows"
end function

function showCharactersList()
    ' Hide loading label and show characters list
    m.loadingLabel.visible = false
    m.charactersList.visible = true
    
    ' Set up character selection event handling
    m.charactersList.observeField("rowItemSelected", "onCharacterSelected")
    
    ' Set focus on the characters list
    m.charactersList.setFocus(true)
end function

