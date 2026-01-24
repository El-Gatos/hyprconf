// Audio.qml - Force Sink Detection
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    
    // --- SINK HUNTING LOGIC ---
    property var sink: Pipewire.defaultSink
    
    // Timer to hunt for a sink if we don't have one
    Timer {
        interval: 1000
        running: !root.sink
        repeat: true
        onTriggered: {
            if (Pipewire.defaultSink) {
                root.sink = Pipewire.defaultSink
                return
            }
            
            // Manual Scan
            var nodes = Pipewire.nodes.values
            for (var i = 0; i < nodes.length; i++) {
                var n = nodes[i]
                // Look for a node that has volume and isn't a microphone (if possible)
                // We check if volume is defined.
                if (n.volume !== undefined) {
                    console.log("Force-picked sink: " + (n.description || n.id))
                    root.sink = n
                    return
                }
            }
        }
    }

    // --- PROPERTIES ---
    property real volume: sink ? sink.volume : 0
    property bool muted: sink ? sink.muted : false
    
    // Interaction State
    property bool hovered: mouseArea.containsMouse
    property bool dragging: mouseArea.pressed
    property bool isActive: hovered || dragging
    
    // --- LAYOUT ---
    implicitWidth: width 
    implicitHeight: 32
    
    // Expand if active
    width: isActive ? 150 : 32
    height: 32
    radius: 16
    
    color: "#B31a2847"
    border.width: 2
    border.color: isActive ? "#66ff6b9d" : "#4Dff6b9d"
    
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // --- VOLUME BAR ---
    Rectangle {
        id: volBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 2
        radius: 14
        
        // Calculate width safely
        width: (parent.width - 4) * root.volume
        
        // Only show when active
        opacity: root.isActive ? 0.8 : 0
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ff6b9d" }
            GradientStop { position: 1.0; color: "#4dd0e1" }
        }
        
        Behavior on width { NumberAnimation { duration: root.dragging ? 20 : 100 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // --- ICON ---
    Item {
        width: 32
        height: 32
        anchors.left: parent.left
        anchors.top: parent.top
        
        Text {
            anchors.centerIn: parent
            text: {
                if (root.muted) return "󰝟"
                if (root.volume >= 0.66) return "󰕾"
                if (root.volume >= 0.33) return "󰖀"
                return "󰕿"
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: root.muted ? "#ff6b9d" : "#4dd0e1"
        }
    }
    
    // --- PERCENTAGE TEXT ---
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        
        text: Math.round(root.volume * 100) + "%"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
        color: "#ffffff"
        style: Text.Outline; styleColor: "#1a2847"
        
        visible: root.isActive
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // --- MOUSE CONTROL ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        function setVolume(mouseX) {
            if (root.sink) {
                var pct = mouseX / root.width
                if (pct < 0) pct = 0
                if (pct > 1) pct = 1
                root.sink.volume = pct
            }
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) setVolume(mouse.x)
        }

        onPositionChanged: function(mouse) {
            if (mouse.buttons & Qt.LeftButton) setVolume(mouse.x)
        }

        onClicked: function(mouse) {
            if (!root.sink) return
            
            if (mouse.button === Qt.RightButton) {
                root.sink.muted = !root.sink.muted
            } else if (mouse.button === Qt.MiddleButton) {
                Quickshell.Process.run("pavucontrol")
            }
        }
        
        onWheel: function(wheel) {
            if (root.sink) {
                var step = 0.05
                if (wheel.angleDelta.y < 0) step = -step
                var newVol = root.sink.volume + step
                
                if (newVol < 0) newVol = 0
                if (newVol > 1) newVol = 1
                
                root.sink.volume = newVol
            }
        }
    }
}