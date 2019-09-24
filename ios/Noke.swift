//
//  File.swift
//  DoubleConversion
//
//  Created by linh on 9/11/19.
//

import Foundation
import NokeMobileLibrary

@objc(Noke)
class Noke : RCTEventEmitter, NokeDeviceManagerDelegate {
    var currentNoke: NokeDevice?
    var isConnected = false
    var isInitializedService = false
    
    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {
        case .Discovered:
            if(isConnected == false) {
                currentNoke = noke
                NokeDeviceManager.shared().connectToNokeDevice(noke)
                sendEvent(withName: "Discovered", body: nokeDeviceInfoFactory(noke))
                isConnected = true
            }
            break
        case .Connecting:
            sendEvent(withName: "Connecting", body: nokeDeviceInfoFactory(noke))
            break
        case .Connected:
            currentNoke = noke
            NokeDeviceManager.shared().stopScan()
            sendEvent(withName: "Connected", body: nokeDeviceInfoFactory(noke))
            break
        case .Syncing:
            sendEvent(withName: "Syncing", body: nokeDeviceInfoFactory(noke))
            break
        case .Unlocked:
            sendEvent(withName: "Unlocked", body: nokeDeviceInfoFactory(noke))
            break
        case .Disconnected:
            isConnected = false
            NokeDeviceManager.shared().startScanForNokeDevices()
            sendEvent(withName: "Disconnected", body: nokeDeviceInfoFactory(noke))
            removeAll()
            break
        }
    }
    
    func nokeDeviceDidShutdown(noke: NokeDevice, isLocked: Bool, didTimeout: Bool) {
        isConnected = false
        NokeDeviceManager.shared().disconnectNokeDevice(noke)
        sendEvent(withName: "Shutdown", body: [
            "noke": nokeDeviceInfoFactory(noke),
            "isLocked": isLocked,
            "didTimeout": didTimeout
            ])
    }
    
    func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        if error != .nokeAPIErrorAPIKey {
            sendEvent(withName: "Error", body: [
                "noke": nokeDeviceInfoFactory(noke),
                "message": message,
                "error": error.rawValue
                ])
        }
    }
    
    func didUploadData(result: Int, message: String) {
        sendEvent(withName: "Uploaded", body: [
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
        sendEvent(withName: "BluetoothStatusChanged", body: [
            "status": status
            ])
    }
    
    @objc func isInitialized(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        resolve(isInitializedService)
    }
    
    @objc func initService() {
        NokeDeviceManager.shared().delegate = self
        NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.SANDBOX)
        isInitializedService = true
        
        sendEvent(withName: "ServiceConnected", body: [
            "connected": true
            ])
        
        startScan()
    }
    
    @objc func unlock(
        _ commands: Array<String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if currentNoke == nil {
            reject(NokeError.NO_LOCK_CONNECTED, NokeError.NO_LOCK_CONNECTED_MESSAGE, NSError(domain: "offline", code: 100, userInfo: [:]))
            return
        } else {
            for command in commands {
                currentNoke?.sendCommands(command)
            }
            resolve(nokeDeviceInfoFactory(currentNoke))
        }
    }
    
    @objc func unlockOffline(
        _ key: String,
        withCommand command: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if currentNoke == nil {
            reject(NokeError.NO_LOCK_CONNECTED, NokeError.NO_LOCK_CONNECTED_MESSAGE, NSError(domain: "unlockOffline", code: Int(NokeError.NO_LOCK_CONNECTED) ?? 100, userInfo: [:]))
            return
        }
        
        if currentNoke?.session == nil {
            reject(NokeError.NO_LOCK_SESSION, NokeError.NO_LOCK_SESSION_MESSAGE, NSError(domain: "unlockOffline", code: Int(NokeError.NO_LOCK_SESSION) ?? 100, userInfo: [:]))
            return
        }
        
        currentNoke?.setOfflineValues(key: key, command: command)
        currentNoke?.offlineUnlock()
        resolve(nokeDeviceInfoFactory(currentNoke))
    }
    
    @objc func change(
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
        resolve(nokeDeviceInfoFactory(noke))
    }
    
    @objc func removeAll() {
        NokeDeviceManager.shared().removeAllNoke()
        NokeDeviceManager.shared().stopScan()
    }
    
    @objc func startScan() {
        NokeDeviceManager.shared().startScanForNokeDevices()
    }
    
    @objc func stopScan() {
        NokeDeviceManager.shared().stopScan()
    }
    
    @objc func disconnectCurrent() {
        if currentNoke != nil {
            NokeDeviceManager.shared().disconnectNokeDevice(currentNoke!)
        }
    }
    
    @objc func getDeviceInfo(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if currentNoke == nil {
            reject(NokeError.NO_LOCK_CONNECTED, NokeError.NO_LOCK_CONNECTED_MESSAGE, NSError(domain: "deviceInfo", code: Int(NokeError.NO_LOCK_CONNECTED) ?? 100, userInfo: [:]))
        } else {
            resolve(nokeDeviceInfoFactory(currentNoke))
        }
    }
    
    private func nokeDeviceInfoFactory(_ noke: NokeDevice?) -> Dictionary<String, Any?> {
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
            "ServiceConnected",
            "ServiceDisconnected",
            "Discovered",
            "Connecting",
            "Connected",
            "Syncing",
            "Unlocked",
            "Shutdown",
            "Disconnected",
            "BluetoothStatusChanged",
            "Uploaded",
            "Error"
        ]
    }
}
