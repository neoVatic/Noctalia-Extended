import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property string niriFile: Quickshell.env("HOME") + "/.config/niri/noctalia.kdl"

  property var colors: ({})
  property int colorsVersion: 0
  property string copiedColor: ""
  property string kdlRaw: ""

  readonly property string niriConfigFile: Quickshell.env("HOME") + "/.config/niri/config.kdl"
  property string mpvpaperPath: ""
  property string configRaw: ""

  function parseMpvpaperPath(text) {
    var match = text.match(/spawn-at-startup\s+"mpvpaper"(?:\s+"[^"]*"){3}\s+"([^"]+)"/);
    return match ? match[1] : "";
  }

  function saveMpvpaperPath() {
    var newRaw = root.configRaw.replace(
      /(spawn-at-startup\s+"mpvpaper"(?:\s+"[^"]*"){3}\s+)"[^"]*"/,
      "$1\"" + root.mpvpaperPath + "\""
    );
    if (newRaw !== root.configRaw) {
      root.configRaw = newRaw;
      configWriter.path = "";
      configWriter.path = root.niriConfigFile;
      configWriter.setText(newRaw);
    }
  }

  function hexToQml(h) {
    if (!h) return "#000000";
    if (h.length === 7 && h.charAt(0) === "#") return "#ff" + h.substring(1);
    if (h.length === 9 && h.charAt(0) === "#") return h;
    return h;
  }

  function getColor(section, key) {
    var _ = colorsVersion;
    if (colors[section] && colors[section][key] !== undefined) return colors[section][key];
    return "#000000";
  }

  function setColor(section, key, value) {
    if (!colors[section]) colors[section] = {};
    var clean = value;
    if (clean.length === 9 && clean.substring(0, 3) === "#ff") clean = "#" + clean.substring(3);
    colors[section][key] = clean;
    colorsVersion++;
  }

  function parseKdl(text) {
    colors = {};
    var sections = ["focus-ring", "border", "tab-indicator"];
    for (var si = 0; si < sections.length; si++) {
      var s = sections[si];
      var re = new RegExp(s + "\\s*\\{([\\s\\S]*?)\\}");
      var m = text.match(re);
      if (m) {
        var block = m[1];
        var colorRe = /(\w[\w-]*)\s+"(#[^"]+)"/g;
        var cm;
        while ((cm = colorRe.exec(block)) !== null) {
          if (!colors[s]) colors[s] = {};
          colors[s][cm[1]] = cm[2];
        }
      }
    }
    colorsVersion++;
  }

  function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function generateMinimalKdl() {
    var t = "layout {\n";
    var secs = ["focus-ring", "border", "tab-indicator"];
    for (var si = 0; si < secs.length; si++) {
      t += "    " + secs[si] + " {\n";
      if (colors[secs[si]]) {
        var kks = Object.keys(colors[secs[si]]);
        for (var ki = 0; ki < kks.length; ki++) {
          t += "        " + kks[ki] + " \"" + colors[secs[si]][kks[ki]] + "\"\n";
        }
      }
      t += "    }\n";
    }
    t += "}\n";
    return t;
  }

  function saveColors() {
    var text = root.kdlRaw;
    if (text && text.length > 0) {
      for (var section in colors) {
        if (!colors.hasOwnProperty(section)) continue;
        for (var key in colors[section]) {
          if (!colors[section].hasOwnProperty(key)) continue;
          var re = new RegExp("(" + escapeRegex(section) + "\\s*\\{[\\s\\S]*?" + escapeRegex(key) + "\\s+\")#[^\"]*\"");
          text = text.replace(re, "$1" + colors[section][key] + "\"");
        }
      }
    } else {
      text = generateMinimalKdl();
    }
    root.kdlRaw = text;
    kdlWriter.path = "";
    kdlWriter.path = root.niriFile;
    kdlWriter.setText(text);
  }

  FileView {
    id: kdlReader
    path: ""
    printErrors: false
    onLoaded: {
      root.kdlRaw = text();
      root.parseKdl(root.kdlRaw);
    }
  }

  FileView {
    id: kdlWriter
    path: ""
    printErrors: false
    onSaved: {
      applyGradient.running = true;
      ToastService.showNotice("Niri Colors", "Saved and applied", "color-picker");
    }
  }

  Process {
    id: applyGradient
    command: ["python3", Quickshell.shellDir + "/Scripts/bash/toggle-niri-gradient.sh"]
  }

  Process {
    id: windowRoundingProcess
    command: ["python3", Quickshell.shellDir + "/Scripts/bash/toggle-niri-window-rounding.sh"]
  }

  FileView {
    id: configReader
    path: ""
    printErrors: false
    onLoaded: {
      root.configRaw = text();
      root.mpvpaperPath = root.parseMpvpaperPath(root.configRaw);
    }
  }

  FileView {
    id: configWriter
    path: ""
    printErrors: false
    onSaved: {
      Quickshell.execDetached(["bash", "-c", "pkill mpvpaper; mpvpaper -o 'loop panscan=1.0' '*' '" + root.mpvpaperPath + "' &"]);
      ToastService.showNotice("mpvpaper", "Wallpaper path saved and applied", "video");
    }
  }

  NToggle {
    label: "Rounded Corners"
    description: "Quick toggle to enable or disable all rounded corners in the UI and niri windows"
    checked: Settings.data.general.roundedCornersEnabled
    onToggled: checked => {
      Settings.data.general.roundedCornersEnabled = checked;
      Settings.saveImmediate();
      windowRoundingProcess.running = true;
    }
  }

  NToggle {
    label: "Niri Focus Ring Gradient"
    description: "Use a gradient instead of a solid color for the active window focus ring"
    checked: Settings.data.niriFocusGradient
    onToggled: checked => {
      Settings.data.niriFocusGradient = checked;
      Settings.saveImmediate();
      applyGradient.running = true;
    }
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL

    NButton {
      text: "Save && Apply"
      onClicked: {
        root.saveColors();
      }
    }

    NText {
      text: "~/.config/niri/noctalia.kdl"
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      elide: Text.ElideMiddle
      Layout.fillWidth: true
    }
  }

  NHeader {
    label: "Focus Ring"
    Layout.bottomMargin: Style.marginM
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: row1.implicitHeight + Style.margin2L

    RowLayout {
      id: row1
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Style.baseWidgetSize
        Layout.preferredHeight: Style.baseWidgetSize
        radius: Style.iRadiusS
        color: root.hexToQml(root.getColor("focus-ring", "active-color"))
        border.color: Color.mOutline
        border.width: Style.borderS
      }

      NText {
        text: "active-color"
        Layout.fillWidth: true
        font.capitalization: Font.Capitalize
      }

      NText {
        text: root.getColor("focus-ring", "active-color").toUpperCase()
        family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
      }

      NIconButton {
        icon: "color-picker"
        onClicked: {
          var dialog = colorPickerComponent.createObject(root, {
            selectedColor: root.hexToQml(root.getColor("focus-ring", "active-color")),
            parent: Overlay.overlay,
            screen: root.getScreen()
          });
          dialog.colorSelected.connect(function(color) {
            root.setColor("focus-ring", "active-color", color.toString());
          });
          dialog.open();
        }
      }

      NIconButton {
        icon: "copy"
        tooltipText: "Copy color code"
        onClicked: {
          root.copiedColor = root.getColor("focus-ring", "active-color");
          Quickshell.execDetached(["wl-copy", root.copiedColor]);
          ToastService.showNotice("Copied", "active-color: " + root.copiedColor, "clipboard");
        }
      }

      NIconButton {
        icon: "clipboard-plus"
        tooltipText: "Paste color code"
        enabled: root.copiedColor.length > 0
        onClicked: {
          if (root.copiedColor)
            root.setColor("focus-ring", "active-color", root.copiedColor);
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: row2.implicitHeight + Style.margin2L

    RowLayout {
      id: row2
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Style.baseWidgetSize
        Layout.preferredHeight: Style.baseWidgetSize
        radius: Style.iRadiusS
        color: root.hexToQml(root.getColor("focus-ring", "inactive-color"))
        border.color: Color.mOutline
        border.width: Style.borderS
      }

      NText {
        text: "inactive-color"
        Layout.fillWidth: true
        font.capitalization: Font.Capitalize
      }

      NText {
        text: root.getColor("focus-ring", "inactive-color").toUpperCase()
        family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
      }

      NIconButton {
        icon: "color-picker"
        onClicked: {
          var dialog = colorPickerComponent.createObject(root, {
            selectedColor: root.hexToQml(root.getColor("focus-ring", "inactive-color")),
            parent: Overlay.overlay,
            screen: root.getScreen()
          });
          dialog.colorSelected.connect(function(color) {
            root.setColor("focus-ring", "inactive-color", color.toString());
          });
          dialog.open();
        }
      }

      NIconButton {
        icon: "copy"
        tooltipText: "Copy color code"
        onClicked: {
          root.copiedColor = root.getColor("focus-ring", "inactive-color");
          Quickshell.execDetached(["wl-copy", root.copiedColor]);
          ToastService.showNotice("Copied", "inactive-color: " + root.copiedColor, "clipboard");
        }
      }

      NIconButton {
        icon: "clipboard-plus"
        tooltipText: "Paste color code"
        enabled: root.copiedColor.length > 0
        onClicked: {
          if (root.copiedColor)
            root.setColor("focus-ring", "inactive-color", root.copiedColor);
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: row3.implicitHeight + Style.margin2L

    RowLayout {
      id: row3
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Style.baseWidgetSize
        Layout.preferredHeight: Style.baseWidgetSize
        radius: Style.iRadiusS
        color: root.hexToQml(root.getColor("focus-ring", "urgent-color"))
        border.color: Color.mOutline
        border.width: Style.borderS
      }

      NText {
        text: "urgent-color"
        Layout.fillWidth: true
        font.capitalization: Font.Capitalize
      }

      NText {
        text: root.getColor("focus-ring", "urgent-color").toUpperCase()
        family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
      }

      NIconButton {
        icon: "color-picker"
        onClicked: {
          var dialog = colorPickerComponent.createObject(root, {
            selectedColor: root.hexToQml(root.getColor("focus-ring", "urgent-color")),
            parent: Overlay.overlay,
            screen: root.getScreen()
          });
          dialog.colorSelected.connect(function(color) {
            root.setColor("focus-ring", "urgent-color", color.toString());
          });
          dialog.open();
        }
      }

      NIconButton {
        icon: "copy"
        tooltipText: "Copy color code"
        onClicked: {
          root.copiedColor = root.getColor("focus-ring", "urgent-color");
          Quickshell.execDetached(["wl-copy", root.copiedColor]);
          ToastService.showNotice("Copied", "urgent-color: " + root.copiedColor, "clipboard");
        }
      }

      NIconButton {
        icon: "clipboard-plus"
        tooltipText: "Paste color code"
        enabled: root.copiedColor.length > 0
        onClicked: {
          if (root.copiedColor)
            root.setColor("focus-ring", "urgent-color", root.copiedColor);
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: row4.implicitHeight + Style.margin2L

    RowLayout {
      id: row4
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Style.baseWidgetSize
        Layout.preferredHeight: Style.baseWidgetSize
        radius: Style.iRadiusS
        color: root.hexToQml(Settings.data.niriGradientTo || "#010409")
        border.color: Color.mOutline
        border.width: Style.borderS
      }

      NText {
        text: "Gradient (to)"
        Layout.fillWidth: true
        font.capitalization: Font.Capitalize
      }

      NText {
        text: (Settings.data.niriGradientTo || "#010409").toUpperCase()
        family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
      }

      NIconButton {
        icon: "color-picker"
        onClicked: {
          var dialog = colorPickerComponent.createObject(root, {
            selectedColor: root.hexToQml(Settings.data.niriGradientTo || "#010409"),
            parent: Overlay.overlay,
            screen: root.getScreen()
          });
          dialog.colorSelected.connect(function(color) {
            var val = color.toString();
            if (val.length === 9 && val.substring(0, 3) === "#ff") val = "#" + val.substring(3);
            Settings.data.niriGradientTo = val;
            Settings.saveImmediate();
            applyGradient.running = true;
          });
          dialog.open();
        }
      }

      NIconButton {
        icon: "copy"
        tooltipText: "Copy color code"
        onClicked: {
          var val = Settings.data.niriGradientTo || "#010409";
          root.copiedColor = val;
          Quickshell.execDetached(["wl-copy", root.copiedColor]);
          ToastService.showNotice("Copied", "gradient-to: " + root.copiedColor, "clipboard");
        }
      }

      NIconButton {
        icon: "clipboard-plus"
        tooltipText: "Paste color code"
        enabled: root.copiedColor.length > 0
        onClicked: {
          if (root.copiedColor) {
            Settings.data.niriGradientTo = root.copiedColor;
            Settings.saveImmediate();
            applyGradient.running = true;
          }
        }
      }
    }
  }

  NDivider { Layout.fillWidth: true; Layout.bottomMargin: Style.marginM }

  NHeader {
    label: "Animated Wallpaper"
    Layout.bottomMargin: Style.marginM
  }

  NTextInput {
    id: mpvpaperInput
    label: "mpvpaper video path"
    description: "Path to the video file used as animated wallpaper"
    text: root.mpvpaperPath
    placeholderText: "/path/to/video.mp4"
    fontFamily: Settings.data.ui.fontFixed
    fontSize: Style.fontSizeS
    onEditingFinished: {
      if (text && text !== root.mpvpaperPath) {
        root.mpvpaperPath = text;
        root.saveMpvpaperPath();
      }
    }
    onAccepted: {
      if (text && text !== root.mpvpaperPath) {
        root.mpvpaperPath = text;
        root.saveMpvpaperPath();
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS

    Item { Layout.fillWidth: true }

    NButton {
      icon: "folder-open"
      text: "Browse..."
      onClicked: mpvpaperPicker.openFilePicker()
    }
  }

  NFilePicker {
    id: mpvpaperPicker
    title: "Select mpvpaper video"
    selectionMode: "files"
    nameFilters: ["*.mp4", "*.avi", "*.mkv", "*.mov", "*.webm", "*.gif"]
    initialPath: {
      var idx = root.mpvpaperPath.lastIndexOf("/");
      return idx >= 0 ? root.mpvpaperPath.substring(0, idx) : Quickshell.env("HOME");
    }
    onAccepted: paths => {
      if (paths.length > 0) {
        root.mpvpaperPath = paths[0];
        mpvpaperInput.text = paths[0];
        root.saveMpvpaperPath();
      }
    }
  }

  NDivider { Layout.fillWidth: true; Layout.bottomMargin: Style.marginM }

  Component {
    id: colorPickerComponent
    NColorPickerDialog {}
  }

  function getScreen() {
    return PanelService.openedPanel?.screen || SettingsPanelService.settingsWindow?.screen || PanelService.findScreenForPanels();
  }

  Component.onCompleted: {
    kdlReader.path = root.niriFile;
    configReader.path = root.niriConfigFile;
  }
}
