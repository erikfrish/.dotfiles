import QtQuick
import QtQuick.Controls
import "PopupBase.qml"

PopupBase {
    id: root
    panelTitle: "Calendar"
    panelSubtitle: monthNames[month] + " " + year
    panelIcon: ""
    panelCentered: true
    panelHeight: 500

    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var weekDays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property var cells: buildCells()

    function buildCells() {
        var first = new Date(year, month, 1)
        var offset = (first.getDay() + 6) % 7
        var days = new Date(year, month + 1, 0).getDate()
        var result = []
        for (var i = 0; i < 42; i++) {
            var day = i - offset + 1
            result.push({ day: day, current: day > 0 && day <= days })
        }
        return result
    }
    function previousMonth() {
        if (month === 0) { month = 11; year-- } else month--
    }
    function nextMonth() {
        if (month === 11) { month = 0; year++ } else month++
    }
    function isToday(day) {
        var now = new Date()
        return day === now.getDate() && month === now.getMonth() && year === now.getFullYear()
    }

    Column {
        width: parent.width
        spacing: 12

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Button { width: 34; height: 34; text: "‹"; onClicked: root.previousMonth() }
            Text { width: parent.width - 84; height: 34; text: root.monthNames[root.month] + " " + root.year; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 14 }
            Button { width: 34; height: 34; text: "›"; onClicked: root.nextMonth() }
        }

        Grid {
            width: parent.width
            columns: 7
            rowSpacing: 4
            columnSpacing: 4
            Repeater {
                model: root.weekDays
                delegate: Text { required property string modelData; width: (parent.width - 24) / 7; height: 24; text: modelData; color: "#777777"; horizontalAlignment: Text.AlignHCenter; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
            }
            Repeater {
                model: root.cells
                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 24) / 7
                    height: 42
                    radius: 7
                    color: root.isToday(modelData.day) && modelData.current ? "#8d8d8d" : "transparent"
                    Text { anchors.centerIn: parent; text: modelData.current ? modelData.day : ""; color: root.isToday(modelData.day) && modelData.current ? "#000000" : (modelData.current ? "#ffffff" : "#333333"); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                }
            }
        }

        Text { width: parent.width; text: "ISO week numbers can be read from the system calendar"; color: "#666666"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; horizontalAlignment: Text.AlignRight; wrapMode: Text.Wrap }
    }
}
