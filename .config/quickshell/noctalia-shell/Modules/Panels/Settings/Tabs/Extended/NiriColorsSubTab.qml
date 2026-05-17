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

  readonly property string millenniumConfigFile: Quickshell.env("HOME") + "/.config/millennium/config.json"
  property string millenniumAccentColor: "#58a6ff"
  property string millenniumConfigRaw: ""

  readonly property string vesktopThemeFile: Quickshell.env("HOME") + "/.config/vesktop/themes/DarkMatter.theme.css"
  property string vesktopThemeRaw: ""
  property var vesktopColorValues: ({})
  property int vesktopVersion: 0

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

  function loadMillenniumConfig() {
    millenniumReader.path = root.millenniumConfigFile;
  }

  function setMillenniumAccentColor(value) {
    var clean = value;
    if (clean.length === 9 && clean.substring(0, 3) === "#ff") clean = "#" + clean.substring(3);
    root.millenniumAccentColor = clean;
    try {
      var config = JSON.parse(root.millenniumConfigRaw);
      config.general.accentColor = clean;
      var newRaw = JSON.stringify(config, null, 2);
      root.millenniumConfigRaw = newRaw;
      millenniumWriter.path = "";
      millenniumWriter.path = root.millenniumConfigFile;
      millenniumWriter.setText(newRaw);
    } catch (e) {}
  }

  function rgbToHex(rgb) {
    var parts = rgb.split(",");
    if (parts.length !== 3) return "#000000";
    var r = parseInt(parts[0].trim());
    var g = parseInt(parts[1].trim());
    var b = parseInt(parts[2].trim());
    return "#" + [r, g, b].map(function(x) {
      var h = x.toString(16);
      return h.length === 1 ? "0" + h : h;
    }).join("");
  }

  function hexToRgb(hex) {
    hex = hex.replace("#", "");
    if (hex.length === 8) hex = hex.substring(2);
    if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
    var r = parseInt(hex.substring(0, 2), 16);
    var g = parseInt(hex.substring(2, 4), 16);
    var b = parseInt(hex.substring(4, 6), 16);
    return r + ", " + g + ", " + b;
  }

  function loadVesktopTheme() {
    vesktopReader.path = root.vesktopThemeFile;
  }

  function setVesktopColor(variable, value) {
    root.vesktopColorValues[variable] = value;
    root.vesktopVersion++;
    var re = new RegExp("(" + root.escapeRegex(variable) + "\\s*:\\s*)[^;]+");
    root.vesktopThemeRaw = root.vesktopThemeRaw.replace(re, "$1" + value);
    vesktopWriter.path = "";
    vesktopWriter.path = root.vesktopThemeFile;
    vesktopWriter.setText(root.vesktopThemeRaw);
  }

  function getVesktopColor(variable) {
    var _ = root.vesktopVersion;
    return root.vesktopColorValues[variable] || "";
  }

  function getVesktopColorHex(variable, format) {
    var _ = root.vesktopVersion;
    var val = root.vesktopColorValues[variable];
    if (!val) return "#000000";
    return format === "rgb" ? root.rgbToHex(val) : val;
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

  FileView {
    id: millenniumReader
    path: ""
    printErrors: false
    onLoaded: {
      root.millenniumConfigRaw = text();
      try {
        var config = JSON.parse(text());
        if (config.general && config.general.accentColor)
          root.millenniumAccentColor = config.general.accentColor;
      } catch (e) {}
    }
  }

  FileView {
    id: millenniumWriter
    path: ""
    printErrors: false
    onSaved: {
      ToastService.showNotice("Steam Accent", "Saved — restart Steam to apply", "color-picker");
    }
  }

  FileView {
    id: vesktopReader
    path: ""
    printErrors: false
    onLoaded: {
      root.vesktopThemeRaw = text();
      var raw = text();
      var colorVars = ["--background-solid", "--background-solid-dark", "--background-solid-darker", "--accent", "--accent-alt"];
      for (var i = 0; i < colorVars.length; i++) {
        var re = new RegExp(root.escapeRegex(colorVars[i]) + "\\s*:\\s*([^;]+)");
        var m = raw.match(re);
        if (m) root.vesktopColorValues[colorVars[i]] = m[1].trim();
      }
      root.vesktopVersion++;
    }
  }

  FileView {
    id: vesktopWriter
    path: ""
    printErrors: false
    onSaved: {
      ToastService.showNotice("Vesktop Theme", "Saved — reload Vesktop to apply", "color-picker");
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

  NHeader {
    label: "Steam Millennium Accent Color"
    description: "Changes the accent color used by Millennium themes"
    Layout.bottomMargin: Style.marginM
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: rowMillennium.implicitHeight + Style.margin2L

    RowLayout {
      id: rowMillennium
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Style.baseWidgetSize
        Layout.preferredHeight: Style.baseWidgetSize
        radius: Style.iRadiusS
        color: root.hexToQml(root.millenniumAccentColor)
        border.color: Color.mOutline
        border.width: Style.borderS
      }

      NText {
        text: "Accent Color"
        Layout.fillWidth: true
        font.capitalization: Font.Capitalize
      }

      NText {
        text: root.millenniumAccentColor.toUpperCase()
        family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
      }

      NIconButton {
        icon: "color-picker"
        onClicked: {
          var dialog = colorPickerComponent.createObject(root, {
            selectedColor: root.hexToQml(root.millenniumAccentColor),
            parent: Overlay.overlay,
            screen: root.getScreen()
          });
          dialog.colorSelected.connect(function(color) {
            root.setMillenniumAccentColor(color.toString());
          });
          dialog.open();
        }
      }

      NIconButton {
        icon: "copy"
        tooltipText: "Copy color code"
        onClicked: {
          root.copiedColor = root.millenniumAccentColor;
          Quickshell.execDetached(["wl-copy", root.copiedColor]);
          ToastService.showNotice("Copied", "Accent: " + root.copiedColor, "clipboard");
        }
      }

      NIconButton {
        icon: "clipboard-plus"
        tooltipText: "Paste color code"
        enabled: root.copiedColor.length > 0
        onClicked: {
          if (root.copiedColor)
            root.setMillenniumAccentColor(root.copiedColor);
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM

    NButton {
      text: "Kill Steam"
      icon: "power-standby"
      onClicked: killSteam.running = true
    }

    NText {
      text: "Forcefully terminates the Steam process"
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      Layout.fillWidth: true
      elide: Text.ElideRight
    }
  }

  Process {
    id: killSteam
    command: ["killall", "steam"]
    onRunningChanged: {
      if (!running)
        ToastService.showNotice("Steam", "Steam process terminated", "power-standby");
    }
  }

  NDivider { Layout.fillWidth: true; Layout.bottomMargin: Style.marginM }

  NHeader {
    label: "Vesktop DarkMatter Theme"
    description: "Customize colors for the Vesktop Discord client theme"
    Layout.bottomMargin: Style.marginM
  }

  Repeater {
    model: [
      { variable: "--background-solid", label: "Background Solid", format: "hex" },
      { variable: "--background-solid-dark", label: "Background Solid Dark", format: "hex" },
      { variable: "--background-solid-darker", label: "Background Solid Darker", format: "hex" },
      { variable: "--accent", label: "Accent", format: "rgb" },
      { variable: "--accent-alt", label: "Accent Alt", format: "rgb" }
    ]

    delegate: NBox {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: rowLayout.implicitHeight + Style.margin2L

      RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        Rectangle {
          Layout.preferredWidth: Style.baseWidgetSize
          Layout.preferredHeight: Style.baseWidgetSize
          radius: Style.iRadiusS
          color: root.hexToQml(root.getVesktopColorHex(modelData.variable, modelData.format))
          border.color: Color.mOutline
          border.width: Style.borderS
        }

        NText {
          text: modelData.label
          Layout.fillWidth: true
          font.capitalization: Font.Capitalize
        }

        NText {
          text: root.getVesktopColor(modelData.variable).toUpperCase()
          family: Settings.data.ui.fontFixed
          color: Color.mOnSurfaceVariant
        }

        NIconButton {
          icon: "color-picker"
          onClicked: {
            var currentHex = root.getVesktopColorHex(modelData.variable, modelData.format);
            var dialog = colorPickerComponent.createObject(root, {
              selectedColor: root.hexToQml(currentHex),
              parent: Overlay.overlay,
              screen: root.getScreen()
            });
            dialog.colorSelected.connect(function(color) {
              var hex = color.toString();
              if (hex.length === 9 && hex.substring(0, 3) === "#ff") hex = "#" + hex.substring(3);
              var value = modelData.format === "rgb" ? root.hexToRgb(hex) : hex;
              root.setVesktopColor(modelData.variable, value);
            });
            dialog.open();
          }
        }

        NIconButton {
          icon: "copy"
          tooltipText: "Copy color code"
          onClicked: {
            var val = root.getVesktopColor(modelData.variable);
            root.copiedColor = val;
            Quickshell.execDetached(["wl-copy", root.copiedColor]);
            ToastService.showNotice("Copied", modelData.label + ": " + root.copiedColor, "clipboard");
          }
        }

        NIconButton {
          icon: "clipboard-plus"
          tooltipText: "Paste color code"
          enabled: root.copiedColor.length > 0
          onClicked: {
            if (root.copiedColor)
              root.setVesktopColor(modelData.variable, root.copiedColor);
          }
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM

    NButton {
      text: "Kill Discord"
      icon: "power-standby"
      onClicked: killDiscord.running = true
    }

    NText {
      text: "Forcefully terminates the Vesktop process"
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      Layout.fillWidth: true
      elide: Text.ElideRight
    }
  }

  Process {
    id: killDiscord
    command: ["pkill", "-f", "vesktop"]
    onRunningChanged: {
      if (!running)
        ToastService.showNotice("Discord", "Vesktop process terminated", "power-standby");
    }
  }

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
    root.loadMillenniumConfig();
    root.loadVesktopTheme();
  }
}
