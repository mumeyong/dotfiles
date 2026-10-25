// mumeyong SDDM greeter, mirroring the mumeyong shell lockscreen
// Adapted from Ambxst by Axenide (AGPL-3.0), modules/lockscreen/LockScreen.qml.
// Wallpaper, blur and palette are kept in sync by ~/.local/bin/sddm-wallpaper-sync
// via theme.conf.user.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1200
    color: "black"

    readonly property int animDuration: 300
    readonly property real roundness: Number(config.Roundness || 16)

    readonly property color cPrimaryFixed: config.PrimaryFixed || "#e0e0ff"
    readonly property color cPrimaryFixedDim: config.PrimaryFixedDim || "#bfc2ff"
    readonly property color cBg: config.Bg || "#0d0d11"
    readonly property color cSurface: config.Surface || "#131318"
    readonly property color cItem: config.OverBackground || "#e4e1e9"
    readonly property color cError: config.Error || "#ffb4ab"
    readonly property color cOverError: config.OverError || "#690005"
    readonly property color cShadow: config.Shadow || "#000000"

    // Phosphor-Bold glyphs (same as qs.modules.theme.Icons)
    readonly property string iconUser: ""
    readonly property string iconCircleNotch: ""
    readonly property string iconSuspend: ""
    readonly property string iconReboot: ""
    readonly property string iconShutdown: ""

    property bool startAnim: false
    property bool authenticating: false
    property string userName: userModel.lastUser || (userNames.count > 0 ? userNames.itemAt(0).name : "")
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    function pillRadius(h) {
        return roundness > 0 ? (h / 2) * (roundness / 16) : 0;
    }

    function cornerRadius(offset) {
        return roundness > 0 ? Math.max(roundness + offset, 0) : 0;
    }

    // Fallback for userName when SDDM has no last user recorded
    Repeater {
        id: userNames
        model: userModel
        delegate: Item {
            required property string name
            visible: false
        }
    }

    FontLoader { id: gothic; source: "fonts/LeagueGothic-Regular.otf" }
    FontLoader { id: phosphor; source: "fonts/Phosphor-Bold.ttf" }
    FontLoader { id: inter; source: "fonts/Inter-Regular.ttf" }
    FontLoader { id: interMedium; source: "fonts/Inter-Medium.ttf" }

    component ClockShadow: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 2
        shadowBlur: 0.5
        shadowColor: root.cShadow
        shadowOpacity: 1
    }

    // Wallpaper: sharp image crossfades into the pre-blurred copy while zooming
    Item {
        id: wallpaper
        anchors.fill: parent

        property real zoomScale: root.startAnim ? 1.25 : 1.0
        transform: Scale {
            origin.x: wallpaper.width / 2
            origin.y: wallpaper.height / 2
            xScale: wallpaper.zoomScale
            yScale: wallpaper.zoomScale
        }

        Behavior on zoomScale {
            NumberAnimation {
                duration: root.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Image {
            anchors.fill: parent
            source: config.Background ? "file://" + config.Background : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            smooth: true
        }

        Image {
            anchors.fill: parent
            source: config.BackgroundBlur ? "file://" + config.BackgroundBlur : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            smooth: true
            opacity: root.startAnim ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.animDuration * 2
                    easing.type: Easing.OutQuint
                }
            }
        }
    }

    // Overlay for dimming
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.startAnim ? 0.25 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.animDuration * 2
                easing.type: Easing.OutQuint
            }
        }
    }

    // Clock (center)
    Item {
        id: clockContainer
        anchors.centerIn: parent
        width: clockRow.width
        height: hoursText.height + (hoursText.height * 0.5)

        property date currentTime: new Date()
        readonly property bool use12h: config.Use12h === "true"

        Row {
            id: clockRow
            anchors.top: parent.top

            Text {
                id: hoursText
                text: clockContainer.use12h ? (clockContainer.currentTime.getHours() % 12 || 12).toString() : Qt.formatTime(clockContainer.currentTime, "hh")
                font.family: gothic.name
                font.pixelSize: 240
                color: root.cPrimaryFixed
                antialiasing: true
                opacity: root.startAnim ? 1 : 0

                property real slideOffset: root.startAnim ? 0 : -150
                transform: Translate { y: hoursText.slideOffset }

                layer.enabled: true
                layer.effect: ClockShadow {}

                Behavior on opacity {
                    NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
                }
                Behavior on slideOffset {
                    NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
                }
            }

            Text {
                id: minutesText
                text: Qt.formatTime(clockContainer.currentTime, "mm")
                font.family: gothic.name
                font.pixelSize: 240
                color: root.cPrimaryFixedDim
                antialiasing: true
                anchors.top: hoursText.top
                anchors.topMargin: hoursText.height * 0.5
                opacity: root.startAnim ? 1 : 0

                property real slideOffset: root.startAnim ? 0 : 150
                transform: Translate { y: minutesText.slideOffset }

                layer.enabled: true
                layer.effect: ClockShadow {}

                Behavior on opacity {
                    NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
                }
                Behavior on slideOffset {
                    NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
                }
            }

            Text {
                id: amPmText
                text: clockContainer.use12h ? Qt.formatTime(clockContainer.currentTime, "ap").toLowerCase() : ""
                font.family: gothic.name
                font.pixelSize: 100
                color: hoursText.color
                antialiasing: true
                anchors.top: hoursText.top
                anchors.topMargin: hoursText.height * 0.35
                visible: clockContainer.use12h
                opacity: root.startAnim ? 1 : 0

                property real slideOffset: root.startAnim ? 0 : -150
                transform: Translate { y: amPmText.slideOffset }

                layer.enabled: true
                layer.effect: ClockShadow {}

                Behavior on opacity {
                    NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
                }
                Behavior on slideOffset {
                    NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockContainer.currentTime = new Date()
        }
    }

    // Password input container (slides up from the bottom)
    Item {
        id: passwordContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.startAnim ? 32 : -80
        width: 350
        height: 96

        opacity: root.startAnim ? 1 : 0
        scale: root.startAnim ? 1 : 0.92

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        Rectangle {
            id: passwordInputBox
            anchors.centerIn: parent
            width: parent.width
            height: 96
            color: root.cBg
            radius: root.pillRadius(height)

            property real shakeOffset: 0
            property bool showError: false

            transform: Translate { x: passwordInputBox.shakeOffset }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 24
                spacing: 12

                // Avatar (64x64)
                Item {
                    id: avatarContainer
                    width: 64
                    height: 64
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: userAvatar
                        anchors.fill: parent
                        source: config.Face ? "file://" + config.Face : ""
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: userAvatar.width
                                    height: userAvatar.height
                                    radius: root.pillRadius(height)
                                }
                            }
                        }
                    }

                    // Fallback icon if image not found
                    Rectangle {
                        anchors.fill: parent
                        radius: root.pillRadius(height)
                        color: root.cSurface
                        visible: userAvatar.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: root.iconUser
                            font.family: phosphor.name
                            font.pixelSize: 32
                            color: root.cItem
                        }
                    }
                }

                // Password field
                Rectangle {
                    id: passwordFieldBg
                    width: parent.width - avatarContainer.width - parent.spacing
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter
                    color: passwordInputBox.showError ? root.cError : root.cSurface
                    radius: root.pillRadius(height)

                    readonly property color item: passwordInputBox.showError ? root.cOverError : root.cItem

                    Behavior on color {
                        ColorAnimation { duration: root.animDuration; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 32
                        spacing: 8

                        // User icon / Spinner
                        Text {
                            id: userIcon
                            text: root.authenticating ? root.iconCircleNotch : root.iconUser
                            font.family: phosphor.name
                            font.pixelSize: 24
                            color: passwordFieldBg.item
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color {
                                ColorAnimation { duration: root.animDuration; easing.type: Easing.OutCubic }
                            }

                            Timer {
                                interval: 100
                                repeat: true
                                running: root.authenticating
                                onTriggered: userIcon.rotation = (userIcon.rotation + 45) % 360
                            }

                            onTextChanged: {
                                if (userIcon.text === root.iconUser)
                                    userIcon.rotation = 0;
                            }
                        }

                        TextField {
                            id: passwordInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: keyboard.capsLock ? "Caps Lock is on" : root.userName
                            placeholderTextColor: Qt.rgba(passwordFieldBg.item.r, passwordFieldBg.item.g, passwordFieldBg.item.b, 0.5)
                            font.family: inter.name
                            font.pixelSize: 14
                            color: passwordFieldBg.item
                            selectionColor: root.cPrimaryFixedDim
                            selectedTextColor: root.cBg
                            background: null
                            echoMode: TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter
                            enabled: !root.authenticating
                            focus: true

                            Behavior on color {
                                ColorAnimation { duration: root.animDuration; easing.type: Easing.OutCubic }
                            }

                            Keys.onEscapePressed: passwordInput.text = ""

                            onAccepted: {
                                if (text === "")
                                    return;
                                root.authenticating = true;
                                sddm.login(root.userName, text, root.sessionIndex);
                            }
                        }
                    }
                }
            }

            SequentialAnimation {
                id: wrongPasswordAnim
                ScriptAction { script: passwordInputBox.showError = true }
                NumberAnimation { target: passwordInputBox; property: "shakeOffset"; to: 10; duration: 50; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordInputBox; property: "shakeOffset"; to: -10; duration: 100; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordInputBox; property: "shakeOffset"; to: 10; duration: 100; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordInputBox; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.InOutQuad }
                PauseAnimation { duration: 400 }
                ScriptAction {
                    script: {
                        passwordInput.text = "";
                        root.authenticating = false;
                        passwordInputBox.showError = false;
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    // Session + power controls (slide in from the right)
    Rectangle {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: root.startAnim ? 32 : -(width + 64)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32 + (96 - height) / 2
        height: 48
        width: controlsRow.implicitWidth + 16
        radius: root.pillRadius(height)
        color: root.cBg
        opacity: root.startAnim ? 1 : 0

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutExpo }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.animDuration * 2; easing.type: Easing.OutQuad }
        }

        // Exposes session names; sessionModel has no direct name lookup
        Repeater {
            id: sessionNames
            model: sessionModel
            delegate: Item {
                required property string name
                visible: false
            }
        }

        Row {
            id: controlsRow
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                id: sessionButton
                height: 36
                width: sessionLabel.implicitWidth + 28
                radius: root.pillRadius(height)
                color: sessionMouse.containsMouse ? root.cSurface : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                visible: sessionNames.count > 0

                Text {
                    id: sessionLabel
                    anchors.centerIn: parent
                    text: sessionNames.count > 0 && sessionNames.itemAt(root.sessionIndex) ? sessionNames.itemAt(root.sessionIndex).name : ""
                    font.family: interMedium.name
                    font.pixelSize: 13
                    color: root.cItem
                    opacity: sessionMouse.containsMouse ? 1 : 0.7
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: sessionNames.count > 1
                    onClicked: {
                        root.sessionIndex = (root.sessionIndex + 1) % sessionNames.count;
                        passwordInput.forceActiveFocus();
                    }
                }
            }

            Repeater {
                model: [
                    { icon: root.iconSuspend, show: sddm.canSuspend, act: () => sddm.suspend() },
                    { icon: root.iconReboot, show: sddm.canReboot, act: () => sddm.reboot() },
                    { icon: root.iconShutdown, show: sddm.canPowerOff, act: () => sddm.powerOff() }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: 36
                    height: 36
                    radius: root.pillRadius(height)
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    visible: modelData.show
                    color: powerMouse.containsMouse ? root.cSurface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: phosphor.name
                        font.pixelSize: 18
                        color: powerMouse.containsMouse ? root.cPrimaryFixed : root.cItem
                        opacity: powerMouse.containsMouse ? 1 : 0.7
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.act()
                    }
                }
            }
        }
    }

    // Screen corners
    Repeater {
        model: 4
        delegate: Canvas {
            required property int index
            readonly property int r: root.cornerRadius(4)
            width: r
            height: r
            x: index % 2 === 0 ? 0 : root.width - r
            y: index < 2 ? 0 : root.height - r
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                switch (index) {
                case 0: ctx.arc(r, r, r, Math.PI, 3 * Math.PI / 2); ctx.lineTo(0, 0); break;
                case 1: ctx.arc(0, r, r, 3 * Math.PI / 2, 2 * Math.PI); ctx.lineTo(r, 0); break;
                case 2: ctx.arc(r, 0, r, Math.PI / 2, Math.PI); ctx.lineTo(0, r); break;
                case 3: ctx.arc(0, 0, r, 0, Math.PI / 2); ctx.lineTo(r, r); break;
                }
                ctx.closePath();
                ctx.fillStyle = "#000000";
                ctx.fill();
            }
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            wrongPasswordAnim.start();
        }

        function onLoginSucceeded() {
            root.startAnim = false;
        }
    }

    Component.onCompleted: {
        startAnim = true;
        passwordInput.forceActiveFocus();
    }
}
