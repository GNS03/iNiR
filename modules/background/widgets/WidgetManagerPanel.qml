pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    width: 280
    height: _wmCol.implicitHeight + 24

    readonly property bool _exampleInstalled: {
        if (!CustomWidgets.ready) return false;
        for (let i = 0; i < CustomWidgets.widgets.length; i++)
            if (CustomWidgets.widgets[i].id === "example-widget") return true;
        return false;
    }

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; propagateComposedEvents: false }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2
        border { width: 1; color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12) }
    }

    Column {
        id: _wmCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        // Header
        StyledText {
            text: Translation.tr("Widgets")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer2
        }

        // Built-in widgets
        Repeater {
            model: [
                { key: "weather", icon: "cloud", label: "Weather", defaultOn: true },
                { key: "clock", icon: "schedule", label: "Clock", defaultOn: true },
                { key: "mediaControls", icon: "album", label: "Media", defaultOn: true },
                { key: "visualizer", icon: "graphic_eq", label: "Visualizer", defaultOn: false },
                { key: "systemMonitor", icon: "monitor_heart", label: "System Monitor", defaultOn: false },
                { key: "battery", icon: "battery_full", label: "Battery", defaultOn: false }
            ]
            Item {
                id: builtinDelegate
                required property var modelData
                readonly property bool widgetEnabled: Config.options?.background?.widgets?.[modelData.key]?.enable ?? modelData.defaultOn
                width: _wmCol.width; height: 36
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    MaterialSymbol { text: builtinDelegate.modelData.icon; iconSize: 18; color: Appearance.colors.colOnLayer2; anchors.verticalCenter: parent.verticalCenter }
                    StyledText { text: builtinDelegate.modelData.label; color: Appearance.colors.colOnLayer2; font.pixelSize: Appearance.font.pixelSize.small; anchors.verticalCenter: parent.verticalCenter }
                }
                RippleButton {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 40; height: 28
                    buttonRadius: Appearance.rounding.small
                    toggled: builtinDelegate.widgetEnabled
                    colBackground: toggled ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.16) : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.06)
                    colBackgroundHover: toggled ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.24) : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)
                    downAction: () => Config.setNestedValue("background.widgets." + builtinDelegate.modelData.key + ".enable", !builtinDelegate.widgetEnabled)
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: parent.toggled ? "visibility" : "visibility_off"; iconSize: 16; color: parent.toggled ? Appearance.colors.colPrimary : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.5) }
                }
            }
        }

        // Separator
        Rectangle { width: parent.width; height: 1; color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.08) }

        // Custom widgets header + actions
        Item {
            width: parent.width; height: 28
            StyledText {
                text: Translation.tr("Custom")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.6)
                anchors.verticalCenter: parent.verticalCenter
            }
            Row {
                spacing: 2
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                RippleButton {
                    width: 26; height: 26; buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.08)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12)
                    downAction: () => CustomWidgets.reload()
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 14; color: Appearance.colors.colOnLayer2 }
                    StyledToolTip { text: Translation.tr("Reload") }
                }
                RippleButton {
                    width: 26; height: 26; buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.08)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12)
                    downAction: () => CustomWidgets.openWidgetDir("")
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: "folder_open"; iconSize: 14; color: Appearance.colors.colOnLayer2 }
                    StyledToolTip { text: Translation.tr("Open folder") }
                }
                RippleButton {
                    visible: !root._exampleInstalled
                    width: 26; height: 26; buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.08)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12)
                    downAction: () => { CustomWidgets.installExample(); CustomWidgets.reload() }
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: "download"; iconSize: 14; color: Appearance.colors.colOnLayer2 }
                    StyledToolTip { text: Translation.tr("Install example") }
                }
            }
        }

        // Custom widget list
        Repeater {
            model: CustomWidgets.ready ? CustomWidgets.widgets : []
            Item {
                id: customDelegate
                required property var modelData
                readonly property bool widgetEnabled: Config.options?.background?.widgets?.custom?.[modelData.id]?.enable ?? true
                width: _wmCol.width; height: 36
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    MaterialSymbol { text: customDelegate.modelData.icon || "widgets"; iconSize: 18; color: Appearance.colors.colOnLayer2; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        StyledText { text: customDelegate.modelData.name; color: Appearance.colors.colOnLayer2; font.pixelSize: Appearance.font.pixelSize.small }
                        StyledText {
                            visible: (customDelegate.modelData.author ?? "").length > 0
                            text: customDelegate.modelData.author ?? ""
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.5)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 2
                    RippleButton {
                        width: 26; height: 26; buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.08)
                        colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12)
                        downAction: () => CustomWidgets.openWidgetDir(customDelegate.modelData.id)
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "edit"; iconSize: 14; color: Appearance.colors.colOnLayer2 }
                        StyledToolTip { text: Translation.tr("Open in editor") }
                    }
                    RippleButton {
                        width: 40; height: 28
                        buttonRadius: Appearance.rounding.small
                        toggled: customDelegate.widgetEnabled
                        colBackground: toggled ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.16) : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.06)
                        colBackgroundHover: toggled ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.24) : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.12)
                        colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)
                        downAction: () => Config.setNestedValue("background.widgets.custom." + customDelegate.modelData.id + ".enable", !customDelegate.widgetEnabled)
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: parent.toggled ? "visibility" : "visibility_off"; iconSize: 16; color: parent.toggled ? Appearance.colors.colPrimary : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.5) }
                    }
                }
            }
        }

        // Empty state
        Item {
            visible: !CustomWidgets.ready || CustomWidgets.widgets.length === 0
            width: parent.width; height: 48
            Column {
                anchors.centerIn: parent
                spacing: 4
                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Translation.tr("No custom widgets"); color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.4); font.pixelSize: Appearance.font.pixelSize.small }
                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: "~/.config/inir/widgets/"; color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.3); font.pixelSize: Appearance.font.pixelSize.smaller }
            }
        }
    }
}
