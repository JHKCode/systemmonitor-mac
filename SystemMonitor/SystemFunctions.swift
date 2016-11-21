//
//  SystemFunctions.swift
//  iCloudMonitor
//
//  Created by Jinhong Kim on 11/11/16.
//  Copyright © 2016 JHK. All rights reserved.
//

import Foundation


struct System {
    
    static func execute(_ path: String, arguments: [String] = [""]) -> String? {
        let pipe = Pipe()
        let task = Process()
        
        task.launchPath = path
        task.arguments = arguments
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        return String(data: data, encoding: .utf8)
    }
    
    
    static func ipAddresses() -> [(name : String, addr: String)] {
        var addresses = [(name : String, addr: String)]()
        
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) != 0 {
            return []
        }
        
        guard let firstAddr = ifaddr else {
            return []
        }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            if let addr = ptr.pointee.ifa_addr {
                
                if (flags & (IFF_UP|IFF_RUNNING) != 0) && (flags & IFF_LOOPBACK == 0) {
                    switch Int32(addr.pointee.sa_family) {
                        /*
                        case AF_LINK:
                            let dl = UnsafePointer<sockaddr_dl>(addr)
                            let lladdr = UnsafeBufferPointer(start: UnsafePointer<Int8>(dl) + 8 + Int(dl.pointee.sdl_nlen),
                                                             count: Int(dl.pointee.sdl_alen))
                            if lladdr.count == 6 {
                                nameToMac[name] = lladdr.map { String(format:"%02hhx", $0)}.joined(separator: ":")
                            }
                         */
                        //case AF_INET6:
                        case AF_INET:
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if (getnameinfo(addr,
                                            socklen_t(addr.pointee.sa_len),
                                            &hostname,
                                            socklen_t(hostname.count),
                                            nil,
                                            socklen_t(0),
                                            NI_NUMERICHOST) == 0) {
                                addresses.append((name: String(cString: ptr.pointee.ifa_name), addr: String(cString: hostname)))
                            }
                        default:
                            break
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        
        return addresses
    }
}


extension System {
    
    static func networkServices() -> [String]? {
        guard let result = System.execute("/usr/sbin/networksetup", arguments: ["-listallnetworkservices"]) else {
            return nil
        }
        
        let networks = ["Ethernet", "Wi-Fi"]
        
        let services: [String] = result.components(separatedBy: "\n").flatMap {
            if networks.contains($0) {
                return $0
            }
            
            return nil
        }
        
        return services
    }
    
    
    static func ipAddress(of service: String) -> String? {
        guard let result = System.execute("/usr/sbin/networksetup", arguments: ["-getinfo", service]) else {
            return nil
        }
        
        
        for info in result.components(separatedBy: "\n") {
            if let _ = info.range(of: "IP address: ") {
                return info.replacingOccurrences(of: "IP address: ", with: "")
            }
        }
        
        return nil
    }
    
}
