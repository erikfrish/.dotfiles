import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "PopupBase.qml"

PopupBase {
    id: root
    panelTitle: "Power"
    panelSubtitle: batteryState
    panelIcon: "󰐥"

    property string batteryText: ""
    property string profileText: ""
    readonly property string batteryPercent: parseField(batteryText, "percentage")
    readonly property string batteryState: parseField(batteryText, "state") || "Battery"
    readonly property string batteryTime: parseField(batteryText, "time to empty") || parseField(batteryText, "time to full")
    readonly property string profile: profileText.trim()

    function parseField(text, field) {
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].toLowerCase().indexOf(field.toLowerCase() + ":") >= 0)
                return lines[i].split(":").slice(1).join(":").trim()
        }
        return ""
    }
    function refresh() {
        if (!battery.running) battery.running = true
        if (!profiles.running) profiles.running = true
    }
    function run(args) { action.command = args; action.running = true; refreshTimer.restart() }

    Process {
        id: battery
        command: ["upower", "-i", "/org/freedesktop/UPower/devices/DisplayDevice"]
        stdout: StdioCollector { onStreamFinished: root.batteryText = text }
    }
    Process {
        id: profiles
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.profileText = text }
    }
    Process { id: action; command: [] }
    Timer { id: refreshTimer; interval: 1200; repeat: false; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    Column {
        width: parent.width
        spacing: 12

        Row {
            width: parent.width
            spacing: 12
            Text { text: root.batteryPercent || "—"; color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 34 }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: root.batteryState; color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                Text { text: root.batteryTime; color: "#888888"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; visible: text !== "" }
            }
        }

        Text { text: "Power profile"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12 }
        Repeater {
            model: ["performance", "balanced", "power-saver"]
            delegate: Rectangle {
                required property string modelData
                width: parent ? parent.width : 0
                height: 40
                radius: 7
                color: root.profile === modelData ? "#242424" : "transparent"
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 10
                    Text { text: root.profile === modelData ? "●" : "○"; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData; color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: root.run(["powerprofilesctl", "set", modelData]) }
            }
        }

        Text { text: "Session"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12; topPadding: 8 }
        Row {
            width: parent.width
            spacing: 8
            Repeater {
                model: [
                    { label: "Lock", icon: "", command: ["loginctl", "lock-session"] },
                    { label: "Sleep", icon: "", command: ["systemctl", "suspend"] },
                    { label: "Logout", icon: "", command: ["niri", "msg", "action", "quit", "--skip-confirmation"] }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: (parent ? parent.width : 0) / 3 - 6
                    height: 52
                    radius: 8
                    color: "#171717"
                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Text { text: modelData.icon; color: "#ffffff"; font.family: "Symbols Nerd Font"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                        Text { text: modelData.label; color: "#a0a0a0"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.run(modelData.command) }
                }
            }
        }
    }
}
