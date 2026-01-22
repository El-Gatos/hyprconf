// Clock.qml
import QtQuick
import Quickshell

Rectangle {
    id: clock
    
    property string currentTime: Qt.formatTime(new Date(), "hh:mm AP")
    property string currentDate: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
    property bool showDate: false
    
    implicitWidth: timeText.implicitWidth + 32
    height: 32
    radius: 10
    
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#26ff6b9d" }
        GradientStop { position: 1.0; color: "#269c4d97" }
    }
    
    border.width: 2
    border.color: "#66ff9eb5"
    
    Behavior on border.color {
        ColorAnimation { duration: 300 }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clock.currentTime = Qt.formatTime(new Date(), "hh:mm AP")
            clock.currentDate = Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
        }
    }
    
    Text {
        id: timeText
        anchors.centerIn: parent
        text: clock.showDate ? clock.currentDate : clock.currentTime
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: "#ff9eb5"
        
        Behavior on text {
            SequentialAnimation {
                NumberAnimation {
                    target: timeText
                    property: "opacity"
                    to: 0
                    duration: 150
                }
                PropertyAction { target: timeText; property: "text" }
                NumberAnimation {
                    target: timeText
                    property: "opacity"
                    to: 1
                    duration: 150
                }
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onEntered: {
            clock.border.color = "#99ff9eb5"
            clock.scale = 1.05
        }
        
        onExited: {
            clock.border.color = "#66ff9eb5"
            clock.scale = 1.0
        }
        
        onClicked: {
            clock.showDate = !clock.showDate
        }
    }
    
    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}