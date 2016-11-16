//
//  ViewController.swift
//  SystemMonitor
//
//  Created by Jinhong Kim on 11/16/16.
//  Copyright © 2016 JHK. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var ipTextField: NSTextField!
    
    
    fileprivate var timer: Timer?
    
    fileprivate var ipAddrs = Dictionary<String, String>()
    
    fileprivate var ipAddrsString: String {
        let ips = ipAddrs.reduce("") {
            $0 + "\($1.key) : \($1.value)\n"
        }
        
        return ips.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    fileprivate var ipAddrFileURL: URL {
        let iCloudDirURL: URL
        if #available(OSX 10.12, *) {
            iCloudDirURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        } else {
            iCloudDirURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.deletingLastPathComponent().appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs"))!
        }
        
        return iCloudDirURL.appendingPathComponent("ipaddr.txt")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let ips = loadPrevIPAddresses() {
            ipAddrs = ips
            ipTextField.stringValue = ipAddrsString
        }
        
        
        setupTimer()
    }
    
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}


extension ViewController {
    
    fileprivate func setupTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
    }
    
    
    public func handleTimer(_ sender: Timer) {
        guard let curIPAddrs = currentIPAddresses() else {
            return
        }
        
        if ipAddrs != curIPAddrs {
            ipAddrs = curIPAddrs
            
            ipTextField.stringValue = ipAddrsString
            
            if saveIPAddresses() == false {
                print("ip addr file writing failed")
            }
        }
    }
    
}


extension ViewController {
    
    fileprivate func loadPrevIPAddresses() -> Dictionary<String, String>? {
        guard let prevIPAddrs = NSDictionary(contentsOf: ipAddrFileURL) else {
            return nil
        }
        
        
        var ips = Dictionary<String, String>()
        
        for (serviceName, ipAddr) in prevIPAddrs {
            if let service = serviceName as? String, let ip = ipAddr as? String {
                ips[service] = ip
            }
        }
        
        return ips
    }
    
    
    fileprivate func currentIPAddresses() -> Dictionary<String, String>? {
        guard let services = System.networkServices() else {
            return nil
        }
        
        
        var ips = Dictionary<String, String>()
        
        for service in services {
            if let ip = System.ipAddress(of: service) {
                ips[service] = ip
            }
        }
        
        return ips
    }
    
    
    fileprivate func saveIPAddresses() -> Bool {
        let ips = NSDictionary(dictionary: ipAddrs)
        
        if ips.write(to: ipAddrFileURL, atomically: true) == false {
            return false
        }
        
        return true
    }
    
}
