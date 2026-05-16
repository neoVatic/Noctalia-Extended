import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Theming
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property var colorCategories: [
    {
      name: "Accent",
      keys: [
        { key: "mPrimary", label: "Primary" },
        { key: "mOnPrimary", label: "On Primary" },
        { key: "mSecondary", label: "Secondary" },
        { key: "mOnSecondary", label: "On Secondary" },
        { key: "mTertiary", label: "Tertiary" },
        { key: "mOnTertiary", label: "On Tertiary" }
      ]
    },
    {
      name: "Utility",
      keys: [
        { key: "mError", label: "Error" },
        { key: "mOnError", label: "On Error" }
      ]
    },
    {
      name: "Surface",
      keys: [
        { key: "mSurface", label: "Surface" },
        { key: "mOnSurface", label: "On Surface" },
        { key: "mSurfaceVariant", label: "Surface Variant" },
        { key: "mOnSurfaceVariant", label: "On Surface Variant" }
      ]
    },
    {
      name: "Stroke",
      keys: [
        { key: "mOutline", label: "Outline" },
        { key: "mShadow", label: "Shadow" }
      ]
    },
    {
      name: "Hover",
      keys: [
        { key: "mHover", label: "Hover" },
        { key: "mOnHover", label: "On Hover" }
      ]
    }
  ]

  readonly property string activeSchemeName: Settings.data.colorSchemes.predefinedScheme || "CUSTOM"
  property var currentSchemeData: null
  property string copiedColor: ""
  property var schemeColorsCache: ({})
  property int cacheVersion: 0

  function getSchemeUserPath(name) {
    if (!name) return "";
    return ColorSchemeService.downloadedSchemesDirectory + "/" + name + "/" + name + ".json";
  }

  function loadCurrentScheme() {
    var name = Settings.data.colorSchemes.predefinedScheme;
    if (!name) {
      currentSchemeData = null;
      return;
    }
    var resolvedPath = ColorSchemeService.resolveSchemePath(name);
    if (resolvedPath) {
      schemeReader.path = resolvedPath;
    }
  }

  function refreshFromCurrentScheme() {
    writeAdapter.mPrimary = Color.mPrimary;
    writeAdapter.mOnPrimary = Color.mOnPrimary;
    writeAdapter.mSecondary = Color.mSecondary;
    writeAdapter.mOnSecondary = Color.mOnSecondary;
    writeAdapter.mTertiary = Color.mTertiary;
    writeAdapter.mOnTertiary = Color.mOnTertiary;
    writeAdapter.mError = Color.mError;
    writeAdapter.mOnError = Color.mOnError;
    writeAdapter.mSurface = Color.mSurface;
    writeAdapter.mOnSurface = Color.mOnSurface;
    writeAdapter.mSurfaceVariant = Color.mSurfaceVariant;
    writeAdapter.mOnSurfaceVariant = Color.mOnSurfaceVariant;
    writeAdapter.mOutline = Color.mOutline;
    writeAdapter.mShadow = Color.mShadow;
    writeAdapter.mHover = Color.mHover;
    writeAdapter.mOnHover = Color.mOnHover;

    loadCurrentScheme();
  }

  Connections {
    target: Settings.data.colorSchemes
    function onPredefinedSchemeChanged() {
      Qt.callLater(function() { root.refreshFromCurrentScheme(); });
    }
  }

  Connections {
    target: ColorSchemeService
    function onSchemesChanged() {
      root.schemeColorsCache = {};
      root.cacheVersion++;
    }
  }

  function saveToSchemeFile() {
    var name = Settings.data.colorSchemes.predefinedScheme;
    if (!name) return;

    var schemeData = currentSchemeData ? JSON.parse(JSON.stringify(currentSchemeData)) : {};

    var colorKeys = ["mPrimary", "mOnPrimary", "mSecondary", "mOnSecondary", "mTertiary", "mOnTertiary", "mError", "mOnError", "mSurface", "mOnSurface", "mSurfaceVariant", "mOnSurfaceVariant", "mOutline", "mShadow", "mHover", "mOnHover"];

    var colors = {};
    for (var i = 0; i < colorKeys.length; i++) {
      colors[colorKeys[i]] = writeAdapter[colorKeys[i]].toString();
    }

    if (schemeData.dark !== undefined || schemeData.light !== undefined) {
      var variantKey = Settings.data.colorSchemes.darkMode ? "dark" : "light";
      if (schemeData[variantKey]) {
        for (var key in colors) {
          schemeData[variantKey][key] = colors[key];
        }
      }
    }

    for (var key in colors) {
      schemeData[key] = colors[key];
    }

    var savePath = getSchemeUserPath(name);
    if (!savePath) return;

    var dir = savePath.substring(0, savePath.lastIndexOf("/"));
    Quickshell.execDetached(["mkdir", "-p", dir]);

    schemeWriter.path = "";
    schemeWriter.path = savePath;
    schemeWriter.setText(JSON.stringify(schemeData, null, 2));

    ColorSchemeService.loadColorSchemes();
  }

  FileView {
    id: colorsFileWriter
    path: ""
    printErrors: false
    JsonAdapter {
      id: writeAdapter
      property color mPrimary: "#000000"
      property color mOnPrimary: "#000000"
      property color mSecondary: "#000000"
      property color mOnSecondary: "#000000"
      property color mTertiary: "#000000"
      property color mOnTertiary: "#000000"
      property color mError: "#000000"
      property color mOnError: "#000000"
      property color mSurface: "#000000"
      property color mOnSurface: "#000000"
      property color mSurfaceVariant: "#000000"
      property color mOnSurfaceVariant: "#000000"
      property color mOutline: "#000000"
      property color mShadow: "#000000"
      property color mHover: "#000000"
      property color mOnHover: "#000000"
    }
  }

  FileView {
    id: schemeReader
    path: ""
    printErrors: false
    onLoaded: {
      try {
        currentSchemeData = JSON.parse(text());
      } catch (e) {
        Logger.e("CustomSubTab", "Failed to parse scheme:", e);
        currentSchemeData = null;
      }
    }
  }

  FileView {
    id: schemeWriter
    path: ""
    printErrors: false
  }

  function getScreen() {
    return PanelService.openedPanel?.screen || SettingsPanelService.settingsWindow?.screen || PanelService.findScreenForPanels();
  }

  function extractSchemeName(schemePath) {
    var pathParts = schemePath.split("/");
    var filename = pathParts[pathParts.length - 1];
    var schemeName = filename.replace(".json", "");
    if (schemeName === "Noctalia-default") schemeName = "Noctalia (default)";
    else if (schemeName === "Noctalia-legacy") schemeName = "Noctalia (legacy)";
    else if (schemeName === "Tokyo-Night") schemeName = "Tokyo Night";
    else if (schemeName === "Rosepine") schemeName = "Rose Pine";
    return schemeName;
  }

  function getSchemeColor(schemeName, colorKey) {
    var _ = cacheVersion;
    if (schemeColorsCache[schemeName]) {
      var entry = schemeColorsCache[schemeName];
      var variant = entry;
      if (entry.dark || entry.light) {
        variant = Settings.data.colorSchemes.darkMode ? (entry.dark || entry.light) : (entry.light || entry.dark);
      }
      if (variant && variant[colorKey]) return variant[colorKey];
    }
    if (colorKey === "mSurface") return Color.mSurfaceVariant;
    if (colorKey === "mPrimary") return Color.mPrimary;
    if (colorKey === "mSecondary") return Color.mSecondary;
    if (colorKey === "mTertiary") return Color.mTertiary;
    if (colorKey === "mError") return Color.mError;
    return Color.mOnSurfaceVariant;
  }

  function schemeLoaded(schemeName, jsonData) {
    var value = jsonData || {};
    schemeColorsCache[schemeName] = value;
    cacheVersion++;
  }

  function updateColor(colorKey, newColor) {
    writeAdapter.mPrimary = Color.mPrimary;
    writeAdapter.mOnPrimary = Color.mOnPrimary;
    writeAdapter.mSecondary = Color.mSecondary;
    writeAdapter.mOnSecondary = Color.mOnSecondary;
    writeAdapter.mTertiary = Color.mTertiary;
    writeAdapter.mOnTertiary = Color.mOnTertiary;
    writeAdapter.mError = Color.mError;
    writeAdapter.mOnError = Color.mOnError;
    writeAdapter.mSurface = Color.mSurface;
    writeAdapter.mOnSurface = Color.mOnSurface;
    writeAdapter.mSurfaceVariant = Color.mSurfaceVariant;
    writeAdapter.mOnSurfaceVariant = Color.mOnSurfaceVariant;
    writeAdapter.mOutline = Color.mOutline;
    writeAdapter.mShadow = Color.mShadow;
    writeAdapter.mHover = Color.mHover;
    writeAdapter.mOnHover = Color.mOnHover;

    writeAdapter[colorKey] = newColor;

    var path = Settings.configDir + "colors.json";
    colorsFileWriter.path = "";
    colorsFileWriter.path = path;
    colorsFileWriter.writeAdapter();
  }

  function applyColors() {
    var path = Settings.configDir + "colors.json";
    colorsFileWriter.path = "";
    colorsFileWriter.path = path;
    colorsFileWriter.writeAdapter();

    saveToSchemeFile();

    ToastService.showNotice("Custom Colors", "Saved to " + activeSchemeName, "settings-color-scheme");
  }

  Item {
    id: fileLoaders
    visible: false

    Repeater {
      model: ColorSchemeService.schemes
      delegate: Item {
        FileView {
          path: modelData
          blockLoading: false
          onLoaded: {
            var schemeName = root.extractSchemeName(path);
            try {
              var jsonData = JSON.parse(text());
              root.schemeLoaded(schemeName, jsonData);
            } catch (e) {
              Logger.w("ColorsSubTab", "Failed to parse JSON for scheme:", schemeName, e);
              root.schemeLoaded(schemeName, null);
            }
          }
        }
      }
    }
  }

  Component.onCompleted: {
    refreshFromCurrentScheme();
  }

  Component {
    id: colorPickerComponent
    NColorPickerDialog {}
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL

    NText {
      text: "Scheme: " + activeSchemeName
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      Layout.fillWidth: true
      elide: Text.ElideRight
    }

    NButton {
      text: "Apply Colors"
      onClicked: root.applyColors()
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
  }

  NHeader {
    label: "Predefined Schemes"
    Layout.bottomMargin: Style.marginM
  }

  GridLayout {
    columns: 2
    rowSpacing: Style.marginM
    columnSpacing: Style.marginM
    Layout.fillWidth: true

    Repeater {
      model: ColorSchemeService.schemes

      Rectangle {
        id: schemeItem
        property string schemePath: modelData
        property string schemeName: root.extractSchemeName(modelData)
        opacity: enabled ? 1.0 : 0.6
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        height: 50 * Style.uiScaleRatio
        radius: Style.radiusS
        color: root.getSchemeColor(schemeName, "mSurface")
        border.width: Style.borderL
        border.color: {
          if ((Settings.data.colorSchemes.predefinedScheme === schemeName) && schemeItem.enabled) return Color.mSecondary;
          if (itemMouseArea.containsMouse) return Color.mHover;
          return Color.mOutline;
        }

        RowLayout {
          id: scheme
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginS

          NText {
            text: schemeItem.schemeName
            pointSize: Style.fontSizeS
            color: Color.mOnSurface
            Layout.fillWidth: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 1
          }

          property int diameter: 16 * Style.uiScaleRatio

          Rectangle { width: scheme.diameter; height: scheme.diameter; radius: scheme.diameter * 0.5; color: root.getSchemeColor(schemeItem.schemeName, "mPrimary") }
          Rectangle { width: scheme.diameter; height: scheme.diameter; radius: scheme.diameter * 0.5; color: root.getSchemeColor(schemeItem.schemeName, "mSecondary") }
          Rectangle { width: scheme.diameter; height: scheme.diameter; radius: scheme.diameter * 0.5; color: root.getSchemeColor(schemeItem.schemeName, "mTertiary") }
          Rectangle { width: scheme.diameter; height: scheme.diameter; radius: scheme.diameter * 0.5; color: root.getSchemeColor(schemeItem.schemeName, "mError") }
        }

        MouseArea {
          id: itemMouseArea
          anchors.fill: parent
          enabled: schemeItem.enabled
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Settings.data.colorSchemes.predefinedScheme = schemeItem.schemeName;
            ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme);
          }
        }

        Rectangle {
          visible: (Settings.data.colorSchemes.predefinedScheme === schemeItem.schemeName) && schemeItem.enabled
          anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: 0; anchors.topMargin: -3
          width: 20; height: 20; radius: Math.min(Style.radiusL, width / 2)
          color: Color.mSecondary; border.width: Style.borderS; border.color: Color.mOnSecondary
          NIcon { icon: "check"; pointSize: Style.fontSizeXS; color: Color.mOnSecondary; anchors.centerIn: parent }
        }

        Behavior on border.color { ColorAnimation { duration: Style.animationNormal } }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
  }

  NHeader {
    label: "Custom Colors"
    description: "Manually adjust individual color values"
    Layout.bottomMargin: Style.marginM
  }

  Repeater {
    model: colorCategories

    delegate: ColumnLayout {
      required property var modelData
      spacing: Style.marginL
      Layout.fillWidth: true
      Layout.bottomMargin: Style.margin2L

      NHeader {
        label: modelData.name
        Layout.bottomMargin: Style.marginM
      }

      Repeater {
        model: modelData.keys

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
              color: Color[modelData.key]
              border.color: Color.mOutline
              border.width: Style.borderS
            }

            NText {
              text: modelData.label
              Layout.fillWidth: true
            }

            NText {
              text: Color[modelData.key].toString().toUpperCase()
              family: Settings.data.ui.fontFixed
              color: Color.mOnSurfaceVariant
            }

            NIconButton {
              icon: "color-picker"
              onClicked: {
                var colorKey = modelData.key;
                var dialog = colorPickerComponent.createObject(root, {
                  selectedColor: Color[colorKey],
                  parent: Overlay.overlay,
                  screen: root.getScreen()
                });
                dialog.colorSelected.connect(function(color) {
                  root.updateColor(colorKey, color);
                });
                dialog.open();
              }
            }

            NIconButton {
              icon: "copy"
              tooltipText: "Copy color code"
              onClicked: {
                root.copiedColor = Color[modelData.key].toString();
                Quickshell.execDetached(["wl-copy", root.copiedColor]);
                ToastService.showNotice("Copied", modelData.label + ": " + Color[modelData.key].toString(), "clipboard");
              }
            }

            NIconButton {
              icon: "clipboard-plus"
              tooltipText: "Paste color code"
              enabled: root.copiedColor.length > 0
              onClicked: {
                if (root.copiedColor)
                  root.updateColor(modelData.key, root.copiedColor);
              }
            }
          }
        }
      }
    }
  }

}
