import Foundation
import os

public enum QLLog {
    public static let app      = Logger(subsystem: "app.quill.ios", category: "app")
    public static let obsidian = Logger(subsystem: "app.quill.ios", category: "obsidian")
    public static let widget   = Logger(subsystem: "app.quill.ios", category: "widget")
    public static let fail     = Logger(subsystem: "app.quill.ios", category: "fail")
}
