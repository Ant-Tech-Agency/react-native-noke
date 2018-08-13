import Foundation

@objc(RNNoke)
class RNNoke : RCTEventEmitter, NokeDeviceManagerDelegate {
    var currentNoke: NokeDevice?
    var errMsg = ""
    var errCode = 301

    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {

        case .nokeDeviceConnectionStateDiscovered:
            NokeDeviceManager.shared().stopScan()
            NokeDeviceManager.shared().connectToNokeDevice(noke)

            sendEvent(withName: "onNokeDiscovered", body: createCommonEvents(noke: noke))
            break
        case .nokeDeviceConnectionStateConnected:
            print(noke.session!)
            currentNoke = noke

            sendEvent(withName: "onNokeConnected", body: createCommonEvents(noke: noke))
            break
        case .nokeDeviceConnectionStateSyncing:

            sendEvent(withName: "onNokeConnecting", body: createCommonEvents(noke: noke))
            break
        case .nokeDeviceConnectionStateUnlocked:

            sendEvent(withName: "onNokeUnlocked", body: createCommonEvents(noke: noke))
            break
        case .nokeDeviceConnectionStateDisconnected:
            NokeDeviceManager.shared().cacheUploadQueue()
            currentNoke = nil

            sendEvent(withName: "onNokeDisconnected", body: createCommonEvents(noke: noke))
            break
        default:

            sendEvent(withName: "onError", body: ["message": "unrecognized state"])
            break
        }
    }

    func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        var eventMsg = message
        if(errMsg != "") {
            eventMsg = errMsg
        }
        sendEvent(withName: "onError", body: ["code": errCode,"message": eventMsg])
    }

    func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        var message = ""
        var code = 1
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
//            NokeDeviceManager.shared().startScanForNokeDevices()
            message = "on"
            code = 1
            errMsg = ""
            errCode = 301
            break
        case NokeManagerBluetoothState.poweredOff:
            message = "off"
            code = 0
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

    // Export constants to use in your native module
    override func constantsToExport() -> [AnyHashable : Any]! {
        return ["AUTHOR": "linh_the_human"]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc func createCommonEvents(noke: NokeDevice) -> [String: Any] {
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

    @objc func addNokeDevice(
        _ data: Dictionary<String, String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        /**
        * name: "Lock Name"
        * mac: "XX:XX:XX:XX:XX:XX"
        * key: "OFFLINE_KEY"
        * cmd: "OFFLINE_COMMAND"
        */
        let noke = NokeDevice.init(
            name: data["name"]! as String,
            mac: data["mac"]! as String
        )

        let key = data["key"] ?? ""
        let command = data["cmd"] ?? ""

        if(key != "" && command != "") {
            noke?.setOfflineValues(
                key: key,
                command: command
            )
        }

        NokeDeviceManager.shared().addNoke(noke!)

        resolve(["status": true])
    }

    @objc func setOfflineData(
        _ data: Dictionary<String, String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        if(currentNoke == nil) {
            let error = NSError(domain: "", code: 404, userInfo: nil)
            reject("message", "currentNoke is null", error)
            return
        }

        let key = data["key"]! as String
        let command = data["cmd"]! as String

        if(key != "" && command != "") {
            currentNoke?.setOfflineValues(
                key: key,
                command: command
            )
        }

        resolve(createCommonEvents(noke: currentNoke!))
    }

    @objc func sendCommands(
        _ command: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        if(currentNoke == nil) {
            let error = NSError(domain: "", code: 404, userInfo: nil)
            reject("message", "currentNoke is null", error)
            return
        }
        currentNoke?.sendCommands(command)

        resolve(["name": currentNoke?.name, "mac": currentNoke?.mac])
    }

    @objc func disconnect(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if(currentNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "currentNoke is null", error)
            return
        }
        NokeDeviceManager.shared().disconnectNokeDevice(currentNoke!)

        resolve(["status": true])
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

    @objc func offlineUnlock(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        var event = [String: Any]()

        if(currentNoke == nil) {
            event["status"] = false
        } else {
            currentNoke?.offlineUnlock()
            event["status"] = true
            event["name"] = currentNoke?.name ?? String()
            event["mac"] = currentNoke?.mac ?? String()
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
