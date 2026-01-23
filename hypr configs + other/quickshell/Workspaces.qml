import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: workspacesContainer
    
    required property var screen
    
    // Manual loop to find monitor index because .find() doesn't exist on QML lists
    property int monitorIndex: {
        var idx = 0;
        for (var i = 0; i < Hyprland.monitors.length; i++) {
            if (Hyprland.monitors[i].name === screen.name) {
                idx = i;
                break;
            }
        }
        return idx;
    }

    property bool isSingleMonitor: Hyprland.monitors.length === 1
    
    // Logic: If single monitor, show 10. If multi, show 5 per screen.
    property int count: isSingleMonitor ? 10 : 5
    property int startId: isSingleMonitor ? 1 : ((monitorIndex * 5) + 1)

    implicitWidth: workspaceLayout.implicitWidth + 16
    height: 32
    radius: 10
    
    color: "#B31a2847"
    border.width: 2
    border.color: "#4Dff6b9d"
    
    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    RowLayout {
        id: workspaceLayout
        anchors.centerIn: parent
        spacing: 6
        
        Repeater {
            model: workspacesContainer.count
            
            Rectangle {
                id: workspace
                
                property int workspaceId: workspacesContainer.startId + index
                
                // Fix: explicit loop to check active status without .find()
                property bool isActive: {
                    var activeId = -1;
                    // Get the active workspace ID for THIS screen
                    for (var i = 0; i < Hyprland.monitors.length; i++) {
                        if (Hyprland.monitors[i].name === screen.name) {
                            activeId = Hyprland.monitors[i].activeWorkspace.id;
                            break;
                        }
                    }
                    return activeId === workspaceId;
                }
                
                // Fix: Check windows using .has() or direct property access if available
                property bool hasWindows: {
                    // Hyprland.workspaces is a Map-like object in Quickshell
                    // We check if the workspace exists in the map
                    return Hyprland.workspaces.has(workspaceId)
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
                
                Text {
                    anchors.centerIn: parent
                    text: workspaceId
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: workspace.isActive ? "#4dd0e1" : (workspace.hasWindows ? "#9c4d97" : "#6b3e8f")
                    Behavior on color { ColorAnimation { duration: 200 } }
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
                        // Standard dispatch. 
                        // Note: We cast to string to be safe.
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