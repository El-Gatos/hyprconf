import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Hyprland
import QtQuick.Layouts

ShellRoot {
    Background {}

    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: panel
            property var modelData
            screen: modelData
            
            // Anchor to the left edge of the screen
            anchors {
                top: true
                bottom: true
                left: true
                right: false
            }
            
            // Total width of the dock area (includes transparency/margins)
            implicitWidth: barBackground.implicitWidth + 16
            
            color: "transparent"
            
            // Mask allows clicks to pass through transparent areas if needed
            mask: Region { item: barBackground }

            Rectangle {
                id: barBackground

                // Float a compact bar rather than stretching the full height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                width: 44
                implicitHeight: mainLayout.implicitHeight + 16
                radius: 12
                
                color: "#cc1a2847"
                border.width: 2
                border.color: "#4Dff6b9d"
                
                ColumnLayout {
                    id: mainLayout
                    anchors.fill: parent
                    anchors.margins: 8
                    
                    spacing: 12
                    
                    // --- TOP SECTION ---
                    Launcher { Layout.alignment: Qt.AlignHCenter }
                    
                    Workspaces {
                        screen: panel.modelData
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    // --- MIDDLE SECTION (Title) ---
                    // Spacer
                    Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }
                    
                    // Rotated Title Wrapper
                    // This container tells the layout the correct VERTICAL dimensions
                    // so the text doesn't overlap or drift.
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        // Visual width is the component's height (32)
                        implicitWidth: 32 
                        // Visual height is the component's width (max 400)
                        implicitHeight: titleComp.implicitWidth
                        
                        WindowTitle { 
                            id: titleComp
                            anchors.centerIn: parent
                            rotation: -90
                        }
                    }
                    
                    // Spacer
                    Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }
                    
                    // --- BOTTOM SECTION ---
                    Audio { 
                        id: audioModule 
                        Layout.alignment: Qt.AlignHCenter 
                    }
                    
                    Battery { Layout.alignment: Qt.AlignHCenter }
                    
                    // Rotated Clock Wrapper
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 32
                        implicitHeight: clockComp.implicitWidth
                        
                        Clock { 
                            id: clockComp 
                            anchors.centerIn: parent
                            rotation: -90
                        }
                    }
                    
                    PowerMenu { Layout.alignment: Qt.AlignHCenter }
                }
            }

            // Shortcuts
            GlobalShortcut {
                name: "vol_up"
                onPressed: audioModule.setVolume(audioModule.internalVolume + 0.05)
            }

            GlobalShortcut {
                name: "vol_down"
                onPressed: audioModule.setVolume(audioModule.internalVolume - 0.05)
            }

            GlobalShortcut {
                name: "vol_mute"
                onPressed: audioModule.toggleMute()
            }
        }
    }
}