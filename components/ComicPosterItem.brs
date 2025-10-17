sub OnContentSet()
    content = m.top.itemContent
    
    if content <> invalid
        ' Set poster URI
        if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
            m.top.FindNode("poster").uri = content.HDPosterUrl
        end if
        
        ' Set the title
        if content.title <> invalid
            m.top.FindNode("titleLabel").text = content.title
        end if
    end if
end sub