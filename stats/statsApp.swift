//
//  statsApp.swift
//  stats
//
//  Created by Eren Esmer on 7/28/25.
//

import SwiftUI
import AppKit

@main
struct statsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var monitor = SystemMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 320)
        
        if let button = statusItem.button {
            let hostingView = NSHostingView(rootView: MenuBarView(monitor: monitor))
            hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 22)
            button.addSubview(hostingView)
            button.frame = hostingView.frame
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

struct MenuBarView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        HStack(spacing: 12) {
            MiniChart(
                label: "CPU",
                value: monitor.cpuUsage,
                history: monitor.cpuHistory,
                color: .blue
            )
            
            MiniChart(
                label: "MEM",
                value: monitor.memoryUsage,
                history: monitor.memoryHistory,
                color: .green
            )
            
            NetworkChart(
                uploadSpeed: monitor.uploadSpeed,
                downloadSpeed: monitor.downloadSpeed,
                uploadHistory: monitor.uploadHistory,
                downloadHistory: monitor.downloadHistory
            )
        }
        .frame(width: 320, height: 22)
    }
}

struct MiniChart: View {
    let label: String
    let value: Double
    let history: [Double]
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .light))
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 50, height: 16)
                
                GeometryReader { geometry in
                    Path { path in
                        guard history.count > 1 else { return }
                        
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(max(history.count - 1, 1))
                        
                        for (index, value) in history.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value / 100.0) * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, lineWidth: 1.5)
                }
                .frame(width: 50, height: 16)
            }
            
            Text(String(format: "%.0f%%", value))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(valueColor(for: value))
                .frame(width: 25, alignment: .trailing)
        }
    }
    
    private func valueColor(for usage: Double) -> Color {
        switch usage {
        case 0..<50:
            return .primary
        case 50..<80:
            return .orange
        default:
            return .red
        }
    }
}

struct NetworkChart: View {
    let uploadSpeed: Double
    let downloadSpeed: Double
    let uploadHistory: [Double]
    let downloadHistory: [Double]
    
    var body: some View {
        HStack(spacing: 4) {
            Text("NET")
                .font(.system(size: 8, weight: .light))
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 50, height: 16)
                
                GeometryReader { geometry in
                    let maxValue = max(uploadHistory.max() ?? 1, downloadHistory.max() ?? 1, 1)
                    
                    Path { path in
                        guard uploadHistory.count > 1 else { return }
                        
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(max(uploadHistory.count - 1, 1))
                        
                        for (index, value) in uploadHistory.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value / maxValue) * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.red, lineWidth: 1.5)
                    
                    Path { path in
                        guard downloadHistory.count > 1 else { return }
                        
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(max(downloadHistory.count - 1, 1))
                        
                        for (index, value) in downloadHistory.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value / maxValue) * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 1.5)
                }
                .frame(width: 50, height: 16)
            }
            
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 7))
                        .foregroundColor(.red)
                    Text(formatBytes(uploadSpeed))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 7))
                        .foregroundColor(.blue)
                    Text(formatBytes(downloadSpeed))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                }
            }
            .frame(width: 55)
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B/s", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0f KB/s", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytes / (1024 * 1024))
        } else {
            return String(format: "%.1f GB/s", bytes / (1024 * 1024 * 1024))
        }
    }
}
