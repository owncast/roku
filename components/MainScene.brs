' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

sub Show(args as Object)
	AppInfo = CreateObject("roAppInfo")

' update theme elements
	m.top.theme = {
        global: {
        	OverhangLogoUri: AppInfo.GetValue("OverhangLogoUri")
            OverhangTitle: AppInfo.GetValue("OverhangTitle")	 		
            OverhangTitleColor: AppInfo.GetValue("OverhangTitleColor")		
            OverhangBackgroundUri: AppInfo.GetValue("OverhangBackgroundUri")		
            OverhangBackgroundColor: AppInfo.GetValue("OverhangBackgroundColor")	

    
            textColor: AppInfo.GetValue("textColor")
            focusRingColor: AppInfo.GetValue("focusRingColor")
            progressBarColor: AppInfo.GetValue("progressBarColor")
			busySpinnerColor: AppInfo.GetValue("busySpinnerColor")                  

           	backgroundImageURI: AppInfo.GetValue("backgroundImageURI") 
            backgroundColor: AppInfo.GetValue("backgroundColor")
        }
    }
    m.grid = CreateObject("roSGNode", "GridView")
    m.grid.SetFields({
        style: "standard"
        posterShape: "16x9"
    })
    content = CreateObject("roSGNode", "ContentNode")
    content.AddFields({
        HandlerConfigGrid: {
            name: "RootHandler"
        }
    })
    m.grid.content = content
    m.grid.ObserveField("rowItemSelected", "OnGridItemSelected")

    m.top.ComponentController.CallFunc("show", {
        view: m.grid
    })

    if IsDeepLinking(args)
        PerformDeepLinking(args)
    end if

    m.top.signalBeacon("AppLaunchComplete")
end sub

sub OnGridItemSelected(event as Object)
    grid = event.GetRoSGNode()
    selectedIndex = event.GetData()

    ' selectedIndex[0] is row, selectedIndex[1] is column; using GetChild() sequentially gets the selected item
    selectedContent = grid.content.GetChild(selectedIndex[0]).GetChild(selectedIndex[1])

    ' populating a DetailsView with only the selected item, index 0, and "false" for "not a content list"
    ' this prevents the app from treating the entire row as a playlist, so when the stream stops playing,
    ' it doesn't autoplay the next one

    detailsView = ShowDetailsView(selectedContent, 0, false)
    detailsView.ObserveField("wasClosed", "OnDetailsWasClosed")
end sub

sub OnDetailsWasClosed(event as Object)
    details = event.GetRoSGNode()
    m.grid.jumpToRowItem = [m.grid.rowItemFocused[0], details.itemFocused]
end sub

sub Input(args as object)
    ' handle roInput event deep linking
    if IsDeepLinking(args)
        PerformDeepLinking(args)
    end if
end sub
