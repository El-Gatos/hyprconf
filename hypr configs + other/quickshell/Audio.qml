// Audio.qml - DEFENSIVE SYNC VERSION
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    
    // --- PIPEWIRE CONNECTION ---
    property var sink: Pipewire.defaultAudioSink
    
    // Internal volume state to prevent NaN loops
    property real internalVolume: 0.0
    property bool internalMuted: false
    
    // --- SYNC TIMER (The Fix for NaN/Unbound) ---
    // Instead of binding directly to a potentially unstable C++ object,
    // we poll the object state safely. This prevents the "Unbound" crashes.
    Timer {
        interval: 100 // 100ms is fast enough for UI, slow enough to be safe
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.sink) return;
            if (!root.sink.audio) return;
            
            // Safe Read
            var v = root.sink.audio.volume;
            var m = root.sink.audio.muted;
            
            // Only update if valid number
            if (v !== undefined && !isNaN(v)) {
                root.internalVolume = v;
            }
            if (m !== undefined) {
                root.internalMuted = m;
            }
        }
    }
    
    // --- UI STATE ---
    property bool hovered: mouseArea.containsMouse
    property bool dragging: mouseArea.pressed
    property bool isActive: hovered || dragging

    Component.onCompleted: console.log("[Audio] Defensive Module Loaded.")

    // --- ACTIONS ---
    function setVolume(val) {
        if (!sink) return;
        
        // Clamp
        var safeVal = val;
        if (safeVal > 1.0) safeVal = 1.0;
        if (safeVal < 0.0) safeVal = 0.0;
        
        // WRITE GUARD: Wrap in try/catch to silence "Unbound" errors
        try {
            if (sink.audio) {
                sink.audio.volume = safeVal;
                // Optimistic update for instant visual feedback
                root.internalVolume = safeVal; 
            }
        } catch (e) {
            // Ignore unbound errors during initialization
        }
    }

    function toggleMute() {
        if (!sink || !sink.audio) return;
        try {
            sink.audio.muted = !sink.audio.muted;
            root.internalMuted = !root.internalMuted;
        } catch (e) {}
    }
    
    // --- UI CONFIGURATION ---
    implicitWidth: width
    implicitHeight: 32
    
    // Animation logic
    width: isActive ? 150 : 32
    height: 32
    radius: 16
    
    // Clips content so the slider doesn't spill out
    clip: true
    
    color: "#B31a2847"
    border.width: 2
    border.color: isActive ? "#66ff6b9d" : "#4Dff6b9d"
    
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // --- VOLUME BAR ---
    Rectangle {
        id: volBar
        // Anchor to left, top, bottom.
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 2
        radius: 14
        
        // Z-Index 0: Background layer
        z: 0
        
        width: {
            var maxW = parent.width - 4;
            var calc = maxW * root.internalVolume;
            return Math.max(0, calc);
        }
        
        opacity: root.isActive ? 0.8 : 0
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ff6b9d" }
            GradientStop { position: 1.0; color: "#4dd0e1" }
        }
        
        Behavior on width {
            enabled: !root.dragging
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // --- ICON (Head) ---
    Item {
        id: iconContainer
        width: 32
        height: 32
        
        // Z-Index 1: Sits on top of the bar
        z: 1
        
        // STRICT ANCHORING: Always on the left edge
        anchors.left: parent.left
        anchors.top: parent.top
        
        Text {
            anchors.centerIn: parent
            text: {
                if (root.internalMuted) return "\uf026";
                if (root.internalVolume >= 0.66) return "\uf028";
                if (root.internalVolume >= 0.33) return "\uf027";
                return "\uf026";
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: (root.internalMuted) ? "#ff6b9d" : "#4dd0e1"
        }
    }

    // --- PERCENTAGE TEXT ---
    Text {
        // Z-Index 1: Sits on top of the bar
        z: 1
        
        // STRICT ANCHORING: Always on the right edge
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        
        text: Math.round(root.internalVolume * 100) + "%"
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
        
        function handleMouse(mouse) {
            var pct = mouse.x / width;
            if (pct < 0) pct = 0; 
            if (pct > 1) pct = 1.0; // Fixed: Added the literal and semicolon
            root.setVolume(pct);
        }

        onPositionChanged: (mouse) => {
            if (pressed) handleMouse(mouse);
        }
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) handleMouse(mouse);
            if (mouse.button === Qt.MiddleButton) root.toggleMute();
        }
        
        onWheel: (wheel) => {
            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.setVolume(root.internalVolume + step);
        }
    }
}