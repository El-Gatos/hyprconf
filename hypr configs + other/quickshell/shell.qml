// shell.qml - Main Quickshell Configuration
// Vaporwave Dreams Theme

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    // 1. The Background component (handles wallpapers for all screens)
    // This sits outside the panel variants because it has its own Variants logic internally.
    Background {}

    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            property var modelData
            screen: modelData
            
            anchors {
                top: true
                left: true
                right: true
            }
            
            implicitHeight: 42
            margins {
                top: 8
                left: 12
                right: 12
            }
            
            color: "transparent"
            
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#B31a2847"
                border.width: 2
                border.color: "#4Dff6b9d"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12
                    
                    // Left side
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: 12
                        
                        Launcher {}
                        
                        // 2. Pass the specific screen modelData to Workspaces
                        // This fixes the issue where clicking on one monitor affected the bar on the other
                        Workspaces {
                            screen: modelData
                        }
                        
                        WindowTitle {}
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Center
                    Clock {
                        Layout.alignment: Qt.AlignCenter
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Right side
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 12
                        
                        Audio {}
                        PowerMenu {}
                    }
                }
            }
        }
    }
    
    // Workspace indicator overlay
    WorkspaceIndicator {}
}