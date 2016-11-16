//
//  ViewController.swift
//  SystemMonitor
//
//  Created by Jinhong Kim on 11/16/16.
//  Copyright © 2016 JHK. All rights reserved.
//

import Cocoa


var iCloudDirURL: URL {
    if #available(OSX 10.12, *) {
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
    } else {
        return (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.deletingLastPathComponent().appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs"))!
    }
}


class ViewController: NSViewController {
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var ipTextField: NSTextField!
    
    @IBOutlet weak var tdmComboBox: NSComboBox!
    
    
    fileprivate var timer: Timer?
    
    
    // ip addr
    fileprivate var ipAddrs = Dictionary<String, String>()
    
    fileprivate var ipAddrsString: String {
        let ips = ipAddrs.reduce("") {
            $0 + "\($1.key) : \($1.value)\n"
        }
        
        return ips.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    fileprivate var ipAddrFileURL: URL {
        return iCloudDirURL.appendingPathComponent("ipaddr.txt")
    }
    
    
    // command
    fileprivate var commands = Dictionary<String, String>()
    
    fileprivate var commandFileURL: URL {
        return iCloudDirURL.appendingPathComponent("command.txt")
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


// MARK: UI Actions


extension ViewController: NSTabViewDelegate {

    @IBAction func handleSendButton(_ sender: NSButton) {
        if saveCommands() == false {
            print("save command failed")
        }
    }
 
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let itemLabel = tabViewItem?.label else {
            return
        }
        
        switch itemLabel {
            case "Command":
                setupCommand()
                break
            
            default:
                break
        }
    }

}


// MARK: Timer


extension ViewController {
    
    fileprivate func setupTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
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


// MARK: IP Address


extension ViewController {
    
    fileprivate func loadPrevIPAddresses() -> Dictionary<String, String>? {
        guard let prevIPAddrs = NSDictionary(contentsOf: ipAddrFileURL) else {
            return nil
        }
        
        return prevIPAddrs as? Dictionary
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


// MARK: Command


extension ViewController {

    func setupCommand() {
        if let cmds = loadPrevCommand() {
            commands = cmds
        }
        
        updateCommandView()
    }
    
    
    func loadPrevCommand() -> Dictionary<String, String>? {
        guard let prevCommands = NSDictionary(contentsOf: commandFileURL) else {
            return nil
        }
        
        return prevCommands as? Dictionary
   }
    
    
    func updateCommandView() {
        if let tdmCommand = commands["TDM"] {
            tdmComboBox.selectItem(withObjectValue: tdmCommand)
        }
    }
    
    
    func saveCommands() -> Bool {
        if let tdmCommand = tdmComboBox.objectValueOfSelectedItem as? String, tdmCommand.isEmpty == false {
            commands["TDM"] = tdmCommand
        }
        
        if commands.isEmpty == false {
            if (commands as NSDictionary).write(to: commandFileURL, atomically: true) == false {
                return false
            }
        }
        
        return true
    }
    
}
