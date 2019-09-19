import { NativeModules, NativeEventEmitter } from 'react-native'

const { Noke } = NativeModules
const NokeEmitter = new NativeEventEmitter(Noke)

export enum NokeEvent {
  Discovered = 'Discovered',
  Connecting = 'Connecting',
  Connected = 'Connected',
  Syncing = 'Syncing',
  Unlocked = 'Unlocked',
  Shutdown = 'Shutdown',
  Disconnected = 'Disconnected',
  Uploaded = 'Uploaded',
  BluetoothStatusChanged = 'BluetoothStatusChanged',
  Error = 'Error',
}

type NokeDevice = {
  battery: string
  connectionState: string
  offlineKey: string
  lastSeen: string
  lockState: string
  mac: string
  name: string
  serial: string
  session: string
  trackingKey: string
  version: string
}

type INoke = {
  initService(): void
  unlock(commands: string[]): Promise<NokeDevice>
  unlockOffline(key: string, command: string): Promise<NokeDevice>
  change(mac: string): Promise<NokeDevice>
  removeAll(): void
  startScan(): void
  stopScan(): void
  disconnectCurrent(): void
  getDeviceInfo(): Promise<NokeDevice>
}

type NokeEventData = {
  eventName: NokeEvent
  info: NokeDevice
}

const RNNoke: INoke = Noke

export function addListener(eventName: NokeEvent, cb: () => void) {
  NokeEmitter.addListener(eventName, cb)
}

export function fromEvent(cb: (data: NokeEventData) => void) {
  NokeEmitter.addListener(NokeEvent.Discovered, cb)
  NokeEmitter.addListener(NokeEvent.Connecting, cb)
  NokeEmitter.addListener(NokeEvent.Connected, cb)
  NokeEmitter.addListener(NokeEvent.Syncing, cb)
  NokeEmitter.addListener(NokeEvent.Unlocked, cb)
  NokeEmitter.addListener(NokeEvent.Disconnected, cb)
  NokeEmitter.addListener(NokeEvent.Error, cb)
  NokeEmitter.addListener(NokeEvent.BluetoothStatusChanged, cb)
  NokeEmitter.addListener(NokeEvent.Uploaded, cb)
  NokeEmitter.addListener(NokeEvent.Shutdown, cb)
}

export const removeAllListeners = NokeEmitter.removeAllListeners

export default RNNoke
