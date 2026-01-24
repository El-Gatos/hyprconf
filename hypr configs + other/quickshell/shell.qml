import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    // Global wallpaper handling
    Background {}

    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: panel
            property var modelData
            screen: modelData
            
            // Reserve space at the top of the screen (strut)
            // This prevents windows from overlapping the bar area
            anchors {
                top: true
                left: true
                right: true
            }
            
            // Height of the clickable area (Bar height + top/bottom margins)
            height: 60 
            
            color: "transparent"
            
            // Pass clicks through empty areas (if supported)
            mask: Region { item: barBackground }

            Rectangle {
                id: barBackground
                
                // --- POSITIONING: EXTENDED BUT FLOATING ---
                anchors.top: parent.top
                anchors.topMargin: 8
                
                // Stretch to fit the screen, but leave a gap (floating look)
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                
                height: 44
                
                // --- STYLING: CAELESTIA ROUNDING ---
                // radius: height / 2 makes it a perfect pill shape
                radius: 12
                
                color: "#cc1a2847" // Slightly more opaque for the main bar
                border.width: 2
                border.color: "#4Dff6b9d"
                
                // --- CONTENT: CENTERED ---
                RowLayout {
                    id: mainLayout
                    
                    // This forces the modules to stay in the EXACT center of the wide bar
                    anchors.centerIn: parent 
                    
                    spacing: 12
                    
                    
                    Workspaces {
                        screen: panel.modelData
                        Layout.alignment: Qt.AlignVCenter
                    }
                    

                    Rectangle {
                        width: 1; height: 18
                        color: "#4Dff6b9d"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Clock { Layout.alignment: Qt.AlignVCenter }
                    
                    Rectangle {
                        width: 1; height: 18
                        color: "#4Dff6b9d"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Audio { Layout.alignment: Qt.AlignVCenter }
                    PowerMenu { Layout.alignment: Qt.AlignVCenter }
                }
            }
        }
    }
    
    WorkspaceIndicator {}
}