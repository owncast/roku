function IsDeepLinking(args as object)
    ' check if deep linking args is valid
    return args <> invalid and args.mediaType <> invalid and args.mediaType <> "" and args.contentId <> invalid and args.contentId <> ""
end function

sub PerformDeepLinking(args as object, pageContent as object)
    if m.deepLinkingHandled = invalid
        m.deepLinkingHandled = false
    end if

    if m.deepLinkingHandled then return

    for each contentRow in pageContent.getChildren(-1, 0)
        for each contentItem in contentRow.getChildren(-1, 0)
            if contentItem.id = args.contentID
                m.deepLinkingHandled = true
                showVideo(contentItem)
                exit for
            end if
        end for
    end for
end sub

sub showVideo(contentItem as object)
    video = CreateObject("roSGNode", "MediaView")
    video.content = contentItem
    video.jumpToItem = 0
    video.isContentList = false
    video.control = "play"

    m.top.ComponentController.CallFunc("show", {
        view: video
    })
end sub
