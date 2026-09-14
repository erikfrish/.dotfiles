import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "PopupBase.qml"

PopupBase {
    id: root
    panelTitle: "Network"
    panelSubtitle: stateText
    panelIcon: ""

    property string stateText: "Loading…"
    property string radioText: ""
    property string wifiText: ""
    property string connectionsText: ""
    property string actionMessage: ""
    readonly property bool wifiEnabled: radioText.trim() === "enabled"
    readonly property var wifiRows: parseWifi(wifiText)
    readonly property var connectionRows: parseConnections(connectionsText)

    function parseWifi(text) {
        var rows = []
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var fields = lines[i].split(":")
            if (fields.length >= 4 && fields[1] !== "")
                rows.push({ inUse: fields[0] === "*", ssid: fields[1], signal: fields[2], security: fields[3] })
        }
        return rows
    }

    function parseConnections(text) {
        var rows = []
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/^(.*):(vpn|wireguard):(.*)$/)
            if (match)
                rows.push({ name: match[1], type: match[2], device: match[3] })
        }
        return rows
    }

    function refresh() {
        if (!snapshot.running) snapshot.running = true
        if (!wifi.running) wifi.running = true
    }

    function parseSnapshot(text) {
        var vpnLines = []
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("RADIO:") === 0)
                root.radioText = lines[i].slice(6)
            else if (lines[i].indexOf("STATE:") === 0)
                root.stateText = lines[i].slice(6)
            else if (lines[i].indexOf("VPN:") === 0)
                vpnLines.push(lines[i].slice(4))
        }
        root.connectionsText = vpnLines.join("\n")
    }

    function run(args) {
        actionMessage = ""
        action.command = args
        action.running = true
        refreshTimer.restart()
    }

    function connectWifi(ssid) {
        var args = ["nmcli", "device", "wifi", "connect", ssid]
        if (wifiPassword.text.trim() !== "")
            args.push("password", wifiPassword.text)
        root.run(args)
    }

    Process {
        id: snapshot
        command: ["bash", "-lc", "printf 'RADIO:%s\\n' \"$(nmcli radio wifi)\"; printf 'STATE:%s\\n' \"$(nmcli -t -f STATE,CONNECTIVITY general)\"; nmcli -t -f NAME,TYPE,DEVICE connection show | awk -F: '$2 == \"vpn\" || $2 == \"wireguard\" { print \"VPN:\" $0 }'"]
        stdout: StdioCollector { onStreamFinished: root.parseSnapshot(text) }
    }
    Process {
        id: wifi
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector { onStreamFinished: root.wifiText = text }
    }
    Process {
        id: action
        command: []
        stderr: StdioCollector { onStreamFinished: { if (text.trim() !== "") root.actionMessage = text.trim() } }
    }
    Timer { id: refreshTimer; interval: 800; repeat: false; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    Column {
        width: parent.width
        spacing: 10
        Rectangle {
            width: parent.width
            height: 48
            radius: 8
            color: "#171717"
            Item {
                anchors.fill: parent
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                    color: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Button { text: "Refresh"; onClicked: root.refresh() }
                    Switch { checked: root.wifiEnabled; onToggled: root.run(["nmcli", "radio", "wifi", checked ? "on" : "off"]) }
                }
            }
        }
        TextField {
            id: wifiPassword
            width: parent.width
            placeholderText: "Password for secured Wi-Fi (optional)"
            echoMode: TextInput.Password
            color: "#ffffff"
        }
        Text { visible: root.actionMessage !== ""; text: root.actionMessage; width: parent.width; color: "#ffb4a2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; wrapMode: Text.Wrap }


        Text { text: "Wi-Fi"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12 }
        Repeater {
            model: root.wifiRows
            delegate: Rectangle {
                required property var modelData
                width: parent ? parent.width : 0
                height: 40
                radius: 7
                color: modelData.inUse ? "#242424" : "transparent"
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    Text { text: modelData.inUse ? "●" : "○"; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: parent.width - 135; text: modelData.ssid; color: "#ffffff"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 42; text: modelData.signal + "%"; color: "#a0a0a0"; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 54; text: modelData.security || "open"; color: "#777777"; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: root.connectWifi(modelData.ssid) }
            }
        }
        Text { visible: root.wifiRows.length === 0; text: "No Wi-Fi networks found"; color: "#666666"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }

        Text { text: "VPN profiles"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12; topPadding: 8 }
        Repeater {
            model: root.connectionRows
            delegate: Rectangle {
                required property var modelData
                width: parent ? parent.width : 0
                height: 38
                radius: 7
                color: modelData.device !== "--" ? "#242424" : "transparent"
                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 20; text: modelData.name; color: "#ffffff"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: root.run(["nmcli", "connection", "up", modelData.name]) }
            }
        }
        Text { text: "Click a network or VPN to connect"; color: "#666666"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; horizontalAlignment: Text.AlignRight; width: parent.width }
    }
}
