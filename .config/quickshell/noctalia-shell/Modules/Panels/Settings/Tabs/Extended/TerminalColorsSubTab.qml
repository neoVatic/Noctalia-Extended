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

  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string tomlPath: homeDir + "/.config/alacritty/themes/noctalia.toml"

  property var colors: ({})
  property int colorsVersion: 0
  property string copiedColor: ""
  property bool loaded: false

  readonly property string presetDir: homeDir + "/.config/noctalia/terminal-presets"
  property var presetList: []
  property string selectedPresetKey: ""

  property var categories: [
    { name: "Primary", section: "primary", keys: ["background", "foreground"] },
    { name: "Cursor", section: "cursor", keys: ["cursor", "text"] },
    { name: "Selection", section: "selection", keys: ["background", "text"] },
    { name: "Normal", section: "normal", keys: ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"] },
    { name: "Bright", section: "bright", keys: ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"] }
  ]

  property var defaultColors: ({
    "primary": { "background": "#1e1e1e", "foreground": "#ffffff" },
    "cursor": { "cursor": "#ffffff", "text": "#1e1e1e" },
    "selection": { "background": "#264f78", "text": "#ffffff" },
    "normal": { "black": "#000000", "red": "#cd3131", "green": "#0dbc79", "yellow": "#e5e510", "blue": "#2472c8", "magenta": "#bc3fbc", "cyan": "#11a8cd", "white": "#e5e5e5" },
    "bright": { "black": "#666666", "red": "#f14c4c", "green": "#23d18b", "yellow": "#f5f543", "blue": "#3b8eea", "magenta": "#d670d6", "cyan": "#29b8db", "white": "#ffffff" }
  })

  function hexToQml(h) {
    if (h && h.length === 7) return "#ff" + h.substring(1);
    return h || "#000000";
  }

  function stripAlpha(h) {
    if (h && h.length === 9 && h.substring(0, 3) === "#ff") return "#" + h.substring(3);
    return h || "#000000";
  }

  function getColor(section, key) {
    var _ = colorsVersion;
    if (colors[section] && colors[section][key] !== undefined) return colors[section][key];
    if (defaultColors[section] && defaultColors[section][key] !== undefined) return defaultColors[section][key];
    return "#000000";
  }

  function setColor(section, key, value) {
    if (!colors[section]) colors[section] = {};
    colors[section][key] = stripAlpha(value);
    colorsVersion++;
  }

  function parseToml(text) {
    colors = {};
    var currentSection = "";
    var lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (!line || line.charAt(0) === '#') continue;
      var sectionMatch = line.match(/^\[colors\.(.+)\]$/);
      if (sectionMatch) {
        currentSection = sectionMatch[1];
        if (!colors[currentSection]) colors[currentSection] = {};
        continue;
      }
      var kvMatch = line.match(/^(\w+)\s*=\s*['"]([^'"]+)['"]$/);
      if (kvMatch && currentSection) {
        colors[currentSection][kvMatch[1]] = kvMatch[2];
      }
    }
    loaded = true;
    colorsVersion++;
  }

  function generateToml() {
    var sections = ["primary", "cursor", "selection", "normal", "bright"];
    var lines = ["# Colors (Noctalia)", ""];
    for (var si = 0; si < sections.length; si++) {
      var section = sections[si];
      var sectionColors = colors[section];
      if (!sectionColors) continue;
      lines.push("[colors." + section + "]");
      var keys = Object.keys(sectionColors);
      for (var ki = 0; ki < keys.length; ki++) {
        lines.push(keys[ki] + " = '" + stripAlpha(sectionColors[keys[ki]]) + "'");
      }
      lines.push("");
    }
    return lines.join('\n');
  }

  function saveToml() {
    Quickshell.execDetached(["mkdir", "-p", homeDir + "/.config/alacritty/themes"]);
    var text = generateToml();
    tomlWriter.path = "";
    tomlWriter.path = tomlPath;
    tomlWriter.setText(text);
    ToastService.showNotice("Terminal Colors", "Saved", "terminal-2");
  }

  function applyColors() {
    saveToml();
    Quickshell.execDetached(["alacritty", "msg", "config", "-w", "-f", tomlPath]);
  }

  function scanPresets() {
    Quickshell.execDetached(["mkdir", "-p", presetDir]);
    scanProcess.command = ["find", presetDir, "-maxdepth", "1", "-name", "*.json", "-type", "f"];
    scanProcess.running = true;
  }

  function savePreset(name) {
    if (!name) return;
    Quickshell.execDetached(["mkdir", "-p", presetDir]);
    var sections = ["primary", "cursor", "selection", "normal", "bright"];
    var data = {};
    for (var si = 0; si < sections.length; si++) {
      var sect = sections[si];
      if (colors[sect]) {
        data[sect] = {};
        var keys = Object.keys(colors[sect]);
        for (var ki = 0; ki < keys.length; ki++) {
          data[sect][keys[ki]] = colors[sect][keys[ki]];
        }
      }
    }
    var filePath = presetDir + "/" + name + ".json";
    presetWriter.path = "";
    presetWriter.path = filePath;
    presetWriter.setText(JSON.stringify(data, null, 2));
  }

  function deletePreset(path) {
    if (!path) return;
    Quickshell.execDetached(["rm", path]);
    Qt.callLater(function() { scanPresets(); });
  }

  FileView {
    id: tomlReader
    path: ""
    printErrors: false
    onLoaded: {
      var t = text();
      if (t && t.length > 0) parseToml(t);
    }
  }

  FileView {
    id: tomlWriter
    path: ""
    printErrors: false
  }

  Process {
    id: scanProcess
    running: false
    onExited: function(exitCode) {
      if (exitCode === 0) {
        var output = stdout.text.trim();
        if (!output) { presetList = []; return; }
        var files = output.split('\n').filter(function(l) { return l.length > 0; });
        var list = [];
        for (var i = 0; i < files.length; i++) {
          var p = files[i];
          var name = p.split('/').pop().replace('.json', '');
          list.push({ name: name, key: name, path: p });
        }
        list.sort(function(a, b) { return a.name.localeCompare(b.name); });
        presetList = list;
      }
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  FileView {
    id: presetReader
    path: ""
    printErrors: false
    onLoaded: {
      try {
        var data = JSON.parse(text());
        var sections = ["primary", "cursor", "selection", "normal", "bright"];
        for (var si = 0; si < sections.length; si++) {
          var sect = sections[si];
          var sectionData = data[sect];
          if (sectionData) {
            var keys = Object.keys(sectionData);
            for (var ki = 0; ki < keys.length; ki++)
              setColor(sect, keys[ki], sectionData[keys[ki]]);
          }
        }
        ToastService.showNotice("Preset Loaded", "Terminal colors loaded", "terminal-2");
      } catch (e) {
        Logger.e("TerminalColors", "Failed to parse preset:", e);
      }
    }
  }

  FileView {
    id: presetWriter
    path: ""
    printErrors: false
    onSaved: {
      scanPresets();
      ToastService.showNotice("Preset Saved", "Terminal preset saved", "terminal-2");
    }
  }

  Component.onCompleted: {
    tomlReader.path = tomlPath;
    scanPresets();
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL

    NButton {
      text: "Save && Apply"
      onClicked: root.applyColors()
    }

    NText {
      text: tomlPath
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      elide: Text.ElideMiddle
      Layout.fillWidth: true
    }
  }

  NHeader {
    label: "Terminal Presets"
    Layout.bottomMargin: Style.marginM
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM

    NComboBox {
      id: presetCombo
      Layout.fillWidth: true
      model: root.presetList
      currentKey: root.selectedPresetKey
      placeholder: presetList.length === 0 ? "No presets saved" : "Select a preset..."
      onSelected: function(key) {
        root.selectedPresetKey = key;
      }
    }

    NButton {
      text: "Load"
      enabled: root.selectedPresetKey.length > 0
      onClicked: {
        for (var i = 0; i < root.presetList.length; i++) {
          if (root.presetList[i].name === root.selectedPresetKey) {
            presetReader.path = "";
            presetReader.path = root.presetList[i].path;
            break;
          }
        }
      }
    }

    NButton {
      text: "Save As..."
      onClicked: {
        presetNameField.text = "";
        saveDialog.open();
      }
    }

    NButton {
      text: "Delete"
      enabled: root.selectedPresetKey.length > 0
      onClicked: {
        for (var i = 0; i < root.presetList.length; i++) {
          if (root.presetList[i].name === root.selectedPresetKey) {
            root.deletePreset(root.presetList[i].path);
            root.selectedPresetKey = "";
            break;
          }
        }
      }
    }
  }

  Popup {
    id: saveDialog
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 320
    height: 160

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NText {
        text: "Save Preset As"
        pointSize: Style.fontSizeL
        font.weight: Font.DemiBold
      }

      NTextInput {
        id: presetNameField
        Layout.fillWidth: true
        placeholderText: "Enter preset name..."
        onAccepted: {
          var name = text.trim();
          if (name) {
            root.savePreset(name);
            saveDialog.close();
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight

        NButton {
          text: "Cancel"
          onClicked: saveDialog.close()
        }

        NButton {
          text: "Save"
          enabled: presetNameField.text.trim().length > 0
          onClicked: {
            var name = presetNameField.text.trim();
            if (name) {
              root.savePreset(name);
              saveDialog.close();
            }
          }
        }
      }
    }
  }

  NDivider { Layout.fillWidth: true; Layout.bottomMargin: Style.marginM }

  Repeater {
    model: categories

    delegate: ColumnLayout {
      property var cat: modelData
      spacing: Style.marginL
      Layout.fillWidth: true
      Layout.bottomMargin: Style.margin2L

      NHeader {
        label: cat.name
        Layout.bottomMargin: Style.marginM
      }

      Repeater {
        model: cat.keys

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
              color: root.hexToQml(root.getColor(cat.section, modelData))
              border.color: Color.mOutline
              border.width: Style.borderS
            }

            NText {
              text: modelData
              Layout.fillWidth: true
              font.capitalization: Font.Capitalize
            }

            NText {
              text: root.getColor(cat.section, modelData).toUpperCase()
              family: Settings.data.ui.fontFixed
              color: Color.mOnSurfaceVariant
            }

            NIconButton {
              icon: "color-picker"
              onClicked: {
                var dialog = colorPickerComponent.createObject(root, {
                  selectedColor: root.hexToQml(root.getColor(cat.section, modelData)),
                  parent: Overlay.overlay,
                  screen: root.getScreen()
                });
                dialog.colorSelected.connect(function(color) {
                  root.setColor(cat.section, modelData, color.toString());
                });
                dialog.open();
              }
            }

            NIconButton {
              icon: "copy"
              tooltipText: "Copy color code"
              onClicked: {
                root.copiedColor = root.getColor(cat.section, modelData);
                Quickshell.execDetached(["wl-copy", root.copiedColor]);
                ToastService.showNotice("Copied", modelData + ": " + root.copiedColor, "clipboard");
              }
            }

            NIconButton {
              icon: "clipboard-plus"
              tooltipText: "Paste color code"
              enabled: root.copiedColor.length > 0
              onClicked: {
                if (root.copiedColor)
                  root.setColor(cat.section, modelData, root.copiedColor);
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: colorPickerComponent
    NColorPickerDialog {}
  }

  function getScreen() {
    return PanelService.openedPanel?.screen || SettingsPanelService.settingsWindow?.screen || PanelService.findScreenForPanels();
  }
}
