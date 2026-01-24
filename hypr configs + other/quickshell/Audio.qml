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
    
    // --- SYNC TIMER (The Fix for NaN/Unbound) ---
    // Instead of binding directly to a potentially unstable C++ object,
    // we poll the object state safely. This prevents the "Unbound" crashes.
    Timer {
        interval: 100 // 100ms is fast enough for UI, slow enough to be safe
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Check if sink is valid; refresh if unbound
            if (!root.sink || !root.sink.audio) {
                root.sink = Pipewire.defaultAudioSink;
                root.sinkValid = false;
                return;
            }
            
            // Verify sink is actually bound before proceeding
            if (root.sink.id === undefined || String(root.sink.id).includes("unbound")) {
                console.warn("[Audio] Sink is unbound, refreshing...");
                root.sink = Pipewire.defaultAudioSink;
                root.sinkValid = false;
                return;
            }
            
            root.sinkValid = true;
            
            // Process pending writes FIRST (while sink is known-good)
            if (root.pendingVolume >= 0 && root.sinkValid) {
                try {
                    root.sink.audio.volume = root.pendingVolume;
                    root.lastWrittenVolume = root.pendingVolume;
                    console.log("[Audio] Volume write queued:", root.pendingVolume);
                } catch (e) {
                    console.warn("[Audio] Failed via Quickshell, using pactl fallback:", e);
                    root.applyVolumeViaDBus(root.pendingVolume);
                }
                root.pendingVolume = -1;
            }
            
            if (root.pendingMuteToggle && root.sinkValid) {
                try {
                    var oldMute = root.sink.audio.muted;
                    var newMute = !oldMute;
                    root.sink.audio.muted = newMute;
                    root.lastWrittenMute = newMute;
                    root.muteWritten = true;
                    console.log("[Audio] Mute toggle queued: was", oldMute, "now", newMute);
                    root.skipNextMuteRead = true;
                } catch (e) {
                    console.warn("[Audio] Failed via Quickshell, using pactl fallback:", e);
                    root.applyMuteViaDBus(!root.lastWrittenMute);
                    root.lastWrittenMute = !root.lastWrittenMute;
                    root.muteWritten = true;
                }
                root.pendingMuteToggle = false;
            }
            
            // Delay read by one tick to let Pipewire settle
            if (root.writeRetries > 0) {
                root.writeRetries--;
                return; // Skip read this tick
            }
            
            // Safe Read - but trust our writes over Pipewire's feedback
            var v = root.sink.audio.volume;
            var m = root.sink.audio.muted;
            
            // Only update volume if we haven't written one this cycle
            if (root.pendingVolume < 0 && v !== undefined && !isNaN(v)) {
                root.internalVolume = v;
                root.lastWrittenVolume = v;
            }
            
            // Only update mute if we haven't just written it
            if (!root.muteWritten && !root.skipNextMuteRead && m !== undefined) {
                root.internalMuted = m;
                root.lastWrittenMute = m;
            } else if (root.skipNextMuteRead) {
                // Skip this read, but next time show the written value
                root.internalMuted = root.lastWrittenMute;
            }
            
            root.skipNextMuteRead = false;
            root.muteWritten = false;
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
        
        // 2. Optimistic Update (Visuals update instantly)
        root.internalVolume = safeVal;

        // 3. Queue Write (Timer will apply it when sink is known-good)
        root.pendingVolume = safeVal;
    }

    function toggleMute() {
        // Optimistic Update
        root.internalMuted = !root.internalMuted;
        
        // Queue Write (Timer will apply it)
        root.pendingMuteToggle = true;
    }
    
    // Fallback: use pactl to actually change volume if Quickshell binding fails
    function applyVolumeViaDBus(volume) {
        var percent = Math.round(volume * 100);
        Quickshell.execute(["pactl", "set-sink-volume", "@DEFAULT_SINK@", percent + "%"], false);
        console.log("[Audio] Applied volume via pactl:", percent + "%");
    }
    
    function applyMuteViaDBus(mute) {
        Quickshell.execute(["pactl", "set-sink-mute", "@DEFAULT_SINK@", mute ? "1" : "0"], false);
        console.log("[Audio] Applied mute via pactl:", mute);
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