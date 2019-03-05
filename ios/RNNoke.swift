//  Created by react-native-create-bridge

import Foundation

@objc(RNNoke)
class RNNoke : RCTEventEmitter, NokeDeviceManagerDelegate {
    var currentNoke: NokeDevice?
    var isConnected = false
    
    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {
        case .nokeDeviceConnectionStateDiscovered:
            if(isConnected == false) {
                currentNoke = noke
                NokeDeviceManager.shared().connectToNokeDevice(noke)
                sendEvent(withName: "onNokeDiscovered", body: nokeDeviceInfo(noke))
                isConnected = true
            }
            break
        case .nokeDeviceConnectionStateConnecting:
            sendEvent(withName: "onNokeConnecting", body: nokeDeviceInfo(noke))
            break
        case .nokeDeviceConnectionStateConnected:
            currentNoke = noke
            NokeDeviceManager.shared().stopScan()
            sendEvent(withName: "onNokeConnected", body: nokeDeviceInfo(noke))
            break
        case .nokeDeviceConnectionStateSyncing:
            sendEvent(withName: "onNokeSyncing", body: nokeDeviceInfo(noke))
            break
        case .nokeDeviceConnectionStateUnlocked:
            sendEvent(withName: "onNokeUnlocked", body: nokeDeviceInfo(noke))
            break
        case .nokeDeviceConnectionStateDisconnected:
            isConnected = false
            NokeDeviceManager.shared().startScanForNokeDevices()
            sendEvent(withName: "onNokeDisconnected", body: nokeDeviceInfo(noke))
            removeAllLock()
            break
        }
    }
    
    func nokeDeviceDidShutdown(noke: NokeDevice, isLocked: Bool, didTimeout: Bool) {
        isConnected = false
        NokeDeviceManager.shared().disconnectNokeDevice(noke)
        sendEvent(withName: "onNokeShutdown", body: [
            "noke": nokeDeviceInfo(noke),
            "isLocked": isLocked,
            "didTimeout": didTimeout
            ])
    }
    
    func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        if error != .nokeAPIErrorAPIKey {
            sendEvent(withName: "onError", body: [
                "noke": nokeDeviceInfo(noke),
                "message": message,
                "error": error.rawValue
                ])
        }
    }
    
    func didUploadData(result: Int, message: String) {
        sendEvent(withName: "onDataUploaded", body: [
            "result": result,
            "message": message
            ])
    }
    
    func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        var status = 0
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            status = 12
            NokeDeviceManager.shared().startScanForNokeDevices()
            break
        case NokeManagerBluetoothState.poweredOff:
            status = 10
            break
        default:
            status = state.rawValue
            break
        }
        sendEvent(withName: "onBluetoothStatusChanged", body: [
            "status": status
            ])
    }
    
    @objc func initService() {
        NokeDeviceManager.shared().delegate = self
        NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.SANDBOX)
        startScan()
    }
    
    @objc func unlock(
        _ commands: Array<String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if currentNoke == nil {
            reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE, NSError(domain: "offline", code: 100, userInfo: [:]))
            return
        } else {
            for command in commands {
                currentNoke?.sendCommands(command)
            }
            resolve(nokeDeviceInfo(currentNoke))
        }
    }
    
    @objc func unlockOffline(
        _ key: String,
        withCommand command: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if currentNoke == nil {
            reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE, NSError(domain: "unlockOffline", code: Int(RNNokeError.NO_LOCK_CONNECTED) ?? 100, userInfo: [:]))
            return
        }
        
        if currentNoke?.session == nil {
            reject(RNNokeError.NO_LOCK_SESSION, RNNokeError.NO_LOCK_SESSION_MESSAGE, NSError(domain: "unlockOffline", code: Int(RNNokeError.NO_LOCK_SESSION) ?? 100, userInfo: [:]))
            return
        }
        
        currentNoke?.offlineUnlock(key: key, command: command)
        resolve(nokeDeviceInfo(currentNoke))
    }
    
    @objc func changeLock(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let noke = NokeDevice(name: mac, mac: mac)
        if currentNoke != nil {
            NokeDeviceManager.shared().disconnectNokeDevice(noke!)
        }
        isConnected = false
        NokeDeviceManager.shared().removeAllNoke()
        NokeDeviceManager.shared().addNoke(noke!)
        NokeDeviceManager.shared().startScanForNokeDevices()
        currentNoke = noke
        resolve(nokeDeviceInfo(noke))
    }
    
    @objc func removeAllLock() {
        NokeDeviceManager.shared().removeAllNoke()
        NokeDeviceManager.shared().stopScan()
    }
    
    @objc func startScan() {
        NokeDeviceManager.shared().startScanForNokeDevices()
    }
    
    @objc func stopScan() {
        NokeDeviceManager.shared().stopScan()
    }
    
    @objc func disconnected() {
        if currentNoke != nil {
            NokeDeviceManager.shared().disconnectNokeDevice(currentNoke!)
        }
    }
    
    @objc func deviceInfo(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if currentNoke == nil {
            reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE, NSError(domain: "deviceInfo", code: Int(RNNokeError.NO_LOCK_CONNECTED) ?? 100, userInfo: [:]))
        } else {
            resolve(nokeDeviceInfo(currentNoke))
        }
    }
    
    private func nokeDeviceInfo(_ noke: NokeDevice?) -> Dictionary<String, Any?> {
        if(noke == nil) {
            return [:]
        } else {
            return [
                "battery":  noke?.battery,
                "connectionState": noke?.connectionState?.rawValue,
                "lastSeen": noke?.lastSeen,
                "lockState": noke?.lockState.rawValue,
                "mac": noke?.mac ?? "",
                "name": noke?.name ?? "",
                "serial": noke?.serial ?? "",
                "session": noke?.session ?? "",
                "trackingKey": noke?.trackingKey ?? "",
                "version": noke?.version ?? ""
            ]
        }
    }
    
    // Export constants to use in your native module
    // func constantsToExport() -> [String : Any]! {
    // return ["EXAMPLE_CONSTANT": "example"]
    // }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
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
            "onNokeShutdown",
            "onNokeDisconnected",
            "onBluetoothStatusChanged",
            "onDataUploaded",
            "onError"
        ]
    }
}
