// Workspaces.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: workspacesContainer
    
    implicitWidth: workspaceLayout.implicitWidth + 16
    height: 32
    radius: 10
    
    color: "#B31a2847"
    border.width: 2
    border.color: "#4Dff6b9d"
    
    RowLayout {
        id: workspaceLayout
        anchors.centerIn: parent
        spacing: 6
        
        Repeater {
            model: 5
            
            Rectangle {
                id: workspace
                
                property int workspaceId: index + 1
                property bool isActive: Hyprland.focusedMonitor ? (Hyprland.focusedMonitor.activeWorkspace ? Hyprland.focusedMonitor.activeWorkspace.id === workspaceId : false) : false
                property bool hasWindows: {
                    for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                        var ws = Hyprland.workspaces.values[i]
                        if (ws.id === workspaceId && ws.windows > 0) {
                            return true
                        }
                    }
                    return false
                }
                
                width: 32
                height: 24
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
                
                // Glow effect for active workspace
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 2
                    color: "transparent"
                    border.width: workspace.isActive ? 2 : 0
                    border.color: "#334dd0e1"
                    opacity: workspace.isActive ? 1 : 0
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        var icons = ["", "", "", "", ""]
                        return workspace.isActive ? "" : (workspace.hasWindows ? icons[index] : "")
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: workspace.isActive ? "#4dd0e1" : (workspace.hasWindows ? "#9c4d97" : "#6b3e8f")
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
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
                        Hyprland.dispatch("workspace", workspaceId.toString())
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