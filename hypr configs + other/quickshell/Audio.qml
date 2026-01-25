import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io

Rectangle {
    id: root
    
    property var sink: Pipewire.defaultAudioSink
    property bool sinkValid: false
    property real internalVolume: 0.0
    property bool internalMuted: false
    property real pendingVolume: -1
    property int muteIgnoreCycles: 0
    property real _lastLoggedVol: -1
    property bool _lastLoggedMute: false
    
    Timer {
        interval: 200 
        running: true
        repeat: true
        onTriggered: {
            root.sinkValid = root.sink && root.sink.audio;

            if (root.pendingVolume >= 0) {
                root.pendingVolume = -1; 
                return;
            }
            
            var ignoreMute = false;
            if (root.muteIgnoreCycles > 0) {
                root.muteIgnoreCycles--;
                ignoreMute = true;
            }

            if (root.sinkValid) {
                var v = root.sink.audio.volume;
                
                if (v !== undefined && !isNaN(v)) {
                    if (root.internalVolume !== v) {
                        root.internalVolume = v;
                        if (root._lastLoggedVol !== v) {
                            root._lastLoggedVol = v;
                        }
                    }
                }
            } else {
                root.sink = Pipewire.defaultAudioSink;
            }
            
            if (!ignoreMute) {
                root.readMuteState();
            }
        }
    }
    
    Process {
        id: muteReader
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        
        onExited: {
            if (exitCode === 0) {
                var output = stdout.trim();
                var isMuted = output.includes("[MUTED]");
                
                if (root.internalMuted !== isMuted) {
                    root.internalMuted = isMuted;
                    if (root._lastLoggedMute !== isMuted) {
                        root._lastLoggedMute = isMuted;
                    }
                }
            }
        }
    }
    
    function readMuteState() {
        muteReader.running = true;
    }
    
    property bool hovered: mouseArea.containsMouse
    property bool dragging: mouseArea.pressed
    property bool isActive: hovered || dragging


    function setVolume(val) {
        var safeVal = val;
        if (safeVal > 1.0) safeVal = 1.0;
        if (safeVal < 0.0) safeVal = 0.0;
        
        root.internalVolume = safeVal;
        root.applyVolumeNative(safeVal);
        root.pendingVolume = safeVal; 
    }

    function toggleMute() {
        root.internalMuted = !root.internalMuted;
        var targetMute = root.internalMuted;
        root.applyMuteNative(targetMute);
        root.muteIgnoreCycles = 5;
    }
    
    Process {
        id: volumeSetter
        running: false
    }
    
    Process {
        id: muteSetter
        running: false
    }
    
    function applyVolumeNative(volume) {
        var percent = Math.round(volume * 100);
        volumeSetter.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percent + "%"];
        volumeSetter.running = true;
    }

    function applyMuteNative(mute) {
        var muteVal = mute ? "1" : "0";
        muteSetter.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", muteVal];
        muteSetter.running = true;
    }
    
    implicitWidth: width
    implicitHeight: 32
    width: isActive ? 150 : 32
    height: 32
    radius: 16
    clip: true
    color: "#B31a2847"
    border.width: 2
    border.color: isActive ? "#66ff6b9d" : "#4Dff6b9d"
    
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 200 } }


    Rectangle {
        id: volBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 2
        radius: 14
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

    Item {
        id: iconContainer
        width: 32
        height: 32
        z: 1
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

    Text {
        z: 1
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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        function handleMouse(mouse) {
            var pct = mouse.x / width;
            if (pct < 0) pct = 0; 
            if (pct > 1) pct = 1.0; 
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