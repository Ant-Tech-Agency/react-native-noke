//
//  NokeDevice.swift
//  NokeMobileLibrary
//
//  Created by Spencer Apsley on 1/12/18.
//  Copyright © 2018 Noke. All rights reserved.
//
import Foundation
import CoreBluetooth


/// Protocol for interacting with the Noke device (in virtually all cases this is the NokeDeviceManager)
protocol NokeDeviceDelegate
{
    /// Called after Noke device reads the session and stores it
    func didSetSession(_ mac:String)
}

/**
 Lock states of Noke Devices
 - Unlocked: Noke device unlocked OR Device has been locked but phone never received updated status
 - Locked: Noke device locked
 */
public enum NokeDeviceLockState : Int{
    case nokeDeviceLockStateUnlocked = 0
    case nokeDeviceLockStateLocked = 1
}

/// Class stores information about the Noke device and contains methods for interacting with the Noke device
public class NokeDevice: NSObject, NSCoding, CBPeripheralDelegate{
    
    /// Time Interval representing the most recent time the device was discovered
    public var lastSeen: Double = 0.0
    
    /// typealias used for handling bytes from the lock
    typealias byteArray = UnsafeMutablePointer<UInt8>
    
    /// Name of the Noke device (strictly cosmetic)
    public var name: String = ""
    
    /// MAC address of Noke device. This can be found in the peripheral name
    public var mac: String = ""
    
    /// Serial number of Noke device. Laser engraved onto the device during manufacturing
    public var serial: String = ""
    
    /// UUID of the lock.  Unique identifier assigned by iOS upon connection
    public var uuid: String = ""
    
    /// Firmware and hardware version of the lock. Follows format: '3P-2.10' where '3P' is the hardware version and '2.10' is the firmware version
    public var version: String = ""
    
    /// Tracking key used to track Noke device usage and activity
    public var trackingKey: String = ""
    
    /// CBPeripheral of the Noke device used by CoreBluetooth
    var peripheral: CBPeripheral?
    
    /// Delegate of the Noke device. In virtually all cases this is the NokeDeviceManager
    var delegate: NokeDeviceDelegate?
    
    /// Byte array read from the session characteristic upon connecting to the Noke device
    public var session: String?
    
    /// Battery level of the Noke device in millivolts
    public var battery: UInt64 = 0
    
    /// Connection state of the Noke device
    public var connectionState: NokeDeviceConnectionState?
    
    /// Lock state of the Noke device
    public var lockState: NokeDeviceLockState?
    
    /// Bluetooth Gatt Service of Noke device
    var nokeService: CBService?
    
    /// Read characteristic of Noke device
    var rxCharacteristic: CBCharacteristic?
    
    /// Write characteristic of Noke device
    var txCharacteristic: CBCharacteristic?
    
    /// Session characteristic of Noke device. This is read upon connecting and used for encryption
    var sessionCharacteristic: CBCharacteristic?
    
    /// Array of commands to be sent to the Noke device
    var commandArray: Array<Data>!
    
    /// Array of responses from the Noke device that need to be uploaded
    var responseArray: Array<String>!
    
    /// Unlock command used for offline unlocking
    var unlockCmd: String = ""
    
    /// Unique key used for encrypting the unlock command for offline unlocking
    var offlineKey: String = ""
    
    /// UUID of the Noke service
    internal static func nokeServiceUUID() -> (CBUUID){
        return CBUUID.init(string: "1bc50001-0200-d29e-e511-446c609db825")
    }
    
    /// UUID of the Noke write characteristic
    internal static func txCharacteristicUUID() -> (CBUUID){
        return CBUUID.init(string: "1bc50002-0200-d29e-e511-446c609db825")
    }
    
    /// UUID of the Noke read characteristic
    internal static func rxCharacteristicUUID() -> (CBUUID){
        return CBUUID.init(string: "1bc50003-0200-d29e-e511-446c609db825")
    }
    
    /// UUID of the Noke session characteristic
    internal static func sessionCharacteristicUUID() -> (CBUUID){
        return CBUUID.init(string: "1bc50004-0200-d29e-e511-446c609db825")
    }
    
    /**
     Initializes a new Noke device with provided properties
     
     - Parameters:
     - name: Name of the noke device (strictly for UI purposes)
     - mac: MAC address of noke device.  NokeDeviceManager will scan for this mac address
     
     -Returns: A beautiful, ready-to-use, Noke device just for you
     */
    public init?(name: String, mac: String){
        self.name = name
        self.mac = mac
        
        self.unlockCmd = ""
        self.offlineKey = ""
        super.init()
    }
    
    /**
     Initializes a new Noke device with provided properties. This is mostly used when loading cached locks from user defaults, but can also be used to initialize a Noke device when more properties are known
     
     - Parameters:
     - name: Name of the noke device (strictly for UI purposes)
     - mac: MAC address of noke device.  NokeDeviceManager will scan for this mac address
     - serial: Serial address of the Noke device, laser-engraved on the device during manufacturing
     - uuid: Unique identifier of the Noke device, assigned by iOS
     - version: Hardware and firmware version of the Noke device
     - trackingKey: Tracking key of the Noke device used to track activity
     - battery: Battery level of the lock in millivolts
     - unlockCmd: Unlock command used for offline unlocking
     - offlineKey: Key used to encrypt the offline unlock command
     
     -Returns: A beautiful, ready-to-use, Noke device just for you
     */
    public init(name: String, mac: String, serial: String, uuid: String, version: String, trackingKey: String, battery: UInt64, unlockCmd: String, offlineKey: String){
        self.name = name
        self.mac = mac
        self.serial = serial
        self.uuid = uuid
        self.version = version
        self.trackingKey = trackingKey
        self.battery = battery
        self.unlockCmd = unlockCmd
        self.offlineKey = offlineKey
    }
    
    /// Method used to encode class to be stored in User Defaults
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.mac, forKey: "mac")
        aCoder.encode(self.serial, forKey:"serial")
        aCoder.encode(self.uuid, forKey:"uuid")
        aCoder.encode(self.version, forKey:"version")
        aCoder.encode(self.trackingKey, forKey:"trackingkey")
        aCoder.encode(self.battery, forKey:"battery")
        aCoder.encode(self.unlockCmd, forKey:"unlockcmd")
        aCoder.encode(self.offlineKey, forKey:"offlinekey")
    }
    
    /// Method used to decode class to reload from User Defaults
    public required convenience init?(coder aDecoder: NSCoder) {
        guard   let name = aDecoder.decodeObject(forKey: "name") as? String,
            let mac = aDecoder.decodeObject(forKey: "mac") as? String,
            let serial = aDecoder.decodeObject(forKey: "serial") as? String,
            let uuid = aDecoder.decodeObject(forKey: "uuid") as? String,
            let version = aDecoder.decodeObject(forKey: "version") as? String,
            let trackingKey = aDecoder.decodeObject(forKey: "trackingkey") as? String,
            let battery = aDecoder.decodeObject(forKey: "battery") as? UInt64,
            let unlockCmd = aDecoder.decodeObject(forKey: "unlockcmd") as? String,
            let offlineKey = aDecoder.decodeObject(forKey: "offlinekey") as? String
            else{return nil}
        
        self.init(
            name: name,
            mac: mac,
            serial: serial,
            uuid: uuid,
            version: version,
            trackingKey: trackingKey,
            battery: battery,
            unlockCmd: unlockCmd,
            offlineKey: offlineKey)
    }
    
    /// Called when initial bluetooth connection has been established
    fileprivate func didConnect(){
        self.peripheral?.delegate = self
        self.peripheral!.discoverServices([NokeDevice.nokeServiceUUID()])
    }
    
    /// Stores the session after reading the session characteristic upon connecting
    fileprivate func setSession(_ data: Data){
        self.session = self.bytesToString(data: data, start: 0, length: 20)
        getBatteryFromSession(data: data)
        self.delegate?.didSetSession(self.mac)
    }
    
    /// Extracts the battery level from the session and stores it in the battery variable
    fileprivate func getBatteryFromSession(data: Data){
        var session = data
        session.withUnsafeMutableBytes{(bytes: UnsafeMutablePointer<UInt8>)->Void in
            let batteryArray = byteArray.allocate(capacity: 2)
            batteryArray[0] = bytes[3]
            batteryArray[1] = bytes[2]
            
            let batteryString = String.init(format: "%02x%02x", batteryArray[0],batteryArray[1])
            let batteryResult = UInt64(batteryString, radix:16)
            battery = batteryResult!
        }
    }
    
    /**
     Adds encrypted command to array to be sent to Noke device
     
     - Parameter data: 20 byte command to be sent to the lock
     */
    internal func addCommandToCommandArray(_ data: Data){
        if(commandArray == nil){
            commandArray = Array<Data>()
        }
        commandArray.append(data)
    }
    
    /// Sends command from the first position of the command array to the Noke device via bluetooth
    internal func writeCommandArray(){
        if(self.txCharacteristic?.properties != nil){
            let cmdData = commandArray.first
            self.peripheral?.writeValue(cmdData!, for:self.txCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }else{
            debugPrint("No write property on TX characteristic")
        }
    }
    
    /// Reads the session characteristic
    fileprivate func readSessionCharacteristic(){
        self.peripheral?.readValue(for: self.sessionCharacteristic!)
    }
    
    /// MARK: CBPeripheral Delegate Methods
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if(error != nil){
            return
        }
        
        for s: CBService in (peripheral.services!){
            if(s.uuid.isEqual(NokeDevice.nokeServiceUUID())){
                self.nokeService = s
                self.peripheral?.discoverCharacteristics([NokeDevice.txCharacteristicUUID(), NokeDevice.rxCharacteristicUUID(), NokeDevice.sessionCharacteristicUUID()], for: s)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if((error) != nil){
            return
        }
        
        for c : CBCharacteristic in service.characteristics!
        {
            if(c.uuid.isEqual(NokeDevice.rxCharacteristicUUID())){
                self.rxCharacteristic = c
                self.peripheral!.setNotifyValue(true, for:self.rxCharacteristic!)
            }
            else if(c.uuid.isEqual(NokeDevice.txCharacteristicUUID())){
                self.txCharacteristic = c
            }
            else if(c.uuid.isEqual(NokeDevice.sessionCharacteristicUUID())){
                self.sessionCharacteristic = c
                self.readSessionCharacteristic()
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil){
            return
        }
        if(characteristic == self.rxCharacteristic){
            let response = characteristic.value
            _ = self.receivedDataFromLock(response!)
        }
        else if(characteristic == self.sessionCharacteristic){
            let data = characteristic.value
            self.setSession(data!)
        }
    }
    
    /**
     Called when the phone receives data from the Noke device.  There are two main types of data packets:
     - Server packets: Encrypted responses from the locks that are parsed by the server. Can include logs, keys, and quick-click confirmations
     - App packets: Unencrypted responses that indicate whether command succeeded or failed.
     
     - Parameter data: 20 byte response from the lock
     */
    fileprivate func receivedDataFromLock(_ data: Data){
        var newData = data
        newData.withUnsafeMutableBytes{(bytes: UnsafeMutablePointer<UInt8>)->Void in
            let dataBytes = bytes
            let destByte = Int(dataBytes[0])
            switch destByte{
            case Constants.SERVER_Dest:
                if(self.session != nil){
                    NokeDeviceManager.shared().addUploadPacketToQueue(
                        response: self.bytesToString(data: data, start: 0, length: 20),
                        session: self.session!,
                        mac: self.mac)
                }
                break
            case Constants.APP_Dest:
                
                let resultByte = Int(data[1])
                switch resultByte{
                case Constants.SUCCESS_ResultType:
                    self.moveToNext()
                    if(self.commandArray == nil || self.commandArray.count == 0){
                        self.lockState = NokeDeviceLockState.nokeDeviceLockStateUnlocked
                        self.connectionState = NokeDeviceConnectionState.nokeDeviceConnectionStateUnlocked
                        NokeDeviceManager.shared().delegate?.nokeDeviceDidUpdateState(to: self.connectionState!, noke: self)
                    }
                    break
                case Constants.INVALIDKEY_ResultType:
                    NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorInvalidKey, message: "Invalid Key Result", noke: self)
                    self.moveToNext()
                    break
                case Constants.INVALIDCMD_ResultType:
                    NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorInvalidCmd, message: "Invalid Command Result", noke: self)
                    self.moveToNext()
                    break
                case Constants.INVALIDPERMISSION_ResultType:
                    NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorInvalidPermission, message: "Invalid Permission (wrong key) Result", noke: self)
                    self.moveToNext()
                    break
                case Constants.SHUTDOWN_ResultType:
                    let lockStateByte = Int32(data[2])
                    if(lockStateByte == 0){
                        self.lockState = NokeDeviceLockState.nokeDeviceLockStateUnlocked
                    }
                    else if(lockStateByte == 1){
                        self.lockState = NokeDeviceLockState.nokeDeviceLockStateLocked
                    }
                    break
                case Constants.INVALIDDATA_ResultType:
                    NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorInvalidData, message: "Invalid Data Result", noke: self)
                    self.moveToNext()
                    break
                case Constants.INVALID_ResultType:
                    NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorInvalidResult, message: "Invalid Result", noke: self)
                    self.moveToNext()
                    break
                default:
                    NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorUnknown, message: "Unable to recognize result", noke: self)
                    self.moveToNext()
                    break
                }
                break
                
            case Constants.INVALID_ResponseType:
                NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeDeviceErrorInvalidResult, message: "Invalid packet received", noke: self)
                break
            default:
                break
            }
        }
    }
    
    /// Moves to next command in the command array in preperation to sending
    func moveToNext(){
        if(commandArray != nil){
            if(commandArray.count >= 1){
                commandArray.remove(at: 0)
                if(commandArray.count >= 1){
                    writeCommandArray()
                }
            }
        }
    }
    
    /**
     Makes the necessary checks and then requests the unlock commands from the server (or generates the unlock command if offline)
     This method is also responsible for sending the command to the lock after it's received
     Before unlocking, please check:
     - unlock URL is set on the NokeDeviceManager
     - unlock endpoint has been properly implemented on server
     - Noke Device is provided with valid offline key and command (if unlocking offline)
     - A internet connection is present (if unlocking online)
     */
    public func unlock(){
        if(Reachability.isConnectedToNetwork()){
            
        }else{
            // TODO: Handle offline unlock
        }
    }
    
    /**
     Sends a command string from the Noke Core API to the Noke device
     
     - Parameter commands: A command string from the Core API. Commands are delimited by '+'
     */
    public func sendCommands(_ commands: String){
        let commandsArr = commands.components(separatedBy: "+")
        for command: String in commandsArr{
            self.addCommandToCommandArray(self.stringToBytes(hexstring: command)!)
        }
        self.writeCommandArray()
    }
    
    /**
     Sets offline key and command used for unlocking offline
     
     - Parameters:
     -key: String used to encrypt the command to the lock. Received from the Core API
     -command: String sent to the lock to unlock offline. Received from the Core API
     */
    public func setOfflineValues(key: String, command: String){
        self.offlineKey = key
        self.unlockCmd = command
    }
    
    /**
     Sets offline values before offline unlocking
     
     - Parameters:
     -key: String used to encrypt the command to the lock. Received from the Core API
     -command: String sent to the lock to unlock offline. Received from the Core API
     */
    public func offlineUnlock(key: String, command: String){
        self.offlineKey = key
        self.unlockCmd = command
        self.offlineUnlock()
    }
    
    /**
     Unlocks the lock using the offline key and the unlock command.  If the keys and commands have been set, no internet connection is required.
     */
    public func offlineUnlock(){
        if(offlineKey.count == Constants.OFFLINE_KEY_LENGTH && unlockCmd.count == Constants.OFFLINE_COMMAND_LENGTH){
            var keydata = Data(capacity: offlineKey.count/2)
            let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
            regex.enumerateMatches(in: offlineKey, options: [], range: NSMakeRange(0, offlineKey.count)) { match, flags, stop in
                let byteString = (offlineKey as NSString).substring(with: match!.range)
                var num = UInt8(byteString, radix: 16)!
                keydata.append(&num, count: 1)
            }
            
            guard keydata.count > 0 else {
                return
            }
            
            var cmddata = Data(capacity:unlockCmd.count/2)
            regex.enumerateMatches(in: unlockCmd, options: [], range: NSMakeRange(0, unlockCmd.count)) { match, flags, stop in
                let byteCmdString = (unlockCmd as NSString).substring(with: match!.range)
                var cmdnum = UInt8(byteCmdString, radix: 16)!
                cmddata.append(&cmdnum, count: 1)
            }
            
            guard cmddata.count > 0 else {
                return
            }
            
            let currentDateTime = Date()
            let timeStamp = UInt64(currentDateTime.timeIntervalSince1970)
            let timedata = Data.init(bytes: [UInt8((timeStamp >> 24) & 0xFF), UInt8((timeStamp >> 16) & 0xFF), UInt8((timeStamp >> 8) & 0xFF), UInt8((timeStamp & 0xFF))])
            
            let finalCmdData = createOfflineUnlock(preSessionKey: keydata, unlockCmd: cmddata, timestamp: timedata)
            
            self.addCommandToCommandArray(finalCmdData)
            self.writeCommandArray()
        }else{
            NokeDeviceManager.shared().delegate?.nokeErrorDidOccur(error: NokeDeviceManagerError.nokeLibraryErrorInvalidOfflineKey, message: "Offline Key/Command is not a valid length", noke: self)
        }
    }
    
    /**
     Creates the offline unlock command, adds the current timestamp, and encrypts using the keys.
     
     - Parameters:
     - preSessionKey: key used to encrypt commands
     - unlockCmd: command to be encrypted
     - timestamp: Current time to be embedded into the command
     */
    fileprivate func createOfflineUnlock(preSessionKey: Data, unlockCmd: Data, timestamp: Data) -> Data
    {
        let newCommandPacket = byteArray.allocate(capacity: 20)
        var key = self.createOfflineCombinedKey(baseKey:preSessionKey)
        var unlockCmdBytes = [UInt8](unlockCmd)
        
        var x = 0
        while x<4 {
            newCommandPacket[x] = unlockCmdBytes[x]
            x += 1
        }
        
        let cmddata = byteArray.allocate(capacity: 16)
        
        var i = 0
        while i<16 {
            cmddata[i] = unlockCmd[i+4]
            i += 1
        }
        
        var timeStampBytes = [UInt8](timestamp)
        
        cmddata[2] = timeStampBytes[3]
        cmddata[3] = timeStampBytes[2]
        cmddata[4] = timeStampBytes[1]
        cmddata[5] = timeStampBytes[0]
        
        var checksum:Int = 0
        var n = 0
        while n<15 {
            checksum += Int(cmddata[n])
            n += 1
        }
        
        cmddata[15] = UInt8.init(truncatingIfNeeded: checksum)
        
        key.withUnsafeMutableBytes {(bytes: UnsafeMutablePointer<UInt8>)->Void in
            let keyBytes = bytes
            self.copyArray(newCommandPacket, outStart: 4, dataIn: self.encryptPacket(keyBytes, data: cmddata), inStart: 0, size: 16)
        }
        
        return Data.init(bytes: [newCommandPacket[0], newCommandPacket[1], newCommandPacket[2], newCommandPacket[3], newCommandPacket[4], newCommandPacket[5], newCommandPacket[6], newCommandPacket[7], newCommandPacket[8], newCommandPacket[9], newCommandPacket[10], newCommandPacket[11], newCommandPacket[12], newCommandPacket[13], newCommandPacket[14], newCommandPacket[15], newCommandPacket[16], newCommandPacket[17], newCommandPacket[18], newCommandPacket[19]])
    }
    
    //Creates offline key by combining the offline key with the session
    fileprivate func createOfflineCombinedKey(baseKey: Data) -> Data{
        
        let session = stringToBytes(hexstring: self.session!)!
        var sessionBytes = [UInt8](session)
        var baseKeyBytes = [UInt8](baseKey)
        
        var total:Int
        var x = 0
        while x<16 {
            
            total = Int(baseKeyBytes[x]) + Int(sessionBytes[x])
            baseKeyBytes[x] = UInt8.init(truncatingIfNeeded: total)
            x += 1
        }
        return Data.init(bytes: baseKeyBytes)
    }
    
    
    /// Converts hex string to byte array (data)
    internal func stringToBytes(hexstring: String) -> Data? {
        var data = Data(capacity: hexstring.count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hexstring, range: NSMakeRange(0, hexstring.utf16.count)) { match, flags, stop in
            let byteString = (hexstring as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        guard data.count > 0 else { return nil }
        return data
    }
    
    /// Converts byte array (data) to hex string
    internal func bytesToString(data:Data, start:Int, length:Int) -> String
    {
        var bytes = [UInt8](data)
        let hex = NSMutableString(string: "")
        var x = 0
        while x < length {
            hex.appendFormat("%02x", bytes[x + start])
            x += 1
        }
        let immutableHex = String.init(hex)
        return immutableHex
    }
    
    fileprivate func copyArray(_ dataOut: byteArray, outStart: Int, dataIn: byteArray, inStart: Int, size: Int){
        
        var x = 0
        while x < size {
            dataOut[x+outStart] = dataIn[x+inStart]
            x += 1
        }
        
    }
    
    fileprivate func copyArray(_ dataOut: byteArray, dataIn: byteArray, size: Int)
    {
        var x = 0
        while x < size {
            
            dataOut[x] = dataIn[x]
            x += 1
        }
    }
    
    fileprivate func copyArray(_ dataOut: Data, dataIn: Data, size: Int) -> Data
    {
        var bytesDataOut = [UInt8](dataOut)
        var bytesDataIn = [UInt8](dataIn)
        
        var x = 0
        while x < size {
            
            bytesDataOut[x] = bytesDataIn[x]
            x += 1
        }
        
        return Data.init(bytes: bytesDataOut)
    }
    
    fileprivate func encryptPacket(_ combinedKey: byteArray, data: byteArray) -> byteArray
    {
        let tempKey = byteArray.allocate(capacity: 16)
        let buffer = byteArray.allocate(capacity: 16)
        self.copyArray(tempKey, dataIn: combinedKey, size: 16)
        aes_enc_dec(data, tempKey, 1)
        self.copyArray(buffer, dataIn: data, size: 16)
        
        return buffer
    }
}
