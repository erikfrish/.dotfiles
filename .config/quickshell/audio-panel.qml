import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    focusable: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dotfiles-audio-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var outputDevices: {
        var result = []
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]
            if (node && node.audio && node.isSink && !node.isStream)
                result.push(node)
        }
        return result
    }
    readonly property var inputDevices: {
        var result = []
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]
            if (node && node.audio && !node.isSink && !node.isStream)
                result.push(node)
        }
        return result
    }
    readonly property var playbackStreams: {
        var result = []
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]
            if (node && node.audio && node.isSink && node.isStream && node.name !== "quickshell")
                result.push(node)
        }
        return result
    }

    function nodeLabel(node) {
        if (!node)
            return "Unavailable"
        return node.description || node.nickname || node.name || "Unnamed device"
    }

    function appLabel(node) {
        if (!node)
            return "Unknown application"
        var props = node.properties || {}
        return props["application.name"] || props["media.name"] || node.description || node.name || "Unknown application"
    }

    function isDefault(node, current) {
        return !!node && !!current && node.id === current.id
    }

    function refreshWaybar() {
        if (!waybarRefresh.running)
            waybarRefresh.running = true
    }

    function toggleMute(node) {
        if (node && node.audio) {
            node.audio.muted = !node.audio.muted
            if (node.isSink && !node.isStream)
                refreshWaybar()
        }
    }

    function setVolume(node, value) {
        if (node && node.audio) {
            node.audio.volume = Math.max(0, Math.min(1.5, value))
            if (node.isSink && !node.isStream)
                refreshWaybar()
        }
    }

    Process {
        id: waybarRefresh
        command: ["pkill", "--signal", "RTMIN+8", "waybar"]
    }

    PwObjectTracker {
        objects: root.nodes
    }


    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: Qt.quit()
    }

    Rectangle {
        id: panel
        z: 1
        width: 448
        height: 720
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 40
            rightMargin: 150
        }
        radius: 14
        color: "#000000"
        border.color: "#292929"
        border.width: 1
        clip: true
        focus: true

        Keys.onEscapePressed: Qt.quit()

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: mouse.accepted = true
        }

        ScrollView {
            id: scroll
            anchors.fill: parent
            anchors.margins: 18
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                id: content
                width: scroll.availableWidth
                spacing: 18

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 46
                        height: 46
                        radius: 23
                        color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && !Pipewire.defaultAudioSink.audio.muted ? "#8d8d8d" : "#242424"

                        Text {
                            anchors.centerIn: parent
                            text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && !Pipewire.defaultAudioSink.audio.muted ? "" : ""
                            color: "#000000"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 21
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: toggleMute(Pipewire.defaultAudioSink)
                        }
                    }

                    Column {
                        width: parent.width - 58
                        spacing: 3

                        Text {
                            width: parent.width
                            text: "Audio"
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 16
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: nodeLabel(Pipewire.defaultAudioSink)
                            color: "#a0a0a0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#242424"
                }

                Text {
                    text: "Output"
                    color: "#8d8d8d"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 12
                }
                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        width: 22
                        text: ""
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        id: outputSlider
                        width: parent.width - 94
                        from: 0
                        to: 1.5
                        stepSize: 0.01
                        value: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
                        onMoved: setVolume(Pipewire.defaultAudioSink, value)
                    }

                    Text {
                        width: 52
                        text: Math.round(outputSlider.value * 100) + "%"
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.outputDevices

                        delegate: Rectangle {
                            required property var modelData
                            width: parent ? parent.width : 0
                            height: 38
                            radius: 7
                            color: isDefault(modelData, Pipewire.defaultAudioSink) ? "#242424" : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: isDefault(modelData, Pipewire.defaultAudioSink) ? "●" : "○"
                                    color: isDefault(modelData, Pipewire.defaultAudioSink) ? "#ffffff" : "#666666"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - 24
                                    text: nodeLabel(modelData)
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Pipewire.preferredDefaultAudioSink = modelData
                                    refreshWaybar()
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    visible: root.inputDevices.length > 0 || !!Pipewire.defaultAudioSource

                    Text {
                        text: "Input"
                        color: "#8d8d8d"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    Row {
                        width: parent.width

                        Text {
                            width: 22
                            text: ""
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Slider {
                            id: inputSlider
                            width: parent.width - 94
                            from: 0
                            to: 1.5
                            stepSize: 0.01
                            value: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? Pipewire.defaultAudioSource.audio.volume : 0
                            onMoved: setVolume(Pipewire.defaultAudioSource, value)
                        }

                        Text {
                            width: 52
                            text: Math.round(inputSlider.value * 100) + "%"
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignRight
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.inputDevices

                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 38
                                radius: 7
                                color: isDefault(modelData, Pipewire.defaultAudioSource) ? "#242424" : "transparent"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: isDefault(modelData, Pipewire.defaultAudioSource) ? "●" : "○"
                                        color: isDefault(modelData, Pipewire.defaultAudioSource) ? "#ffffff" : "#666666"
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        width: parent.width - 24
                                        text: nodeLabel(modelData)
                                        color: "#ffffff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    visible: root.playbackStreams.length > 0

                    Text {
                        text: "Applications"
                        color: "#8d8d8d"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.playbackStreams

                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 48
                                radius: 7
                                color: "transparent"

                                Column {
                                    anchors.left: parent.left
                                    anchors.right: streamSlider.left
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: appLabel(modelData)
                                        color: "#ffffff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.audio && modelData.audio.muted ? "muted" : "playback"
                                        color: "#777777"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                    }
                                }

                                Slider {
                                    id: streamSlider
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 112
                                    from: 0
                                    to: 1.5
                                    stepSize: 0.01
                                    value: modelData.audio ? modelData.audio.volume : 0
                                    onMoved: setVolume(modelData, value)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    onClicked: toggleMute(modelData)
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Pipewire.ready ? "Click outside or press Escape to close" : "Connecting to PipeWire…"
                    color: "#666666"
                    horizontalAlignment: Text.AlignRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        }
    }
}
