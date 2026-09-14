import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "PopupBase.qml"

PopupBase {
    id: root
    panelTitle: "Display"
    panelSubtitle: displayText
    panelIcon: "󰍹"

    property string displayText: "Loading…"
    property string outputsText: ""
    property int brightnessValue: 0

    function refresh() {
        if (!brightness.running) brightness.running = true
        if (!outputs.running) outputs.running = true
    }
    function run(args) { action.command = args; action.running = true; refreshTimer.restart() }
    function parseBrightness(text) {
        try {
            var data = JSON.parse(text)
            root.displayText = data.text || (Math.round(data.percentage) + "%")
            return Number(data.percentage || 0)
        } catch (error) {
            root.displayText = "Unavailable"
            return 0
        }
    }

    Process {
        id: brightness
        command: ["bash", "-lc", "$HOME/.config/desktop/scripts/brightness --json"]
        stdout: StdioCollector { onStreamFinished: root.brightnessValue = root.parseBrightness(text) }
    }
    Process { id: outputs; command: ["niri", "msg", "outputs"]; stdout: StdioCollector { onStreamFinished: root.outputsText = text } }
    Process { id: action; command: [] }
    Timer { id: refreshTimer; interval: 900; repeat: false; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    Column {
        width: parent.width
        spacing: 12

        Text { text: "Brightness"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12 }
        Row {
            width: parent.width
            spacing: 10
            Text { text: "󰃠"; color: "#ffffff"; font.family: "Symbols Nerd Font"; font.pixelSize: 16; width: 22; anchors.verticalCenter: parent.verticalCenter }
            Slider {
                id: slider
                width: parent.width - 92
                from: 1
                to: 100
                stepSize: 1
                value: root.brightnessValue || 1
                onMoved: root.run(["bash", "-lc", "$HOME/.config/desktop/scripts/brightness --set " + Math.round(value)])
            }
            Text { width: 52; text: Math.round(slider.value) + "%"; color: "#ffffff"; horizontalAlignment: Text.AlignRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }

        Text { text: "Outputs"; color: "#8d8d8d"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 12; topPadding: 8 }
        Rectangle {
            width: parent.width
            height: 220
            radius: 8
            color: "#111111"
            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                Text { width: parent.width; text: root.outputsText || "No output information"; color: "#a0a0a0"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; wrapMode: Text.Wrap }
            }
        }
        Row {
            width: parent.width
            spacing: 8
            Button { text: "Night light"; onClicked: root.run(["bash", "-lc", "if systemctl --user is-active --quiet gammastep; then systemctl --user stop gammastep; else systemctl --user start gammastep; fi"]) }
            Button { text: "Reset 100%"; onClicked: root.run(["bash", "-lc", "$HOME/.config/desktop/scripts/brightness --set 100"]) }
        }
    }
}
