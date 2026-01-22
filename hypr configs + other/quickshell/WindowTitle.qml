// WindowTitle.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: windowTitle
    
    property string title: {
        if (!Hyprland.focusedMonitor) return "Desktop"
        var workspace = Hyprland.focusedMonitor.activeWorkspace
        if (!workspace) return "Desktop"
        var window = workspace.lastFocusedWindow
        return window ? window.title : "Desktop"
    }
    
    implicitWidth: Math.min(titleText.implicitWidth + 32, 400)
    height: 32
    radius: 10
    
    color: "#B31a2847"
    border.width: 2
    border.color: "#4D4dd0e1"
    
    clip: true
    
    Text {
        id: titleText
        anchors.centerIn: parent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        
        text: windowTitle.title
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.weight: Font.Medium
        color: "#4dd0e1"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
        
        Behavior on text {
            SequentialAnimation {
                NumberAnimation {
                    target: titleText
                    property: "opacity"
                    to: 0
                    duration: 100
                }
                PropertyAction { target: titleText; property: "text" }
                NumberAnimation {
                    target: titleText
                    property: "opacity"
                    to: 1
                    duration: 100
                }
            }
        }
    }
    
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}