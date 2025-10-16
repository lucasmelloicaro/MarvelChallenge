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
    print ">>>>>>> showComicsGrid() START <<<<<<<<"
    print "RowList object: " + type(m.comicsGrid)
    print "RowList valid: " + (m.comicsGrid <> invalid).toStr()
    
    if m.comicsGrid <> invalid
        print "Before changes:"
        print "  RowList visible: " + m.comicsGrid.visible.toStr()
        print "  RowList translation: " + formatJson(m.comicsGrid.translation)
        print "  RowList content valid: " + (m.comicsGrid.content <> invalid).toStr()
        
        if m.comicsGrid.content <> invalid
            print "  Content children count: " + m.comicsGrid.content.getChildCount().toStr()
        end if
    end if
    
    print "Loading label visible before: " + m.loadingLabel.visible.toStr()
    
    ' Always show the grid after comics are created
    m.loadingLabel.visible = false
    m.comicsGrid.visible = true
    
    print "After changes:"
    print "  RowList visible: " + m.comicsGrid.visible.toStr()
    print "  Loading label visible: " + m.loadingLabel.visible.toStr()
    
    ' Set focus on the RowList
    m.comicsGrid.setFocus(true)
    print "Focus set on RowList"
    
    ' Show details for the first comic (index 0)
    updateFocusedComicDetails(0)
    print "RowList has focus: " + m.comicsGrid.hasFocus().toStr()
    
    print ">>>>>>> showComicsGrid() END <<<<<<<<"
end function



' Marvel Comics Collection API using Task (proper threading)
function fetchMarvelComics()
    print "========================================="
    print "Starting Marvel Comics Collection API"
    print "Using: https://developer.marvel.com/docs#!/public/getComicsCollection_get_6"
    print "========================================="
    
    ' Create timestamp for API authentication
    dateTime = CreateObject("roDateTime")
    ts = dateTime.AsSeconds().toStr()
    
    ' Create hash for Marvel API authentication (md5(ts + privateKey + publicKey))
    hashString = ts + m.privateKey + m.publicKey
    print "Creating authentication hash..."
    
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
    
    print "Creating Marvel API Task..."
    
    ' Create and configure the API task from api folder
    m.apiTask = CreateObject("roSGNode", "MarvelApiTask")
    m.apiTask.url = apiUrl
    m.apiTask.observeField("response", "onMarvelApiResponse")
    
    ' Update UI to show loading
    m.loadingLabel.text = "Fetching Marvel Comics..."
    
    ' Start the task
    m.apiTask.control = "RUN"
    
    print "Marvel API Task started"
end function

function onMarvelApiResponse(event as Object)
    print "========================================="
    print "MARVEL API RESPONSE RECEIVED"
    print "========================================="
    
    response = event.GetData()
    
    if response <> invalid and response.code = 200 and response.body <> ""
        print "SUCCESS: Processing Marvel Comics data"
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
    print "========================================="
    print "PARSING MARVEL COMICS COLLECTION RESPONSE"
    print "========================================="
    
    json = ParseJson(responseString)
    
    if json <> invalid and json.data <> invalid and json.data.results <> invalid
        comics = json.data.results
        
        print "MARVEL COMICS COLLECTION API - SUCCESS!"
        print ""
        print "Collection Summary:"
        print "  Total Available: "; json.data.total
        print "  In This Response: "; comics.Count()
        print "  Limit: "; json.data.limit
        print "  Offset: "; json.data.offset
        print "========================================="
        
        ' Print detailed information about each comic
        for i = 0 to comics.Count() - 1
            comic = comics[i]
            
            print "Comic #"; (i+1); " Details:"
            print "  ID: "; comic.id
            print "  Title: "; comic.title
            
            if comic.description <> invalid and comic.description <> ""
                print "  Description: "; Left(comic.description, 150); "..."
            else
                print "  Description: No description available"
            end if
            
            if comic.pageCount <> invalid
                print "  Page Count: "; comic.pageCount
            end if
            
            ' Print dates
            if comic.dates <> invalid and comic.dates.Count() > 0
                for each dateItem in comic.dates
                    if dateItem.type = "onsaleDate"
                        print "  On Sale Date: "; dateItem.date
                        exit for
                    end if
                end for
            end if
            
            ' Print prices
            if comic.prices <> invalid and comic.prices.Count() > 0
                for each priceItem in comic.prices
                    if priceItem.type = "printPrice" and priceItem.price > 0
                        print "  Price: $"; priceItem.price
                        exit for
                    end if
                end for
            end if
            
            ' Print creators
            if comic.creators <> invalid and comic.creators.items <> invalid and comic.creators.items.Count() > 0
                print "  Creators:"
                for j = 0 to comic.creators.items.Count() - 1
                    if j >= 2 then exit for ' Limit to first 2 creators for brevity
                    creator = comic.creators.items[j]
                    print "    - "; creator.name; " ("; creator.role; ")"
                end for
            end if
            
            print "  ---"
        end for
        
        ' Create grid content for the comics
        createComicsGrid(comics)
        
        ' Show the grid
        showComicsGrid()
        
    else
        print "========================================="
        print "ERROR: Failed to parse Marvel API response"
        print "========================================="
        if json = invalid
            print "JSON parsing failed - invalid response"
        else if json.data = invalid
            print "No 'data' field in response"
            print "Response keys: "; json.Keys()
        else if json.data.results = invalid
            print "No 'results' field in data"
            print "Data keys: "; json.data.Keys()
        end if
        
        m.loadingLabel.text = "Failed to parse Marvel API response - check debug console"
    end if
end function

function createComicsGrid(comics as Object)
    print "Creating RowList with " + comics.Count().toStr() + " comics"
    
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
            ' Just use the base image ID without size variant - like 68d3f9621f9f4.jpg
            imageUrl = comic.thumbnail.path + "." + comic.thumbnail.extension
            itemContent.HDPosterUrl = imageUrl
            itemContent.FHDPosterUrl = imageUrl
            itemContent.SDPosterUrl = imageUrl
            
            print "Comic " + (i+1).toStr() + ": " + comic.title
            print "  Image URL: " + imageUrl
        else
            print "Comic " + (i+1).toStr() + ": " + comic.title + " - NO THUMBNAIL"
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
            print "  Detail Image URL: " + detailImageUrl
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
    
    print "RowList content created successfully with " + rowContent.getChildCount().toStr() + " items"
    print "Content structure:"
    print "  Root content children: " + content.getChildCount().toStr()
    print "  First row children: " + rowContent.getChildCount().toStr()
    
    ' Debug: Check the first item's content
    if rowContent.getChildCount() > 0
        firstItem = rowContent.getChild(0)
        print "  First item details:"
        print "    Title: " + firstItem.title
        if firstItem.HDPosterUrl <> invalid
            print "    HDPosterUrl: " + firstItem.HDPosterUrl
        end if
        if firstItem.FHDPosterUrl <> invalid
            print "    FHDPosterUrl: " + firstItem.FHDPosterUrl
        end if
        if firstItem.SDPosterUrl <> invalid
            print "    SDPosterUrl: " + firstItem.SDPosterUrl
        end if
    end if
end function

function onComicSelected(event as Object)
    selection = event.GetData()
    print "Comic selected - Selection type: " + type(selection)
    
    if selection <> invalid
        ' rowItemSelected returns a 2-element array: [rowIndex, itemIndex]
        if type(selection) = "roArray" and selection.Count() = 2
            rowIndex = selection[0]
            itemIndex = selection[1]
            print "Comic selected - Row: " + rowIndex.toStr() + ", Item: " + itemIndex.toStr()
            
            ' Get the selected comic content
            if m.comicsGrid.content <> invalid
                rowNode = m.comicsGrid.content.getChild(rowIndex)
                if rowNode <> invalid
                    comicNode = rowNode.getChild(itemIndex)
                    if comicNode <> invalid
                        print "==================================="
                        print "SELECTED COMIC DETAILS"
                        print "==================================="
                        print "Title: " + comicNode.title
                        if comicNode.description <> invalid
                            print "Description: " + comicNode.description
                        end if
                        if comicNode.id <> invalid
                            print "Comic ID: " + comicNode.id
                        end if
                        print "==================================="
                    end if
                end if
            end if
        else if type(selection) = "roInt"
            ' Fallback for single item selection
            itemIndex = selection
            print "Comic selected - Item: " + itemIndex.toStr()
            
            ' Get the selected comic content (single row, so use index 0 for row)
            if m.comicsGrid.content <> invalid
                rowNode = m.comicsGrid.content.getChild(0) ' Always row 0 for single-row RowList
                if rowNode <> invalid
                    comicNode = rowNode.getChild(itemIndex)
                    if comicNode <> invalid
                        print "==================================="
                        print "SELECTED COMIC DETAILS"
                        print "==================================="
                        print "Title: " + comicNode.title
                        if comicNode.description <> invalid
                            print "Description: " + comicNode.description
                        end if
                        if comicNode.id <> invalid
                            print "Comic ID: " + comicNode.id
                        end if
                        print "==================================="
                    end if
                end if
            end if
        else
            print "Comic selected - Unexpected selection type: " + type(selection) + ", value: " + selection.toStr()
        end if
    else
        print "Comic selected - invalid selection data"
    end if
end function

function onComicFocused(event as Object)
    selection = event.GetData()
    print "Comic focused - Selection type: " + type(selection)
    
    if selection <> invalid
        ' rowItemFocused returns a 2-element array: [rowIndex, itemIndex]
        if type(selection) = "roArray" and selection.Count() = 2
            rowIndex = selection[0]
            itemIndex = selection[1]
            print "Comic focused - Row: " + rowIndex.toStr() + ", Item: " + itemIndex.toStr()
            
            ' Update the focused comic details
            updateFocusedComicDetails(itemIndex)
        else if type(selection) = "roInt"
            ' Fallback for single item selection
            itemIndex = selection
            print "Comic focused - Item: " + itemIndex.toStr()
            
            ' Update the focused comic details
            updateFocusedComicDetails(itemIndex)
        else
            print "Comic focused - Unexpected selection type: " + type(selection) + ", value: " + selection.toStr()
        end if
    else
        print "Comic focused - invalid selection data"
    end if
end function

function updateFocusedComicDetails(itemIndex as Integer)
    ' Get the focused comic content (single row, so use index 0 for row)
    if m.comicsGrid.content <> invalid
        rowNode = m.comicsGrid.content.getChild(0) ' Always row 0 for single-row RowList
        if rowNode <> invalid
            comicNode = rowNode.getChild(itemIndex)
            if comicNode <> invalid
                print "==================================="
                print "UPDATING FOCUSED COMIC DETAILS"
                print "==================================="
                
                ' Update title
                if comicNode.title <> invalid
                    m.comicTitle.text = comicNode.title
                    print "Title: " + comicNode.title
                else
                    m.comicTitle.text = "Unknown Title"
                end if
                
                ' Update description
                if comicNode.description <> invalid
                    m.comicDescription.text = comicNode.description
                    print "Description: " + Left(comicNode.description, 100) + "..."
                else
                    m.comicDescription.text = "No description available"
                end if
                
                ' Update detail image
                if comicNode.detailImageUrl <> invalid
                    m.focusedComicImage.uri = comicNode.detailImageUrl
                    m.focusedComicImage.visible = true
                    print "Detail Image: " + comicNode.detailImageUrl
                else
                    m.focusedComicImage.visible = false
                    print "No detail image available"
                end if
                
                ' Show the details group
                m.comicDetailsGroup.visible = true
                
                print "==================================="
            end if
        end if
    end if
end function