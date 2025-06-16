import Foundation
import AppKit

func setIcon(forFile filePath: String, withIcon iconPath: String) {
    let fileURL = URL(fileURLWithPath: filePath)
    let iconURL = URL(fileURLWithPath: iconPath)

    guard let iconImage = NSImage(contentsOf: iconURL) else {
        print("Failed to load icon image.")
        return
    }

    do {
        try NSWorkspace.shared.setIcon(iconImage, forFile: filePath, options: [])
        print("Icon set successfully.")
    } catch {
        print("Failed to set icon: \(error)")
    }
}

if CommandLine.argc < 3 {
    print("Usage: change_icon <webloc_file> <icon_file>")
    exit(1)
}

let weblocFile = CommandLine.arguments[1]
let iconFile = CommandLine.arguments[2]

setIcon(forFile: weblocFile, withIcon: iconFile)