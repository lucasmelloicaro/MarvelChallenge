sub OnContentSet()
    print ">>>>>>> ComicPosterItem.OnContentSet() called <<<<<<<<"
    content = m.top.itemContent
    
    if content <> invalid
        print "Content is valid - Title: " + content.title
        
        ' Set poster URI using the same pattern as working component
        posterUri = ""
        
        if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
            posterUri = content.HDPosterUrl
            print "Using HDPosterUrl: " + posterUri
        end if
        
        ' Set the poster URI
        if posterUri <> ""
            m.top.FindNode("poster").uri = posterUri
            print "Poster URI set successfully"
        else
            print "No valid poster URI found"
        end if
        
        ' Set the title
        if content.title <> invalid
            m.top.FindNode("titleLabel").text = content.title
            print "Title set: " + content.title
        end if
    else
        print "Content is INVALID"
    end if
end sub