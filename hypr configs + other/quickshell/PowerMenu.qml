// PowerMenu.qml
import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: powerMenu
    
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
        text: "⏻"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        color: mouseArea.containsMouse ? "#ff6b9d" : "#e91e63"
        
        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            powerMenu.scale = 0.9
            scaleAnimation.start()
            Quickshell.Process.run("rofi", [
                "-show", "power-menu", 
                "-modi", "power-menu:~/.config/rofi/scripts/power-menu.sh"
            ])
        }
    }
    
    SequentialAnimation {
        id: scaleAnimation
        NumberAnimation {
            target: powerMenu
            property: "scale"
            to: 1.0
            duration: 150
            easing.type: Easing.OutBack
        }
    }
}