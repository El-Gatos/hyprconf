import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: workspacesContainer
    
    required property var screen
    
    // Get monitor for this screen
    property var monitor: {
        for (var i = 0; i < Hyprland.monitors.length; i++) {
            if (Hyprland.monitors[i].name === screen.name) {
                return Hyprland.monitors[i];
            }
        }
        return null;
    }
    
    // Get current active workspace ID
    property int activeWorkspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    
    // Total workspaces available
    property int totalWorkspaces: 10
    
    // How many to show at once
    property int visibleCount: 5
    
    // Calculate starting workspace to show (to keep active centered)
    property int startingWorkspace: {
        var half = Math.floor(visibleCount / 2)
        var start = activeWorkspaceId - half
        
        // Clamp to valid range
        start = Math.max(1, start)
        start = Math.min(totalWorkspaces - visibleCount + 1, start)
        
        return start
    }

    implicitWidth: workspaceLayout.implicitWidth + 16
    height: 32
    radius: 10
    
    color: "#B31a2847"
    border.width: 2
    border.color: "#4Dff6b9d"
    
    clip: true
    
    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    Item {
        anchors.fill: parent
        anchors.margins: 8
        
        RowLayout {
            id: workspaceLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            
            Repeater {
                model: visibleCount
                
                Rectangle {
                    id: workspace
                    
                    property int workspaceId: startingWorkspace + index
                    property bool isActive: activeWorkspaceId === workspaceId
                    property bool hasWindows: {
                        for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                            var ws = Hyprland.workspaces.values[i]
                            if (ws.id === workspaceId && ws.windows > 0) {
                                return true
                            }
                        }
                        return false
                    }
                    
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 24
                    radius: 8
                    
                    gradient: Gradient {
                        GradientStop { 
                            position: 0.0
                            color: workspace.isActive ? "#4Dff6b9d" : "transparent"
                        }
                        GradientStop { 
                            position: 1.0
                            color: workspace.isActive ? "#4D4dd0e1" : "transparent"
                        }
                    }
                    
                    border.width: workspace.isActive ? 2 : 0
                    border.color: "#804dd0e1"
                    
                    Behavior on border.width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    
                    Behavior on gradient {
                        ColorAnimation { duration: 300 }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: workspaceId
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: workspace.isActive ? 15 : 14
                        font.weight: workspace.isActive ? Font.Bold : Font.Normal
                        color: workspace.isActive ? "#4dd0e1" : (workspace.hasWindows ? "#9c4d97" : "#6b3e8f")
                        
                        Behavior on color { 
                            ColorAnimation { duration: 200 } 
                        }
                        
                        Behavior on font.pixelSize {
                            NumberAnimation { duration: 200 }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onPressed: workspace.scale = 0.9
                        onReleased: workspace.scale = 1.1
                        
                        onEntered: {
                            workspace.scale = 1.1
                            if (!workspace.isActive) {
                                workspace.border.width = 1
                                workspace.border.color = "#4Dff6b9d"
                            }
                        }
                        
                        onExited: {
                            workspace.scale = 1.0
                            if (!workspace.isActive) {
                                workspace.border.width = 0
                            }
                        }
                        
                        onClicked: {
                            Hyprland.dispatch("workspace " + workspaceId)
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation { 
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }
                }
            }
        }
    }
    
    // Mouse wheel handler for cycling through workspaces
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                // Scroll up - go to previous workspace
                var prev = activeWorkspaceId - 1
                if (prev < 1) prev = totalWorkspaces
                Hyprland.dispatch("workspace " + prev)
            } else if (wheel.angleDelta.y < 0) {
                // Scroll down - go to next workspace
                var next = activeWorkspaceId + 1
                if (next > totalWorkspaces) next = 1
                Hyprland.dispatch("workspace " + next)
            }
        }
    }
}