// Audio.qml
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: audio
    
    property real volume: Pipewire.defaultSink ? Pipewire.defaultSink.volume : 0
    property bool muted: Pipewire.defaultSink ? Pipewire.defaultSink.muted : false
    
    implicitWidth: audioLayout.implicitWidth + 24
    height: 32
    radius: 10
    
    color: "#B31a2847"
    border.width: 2
    border.color: mouseArea.containsMouse ? "#664dd0e1" : "#4D4dd0e1"
    
    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }
    
    Row {
        id: audioLayout
        anchors.centerIn: parent
        spacing: 8
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (audio.muted) return "󰝟"
                if (audio.volume > 0.66) return ""
                if (audio.volume > 0.33) return ""
                return ""
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: audio.muted ? "#ff6b9d" : "#4dd0e1"
            
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
            
            // Pulse animation when unmuted and sound is playing
            SequentialAnimation on scale {
                running: !audio.muted && audio.volume > 0
                loops: Animation.Infinite
                NumberAnimation { to: 1.2; duration: 300 }
                NumberAnimation { to: 1.0; duration: 300 }
            }
        }
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: audio.muted ? "Muted" : Math.round(audio.volume * 100) + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#ffb3c6"
            opacity: audio.muted ? 0.6 : 1.0
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.Process.run("pavucontrol")
            } else if (mouse.button === Qt.RightButton) {
                if (Pipewire.defaultSink) {
                    Pipewire.defaultSink.muted = !Pipewire.defaultSink.muted
                }
            }
        }
        
        onWheel: function(wheel) {
            if (Pipewire.defaultSink) {
                var delta = wheel.angleDelta.y / 120 * 0.05
                var newVolume = Math.max(0, Math.min(1, Pipewire.defaultSink.volume + delta))
                Pipewire.defaultSink.volume = newVolume
            }
        }
    }
    
    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutBack
        }
    }
}