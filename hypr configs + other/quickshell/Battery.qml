// Battery.qml - FIXED
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    id: battery
    
    property var upower: UPower.displayDevice
    
    // FIX: Percentage is already 0-100 range, multiply by 100 if it's 0-1
    property real percentage: {
        if (!upower) return 0
        var pct = upower.percentage
        // If percentage is less than 1, it's in decimal form (0.84 = 84%)
        return pct < 1 ? pct * 100 : pct
    }
    
    // FIX: Check state as a number instead of enum
    // Charging = 1, Discharging = 2, Empty = 3, FullyCharged = 4, etc.
    property bool charging: upower ? (upower.state === 1 || upower.state === 4) : false
    
    Component.onCompleted: {
        console.log("Battery loaded - Percentage:", percentage + "%", "State:", upower ? upower.state : "null")
    }
    
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
                if (!upower) return "󰂑"
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
            color: !upower ? "#6b3e8f" : (percentage < 20 ? "#ff6b9d" : "#26c6da")
            
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: upower ? (Math.round(percentage) + "%") : "N/A"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#ffb3c6"
        }
    }
}