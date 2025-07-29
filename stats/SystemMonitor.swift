//
//  SystemMonitor.swift
//  stats
//
//  Created by Eren Esmer on 7/28/25.
//

import Foundation
import Darwin
import SystemConfiguration

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    @Published var downloadSpeed: Double = 0.0
    @Published var cpuHistory: [Double] = []
    @Published var memoryHistory: [Double] = []
    @Published var uploadHistory: [Double] = []
    @Published var downloadHistory: [Double] = []
    
    private let maxHistoryCount = 50
    private var timer: Timer?
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private var previousNetworkStats: NetworkStats?
    private var lastUpdateTime: Date?
    
    struct NetworkStats {
        let bytesIn: UInt64
        let bytesOut: UInt64
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStats() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
        
        let networkSpeeds = getNetworkSpeeds()
        downloadSpeed = networkSpeeds.download
        uploadSpeed = networkSpeeds.upload
        
        cpuHistory.append(cpuUsage)
        memoryHistory.append(memoryUsage)
        uploadHistory.append(uploadSpeed)
        downloadHistory.append(downloadSpeed)
        
        if cpuHistory.count > maxHistoryCount {
            cpuHistory.removeFirst()
        }
        
        if memoryHistory.count > maxHistoryCount {
            memoryHistory.removeFirst()
        }
        
        if uploadHistory.count > maxHistoryCount {
            uploadHistory.removeFirst()
        }
        
        if downloadHistory.count > maxHistoryCount {
            downloadHistory.removeFirst()
        }
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        defer {
            if let previousCPUInfo = previousCPUInfo {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), vm_size_t(previousCPUInfoCount))
            }
            previousCPUInfo = cpuInfo
            previousCPUInfoCount = numCpuInfo
        }
        
        guard let previousCPUInfo = previousCPUInfo else { return 0.0 }
        
        var totalUsage: Double = 0.0
        
        for i in 0..<Int(numCpus) {
            let cpuLoad = cpuInfo.advanced(by: Int(CPU_STATE_MAX) * i)
            let previousCpuLoad = previousCPUInfo.advanced(by: Int(CPU_STATE_MAX) * i)
            
            let userDiff = Double(cpuLoad[Int(CPU_STATE_USER)] - previousCpuLoad[Int(CPU_STATE_USER)])
            let systemDiff = Double(cpuLoad[Int(CPU_STATE_SYSTEM)] - previousCpuLoad[Int(CPU_STATE_SYSTEM)])
            let idleDiff = Double(cpuLoad[Int(CPU_STATE_IDLE)] - previousCpuLoad[Int(CPU_STATE_IDLE)])
            let niceDiff = Double(cpuLoad[Int(CPU_STATE_NICE)] - previousCpuLoad[Int(CPU_STATE_NICE)])
            
            let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
            
            if totalTicks > 0 {
                let usage = ((userDiff + systemDiff + niceDiff) / totalTicks) * 100.0
                totalUsage += usage
            }
        }
        
        return totalUsage / Double(numCpus)
    }
    
    private func getMemoryUsage() -> Double {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        let pageSize = vm_kernel_page_size
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        let usedMemory = (UInt64(info.active_count) + UInt64(info.wire_count)) * UInt64(pageSize)
        
        return Double(usedMemory) / Double(totalMemory) * 100.0
    }
    
    private func getNetworkSpeeds() -> (download: Double, upload: Double) {
        let currentStats = getNetworkStats()
        let currentTime = Date()
        
        guard let previousStats = previousNetworkStats,
              let lastTime = lastUpdateTime else {
            previousNetworkStats = currentStats
            lastUpdateTime = currentTime
            return (0, 0)
        }
        
        let timeDiff = currentTime.timeIntervalSince(lastTime)
        guard timeDiff > 0 else { return (0, 0) }
        
        let downloadBytes = Double(currentStats.bytesIn - previousStats.bytesIn)
        let uploadBytes = Double(currentStats.bytesOut - previousStats.bytesOut)
        
        let downloadSpeed = downloadBytes / timeDiff
        let uploadSpeed = uploadBytes / timeDiff
        
        previousNetworkStats = currentStats
        lastUpdateTime = currentTime
        
        return (downloadSpeed, uploadSpeed)
    }
    
    private func getNetworkStats() -> NetworkStats {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var totalBytesIn: UInt64 = 0
        var totalBytesOut: UInt64 = 0
        
        guard getifaddrs(&ifaddr) == 0 else {
            return NetworkStats(bytesIn: 0, bytesOut: 0)
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let name = String(cString: (interface?.ifa_name)!)
            
            if name.hasPrefix("lo") { continue }
            
            if let data = interface?.ifa_data {
                let networkData = data.assumingMemoryBound(to: if_data.self)
                totalBytesIn += UInt64(networkData.pointee.ifi_ibytes)
                totalBytesOut += UInt64(networkData.pointee.ifi_obytes)
            }
        }
        
        return NetworkStats(bytesIn: totalBytesIn, bytesOut: totalBytesOut)
    }
}