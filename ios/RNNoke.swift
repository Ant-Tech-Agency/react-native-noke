import Foundation

@objc(RNNoke)
class RNNoke : RCTEventEmitter, NokeDeviceManagerDelegate {
    var currentNoke: NokeDevice?
    var errMsg = ""
    var errCode = 301
    var lastEventCode = 0

    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        let body = createCommonEvents(noke: noke)
        switch state {

        case .nokeDeviceConnectionStateDiscovered:
            NokeDeviceManager.shared().stopScan()
            
            if(currentNoke?.mac != noke.mac) {
                NokeDeviceManager.shared().connectToNokeDevice(noke)
            }
            lastEventCode = 0
            sendEvent(withName: "onNokeDiscovered", body: body)
            break
        case .nokeDeviceConnectionStateConnecting:
            lastEventCode = 1
            sendEvent(withName: "onNokeConnecting", body: body)
            break
        case .nokeDeviceConnectionStateConnected:
            lastEventCode = 2
            sendEvent(withName: "onNokeConnected", body: body)
            break
        case .nokeDeviceConnectionStateSyncing:
            lastEventCode = 3
            sendEvent(withName: "onNokeSyncing", body: body)
            break
        case .nokeDeviceConnectionStateUnlocked:
            lastEventCode = 4
            sendEvent(withName: "onNokeUnlocked", body: body)
            break
        case .nokeDeviceConnectionStateDisconnected:
            NokeDeviceManager.shared().stopScan()
            lastEventCode = 5
            sendEvent(withName: "onNokeDisconnected", body: createCommonEvents(noke: noke))
            break
        }
    }

    func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        var eventMsg = message
        if(message != "") {
            eventMsg = errMsg
        }
        lastEventCode = 6
        sendEvent(withName: "onError", body: ["code": errCode,"message": eventMsg])
    }

    func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        var message = ""
        var code = 1
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            message = "on"
            code = 12
            errMsg = ""
            errCode = 301
            break
        case NokeManagerBluetoothState.poweredOff:
            message = "off"
            code = 10
            errMsg = "Bluetooth is disabled"
            errCode = 302
            break
        default:
            debugPrint("NOKE MANAGER UNSUPPORTED")
            message = "unsupported"
            code = -1
            break
        }
        sendEvent(withName: "onBluetoothStatusChanged", body: ["code": code, "message": message])
    }
    
    func getCurrentNoke(macAddress: String) -> NokeDevice? {
        let nokeDevices = NokeDeviceManager.shared().nokeDevices
        
        for noke in nokeDevices {
            if nokeDevices.contains(noke) {
                return noke
            }
        }
        
        return nil
    }
    
    func addNokeIfNeeded(nokeHashMap: NokeHashMap) -> NokeDevice? {
        let name = nokeHashMap.name
        let key = nokeHashMap.key
        let command = nokeHashMap.command
        let macAddress = nokeHashMap.macAddress
        
        var nokeDevice = getCurrentNoke(macAddress: macAddress)
        
        if(nokeDevice == nil) {
            nokeDevice = NokeDevice.init(name: name, mac: macAddress)
            NokeDeviceManager.shared().addNoke(nokeDevice!)
        }
        
        if(nokeDevice?.offlineKey == nil) {
            if(key != "" && command != "") {
                nokeDevice?.setOfflineValues(key: key, command: command)
            }
        }
        
        currentNoke = nokeDevice
        
        return nokeDevice
    }
    
    @objc func addNokeDevice(
        _ data: Dictionary<String, Any>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        let nokeHashMap = NokeHashMap.init(data: data)
        
        let nokeDevice = addNokeIfNeeded(nokeHashMap: nokeHashMap)
        
        resolve(createCommonEvents(noke: nokeDevice!))
    }
    
    @objc func addNokeDeviceOnce(
        _ data: Dictionary<String, Any>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let nokeHashMap = NokeHashMap.init(data: data)
        let macAddress = nokeHashMap.macAddress
        
        if(currentNoke != nil && currentNoke?.mac != macAddress) {
            NokeDeviceManager.shared().removeNoke(mac: macAddress)
        }
        
        let nokeDevice = addNokeIfNeeded(nokeHashMap: nokeHashMap)
        
        resolve(createCommonEvents(noke: nokeDevice!))
    }

    // Export constants to use in your native module
    override func constantsToExport() -> [AnyHashable : Any]! {
        return ["AUTHOR": "linh_the_human"]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    func createCommonEvents(noke: NokeDevice) -> [String: Any] {
        return [
            "name": noke.name,
            "mac": noke.mac,
            "session": noke.session ?? "",
            "status": true
        ]
    }

    @objc func initiateNokeService(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().delegate = self

        resolve(["status": true])
    }

    @objc func startScan(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().startScanForNokeDevices()

        resolve(["status": true])
    }

    @objc func stopScan(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().stopScan()

        resolve(["status": true])
    }

    @objc func sendCommands(
        _ data: Dictionary<String, Any>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        let nokeHashMap = NokeHashMap.init(data: data)
        let macAddress = nokeHashMap.macAddress
        let commands = nokeHashMap.commands
        let nokeDevice = getCurrentNoke(macAddress: macAddress)
        
        if (nokeDevice == nil) {
            reject("100", "Noke device is null", NSError(domain: "offlineUnlock", code: 100, userInfo: [:]))
            return
        }
        
        if (!commands.isEmpty) {
            for cmd in commands {
                nokeDevice?.sendCommands(cmd)
            }
        }
        
        resolve(createCommonEvents(noke: nokeDevice!))
    }

    @objc func removeAllNokes(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        NokeDeviceManager.shared().removeAllNoke()

        resolve(nil)
    }

    @objc func removeNokeDevice(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        NokeDeviceManager.shared().removeNoke(mac: mac)

        resolve(nil)
    }

    @objc func offlineUnlock(
        _ data: Dictionary<String, Any>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let nokeHashMap = NokeHashMap.init(data: data)
        let macAddress = nokeHashMap.macAddress
        let nokeDevice = getCurrentNoke(macAddress: macAddress)
        
        if(nokeDevice == nil) {
            reject("100", "Noke device is null", NSError(domain: "offlineUnlock", code: 100, userInfo: [:]))
            return
        }
        
        let event = createCommonEvents(noke: nokeDevice!)
        
        if(lastEventCode == 4) {
            resolve(event)
            return
        }
        
        if(nokeDevice?.unlockCmd != "") {
            nokeDevice?.unlock()
        }
        
        resolve(event)
    }

    @objc func getDeviceInfo(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        var event = [String: Any]()

        if(currentNoke == nil) {
            event["status"] = false
        } else {
            event["status"] = true
            event["name"] = currentNoke?.name ?? String()
            event["battery"] = currentNoke?.battery ?? Int()
            event["mac"] = currentNoke?.mac ?? String()
            event["offlineKey"] = currentNoke?.offlineKey ?? String()
            event["offlineUnlockCmd"] = currentNoke?.unlockCmd ?? String()
            event["serial"] = currentNoke?.serial ?? String()
            event["session"] = currentNoke?.session ?? String()
            event["trackingKey"] = currentNoke?.trackingKey ?? String()
            event["lastSeen"] = currentNoke?.lastSeen ?? Double()
            event["version"] = currentNoke?.version ?? String()
        }

        resolve(event)
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
