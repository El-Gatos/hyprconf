import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData

        exclusionMode: ExclusionMode.Ignore

        // 1. Anchors are boolean flags in Quickshell, not a geometry object
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // 2. FIX: Use the WlrLayershell attached property for the layer
        WlrLayershell.layer: WlrLayer.Background
        
        // Optional: Exclude this window from taking up input space
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        color: "#1a2847"

        Image {
            anchors.fill: parent
            // Ensure this path is correct and absolute
            source: "/home/misty/Pictures/Wallpapers/dark-forest.jpg"
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }
    }
}