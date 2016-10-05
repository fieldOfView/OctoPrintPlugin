import UM 1.2 as UM
import Cura 1.0 as Cura

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

Cura.MachineAction
{
    id: base
    anchors.fill: parent;
    property var selectedInstance: null
    Column
    {
        anchors.fill: parent;
        id: discoverOctoPrintAction

        spacing: UM.Theme.getSize("default_margin").height

        SystemPalette { id: palette }
        UM.I18nCatalog { id: catalog; name:"cura" }
        Label
        {
            id: pageTitle
            width: parent.width
            text: catalog.i18nc("@title", "Connect to OctoPrint")
            wrapMode: Text.WordWrap
            font.pointSize: 18
        }

        Label
        {
            id: pageDescription
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "Select your OctoPrint instance from the list below:")
        }

        Row
        {
            spacing: UM.Theme.getSize("default_lining").width

            Button
            {
                id: addButton
                text: catalog.i18nc("@action:button", "Add");
                onClicked:
                {
                    manualPrinterDialog.showDialog("", "", "80", "/");
                }
            }

            Button
            {
                id: editButton
                text: catalog.i18nc("@action:button", "Edit")
                enabled: base.selectedInstance != null && base.selectedInstance.getProperty("manual") == "true"
                onClicked:
                {
                    manualPrinterDialog.showDialog(base.selectedInstance.name, base.selectedInstance.ipAddress,
                                                   base.selectedInstance.port, base.selectedInstance.path);
                }
            }

            Button
            {
                id: removeButton
                text: catalog.i18nc("@action:button", "Remove")
                enabled: base.selectedInstance != null && base.selectedInstance.getProperty("manual") == "true"
                onClicked: manager.removeManualInstance(base.selectedInstance.name)
            }

            Button
            {
                id: rediscoverButton
                text: catalog.i18nc("@action:button", "Refresh")
                onClicked: manager.startDiscovery()
            }
        }

        Row
        {
            width: parent.width
            spacing: UM.Theme.getSize("default_margin").width
            ScrollView
            {
                id: objectListContainer
                frameVisible: true
                width: parent.width * 0.5
                height: base.height - parent.y

                Rectangle
                {
                    parent: viewport
                    anchors.fill: parent
                    color: palette.light
                }

                ListView
                {
                    id: listview
                    model: manager.discoveredInstances
                    onModelChanged:
                    {
                        var selectedKey = manager.getStoredKey();
                        for(var i = 0; i < model.length; i++) {
                            if(model[i].getKey() == selectedKey)
                            {
                                currentIndex = i;
                                return
                            }
                        }
                        currentIndex = -1;
                    }
                    width: parent.width
                    currentIndex: activeIndex
                    onCurrentIndexChanged: base.selectedInstance = listview.model[currentIndex]
                    Component.onCompleted: manager.startDiscovery()
                    delegate: Rectangle
                    {
                        height: childrenRect.height
                        color: ListView.isCurrentItem ? palette.highlight : index % 2 ? palette.base : palette.alternateBase
                        width: parent.width
                        Label
                        {
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("default_margin").width
                            anchors.right: parent.right
                            text: listview.model[index].name
                            color: parent.ListView.isCurrentItem ? palette.highlightedText : palette.text
                            elide: Text.ElideRight
                        }

                        MouseArea
                        {
                            anchors.fill: parent;
                            onClicked:
                            {
                                if(!parent.ListView.isCurrentItem)
                                {
                                    parent.ListView.view.currentIndex = index;
                                }
                            }
                        }
                    }
                }
            }
            Column
            {
                width: parent.width * 0.5
                visible: base.selectedInstance != null
                spacing: UM.Theme.getSize("default_margin").height
                Label
                {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: base.selectedInstance ? base.selectedInstance.name : ""
                    font.pointSize: 16
                    elide: Text.ElideRight
                }
                Grid
                {
                    width: parent.width
                    columns: 2
                    rowSpacing: UM.Theme.getSize("default_lining").height
                    Label
                    {
                        width: parent.width * 0.3
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "Version")
                    }
                    Label
                    {
                        width: parent.width * 0.7
                        wrapMode: Text.WordWrap
                        text: base.selectedInstance ? base.selectedInstance.octoprintVersion : ""
                    }
                    Label
                    {
                        width: parent.width * 0.2
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "Address")
                    }
                    Label
                    {
                        width: parent.width * 0.8
                        wrapMode: Text.WordWrap
                        text: base.selectedInstance ? "%1:%2".arg(base.selectedInstance.ipAddress).arg(String(base.selectedInstance.port)) : ""
                    }
                    Label
                    {
                        width: parent.width * 0.2
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "API Key")
                    }
                    TextField
                    {
                        id: apiKey
                        width: parent.width * 0.8 - UM.Theme.getSize("default_margin").width
                        text: manager.apiKey
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label", "Please enter the API key to access OctoPrint above. You can get the OctoPrint API key through the OctoPrint web page.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                CheckBox
                {
                    id: autoPrintCheckBox
                    text: catalog.i18nc("@label", "Automatically start print job after uploading")
                    checked: Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_auto_print") != "false"
                    onClicked:
                    {
                        Cura.ContainerManager.setContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_auto_print", String(checked))
                    }
                    width: parent.width
                }

                Flow
                {
                    spacing: UM.Theme.getSize("default_margin").width

                    Button
                    {
                        text: catalog.i18nc("@action", "Open in browser...")
                        onClicked: manager.openWebPage(base.selectedInstance.baseURL)
                    }

                    Button
                    {
                        text: catalog.i18nc("@action:button", "Connect")
                        enabled: apiKey.text != ""
                        onClicked:
                        {
                            manager.setKey(base.selectedInstance.getKey())
                            manager.setApiKey(apiKey.text)
                            completed()
                        }
                    }
                }
            }
        }
    }

    UM.Dialog
    {
        id: manualPrinterDialog
        property string oldName
        property alias nameText: nameField.text
        property alias addressText: addressField.text
        property alias portText: portField.text
        property alias pathText: pathField.text

        title: catalog.i18nc("@title:window", "Manually added OctoPrint instance")

        minimumWidth: 400 * Screen.devicePixelRatio
        minimumHeight: 140 * Screen.devicePixelRatio
        width: minimumWidth
        height: minimumHeight

        signal showDialog(string name, string address, string port, string path_)
        onShowDialog:
        {
            oldName = name;
            nameText = name;
            nameField.selectAll();
            nameField.focus = true;

            addressText = address;
            portText = port;
            pathText = path_;

            manualPrinterDialog.show();
        }

        onAccepted:
        {
            if(oldName != nameText)
            {
                manager.removeManualInstance(oldName);
            }
            if(portText == "")
            {
                portText = "80" // default http port
            }
            if(pathText.substr(0,1) != "/")
            {
                pathText = "/" + pathText // ensure absolute path
            }
            manager.setManualInstance(nameText, addressText, parseInt(portText), pathText)
        }

        Column {
            anchors.fill: parent
            spacing: UM.Theme.getSize("default_margin").height

            Grid
            {
                columns: 2
                width: parent.width
                verticalItemAlignment: Grid.AlignVCenter
                rowSpacing: UM.Theme.getSize("default_lining").height

                Label
                {
                    text: catalog.i18nc("@alabel","Instance Name")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: nameField
                    maximumLength: 20
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@alabel","IP Address or Hostname")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: addressField
                    maximumLength: 30
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@alabel","Port Number")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: portField
                    maximumLength: 5
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[0-9]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@alabel","Path")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: pathField
                    maximumLength: 30
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_\/]*/
                    }
                }
            }
        }

        rightButtons: [
            Button {
                text: catalog.i18nc("@action:button","Cancel")
                onClicked:
                {
                    manualPrinterDialog.reject()
                    manualPrinterDialog.hide()
                }
            },
            Button {
                text: catalog.i18nc("@action:button", "Ok")
                onClicked:
                {
                    manualPrinterDialog.accept()
                    manualPrinterDialog.hide()
                }
                enabled: manualPrinterDialog.nameText.trim() != "" && manualPrinterDialog.addressText.trim() != ""
                isDefault: true
            }
        ]
    }
}