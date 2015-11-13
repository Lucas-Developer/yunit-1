/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Gestures 0.1

TutorialPage {
    id: root

    // This page is a bit fragile.  It relies on knowing how the app beneath
    // the shell will react to a drag.  What we do is put a monitor-only DDA
    // at the bottom of the page (so that we know when the drag is finished)
    // and pass the events on through to the app.  Thus, it sees the drag and
    // brings its bottom edge up.
    //
    // Unfortunately, each app is on its own when implementing the bottom edge
    // drag.  Most share copied-and-pasted code right now, but they will
    // eventually consolidate on a version of DirectionalDragArea that will
    // land in the SDK (making our guessing job easier).  Though, also in the
    // future, this whole bottom tutorial component will also land in the SDK,
    // rending our version here obsolete.
    //
    // Anyway, for the moment, we base our guesses on the copied-and-pasted
    // code used in several of the core apps and only bring this component
    // up if we are in those core apps.

    readonly property real dragAreaHeight: units.gu(3) // based on PageWithBottomEdge.qml
    readonly property real targetDistance: height * 0.2 + dragAreaHeight // based on PageWithBottomEdge.qml

    opacityOverride: dragArea.dragging ? 1 - (-dragArea.distance / targetDistance) : 1

    mouseArea {
        anchors.bottomMargin: root.dragAreaHeight
    }

    background {
        sourceSize.height: 1080
        sourceSize.width: 1916
        source: Qt.resolvedUrl("graphics/background2.png")
        rotation: 180
    }

    arrow {
        anchors.bottom: root.bottom
        anchors.bottomMargin: units.gu(4)
        anchors.horizontalCenter: root.horizontalCenter
        rotation: -90
    }

    label {
        text: i18n.tr("Swipe from the bottom edge to manage the app")
        anchors.bottom: arrow.top
        anchors.bottomMargin: units.gu(3)
        anchors.horizontalCenter: root.horizontalCenter
        anchors.horizontalCenterOffset: (label.width - label.contentWidth) / 2
        width: root.width - units.gu(8)
    }

    // Watches drag events but does not intercept them, so that the app beneath
    // will still drag the bottom edge up.
    DirectionalDragArea {
        id: dragArea
        monitorOnly: true
        direction: Direction.Upwards
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.dragAreaHeight

        // Because apps currently don't use DDA, and DDA will stop a gesture if
        // horizontal motion is detected.  But our apps wont'.  So turn off
        // that gesture cleverness on our part, it will only get us out of sync.
        immediateRecognition: true
    }
}
