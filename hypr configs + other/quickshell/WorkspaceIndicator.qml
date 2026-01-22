// WorkspaceIndicator.qml - Floating workspace switcher overlay
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
    model: Quickshell.screens
    
    PopupWindow {
        id: wsIndicator
        
        property var modelData
        property int lastWorkspace: 1
        property int currentWorkspace: Hyprland.focusedMonitor ? (Hyprland.focusedMonitor.activeWorkspace ? Hyprland.focusedMonitor.activeWorkspace.id : 1) : 1
        
        screen: modelData
        visible: false
        
        implicitWidth: 500
        implicitHeight: 120
        
        color: "transparent"
        
        onCurrentWorkspaceChanged: {
            if (currentWorkspace !== lastWorkspace) {
                showIndicator()
                lastWorkspace = currentWorkspace
            }
        }
        
        function showIndicator() {
            wsIndicator.visible = true
            wsIndicator.opacity = 1.0
            hideTimer.restart()
        }
        
        Timer {
            id: hideTimer
            interval: 1500
            onTriggered: {
                fadeOut.start()
            }
        }
        
        NumberAnimation {
            id: fadeOut
            target: wsIndicator
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.InOutCubic
            onFinished: {
                wsIndicator.visible = false
            }
        }
        
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#E61a2847"
            border.width: 3
            border.color: "#B3ff6b9d"
            
            scale: wsIndicator.visible ? 1.0 : 0.8
            
            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
            
            // Gradient background
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ff6b9d" }
                    GradientStop { position: 0.5; color: "#9c4d97" }
                    GradientStop { position: 1.0; color: "#4dd0e1" }
                }
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Workspace " + wsIndicator.currentWorkspace
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "#ff9eb5"
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    
                    Repeater {
                        model: 10
                        
                        Rectangle {
                            id: wsIndicatorDot
                            
                            property int workspaceId: index + 1
                            property bool isActive: wsIndicatorDot.workspaceId === wsIndicator.currentWorkspace
                            property bool hasWindows: {
                                for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                                    var ws = Hyprland.workspaces.values[i]
                                    if (ws.id === workspaceId && ws.windows > 0) {
                                        return true
                                    }
                                }
                                return false
                            }
                            
                            width: isActive ? 60 : 40
                            height: 40
                            radius: 12
                            
                            color: isActive ? "#66ff6b9d" : (hasWindows ? "#332d4a7c" : "transparent")
                            border.width: 2
                            border.color: isActive ? "#ff6b9d" : (hasWindows ? "#4d4a7c" : "#1a2d4a7c")
                            
                            Behavior on width {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutBack
                                }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                            
                            Behavior on border.color {
                                ColorAnimation { duration: 200 }
                            }
                            
                            // Glow effect for active workspace
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -6
                                radius: parent.radius + 3
                                color: "transparent"
                                border.width: isActive ? 3 : 0
                                border.color: "#4D4dd0e1"
                                opacity: isActive ? 1 : 0
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }
                                
                                // Pulse animation
                                SequentialAnimation on scale {
                                    running: isActive
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1.1; duration: 1000; easing.type: Easing.InOutCubic }
                                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutCubic }
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: workspaceId
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: isActive ? 16 : 14
                                font.weight: isActive ? Font.Bold : Font.Normal
                                color: isActive ? "#4dd0e1" : (hasWindows ? "#9c4d97" : "#6b3e8f")
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                                
                                Behavior on font.pixelSize {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}