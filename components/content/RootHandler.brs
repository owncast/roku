' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

sub GetContent()

    appInfo = CreateObject("roAppInfo")
    feedURL = appInfo.GetValue("FEED_URL")

    MAXSIZE = 500 * 1024

    print feedURL

    url = CreateObject("roUrlTransfer")
    url.SetUrl(feedURL)
    url.EnablePeerVerification(false)
    url.SetCertificatesFile("pkg:/certs/ca-bundle.crt")
    url.AddHeader("X-Roku-Reserved-Dev-Id", "")
    url.InitClientCertificates()
    feed = url.GetToString()
    
    #if false
    'this is for a sample, usually feed is retrieved from url using roUrlTransfer
    'feed = ReadAsciiFile("pkg:/feed/feed.json")
    'feed = ReadAsciiFile("pkg:/feed/mRSS_Feed.xml")
    'feed = ReadAsciiFile("pkg:/feed/large_feed.json")
    'Sleep(2000) ' to emulate API call
    #endif

    if( feed.Len() < MAXSIZE AND feed.len() > 0 )
        'assuming JSON
        feedType = "JSON"
        parsed = parseRokuFeedSpec(feed)
    else
        if( feed.Len() > MAXSIZE )
            'any feed over 500Kb is too large to parse locally
            print "FEED is too large: ", feed.Len()
            rootChildren = {
                children: []
                }
                children = []
            itemNode = CreateObject("roSGNode", "ContentNode")
                Utils_ForceSetFields(itemNode, {
                    hdPosterUrl: "pkg:/images/feed_too_large.jpg"
                    Description: "Feed is too large"
                    id: "0"
                    Categories: "Feed is too large"
                    title: "Feed is too large"
                    url: ""
                })
            children.Push(itemNode)
            rowAA = {
                title: "Feed is too large"
                children: children
                }
            rootChildren.children.Push(rowAA)
            m.top.content.Update(rootChildren)
        else
            print "Cannot obtain Feed: ", feed.Len()
            rootChildren = {
                children: []
                }
                children = []
            itemNode = CreateObject("roSGNode", "ContentNode")
                Utils_ForceSetFields(itemNode, {
                    hdPosterUrl: ""
                    Description: "Cannot obtain Feed"
                    id: "0"
                    Categories: "Cannot obtain Feed"
                    title: "Cannot obtain Feed"
                    url: ""
                })
            children.Push(itemNode)
            rowAA = {
                title: "Cannot obtain Feed"
                children: children
                }
            rootChildren.children.Push(rowAA)
            m.top.content.Update(rootChildren) 
        endif
    endif   
end sub

'
' Parse Roku feed spec, majority of Direct Publisher 
' channels will fall into this category 
'
function parseRokuFeedSpec(xmlString as string) as Object
        json = ParseJson(xmlString)
        if json <> invalid ' and json.rows <> invalid and json.rows.Count() > 0
            rootChildren = {
            children: []
            }
            channelsByTag = {
                "now-live": { name: "Now Live", channels: [] },
                "music": { name: "Music", channels: [] },
                "tech": { name: "Tech", channels: [] },
                "chatting": { name: "Chatting", channels: [] },
                "video-games": { name: "Video Games", channels: [] },
                "now-offline": { name: "Offline", channels: [] }
            }
 
            allChannels = {
                name: "All Feeds"
                channels: []
            }

            favoriteChannels = {
                name: "Favorites"
                channels: []
            }
            favorites = Utils_GetFavorites()

            tagOrder = ["now-live", "music", "tech", "chatting", "video-games", "now-offline"]
            for each item in json
                value = json[item]
                if item = "liveFeeds"
                    for each arrayItem in value
                        isFavorite = false
                        if favorites?[arrayItem["id"]] <> invalid
                            isFavorite = true
                            itemNode = CreateOwncastFeedContentNode(arrayItem, isFavorite)
                            favoriteChannels.channels.Push(itemNode)
                        end if
                        ' Note that this was originally a "for each" loop, but something about nesting
                        ' this code as another "for each" loop led to only the first tag being considered
                        ' so it's been converted to the more traditional style just to avoid the problem
                        for i=0 to arrayItem["tags"].Count()-1
                            tag = arrayItem["tags"][i]
                            if channelsByTag.DoesExist(tag)
                                itemNode = CreateOwncastFeedContentNode(arrayItem, isFavorite)
                                channelsByTag[tag].channels.Push(itemNode)
                            end if
                        end for

                        ' Seems you need a unique ContentNode per place in the grid
                        ' so this one is for the "all feeds" one
                        itemNode = CreateOwncastFeedContentNode(arrayItem, isFavorite)
                        allChannels.channels.Push(itemNode)
                    end for
                end if
            end for

            ' Render out the rows here
            if favoriteChannels["channels"].Count() > 0
                row = {
                    title: favoriteChannels.name
                    children: favoriteChannels.channels
                }
                rootChildren.children.Push(row)
            end if

            for each tag in tagOrder
                row = {
                    title: channelsByTag[tag].name
                    children: channelsByTag[tag].channels
                }
                rootChildren.children.Push(row)
            end for
            allChannelsRow = {
                title: allChannels.name
                children: allChannels.channels
            }
            rootChildren.children.Push(allChannelsRow)
            m.top.content.Update(rootChildren)
        end if
end function

function CreateOwncastFeedContentNode(arrayItem, isFavorite)
    itemNode = CreateObject("roSGNode", "ContentNode")
    Utils_ForceSetFields(itemNode, {
        hdPosterUrl: arrayItem.thumbnail
        Description: arrayItem.shortDescription
        id: arrayItem.id
        Categories: ConvertToStringAndJoin(arrayItem["tags"], ", ")
        title: arrayItem.title
        favorite: isFavorite
        favoriteUpdated: false
    })
    for i = 0 to arrayItem["tags"].Count() - 1
        if arrayItem["tags"][i] = "now-live"
            itemNode.setField("shortDescriptionLine1", "LIVE")
        end if
    end for
    itemNode.Url = arrayItem.content.videos[0].url
    return itemNode
end function

function ConvertToStringAndJoin(dataArray as Object, divider = " | " as String) as String
    result = ""
    if Type(dataArray) = "roArray" and dataArray.Count() > 0
        for each item in dataArray
            if item <> invalid
                strFormat = invalid
                if GetInterface(item, "ifToStr") <> invalid
                    strFormat = item.Tostr()
                else if GetInterface(item, "ifArrayJoin") <> invalid
                    strFormat = item.Join(" | ")
                end if
                if strFormat <> invalid then
                    if strFormat.Len() > 0
                        if result.Len() > 0 then result += divider
                        result += strFormat
                    end if
                end if
            end if
        end for
    end if
    return result
end function

