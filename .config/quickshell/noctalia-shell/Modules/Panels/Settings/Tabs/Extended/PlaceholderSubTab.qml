import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import Quickshell
import Quickshell.Io

ColumnLayout {
  spacing: Style.marginL
  Layout.fillWidth: true
  Layout.topMargin: Style.marginL

  NToggle {
    id: gradientToggle
    label: "Niri Focus Ring Gradient"
    description: "Use a gradient instead of a solid color for the active window focus ring"
    checked: Settings.data.niriFocusGradient
    onToggled: checked => {
                  Settings.data.niriFocusGradient = checked;
                  Settings.saveImmediate();
                  applyGradient.running = true;
                }
  }

  Process {
    id: applyGradient
    command: ["python3", Quickshell.shellDir + "/Scripts/bash/toggle-niri-gradient.sh"]
  }

  Item { Layout.fillHeight: true }
}
