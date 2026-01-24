// Audio.qml - CLI MODE (Debug & Ruthless Parsing)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    
    // --- INTERNAL STATE ---
    property real volume: 0.0
    property bool muted: false
    
    // --- LAYOUT STATE ---
    property bool hovered: mouseArea.containsMouse
    property bool dragging: mouseArea.pressed
    property bool isActive: hovered || dragging
    
    // --- POLLING LOGIC ---
    // We poll the system constantly. This ensures that if you change volume
    // via keyboard or another app, this pill updates to match.
    Timer {
        interval: 300 // Check every 300ms
        running: true 
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Don't poll while dragging OR if the previous poll is still stuck
            if (!root.dragging && !pollProc.running) {
                pollProc.running = true
            }
        }
    }

    Process {
        id: pollProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        onStdoutChanged: {
            var out = pollProc.stdout.toString().trim()
            // If wpctl returns nothing (some systems use pactl), try pactl as a fallback
            if (!out) {
                pollAlt.running = true
                return
            }
            
            // DEBUG: Uncomment this if it still fails to see what wpctl returns
            // console.log("[AudioPoll] Raw output: '" + out + "'")
            
            // RUTHLESS PARSING:
            // Find the first sequence of numbers with a dot or comma.
            // Ignore "Volume:" text entirely.
            // Matches: "0.45", "Volume: 0.45", "Vol: 0,45", etc.
            var matches = out.match(/(\d+[.,]\d+)/g)

            if (matches && matches.length > 0) {
                // Use the latest parsed value in case stdout accumulates
                var valStr = matches[matches.length - 1].replace(',', '.')
                var newVol = parseFloat(valStr)
                
                // Only update if valid and changed
                if (!isNaN(newVol) && Math.abs(newVol - root.volume) > 0.01) {
                    // console.log("[AudioPoll] Syncing volume: " + newVol)
                    root.volume = newVol
                }
            }
            
            var isMuted = out.includes("[MUTED]")
            if (root.muted !== isMuted) root.muted = isMuted
        }
    }

    // Fallback for systems where `pactl` updates volume (e.g., PulseAudio compatibility)
    Process {
        id: pollAlt
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        onStdoutChanged: {
            var out = pollAlt.stdout.toString().trim()
            if (!out) return

            // Parse last percentage found, e.g. "Front Left: 65536 / 100% / 0.00 dB"
            var matches = out.match(/(\d+)%/g)
            if (matches && matches.length > 0) {
                var last = matches[matches.length - 1].replace('%','')
                var newVol = parseFloat(last) / 100.0
                if (!isNaN(newVol) && Math.abs(newVol - root.volume) > 0.01) {
                    root.volume = newVol
                }
            }
        }
    }

    // --- COMMAND EXECUTION ---
    function setVolume(val) {
        // Optimistic update
        root.volume = val
        // Send to system
        setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)]
        setVolProc.running = true
    }
    
    Process { id: setVolProc }

    function toggleMute() {
        root.muted = !root.muted
        muteProc.running = true
    }
    
    Process { 
        id: muteProc 
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] 
    }
    
    // --- UI CONFIGURATION ---
    implicitWidth: width
    implicitHeight: 32
    
    // Animation logic
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
        
        // Pure math binding
        width: {
            var maxW = parent.width - 4
            var calc = maxW * root.volume
            return Math.max(0, calc)
        }
        
        opacity: root.isActive ? 0.8 : 0
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ff6b9d" }
            GradientStop { position: 1.0; color: "#4dd0e1" }
        }
        
        // Smooth animation when polling (keys), instant update when dragging (mouse)
        Behavior on width {
            enabled: !root.dragging
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
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
        
        function handleMouse(mouse) {
            var pct = mouse.x / width
            if (pct < 0) pct = 0; 
            if (pct > 1) pct = 1;
            setVolume(pct)
        }
        
        onPressed: (mouse) => { 
            if (mouse.button === Qt.LeftButton) handleMouse(mouse) 
        }
        
        onPositionChanged: (mouse) => { 
            if (mouse.buttons & Qt.LeftButton) handleMouse(mouse) 
        }
        
        onWheel: (wheel) => {
            var step = 0.05
            if (wheel.angleDelta.y < 0) step = -step
            var newVol = root.volume + step
            if (newVol < 0) newVol = 0; 
            if (newVol > 1) newVol = 1;
            setVolume(newVol)
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                toggleMute()
            } else if (mouse.button === Qt.MiddleButton) {
                Process.run(["pavucontrol"])
            }
        }
    }
}
