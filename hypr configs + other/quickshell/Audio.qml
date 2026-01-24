// Audio.qml - DEFENSIVE SYNC VERSION
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    
    // --- PIPEWIRE CONNECTION ---
    property var sink: Pipewire.defaultAudioSink
    property bool sinkValid: false
    
    // Internal volume state to prevent NaN loops
    property real internalVolume: 0.0
    property bool internalMuted: false
    
    // Pending write requests (processed by Timer)
    property real pendingVolume: -1
    property bool pendingMuteToggle: false
    property bool skipNextMuteRead: false
    property int writeRetries: 0
    
    // Track what we've written to avoid reverting on bad reads
    property real lastWrittenVolume: -1
    property bool lastWrittenMute: false
    property bool muteWritten: false
    
    Timer {
        interval: 200 
        running: true
        repeat: true
        onTriggered: {
            // ---------------------------------------------------------
            // 1. HANDLE PENDING WRITES (The Shield)
            // ---------------------------------------------------------
            
            // If we just clicked volume, skip reading volume this tick
            if (root.pendingVolume >= 0) {
                root.pendingVolume = -1; 
                return;
            }
            
            // If we just clicked mute, skip reading mute this tick
            // We turn off the flag so the NEXT tick will read normally.
            if (root.muteWritten) {
                root.muteWritten = false;
                return;
            }

            // ---------------------------------------------------------
            // 2. SYNC WITH SYSTEM
            // ---------------------------------------------------------
            if (root.sink && root.sink.audio) {
                var v = root.sink.audio.volume;
                var m = root.sink.audio.muted;
                
                // Only update internal state if we didn't just write to it
                if (v !== undefined && !isNaN(v)) {
                    root.internalVolume = v;
                }
                
                // CRITICAL: Only update mute if the system actually disagrees
                if (m !== undefined) {
                    root.internalMuted = m;
                }
            } else {
                root.sink = Pipewire.defaultAudioSink;
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
        // 1. Clamp logic
        var safeVal = val;
        if (safeVal > 1.0) safeVal = 1.0;
        if (safeVal < 0.0) safeVal = 0.0;
        
        // 2. Visual Update (Instant feedback)
        root.internalVolume = safeVal;
        
        // 3. NUCLEAR OPTION: Direct System Call
        // We bypass the Quickshell object entirely for writing.
        root.applyVolumeViaDBus(safeVal);
        
        // Disable the read timer for a moment so the bar doesn't jitter
        root.pendingVolume = safeVal; 
    }

    function toggleMute() {
        // 1. Visual Update
        root.internalMuted = !root.internalMuted;
        
        // 2. Direct System Call
        root.applyMuteViaDBus(root.internalMuted);
        
        // 3. Set the "Ignore" flag
        // This tells the Timer: "Don't trust the system for a moment, I just changed it."
        root.muteWritten = true;
    }
    
    function applyVolumeViaDBus(volume) {
        var percent = Math.round(volume * 100);
        // FORCE PACTL: This talks directly to the audio server
        Quickshell.execute(["pactl", "set-sink-volume", "@DEFAULT_SINK@", percent + "%"]);
        console.log("[Audio] Forcing write via pactl:", percent + "%");
    }

    function applyMuteViaDBus(mute) {
        Quickshell.execute(["pactl", "set-sink-mute", "@DEFAULT_SINK@", mute ? "1" : "0"]);
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

        onPositionChanged: function(mouse) {
            if (mouseArea.pressed) handleMouse(mouse);
        }
        
        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) handleMouse(mouse);
            if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) root.toggleMute();
        }
        
        onWheel: function(wheel) {
            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.setVolume(root.internalVolume + step);
        }
    }
}