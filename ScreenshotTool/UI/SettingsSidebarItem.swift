import Foundation

struct SettingsSidebarItem: Equatable, Identifiable, Hashable {
    let id: String
    let title: String
    let groupTitle: String
    let iconSystemName: String
    let description: String

    static let defaultItems: [SettingsSidebarItem] = [
        .init(id: "general", title: "通用", groupTitle: "基础", iconSystemName: "slider.horizontal.3", description: "后台驻留、菜单栏与启动行为"),
        .init(id: "appearance", title: "外观", groupTitle: "基础", iconSystemName: "circle.lefthalf.filled", description: "浅色、深色和跟随系统"),
        .init(id: "capture", title: "截图", groupTitle: "截图", iconSystemName: "camera.viewfinder", description: "捕获与输出"),
        .init(id: "annotation", title: "标注", groupTitle: "截图", iconSystemName: "pencil.tip", description: "默认样式与编辑行为"),
        .init(id: "input-method", title: "输入法规则", groupTitle: "输入法", iconSystemName: "globe", description: "全局默认与应用规则"),
        .init(id: "diagnostics", title: "权限与诊断", groupTitle: "其他", iconSystemName: "stethoscope", description: "系统权限与运行状态")
    ]
}
