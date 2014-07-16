/*
 * Copyright (C) 2014 Canonical, Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import "../Components"

Item {
    id: root

    // TODO Search ?

    property real progress: 0
    property var scope: null
    property var dashItemEater: {
        if (tabBar.currentTab == 0 && middleItems.count > 0) {
            var loaderItem = middleItems.itemAt(0).item;
            return loaderItem && loaderItem.currentItem ? loaderItem.currentItem : null;
        }
        return null;
    }
    property int currentIndex: 0
    property real scopeScale: 1
    property real overrideOpacity: -1
    property QtObject scopeStyle: QtObject {
        property string headerLogo: ""
        property color foreground: "white"
        property color background: "transparent"
    }
    property size allCardSize: {
        if (middleItems.count > 1) {
            var loaderItem = middleItems.itemAt(1).item;
            if (loaderItem) {
                var cardTool = loaderItem.cardTool;
                return Qt.size(cardTool.cardWidth, cardTool.cardHeight);
            }
        }
        return Qt.size(0, 0);
    }

    signal done()
    signal favoriteSelected(int index)
    signal allFavoriteSelected(var scopeId)
    signal allSelected(var scopeId, var pos)

    function allScopeCardPosition(scopeId) {
        if (middleItems.count > 1) {
            var loaderItem = middleItems.itemAt(1).item;
            if (loaderItem) {
                var pos = loaderItem.scopeCardPosition(scopeId);
                return loaderItem.mapToItem(null, pos.x, pos.y);
            }
        }
    }

    onProgressChanged: {
        if (progress == 0) {
            tabBar.currentTab = 0;
        }
    }

    DashBackground {
        anchors.fill: parent
        Rectangle {
            color: "black"
            anchors.fill: parent
            opacity: 0.6
        }
    }

    Binding {
        target: root.scope
        property: "searchQuery"
        value: pageHeader.searchQuery
    }

    Item {
        id: scopesOverviewContent
        x: previewListView.open ? -width : 0
        Behavior on x { UbuntuNumberAnimation { } }
        width: parent.width
        height: parent.height

        Item {
            id: topBar
            width: parent.width
            height: pageHeader.height + (tabBar.opacity == 1 ? tabBar.height + tabBar.anchors.margins : 0)

            y: {
                if (root.progress < 0.5) {
                    return -height;
                } else {
                    return -height + (root.progress - 0.5) * height * 2;
                }
            }

            PageHeader {
                id: pageHeader
                width: parent.width
                clip: true
                title: i18n.tr("Manage Dash")
                scopeStyle: root.scopeStyle
                showSignatureLine: false
                searchEntryEnabled: true
                searchInProgress: root.scope ? root.scope.searchInProgress : false
            }

            ScopesOverviewTab {
                id: tabBar
                anchors {
                    left: parent.left
                    right: parent.right
                    top: pageHeader.bottom
                    margins: units.gu(2)
                }
                height: units.gu(4)

                enabled: opacity == 1
                opacity: !scope || scope.searchQuery == "" ? 1 : 0
                Behavior on opacity { }
            }
        }

        Repeater {
            id: middleItems
            model: scope && scope.searchQuery == "" ? scope.categories : null
            delegate: Loader {
                id: loader

                height: {
                    if (index == 0) {
                        return root.height;
                    } else {
                        return root.height - topBar.height - units.gu(2)
                    }
                }
                width: {
                    if (index == 0) {
                        return root.width / scopeScale
                    } else {
                        return root.width
                    }
                }
                x: {
                    if (index == 0) {
                        return (root.width - width) / 2;
                    } else {
                        return 0;
                    }
                }
                anchors {
                    bottom: scopesOverviewContent.bottom
                }

                scale: index == 0 ? scopeScale : 1

                opacity: {
                    if (root.overrideOpacity >= 0)
                        return root.overrideOpacity;

                    if (tabBar.currentTab != index)
                        return 0;

                    return index == 0 ? 1 : root.progress;
                }
                Behavior on opacity {
                    enabled: root.progress == 1
                    UbuntuNumberAnimation { }
                }
                enabled: opacity == 1

                clip: index == 1

                CardTool {
                    id: cardTool
                    objectName: "cardTool"
                    count: results.count
                    template: model.renderer
                    components: model.components
                    viewWidth: parent.width
                }

                source: {
                    if (index == 0 && categoryId == "favorites") return "ScopesOverviewFavorites.qml";
                    else if (index == 1 && categoryId == "all") return "ScopesOverviewAll.qml";
                    else return "";
                }

                onLoaded: {
                    item.model = Qt.binding(function() { return results })
                    item.cardTool = cardTool;
                    if (index == 0) {
                        item.scopeWidth = root.width;
                        item.scopeHeight = root.height;
                        item.appliedScale = Qt.binding(function() { return loader.scale })
                        item.currentIndex = Qt.binding(function() { return root.currentIndex })
                    } else if (index == 1) {
                        item.extraHeight = bottomBar.height;
                    }
                }

                Connections {
                    target: loader.item
                    onClicked: {
                        if (tabBar.currentTab == 0) {
                            root.favoriteSelected(index)
                        } else {
                            var favoriteScopesItem = middleItems.itemAt(0).item;
                            var scopeIndex = favoriteScopesItem.model.scopeIndex(itemModel.scopeId);
                            if (scopeIndex >= 0) {
                                root.allFavoriteSelected(itemModel.scopeId);
                            } else {
                                root.allSelected(itemModel.scopeId, item.mapToItem(null, 0, 0));
                            }
                        }
                    }
                    onPressAndHold: {
                        previewListView.model = target.model;
                        previewListView.currentIndex = -1
                        previewListView.currentIndex = index;
                        previewListView.open = true
                    }
                }
            }
        }

        GenericScopeView {
            id: searchResultsViewer
            anchors {
                top: topBar.bottom
                right: parent.right
                left: parent.left
                bottom: parent.bottom
            }
            scope: root.scope && root.scope.searchQuery != "" ? root.scope : null
            scopeStyle: root.scopeStyle
            enabled: opacity == 1
            showPageHeader: false
            clip: true
            opacity: searchResultsViewer.scope ? 1 : 0
            Behavior on opacity { UbuntuNumberAnimation {} }
        }

        Rectangle {
            id: bottomBar
            color: "black"
            height: units.gu(6)
            width: parent.width
            enabled: opacity == 0.4
            opacity: scope && scope.searchQuery == "" ? 0.4 : 0
            Behavior on opacity { UbuntuNumberAnimation {} }
            y: {
                if (root.progress < 0.5) {
                    return parent.height;
                } else {
                    return parent.height - (root.progress - 0.5) * height * 2;
                }
            }

            AbstractButton {
                width: Math.max(label.width + units.gu(2), units.gu(10))
                height: units.gu(4)
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    anchors.fill: parent
                    border.color: "white"
                    border.width: units.dp(1)
                    radius: units.dp(10)
                    color: parent.pressed ? "gray" : "transparent"
                }
                Label {
                    id: label
                    anchors.centerIn: parent
                    text: i18n.tr("Done")
                    color: parent.pressed ? "black" : "white"
                }
                onClicked: root.done();
            }
        }
    }

    PreviewListView {
        id: previewListView
        objectName: "scopesOverviewPreviewListView"
        scope: root.scope
        scopeStyle: root.scopeStyle
        visible: x != width
        width: parent.width
        height: parent.height
        anchors.left: scopesOverviewContent.right
    }
}
