import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    default property alias content: contentItem.data
    property string panelTitle: "Panel"
    property string panelSubtitle: ""
    property string panelIcon: ""
    property bool outsideClickEnabled: false
    property int panelWidth: 448
    property int panelHeight: 720
    property int panelRightMargin: 150
    property bool panelCentered: false
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    visible: true
    focusable: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dotfiles-" + panelTitle.toLowerCase()
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    function dismiss() { Qt.quit() }
    Timer { id: outsideClickTimer; interval: 400; running: true; repeat: false; onTriggered: root.outsideClickEnabled = true }
    MouseArea {
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.AllButtons
        onClicked: if (root.outsideClickEnabled) root.dismiss()
    }
    Rectangle {
        id: panel
        z: 1
        width: root.panelWidth
        height: root.panelHeight
        x: root.panelCentered ? (parent.width - width) / 2 : parent.width - width - root.panelRightMargin
        anchors {
            top: parent.top
            topMargin: 40
        }
        radius: 14
        color: "#000000"
        border.color: "#292929"
        border.width: 1
        clip: true
        focus: true

        Keys.onEscapePressed: root.dismiss()

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: mouse.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 46
                    height: 46
                    radius: 23
                    color: "#242424"
                    visible: root.panelIcon !== ""

                    Text {
                        anchors.centerIn: parent
                        text: root.panelIcon
                        color: "#ffffff"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 20
                    }
                }

                Column {
                    width: parent.width - (root.panelIcon !== "" ? 58 : 0)
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: root.panelTitle
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 16
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.panelSubtitle
                        color: "#a0a0a0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#242424" }

            Item {
                id: contentItem
                width: parent.width
                height: parent.height - 70
            }
        }
    }
}
