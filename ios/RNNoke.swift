import Foundation

@objc(RNNoke)
class RNNoke : RCTEventEmitter, NokeDeviceManagerDelegate {
    var currentNoke: NokeDevice?
    
    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {
            
        case .nokeDeviceConnectionStateDiscovered:
            NokeDeviceManager.shared().stopScan()
            NokeDeviceManager.shared().connectToNokeDevice(noke)
            
            sendEvent(withName: "onNokeDiscovered", body: ["name": noke.name, "mac": noke.mac])
            break
        case .nokeDeviceConnectionStateConnected:
            print(noke.session!)
            currentNoke = noke
            
            sendEvent(withName: "onNokeConnected", body: ["name": noke.name, "mac": noke.mac])
            break
        case .nokeDeviceConnectionStateSyncing:
            
            sendEvent(withName: "onNokeConnecting", body: ["name": noke.name, "mac": noke.mac])
            break
        case .nokeDeviceConnectionStateUnlocked:
            
            sendEvent(withName: "onNokeUnlocked", body: ["name": noke.name, "mac": noke.mac])
            break
        case .nokeDeviceConnectionStateDisconnected:
            NokeDeviceManager.shared().cacheUploadQueue()
//            NokeDeviceManager.shared().startScanForNokeDevices()
            currentNoke = nil
            
            sendEvent(withName: "onNokeDisconnected", body: ["name": noke.name, "mac": noke.mac])
            break
        default:
            
            sendEvent(withName: "onError", body: ["message": "unrecognized state"])
            break
        }
    }
    
    func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        debugPrint("NOKE MANAGER ON")
        sendEvent(withName: "onError", body: ["code": 0,"mesage": message])
    }
    
    func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        var message: String = ""
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
//            NokeDeviceManager.shared().startScanForNokeDevices()
            message = "on"
            break
        case NokeManagerBluetoothState.poweredOff:
            debugPrint("NOKE MANAGER OFF")
            message = "off"
            break
        default:
            debugPrint("NOKE MANAGER UNSUPPORTED")
            message = "unsupported"
            break
        }
        sendEvent(withName: "onBluetoothStatusChanged", body: ["code": 0, "message": message])
    }
    
    // Export constants to use in your native module
    override func constantsToExport() -> [AnyHashable : Any]! {
        return ["AUTHOR": "linh_the_human"]
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc func startScan(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().startScanForNokeDevices()
        
        resolve(["status": true])
    }
    
    @objc func initiateNokeService(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().delegate = self
        
        resolve(["status": true])
    }
    
    @objc func addNokeDevice(
        _ data: Dictionary<String, String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        /**
         * name: "New Lock"
         * mac: "CB:BC:87:3B:CB:D7"
         * key: "9966eb079eabb129e7adbded88eab6c3
         * cmd: "0152843f00a2dec3515b000000000000000000ef"
         */
        let noke = NokeDevice.init(
            name: data["name"]! as String,
            mac: data["mac"]! as String
        )
        
        noke?.setOfflineValues(
            key: data["key"]! as String,
            command: data["cmd"]! as String
        )
        NokeDeviceManager.shared().addNoke(noke!)
        
        resolve(["status": true])
    }
    
    @objc func sendCommands(
        _ command: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        if(currentNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "mNokeService is null", error)
            return
        }
        currentNoke?.sendCommands(command)
        
        resolve(["name": currentNoke?.name, "mac": currentNoke?.mac])
    }
    
    @objc func offlineUnlock(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        var event: [String: Any] = [
            "name": currentNoke?.name ?? String(),
            "mac": currentNoke?.mac ?? String()
        ]
        if(currentNoke == nil) {
            event["success"] = false
        } else {
            currentNoke?.offlineUnlock()
            event["success"] = true
        }
        
        resolve(event)
    }
    
    @objc func removeAllNokes(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        
        NokeDeviceManager.shared().removeAllNoke()
        
        resolve([
            "status": true
            ])
    }
    
    @objc func removeNokeDevice(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        
        NokeDeviceManager.shared().removeNoke(mac: mac)
        
        resolve([
            "status": true
            ])
    }
    
    override func supportedEvents() -> [String]! {
        return [
            "onServiceConnected",
            "onServiceDisconnected",
            "onNokeDiscovered",
            "onNokeConnecting",
            "onNokeConnected",
            "onNokeSyncing",
            "onNokeUnlocked",
            "onNokeDisconnected",
            "onBluetoothStatusChanged",
            "onError"
        ]
    }
    
}
