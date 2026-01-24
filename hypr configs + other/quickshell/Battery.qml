// Battery.qml
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    id: battery
    
    property var upower: Upower.displayDevice
    property real percentage: upower ? upower.percentage : 0
    property bool charging: upower ? upower.state === UPower.DeviceState.Charging : false
    
    implicitWidth: batteryRow.implicitWidth + 24
    height: 32
    radius: 10
    color: "#B31a2847"
    border.width: 2
    border.color: charging ? "#4D4dd0e1" : "#4D26c6da"
    
    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }
    
    Row {
        id: batteryRow
        anchors.centerIn: parent
        spacing: 8
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (charging) return "󰂄"
                if (percentage > 90) return "󰁹"
                if (percentage > 70) return "󰂀"
                if (percentage > 50) return "󰁾"
                if (percentage > 30) return "󰁼"
                if (percentage > 15) return "󰁺"
                return "󰂎"
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: percentage < 20 ? "#ff6b9d" : "#26c6da"
            
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(percentage) + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#ffb3c6"
        }
    }
}
