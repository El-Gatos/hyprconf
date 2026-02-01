import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: workspacesContainer
    
    required property var screen
    property string monitorName: screen.name
    
    property var monitor: {
        var monitors = Hyprland.monitors.values ? Hyprland.monitors.values : Hyprland.monitors
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === monitorName) {
                return monitors[i];
            }
        }
        return null;
    }
    
    property int activeWorkspaceId: monitor && monitor.activeWorkspace 
        ? monitor.activeWorkspace.id 
        : 1
    
    property int totalWorkspaces: 10
    property int visibleCount: 5
    
    // SWAPPED: Width/Height for vertical layout
    property int itemWidth: 24
    property int itemHeight: 32
    property int spacing: 6

    // Vertical Calculation
    implicitWidth: 32
    implicitHeight: (itemHeight * visibleCount) + (spacing * (visibleCount - 1)) + 16
    
    radius: 10
    color: "#B31a2847"
    border.width: 2
    border.color: "#4Dff6b9d"
    
    clip: true 

    ListView {
        id: workspaceList
        
        // Vertical Anchoring
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        
        width: itemWidth
        
        // Changed to Vertical
        orientation: ListView.Vertical
        spacing: workspacesContainer.spacing
        
        highlightMoveDuration: 450
        highlightMoveVelocity: -1 
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: (height - itemHeight) / 2
        preferredHighlightEnd: (height - itemHeight) / 2 + itemHeight
        boundsBehavior: Flickable.StopAtBounds
        
        currentIndex: activeWorkspaceId - 1 
        interactive: false 
        
        model: totalWorkspaces
        
        delegate: Rectangle {
            id: workspace
            property int workspaceId: index + 1
            property bool isActive: activeWorkspaceId === workspaceId
            property bool hasWindows: {
                var wList = Hyprland.workspaces.values ? Hyprland.workspaces.values : Hyprland.workspaces
                for (var i = 0; i < wList.length; i++) {
                    var ws = wList[i]
                    if (ws.id === workspaceId && ws.windows > 0) return true
                }
                return false
            }

            width: workspacesContainer.itemWidth
            height: workspacesContainer.itemHeight
            radius: 8

            gradient: Gradient {
                GradientStop { position: 0.0; color: workspace.isActive ? "#4Dff6b9d" : "transparent" }
                GradientStop { position: 1.0; color: workspace.isActive ? "#4D4dd0e1" : "transparent" }
            }
            
            border.width: workspace.isActive ? 2 : 0
            border.color: "#804dd0e1"
            
            Behavior on border.width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on gradient { ColorAnimation { duration: 300 } }
            
            Text {
                anchors.centerIn: parent
                text: workspaceId
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: workspace.isActive ? 15 : 14
                font.weight: workspace.isActive ? Font.Bold : Font.Normal
                color: workspace.isActive ? "#4dd0e1" : (workspace.hasWindows ? "#9c4d97" : "#6b3e8f")
                
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + workspaceId)
                
                onEntered: {
                    workspace.scale = 1.1
                    if (!workspace.isActive) {
                        workspace.border.width = 1
                        workspace.border.color = "#4Dff6b9d"
                    }
                }
                onExited: {
                    workspace.scale = 1.0
                    if (!workspace.isActive) workspace.border.width = 0
                }
                onPressed: workspace.scale = 0.9
                onReleased: workspace.scale = 1.1
            }
            
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                var prev = activeWorkspaceId - 1
                if (prev < 1) prev = totalWorkspaces
                Hyprland.dispatch("workspace " + prev)
            } else if (wheel.angleDelta.y < 0) {
                var next = activeWorkspaceId + 1
                if (next > totalWorkspaces) next = 1
                Hyprland.dispatch("workspace " + next)
            }
        }
    }
}