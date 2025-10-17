function init()
    ' Initialize focus handling
    m.top.observeField("focusedChild", "onFocusChanged")
end function

sub OnContentSet()
    content = m.top.itemContent
    
    if content <> invalid
        ' Set character image
        if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
            m.top.FindNode("characterImage").uri = content.HDPosterUrl
        end if
        
        ' Set character name
        if content.title <> invalid
            m.top.FindNode("characterName").text = content.title
        end if
        
        ' Set character description
        if content.description <> invalid
            m.top.FindNode("characterDescription").text = content.description
        end if
    end if
end sub

function onFocusChanged()
    ' Handle focus visual feedback
    selectionRect = m.top.FindNode("selectionRect")
    if m.top.hasFocus()
        selectionRect.visible = true
    else
        selectionRect.visible = false
    end if
end function