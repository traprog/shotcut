/*
 * Copyright (c) 2018-2021 Meltytech, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Shotcut.Controls 1.0 as Shotcut

Item {
    property string rectProperty: 'rect'
    property rect filterRect
    property string startValue: '_shotcut:startValue'
    property string middleValue: '_shotcut:middleValue'
    property string endValue: '_shotcut:endValue'

    function getPosition() {
        return Math.max(producer.position - (filter.in - producer.in), 0);
    }

    function setFilter(position) {
        if (position !== null) {
            filter.blockSignals = true;
            if (position <= 0 && filter.animateIn > 0)
                filter.set(startValue, filterRect);
            else if (position >= filter.duration - 1 && filter.animateOut > 0)
                filter.set(endValue, filterRect);
            else
                filter.set(middleValue, filterRect);
            filter.blockSignals = false;
        }
        if (filter.animateIn > 0 || filter.animateOut > 0) {
            filter.resetProperty(rectProperty);
            positionKeyframesButton.checked = false;
            if (filter.animateIn > 0) {
                filter.set(rectProperty, filter.getRect(startValue), 0);
                filter.set(rectProperty, filter.getRect(middleValue), filter.animateIn - 1);
            }
            if (filter.animateOut > 0) {
                filter.set(rectProperty, filter.getRect(middleValue), filter.duration - filter.animateOut);
                filter.set(rectProperty, filter.getRect(endValue), filter.duration - 1);
            }
        } else if (!positionKeyframesButton.checked) {
            filter.resetProperty(rectProperty);
            filter.set(rectProperty, filter.getRect(middleValue));
        } else if (position !== null) {
            filter.set(rectProperty, filterRect, position);
        }
    }

    function setControls() {
    }

    function setKeyframedControls() {
        var position = getPosition();
        var newValue = filter.getRect(rectProperty, position);
        if (filterRect !== newValue) {
            filterRect = newValue;
            rectX.value = filterRect.x.toFixed();
            rectY.value = filterRect.y.toFixed();
            rectW.value = filterRect.width.toFixed();
            rectH.value = filterRect.height.toFixed();
        }
        var enabled = position <= 0 || (position >= (filter.animateIn - 1) && position <= (filter.duration - filter.animateOut)) || position >= (filter.duration - 1);
        rectX.enabled = enabled;
        rectY.enabled = enabled;
        rectW.enabled = enabled;
        rectH.enabled = enabled;
        positionKeyframesButton.checked = filter.keyframeCount(rectProperty) > 0 && filter.animateIn <= 0 && filter.animateOut <= 0;
    }

    width: 350
    height: 180
    Component.onCompleted: {
        filter.blockSignals = true;
        filter.set(middleValue, Qt.rect(0, 0, profile.width, profile.height));
        filter.set(startValue, Qt.rect(0, 0, profile.width, profile.height));
        filter.set(endValue, Qt.rect(0, 0, profile.width, profile.height));
        if (filter.isNew) {
            // Add default preset.
            filter.set(rectProperty, '0%/0%:10%x10%');
            filter.savePreset(preset.parameters);
        } else {
            filter.set(middleValue, filter.getRect(rectProperty, filter.animateIn + 1));
            if (filter.animateIn > 0)
                filter.set(startValue, filter.getRect(rectProperty, 0));

            if (filter.animateOut > 0)
                filter.set(endValue, filter.getRect(rectProperty, filter.duration - 1));

        }
        filter.blockSignals = false;
        setControls();
        setKeyframedControls();
        if (filter.isNew)
            filter.set(rectProperty, filter.getRect(rectProperty));

    }

    GridLayout {
        columns: 6
        anchors.fill: parent
        anchors.margins: 8

        Label {
            text: qsTr('Preset')
            Layout.alignment: Qt.AlignRight
        }

        Shotcut.Preset {
            id: preset

            parameters: [rectProperty]
            Layout.columnSpan: 5
            onBeforePresetLoaded: {
                filter.resetProperty(rectProperty);
            }
            onPresetSelected: {
                setControls();
                setKeyframedControls();
                positionKeyframesButton.checked = filter.keyframeCount(rectProperty) > 0 && filter.animateIn <= 0 && filter.animateOut <= 0;
                filter.blockSignals = true;
                filter.set(middleValue, filter.getRect(rectProperty, filter.animateIn + 1));
                if (filter.animateIn > 0)
                    filter.set(startValue, filter.getRect(rectProperty, 0));

                if (filter.animateOut > 0)
                    filter.set(endValue, filter.getRect(rectProperty, filter.duration - 1));

                filter.blockSignals = false;
            }
        }

        Label {
            text: qsTr('Position')
            Layout.alignment: Qt.AlignRight
        }

        RowLayout {
            Layout.columnSpan: 3

            Shotcut.DoubleSpinBox {
                id: rectX

                Layout.minimumWidth: 100
                horizontalAlignment: Qt.AlignRight
                decimals: 0
                stepSize: 1
                from: -1e+09
                to: 1e+09
                onValueModified: {
                    if (filterRect.x !== value) {
                        filterRect.x = value;
                        setFilter(getPosition());
                    }
                }
            }

            Label {
                text: ','
                Layout.minimumWidth: 20
                horizontalAlignment: Qt.AlignHCenter
            }

            Shotcut.DoubleSpinBox {
                id: rectY

                Layout.minimumWidth: 100
                horizontalAlignment: Qt.AlignRight
                decimals: 0
                stepSize: 1
                from: -1e+09
                to: 1e+09
                onValueModified: {
                    if (filterRect.y !== value) {
                        filterRect.y = value;
                        setFilter(getPosition());
                    }
                }
            }

        }

        Shotcut.UndoButton {
            onClicked: {
                rectX.value = rectY.value = 0;
                filterRect.x = filterRect.y = 0;
                setFilter(getPosition());
            }
        }

        Shotcut.KeyframesButton {
            id: positionKeyframesButton

            Layout.rowSpan: 2
            onToggled: {
                if (checked) {
                    filter.clearSimpleAnimation(rectProperty);
                    filter.set(rectProperty, filterRect, getPosition());
                } else {
                    filter.resetProperty(rectProperty);
                    filter.set(rectProperty, filterRect);
                }
                checked = filter.keyframeCount(rectProperty) > 0 && filter.animateIn <= 0 && filter.animateOut <= 0;
            }
        }

        Label {
            text: qsTr('Size')
            Layout.alignment: Qt.AlignRight
        }

        RowLayout {
            Layout.columnSpan: 3

            Shotcut.DoubleSpinBox {
                id: rectW

                Layout.minimumWidth: 100
                horizontalAlignment: Qt.AlignRight
                decimals: 0
                stepSize: 1
                from: -1e+09
                to: 1e+09
                onValueModified: {
                    if (filterRect.width !== value) {
                        filterRect.width = value;
                        setFilter(getPosition());
                    }
                }
            }

            Label {
                text: 'x'
                Layout.minimumWidth: 20
                horizontalAlignment: Qt.AlignHCenter
            }

            Shotcut.DoubleSpinBox {
                id: rectH

                Layout.minimumWidth: 100
                horizontalAlignment: Qt.AlignRight
                decimals: 0
                stepSize: 1
                from: -1e+09
                to: 1e+09
                onValueModified: {
                    if (filterRect.height !== value) {
                        filterRect.height = value;
                        setFilter(getPosition());
                    }
                }
            }

        }

        Shotcut.UndoButton {
            onClicked: {
                rectW.value = profile.width / 10;
                rectH.value = profile.height / 10;
                filterRect.width = profile.width / 10;
                filterRect.height = profile.height / 10;
                setFilter(getPosition());
            }
        }

        Item {
            Layout.fillHeight: true
        }

    }

    Connections {
        function onChanged() {
            setKeyframedControls();
        }

        function onInChanged() {
            setKeyframedControls();
            setFilter(null);
        }

        function onOutChanged() {
            setKeyframedControls();
            setFilter(null);
        }

        function onAnimateInChanged() {
            setKeyframedControls();
            setFilter(null);
        }

        function onAnimateOutChanged() {
            setKeyframedControls();
            setFilter(null);
        }

        target: filter
    }

    Connections {
        function onPositionChanged() {
            setKeyframedControls();
        }

        target: producer
    }

}
