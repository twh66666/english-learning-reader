import SwiftUI

struct ReaderSettingsView: View {
    @Binding var settings: ReaderSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("文字") {
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $settings.fontSize, in: 14...32, step: 1)
                        Image(systemName: "textformat.size.larger")
                    }
                    HStack {
                        Text("行距")
                        Slider(value: $settings.lineSpacing, in: 2...16, step: 1)
                    }
                }

                Section("背景") {
                    Picker("主题", selection: $settings.theme) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("亮度") {
                    HStack {
                        Image(systemName: "sun.min")
                        Slider(value: $settings.brightness, in: 0.05...1.0, step: 0.01)
                        Image(systemName: "sun.max")
                    }
                }

                Section("翻页") {
                    Toggle("音量键翻页", isOn: $settings.volumePagingEnabled)
                }
            }
            .navigationTitle("阅读设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
