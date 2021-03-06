/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.latte 0.2 as Latte

import "../../code/MathTools.js" as MathTools

Item{
    id: wrapper

    width: {
        if (appletItem.isInternalViewSplitter && !root.editMode)
            return 0;

        if (appletItem.isSeparator && !root.editMode) {
            if (!root.isVertical)
                return -1;
            else
                return root.iconSize;
        }

        //! width for applets that use fillWidth/fillHeight such plasma taskmanagers and AWC
        if (appletItem.needsFillSpace && root.isHorizontal) {
            if (root.panelAlignment !== Latte.Types.Justify) {
                var maximumValue = (applet.Layout.maximumWidth === Infinity) || applet.Layout.maximumWidth === -1 ?
                            appletItem.sizeForFill : Math.min(appletItem.sizeForFill, applet.Layout.maximumWidth);

                var constrainedWidth = MathTools.bound(applet.Layout.minimumWidth, applet.Layout.preferredWidth, maximumValue);

                return root.editMode ? Math.max(constrainedWidth, root.iconSize) : constrainedWidth;
            }

            if(appletItem.sizeForFill>-1){
                return appletItem.sizeForFill;
            }
        }

        if (appletItem.latteApplet) {
            //! commented because it was breaking the context menu available area, I don't remember where
            //! we needed this...

            // if (appletItem.showZoomed && root.isVertical)
            //   return root.statesLineSize + root.thickMargin + root.iconSize + 1;
            //else
            return latteApplet.tasksWidth;
        } else {
            return scaledWidth;
        }
    }

    height: {
        if (appletItem.isInternalViewSplitter && !root.editMode)
            return 0;

        if (appletItem.isSeparator && !root.editMode) {
            if (root.isVertical)
                return -1;
            else
                return root.iconSize;
        }

        //! height for applets that use fillWidth/fillHeight such plasma taskmanagers and AWC
        if (appletItem.needsFillSpace && root.isVertical) {
            if (root.panelAlignment !== Latte.Types.Justify) {
                var maximumValue = (applet.Layout.maximumHeight === Infinity) || applet.Layout.maximumHeight === -1 ?
                            appletItem.sizeForFill : Math.min(appletItem.sizeForFill, applet.Layout.maximumHeight);

                var constrainedHeight = MathTools.bound(applet.Layout.minimumHeight, applet.Layout.preferredHeight, maximumValue);

                return root.editMode ? Math.max(constrainedHeight, root.iconSize) : constrainedHeight;
            }

            if (appletItem.sizeForFill>-1){
                return appletItem.sizeForFill;
            }
        }

        if (appletItem.latteApplet) {
            //! commented because it was breaking the context menu available area, I don't remember where
            //! we needed this...

            //if (appletItem.showZoomed && root.isHorizontal)
            // return root.statesLineSize + root.thickMargin + root.iconSize + 1;
            //  else
            return latteApplet.tasksHeight;
        } else {
            return scaledHeight;
        }
    }

    opacity: appletColorizer.mustBeShown ? 0 : 1

    //width: appletItem.isInternalViewSplitter && !root.editMode ? 0 : Math.round( latteApplet ? ((appletItem.showZoomed && root.isVertical) ?
    //                                                                        scaledWidth : latteApplet.tasksWidth) : scaledWidth )
    //height: appletItem.isInternalViewSplitter&& !root.editMode ? 0 : Math.round( latteApplet ? ((appletItem.showZoomed && root.isHorizontal) ?
    //                                                                          scaledHeight : latteApplet.tasksHeight ): scaledHeight )

    property bool disableScaleWidth: false
    property bool disableScaleHeight: false
    property bool editMode: root.editMode

    property int appletMinimumWidth: applet && applet.Layout ?  applet.Layout.minimumWidth : -1
    property int appletMinimumHeight: applet && applet.Layout ? applet.Layout.minimumHeight : -1

    property int appletPreferredWidth: applet && applet.Layout ?  applet.Layout.preferredWidth : -1
    property int appletPreferredHeight: applet && applet.Layout ?  applet.Layout.preferredHeight : -1

    property int appletMaximumWidth: applet && applet.Layout ?  applet.Layout.maximumWidth : -1
    property int appletMaximumHeight: applet && applet.Layout ?  applet.Layout.maximumHeight : -1

    property int iconSize: root.iconSize

    property int marginWidth: root.isVertical ?
                                  (appletItem.isSystray ? root.thickMarginBase : root.thickMargin ) :
                                  (root.inFullJustify && (appletItem.firstChildOfStartLayout || appletItem.lastChildOfEndLayout ) ? 0 : root.iconMargin)  //Fitt's Law
    property int marginHeight: root.isHorizontal ?
                                   (appletItem.isSystray ? root.thickMarginBase : root.thickMargin ) :
                                   (root.inFullJustify && (appletItem.firstChildOfStartLayout || appletItem.lastChildOfEndLayout ) ? 0 : root.iconMargin)  //Fitt's Law

    property real scaledWidth: zoomScaleWidth * (layoutWidth + marginWidth)
    property real scaledHeight: zoomScaleHeight * (layoutHeight + marginHeight)
    property real zoomScaleWidth: disableScaleWidth ? 1 : zoomScale
    property real zoomScaleHeight: disableScaleHeight ? 1 : zoomScale

    property int layoutWidthResult: 0

    property int layoutWidth
    property int layoutHeight

    // property int localMoreSpace: root.reverseLinesPosition ? root.statesLineSize + 2 : appletMargin
    property int localMoreSpace: appletMargin

    property int moreHeight: (appletItem.isSystray || root.reverseLinesPosition)
                             && root.isHorizontal ? localMoreSpace : 0
    property int moreWidth: (appletItem.isSystray || root.reverseLinesPosition)
                            && root.isVertical ? localMoreSpace : 0

    property real center:(width + hiddenSpacerLeft.separatorSpace + hiddenSpacerRight.separatorSpace) / 2
    property real zoomScale: 1

    property int index: appletItem.index

    property Item wrapperContainer: _wrapperContainer
    property Item clickedEffect: _clickedEffect
    property Item containerForOverlayIcon: _containerForOverlayIcon

    Behavior on opacity {
        NumberAnimation {
            duration: 0.8 * root.animationTime
            easing.type: Easing.OutCubic
        }
    }

    // property int pHeight: applet ? applet.Layout.preferredHeight : -10

    /*function debugLayouts(){
        if(applet){
            console.log("---------- "+ applet.pluginName +" ----------");
            console.log("MinW "+applet.Layout.minimumWidth);
            console.log("PW "+applet.Layout.preferredWidth);
            console.log("MaxW "+applet.Layout.maximumWidth);
            console.log("FillW "+applet.Layout.fillWidth);
            console.log("-----");
            console.log("MinH "+applet.Layout.minimumHeight);
            console.log("PH "+applet.Layout.preferredHeight);
            console.log("MaxH "+applet.Layout.maximumHeight);
            console.log("FillH "+applet.Layout.fillHeight);
            console.log("-----");
            console.log("LayoutW: " + layoutWidth);
            console.log("LayoutH: " + layoutHeight);
        }
    }

    onLayoutWidthChanged: {
        debugLayouts();
    }

    onLayoutHeightChanged: {
        debugLayouts();
    }*/

    onAppletMinimumWidthChanged: {
        if(zoomScale == 1)
            checkCanBeHovered();

        updateLayoutWidth();
    }

    onAppletMinimumHeightChanged: {
        if(zoomScale == 1)
            checkCanBeHovered();

        updateLayoutHeight();
    }

    onAppletPreferredWidthChanged: updateLayoutWidth();
    onAppletPreferredHeightChanged: updateLayoutHeight();

    onAppletMaximumWidthChanged: updateLayoutWidth();
    onAppletMaximumHeightChanged: updateLayoutHeight();

    onIconSizeChanged: {
        updateLayoutWidth();
        updateLayoutHeight();
    }

    onEditModeChanged: {
        updateLayoutWidth();
        updateLayoutHeight();
    }

    onZoomScaleChanged: {
        if ((zoomScale === root.zoomFactor) && !root.globalDirectRender) {
            root.setGlobalDirectRender(true);
        }

        if ((zoomScale > 1) && !appletItem.isZoomed) {
            appletItem.isZoomed = true;
            if (!root.editMode && !animationWasSent) {
                root.slotAnimationsNeedBothAxis(1);
                animationWasSent = true;
            }
        } else if ((zoomScale == 1) && appletItem.isZoomed) {
            appletItem.isZoomed = false;
            if (animationWasSent) {
                root.slotAnimationsNeedBothAxis(-1);
                animationWasSent = false;
            }
        }
    }

    Connections {
        target: root
        onIsVerticalChanged: {
            if (appletItem.latteApplet) {
                return;
            }

            wrapper.disableScaleWidth = false;
            wrapper.disableScaleHeight = false;

            if (root.isVertical)  {
                wrapper.updateLayoutHeight();
                wrapper.updateLayoutWidth();
            } else {
                wrapper.updateLayoutWidth();
                wrapper.updateLayoutHeight();
            }
        }
    }

    function updateLayoutHeight(){
        if (appletItem.needsFillSpace && root.isVertical) {
            layoutsContainer.updateSizeForAppletsInFill();
            return;
        }

        if (isLattePlasmoid) {
            return;
        } else if (appletItem.isInternalViewSplitter){
            if(!root.editMode)
                layoutHeight = 0;
            else
                layoutHeight = root.iconSize + moreHeight + root.statesLineSize;
        }
        else if(applet && applet.pluginName === "org.kde.plasma.panelspacer"){
            layoutHeight = root.iconSize + moreHeight;
        }
        else if(appletItem.isSystray && root.isHorizontal){
            layoutHeight = root.statesLineSize + root.iconSize;
        }
        else{
            if(applet && (applet.Layout.minimumHeight > root.iconSize) && root.isVertical && !canBeHovered && !communicator.overlayLatteIconIsActive){
                layoutHeight = applet.Layout.minimumHeight;
            } //it is used for plasmoids that need to scale only one axis... e.g. the Weather Plasmoid
            else if(applet
                    && ( applet.Layout.maximumHeight < root.iconSize
                        || applet.Layout.preferredHeight > root.iconSize
                        || appletItem.lockZoom)
                    && root.isVertical
                    && !disableScaleWidth
                    && !communicator.overlayLatteIconIsActive) {

                if (!appletItem.isSpacer) {
                    disableScaleHeight = true;
                }
                //this way improves performance, probably because during animation the preferred sizes update a lot
                if((applet.Layout.maximumHeight < root.iconSize)){
                    layoutHeight = applet.Layout.maximumHeight;
                } else if (applet.Layout.minimumHeight > root.iconSize){
                    layoutHeight = applet.Layout.minimumHeight;
                } else if ((applet.Layout.preferredHeight > root.iconSize)
                           || (appletItem.lockZoom && applet.Layout.preferredHeight > 0 )){
                    layoutHeight = applet.Layout.preferredHeight;
                } else{
                    layoutHeight = root.iconSize + moreHeight;
                }
            } else {
                layoutHeight = root.iconSize + moreHeight;
            }
        }
    }

    function updateLayoutWidth(){
        if (appletItem.needsFillSpace && root.isHorizontal) {
            layoutsContainer.updateSizeForAppletsInFill();
            return;
        }

        if (isLattePlasmoid) {
            return;
        } else if (appletItem.isInternalViewSplitter){
            if(!root.editMode)
                layoutWidth = 0;
            else
                layoutWidth = root.iconSize + moreWidth + root.statesLineSize;
        }
        else if(applet && applet.pluginName === "org.kde.plasma.panelspacer"){
            layoutWidth = root.iconSize + moreWidth;
        }
        else if(appletItem.isSystray && root.isVertical){
            layoutWidth = root.statesLineSize + root.iconSize;
        }
        else{
            if(applet && (applet.Layout.minimumWidth > root.iconSize) && root.isHorizontal && !canBeHovered && !communicator.overlayLatteIconIsActive){
                layoutWidth = applet.Layout.minimumWidth;
            } //it is used for plasmoids that need to scale only one axis... e.g. the Weather Plasmoid
            else if(applet
                    && ( applet.Layout.maximumWidth < root.iconSize
                        || applet.Layout.preferredWidth > root.iconSize
                        || appletItem.lockZoom)
                    && root.isHorizontal
                    && !disableScaleHeight
                    && !communicator.overlayLatteIconIsActive){

                if (!appletItem.isSpacer) {
                    disableScaleWidth = true;
                }
                //this way improves performance, probably because during animation the preferred sizes update a lot
                if((applet.Layout.maximumWidth < root.iconSize)){
                    //   return applet.Layout.maximumWidth;
                    layoutWidth = applet.Layout.maximumWidth;
                } else if (applet.Layout.minimumWidth > root.iconSize){
                    layoutWidth = applet.Layout.minimumWidth;
                } else if ((applet.Layout.preferredWidth > root.iconSize)
                           || (appletItem.lockZoom && applet.Layout.preferredWidth > 0 )){
                    layoutWidth = applet.Layout.preferredWidth;
                } else{
                    layoutWidth = root.iconSize + moreWidth;
                }
            } else{
                layoutWidth = root.iconSize + moreWidth;
            }
        }
    }

    Item{
        id:_wrapperContainer

        width:{
            if (appletItem.needsFillSpace && (appletItem.sizeForFill>-1) && root.isHorizontal){
                return wrapper.width;
            }

            if (appletItem.isInternalViewSplitter) {
                return wrapper.layoutWidth;
            } else {
                if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                    return parent.zoomScaleWidth * (root.iconSize + root.thickMarginBase + root.thickMarginHigh);
                } else {
                    return parent.zoomScaleWidth * wrapper.layoutWidth;
                }
            }
        }

        height:{
            if (appletItem.needsFillSpace && (appletItem.sizeForFill>-1) && root.isVertical){
                return wrapper.height;
            }

            if (appletItem.isInternalViewSplitter) {
                return wrapper.layoutHeight;
            } else {
                if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
                    return parent.zoomScaleHeight * (root.iconSize + root.thickMarginBase + root.thickMarginHigh);
                } else {
                    return parent.zoomScaleHeight * wrapper.layoutHeight;
                }
            }

        }

        //width: Math.round( appletItem.isInternalViewSplitter ? wrapper.layoutWidth : parent.zoomScaleWidth * wrapper.layoutWidth )
        //height: Math.round( appletItem.isInternalViewSplitter ? wrapper.layoutHeight : parent.zoomScaleHeight * wrapper.layoutHeight )

        anchors.rightMargin: plasmoid.location === PlasmaCore.Types.RightEdge ? lowThickUsed : 0
        anchors.leftMargin: plasmoid.location === PlasmaCore.Types.LeftEdge ? lowThickUsed : 0
        anchors.topMargin: plasmoid.location === PlasmaCore.Types.TopEdge ? lowThickUsed : 0
        anchors.bottomMargin: plasmoid.location === PlasmaCore.Types.BottomEdge ? lowThickUsed : 0

        opacity: appletShadow.active ? 0 : 1

        property int lowThickUsed: 0 //root.thickMarginBase

        //BEGIN states
        states: [
            State {
                name: "left"
                when: (plasmoid.location === PlasmaCore.Types.LeftEdge)

                AnchorChanges {
                    target: _wrapperContainer
                    anchors{ verticalCenter:wrapper.verticalCenter; horizontalCenter:undefined;
                        top:undefined; bottom:undefined; left:parent.left; right:undefined;}
                }
            },
            State {
                name: "right"
                when: (plasmoid.location === PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: _wrapperContainer
                    anchors{ verticalCenter:wrapper.verticalCenter; horizontalCenter:undefined;
                        top:undefined; bottom:undefined; left:undefined; right:parent.right;}
                }
            },
            State {
                name: "bottom"
                when: (plasmoid.location === PlasmaCore.Types.BottomEdge)

                AnchorChanges {
                    target: _wrapperContainer
                    anchors{ verticalCenter:undefined; horizontalCenter:wrapper.horizontalCenter;
                        top:undefined; bottom:parent.bottom; left:undefined; right:undefined;}
                }
            },
            State {
                name: "top"
                when: (plasmoid.location === PlasmaCore.Types.TopEdge)

                AnchorChanges {
                    target: _wrapperContainer
                    anchors{  verticalCenter:undefined; horizontalCenter:wrapper.horizontalCenter;
                        top:parent.top; bottom:undefined; left:undefined; right:undefined;}
                }
            }
        ]
        //END states

        ///Secret MouseArea to be used by the folder widget
        Loader{
            anchors.fill: parent
            active: communicator.overlayLatteIconIsActive && applet.pluginName === "org.kde.plasma.folder"
            sourceComponent: MouseArea{
                onClicked: latteView.toggleAppletExpanded(applet.id);
            }
        }

        Item{
            id: _containerForOverlayIcon
            anchors.fill: parent
        }

        Loader{
            anchors.fill: parent
            active: communicator.overlayLatteIconIsActive
            sourceComponent: Latte.IconItem{
                id: overlayIconItem
                anchors.fill: parent
                source: {
                    if (communicator.appletIconItemIsShown())
                        return communicator.appletIconItem.source;
                    else if (communicator.appletImageItemIsShown())
                        return communicator.appletImageItem.source;
                }

                usesPlasmaTheme: communicator.appletIconItemIsShown() ? communicator.appletIconItem.usesPlasmaTheme : false

                Loader{
                    anchors.centerIn: parent
                    active: root.debugModeOverloadedIcons
                    sourceComponent: Rectangle{
                        width: 30
                        height: 30
                        color: "green"
                        opacity: 0.65
                    }
                }

                //ActiveIndicator{}
            }
        }
    }

    //spacer background
    Loader{
        anchors.fill: _wrapperContainer
        active: applet && (applet.pluginName === "org.kde.plasma.panelspacer") && root.editMode

        sourceComponent: Rectangle{
            anchors.fill: parent
            border.width: 1
            border.color: theme.textColor
            color: "transparent"
            opacity: 0.7

            radius: root.iconMargin
            Rectangle{
                anchors.centerIn: parent
                color: parent.border.color

                width: parent.width - 1
                height: parent.height - 1

                opacity: 0.2
            }
        }
    }

    Loader{
        anchors.fill: _wrapperContainer
        active: appletItem.isInternalViewSplitter && root.editMode

        rotation: root.isVertical ? 90 : 0

        sourceComponent: PlasmaCore.SvgItem{
            id:splitterImage
            anchors.fill: parent

            svg: PlasmaCore.Svg{
                imagePath: root.universalSettings.splitterIconPath()
            }

            layer.enabled: true
            layer.effect: DropShadow {
                radius: root.appShadowSize
                fast: true
                samples: 2 * radius
                color: root.appShadowColor

                verticalOffset: 2
            }

            Component.onCompleted: {
                if (root.isVertical)  {
                    wrapper.updateLayoutHeight();
                    wrapper.updateLayoutWidth();
                } else {
                    wrapper.updateLayoutWidth();
                    wrapper.updateLayoutHeight();
                }
            }
        }
    }

    ///Shadow in applets
    Loader{
        id: appletShadow
        anchors.fill: appletItem.appletWrapper

        active: appletItem.applet && !appletColorizer.mustBeShown
                && (((plasmoid.configuration.shadows === 1 /*Locked Applets*/
                      && (!appletItem.canBeHovered || (appletItem.lockZoom && (applet.pluginName !== root.plasmoidName))) )
                     || (plasmoid.configuration.shadows === 2 /*All Applets*/
                         && (applet.pluginName !== root.plasmoidName)))
                    || (root.forceTransparentPanel && plasmoid.configuration.shadows>0 && applet.pluginName !== root.plasmoidName)) /*on forced transparent state*/

        onActiveChanged: {
            if (active) {
                wrapperContainer.opacity = 0;
            } else {
                wrapperContainer.opacity = 1;
            }
        }

        sourceComponent: DropShadow{
            anchors.fill: parent
            color: root.appShadowColor //"#ff080808"
            fast: true
            samples: 2 * radius
            source: communicator.overlayLatteIconIsActive ? _wrapperContainer : appletItem.applet
            radius: shadowSize
            verticalOffset: forcedShadow ? 0 : 2

            property int shadowSize : root.appShadowSize //Math.ceil(root.iconSize / 12)

            property bool forcedShadow: root.forceTransparentPanel && plasmoid.configuration.shadows>0 && applet.pluginName !== root.plasmoidName ? true : false
        }
    }

    BrightnessContrast{
        id:hoveredImage
        anchors.fill: _wrapperContainer
        source: _wrapperContainer

        enabled: opacity != 0 ? true : false
        opacity: appletMouseArea.containsMouse ? 1 : 0
        brightness: 0.25
        contrast: 0.15

        Behavior on opacity {
            NumberAnimation { duration: root.durationTime*units.longDuration }
        }
    }

    BrightnessContrast {
        id: _clickedEffect
        anchors.fill: _wrapperContainer
        source: _wrapperContainer

        visible: clickedAnimation.running
    }

    /*   onHeightChanged: {
        if ((index == 1)|| (index==3)){
            console.log("H: "+index+" ("+zoomScale+"). "+currentLayout.children[1].height+" - "+currentLayout.children[3].height+" - "+(currentLayout.children[1].height+currentLayout.children[3].height));
        }
    }

    onZoomScaleChanged:{
        if ((index == 1)|| (index==3)){
            console.log(index+" ("+zoomScale+"). "+currentLayout.children[1].height+" - "+currentLayout.children[3].height+" - "+(currentLayout.children[1].height+currentLayout.children[3].height));
        }
    }*/

    Loader{
        anchors.fill: parent
        active: root.debugMode

        sourceComponent: Rectangle{
            anchors.fill: parent
            color: "transparent"
            //! red visualizer, in debug mode for the applets that use fillWidth or fillHeight
            //! green, for the rest
            border.color:  (appletItem.needsFillSpace && (appletItem.sizeForFill>-1) && root.isHorizontal) ? "red" : "green"
            border.width: 1
        }
    }

    Behavior on zoomScale {
        enabled: !root.globalDirectRender
        NumberAnimation {
            duration: 3 * appletItem.animationTime
            easing.type: Easing.OutCubic
        }
    }

    Behavior on zoomScale {
        enabled: root.globalDirectRender && !restoreAnimation.running
        NumberAnimation { duration: root.directRenderAnimationTime }
    }

    function calculateScales( currentMousePosition ){
        if (root.editMode || root.zoomFactor===1 || root.durationTime===0) {
            return;
        }

        var distanceFromHovered = Math.abs(index - layoutsContainer.hoveredIndex);

        // A new algorithm trying to make the zoom calculation only once
        // and at the same time fixing glitches
        if ((distanceFromHovered == 0)&&
                (currentMousePosition  > 0) ){

            //use the new parabolicManager in order to handle all parabolic effect messages
            var scales = parabolicManager.applyParabolicEffect(index, currentMousePosition, center);

            /*if (root.latteApplet && Math.abs(index - root.latteAppletPos) > 2){
                root.latteApplet.clearZoom();
            }*/

            //Left hiddenSpacer
            if(appletItem.startEdge){
                hiddenSpacerLeft.nScale = scales.leftScale - 1;
            }

            //Right hiddenSpacer  ///there is one more item in the currentLayout ????
            if(appletItem.endEdge){
                hiddenSpacerRight.nScale =  scales.rightScale - 1;
            }

            zoomScale = root.zoomFactor;
        }

    } //scale


    function signalUpdateScale(nIndex, nScale, step){
        if(appletItem && !appletItem.containsMouse && (appletItem.index === nIndex)){
            if ( ((canBeHovered && !lockZoom ) || appletItem.latteApplet)
                    && (applet && applet.status !== PlasmaCore.Types.HiddenStatus)
                    //&& (index != currentLayout.hoveredIndex)
                    ){
                if(!appletItem.latteApplet){
                    if(nScale >= 0)
                        zoomScale = nScale + step;
                    else
                        zoomScale = zoomScale + step;
                }
            }
        }
    }

    Component.onCompleted: {
        root.updateScale.connect(signalUpdateScale);
    }

    Component.onDestruction: {
        root.updateScale.disconnect(signalUpdateScale);
    }
}// Main task area // id:wrapper
