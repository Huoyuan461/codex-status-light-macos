import Foundation

enum DisplayMode: String, CaseIterable, Identifiable {
    case notch
    case desktop
    case menuBar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notch: "刘海旁"
        case .desktop: "桌面任意位置"
        case .menuBar: "仅菜单栏"
        }
    }

    var detail: String {
        switch self {
        case .notch: "固定在屏幕顶部刘海右侧"
        case .desktop: "悬浮在所有窗口上方，可自由拖动"
        case .menuBar: "只保留右上角菜单栏状态灯"
        }
    }
}
