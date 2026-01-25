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
            
            anchors {
                top: true
                left: true
                right: true
            }
            
            implicitHeight: 60 
            
            color: "transparent"
            
            mask: Region { item: barBackground }

            Rectangle {
                id: barBackground
                
                anchors.top: parent.top
                anchors.topMargin: 8
                
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                
                height: 44
                
                radius: 12
                
                color: "#cc1a2847"
                border.width: 2
                border.color: "#4Dff6b9d"
                
                RowLayout {
                    id: mainLayout
                    
                    anchors.centerIn: parent 
                    
                    spacing: 12
                    
                    Launcher { Layout.alignment: Qt.AlignVCenter }
                    
                    Workspaces {
                        screen: panel.modelData
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Clock { Layout.alignment: Qt.AlignVCenter }
                    
                    Audio { id: audioModule 
                    Layout.alignment: Qt.AlignVCenter 
                    }
                    
                    Battery { Layout.alignment: Qt.AlignVCenter }
                    PowerMenu { Layout.alignment: Qt.AlignVCenter }
                }
            }

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
