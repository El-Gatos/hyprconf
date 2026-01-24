// Launcher.qml - FIXED
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: launcher
    
    width: 42
    height: 32
    radius: 10
    
    color: mouseArea.containsMouse ? "#33ff6b9d" : "transparent"
    border.width: 2
    border.color: mouseArea.containsMouse ? "#99ff6b9d" : "#4Dff6b9d"
    
    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    
    Behavior on border.color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    
    Text {
        anchors.centerIn: parent
        text: "󰣇"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        color: mouseArea.containsMouse ? "#ff6b9d" : "#4dd0e1"
        
        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
    
    Process {
        id: rofiProcess
        running: false
        command: ["rofi", "-show", "drun"]
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            launcher.scale = 0.9
            scaleAnimation.start()
            rofiProcess.running = true
        }
    }
    
    SequentialAnimation {
        id: scaleAnimation
        NumberAnimation {
            target: launcher
            property: "scale"
            to: 1.0
            duration: 150
            easing.type: Easing.OutBack
        }
    }
}