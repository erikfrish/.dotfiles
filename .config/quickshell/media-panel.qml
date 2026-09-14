import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "PopupBase.qml"

PopupBase {
    id: root
    panelTitle: "Media"
    panelSubtitle: currentTitle || "No active player"
    panelIcon: "󰐊"

    property string playersText: ""
    property string metadataText: ""
    readonly property var players: parsePlayers(playersText)
    readonly property var metadata: parseMetadata(metadataText)
    readonly property string currentTitle: metadata.title || metadata.artist || ""

    function parsePlayers(text) {
        var result = []
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) if (lines[i].trim() !== "") result.push(lines[i].trim())
        return result
    }
    function parseMetadata(text) {
        var fields = text.trim().split("\t")
        return { status: fields[0] || "", title: fields[1] || "", artist: fields[2] || "", album: fields[3] || "", player: fields[4] || "" }
    }
    function refresh() {
        if (!playersProc.running) playersProc.running = true
        if (!metadataProc.running) metadataProc.running = true
    }
    function run(args) { action.command = args; action.running = true; refreshTimer.restart() }

    Process { id: playersProc; command: ["playerctl", "-l"]; stdout: StdioCollector { onStreamFinished: root.playersText = text } }
    Process { id: metadataProc; command: ["playerctl", "metadata", "--format", "{{status}}\t{{title}}\t{{artist}}\t{{album}}\t{{playerName}}"] ; stdout: StdioCollector { onStreamFinished: root.metadataText = text } }
    Process { id: action; command: [] }
    Timer { id: refreshTimer; interval: 700; repeat: false; onTriggered: root.refresh() }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    Column {
        width: parent.width
        spacing: 12

        Rectangle {
            width: parent.width
            height: 86
            radius: 8
            color: "#171717"
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4
                Text { width: parent.width; text: root.metadata.title || "Nothing playing"; color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight }
                Text { width: parent.width; text: root.metadata.artist || root.metadata.player || ""; color: "#999999"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; elide: Text.ElideRight }
                Text { width: parent.width; text: root.metadata.status || "Stopped"; color: "#666666"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            Button { text: ""; font.family: "Symbols Nerd Font"; onClicked: root.run(["playerctl", "previous"]) }
            Button { text: root.metadata.status === "Playing" ? "" : ""; font.family: "Symbols Nerd Font"; onClicked: root.run(["playerctl", "play-pause"]) }
            Button { text: ""; font.family: "Symbols Nerd Font"; onClicked: root.run(["playerctl", "next"]) }
        }

        Text { text: "Players"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12; topPadding: 8 }
        Repeater {
            model: root.players
            delegate: Rectangle {
                required property string modelData
                width: parent ? parent.width : 0
                height: 38
                radius: 7
                color: modelData === root.metadata.player ? "#242424" : "transparent"
                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: "#ffffff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: root.run(["playerctl", "--player", modelData, "play-pause"]) }
            }
        }
        Text { visible: root.players.length === 0; text: "No MPRIS players"; color: "#666666"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
    }
}
