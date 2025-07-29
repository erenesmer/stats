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
        statusItem = NSStatusBar.system.statusItem(withLength: 230)
        
        if let button = statusItem.button {
            let hostingView = NSHostingView(rootView: MenuBarView(monitor: monitor))
            hostingView.frame = NSRect(x: 0, y: 0, width: 230, height: 22)
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
            CPUChart(
                value: monitor.cpuUsage,
                history: monitor.cpuHistory
            )
            
            MemoryBar(
                usedGB: monitor.memoryUsedGB,
                totalGB: monitor.memoryTotalGB,
                percentage: monitor.memoryUsage
            )
            
            NetworkChart(
                uploadSpeed: monitor.uploadSpeed,
                downloadSpeed: monitor.downloadSpeed,
                uploadHistory: monitor.uploadHistory,
                downloadHistory: monitor.downloadHistory
            )
        }
        .frame(width: 230, height: 22)
    }
}

struct CPUChart: View {
    let value: Double
    let history: [Double]
    
    var body: some View {
        HStack(spacing: 4) {
            VStack(spacing: -2) {
                Text("C")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white)
                Text("P")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white)
                Text("U")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
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
                    .stroke(Color.blue, lineWidth: 1.5)
                }
                .frame(width: 50, height: 16)
                .mask(RoundedRectangle(cornerRadius: 4))
            }
            
            Text(String(format: "%.0f%%", value))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 20)
        }
    }
}

struct MemoryBar: View {
    let usedGB: Double
    let totalGB: Double
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 4) {
            VStack(spacing: -2) {
                Text("M")
                    .font(.system(size: 6, weight: .medium))
                    .foregroundColor(.white)
                Text("E")
                    .font(.system(size: 6, weight: .medium))
                    .foregroundColor(.white)
                Text("M")
                    .font(.system(size: 6, weight: .medium))
                    .foregroundColor(.white)
            }
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.3))
                    .padding(0.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                    )
                    .frame(width: 8, height: 16)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange)
                    .frame(width: 6, height: 16 * (percentage / 100))
            }
            
            Text(String(format: "%.1fGB", usedGB))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
        }
    }
}

#Preview {
    MemoryBar(usedGB: 12.4, totalGB: 16.0, percentage: 50)
    CPUChart(value: 34.3, history: [])
}

struct NetworkChart: View {
    let uploadSpeed: Double
    let downloadSpeed: Double
    let uploadHistory: [Double]
    let downloadHistory: [Double]
    
    var body: some View {
        HStack(spacing: 4) {
//            VStack(spacing: -2) {
//                Text("N")
//                    .font(.system(size: 7, weight: .medium))
//                    .foregroundColor(.white)
//                Text("E")
//                    .font(.system(size: 7, weight: .medium))
//                    .foregroundColor(.white)
//                Text("T")
//                    .font(.system(size: 7, weight: .medium))
//                    .foregroundColor(.white)
//            }
            
//            ZStack {
//                RoundedRectangle(cornerRadius: 4)
//                    .fill(Color.black.opacity(0.3))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 4)
//                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
//                    )
//                    .frame(width: 50, height: 16)
                
//                GeometryReader { geometry in
//                    let maxValue = max(uploadHistory.max() ?? 1, downloadHistory.max() ?? 1, 1)
//                    
//                    Path { path in
//                        guard uploadHistory.count > 1 else { return }
//                        
//                        let width = geometry.size.width
//                        let height = geometry.size.height
//                        let stepX = width / CGFloat(max(uploadHistory.count - 1, 1))
//                        
//                        for (index, value) in uploadHistory.enumerated() {
//                            let x = CGFloat(index) * stepX
//                            let y = height - (CGFloat(value / maxValue) * height)
//                            
//                            if index == 0 {
//                                path.move(to: CGPoint(x: x, y: y))
//                            } else {
//                                path.addLine(to: CGPoint(x: x, y: y))
//                            }
//                        }
//                    }
//                    .stroke(Color.red, lineWidth: 1.5)
//                    
//                    Path { path in
//                        guard downloadHistory.count > 1 else { return }
//                        
//                        let width = geometry.size.width
//                        let height = geometry.size.height
//                        let stepX = width / CGFloat(max(downloadHistory.count - 1, 1))
//                        
//                        for (index, value) in downloadHistory.enumerated() {
//                            let x = CGFloat(index) * stepX
//                            let y = height - (CGFloat(value / maxValue) * height)
//                            
//                            if index == 0 {
//                                path.move(to: CGPoint(x: x, y: y))
//                            } else {
//                                path.addLine(to: CGPoint(x: x, y: y))
//                            }
//                        }
//                    }
//                    .stroke(Color.blue, lineWidth: 1.5)
//                }
//                .frame(width: 50, height: 16)
//                .mask(RoundedRectangle(cornerRadius: 4))
//            }
            
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 2) {
                    Text(formatBytes(uploadSpeed))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 7))
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 2) {
                    Text(formatBytes(downloadSpeed))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 7))
                        .foregroundColor(.blue)
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
