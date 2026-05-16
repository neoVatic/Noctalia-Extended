import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  readonly property string roundingFile: Quickshell.env("HOME") + "/.config/niri/noctalia-windows.kdl"
  property bool roundingEnabled: false

  FileView {
    id: reader
    path: ""
    printErrors: false
    onLoaded: {
      var content = text();
      var enabled = content.indexOf("geometry-corner-radius") >= 0;
      if (enabled !== root.roundingEnabled) {
        root.roundingEnabled = enabled;
        Settings.data.general.roundedCornersEnabled = enabled;
        Settings.data.general.radiusRatio = enabled ? 1 : 0;
        Settings.data.general.iRadiusRatio = enabled ? 1 : 0;

        var monitors = Settings.data.desktopWidgets.monitorWidgets;
        if (monitors) {
          for (var i = 0; i < monitors.length; i++) {
            var list = monitors[i].widgets;
            if (list) {
              for (var j = 0; j < list.length; j++) {
                if (list[j].roundedCorners !== undefined) {
                  list[j].roundedCorners = enabled;
                }
              }
            }
          }
        }

        Settings.saveImmediate();
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      reader.path = "";
      reader.path = root.roundingFile;
    }
  }

  Component.onCompleted: {
    reader.path = root.roundingFile;
  }
}
