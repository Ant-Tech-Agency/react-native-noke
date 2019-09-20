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
  ServiceConnected = 'ServiceConnected',
  ServiceDisconnected = 'ServiceDisconnected'
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

function fromEvent(cb: (data: NokeEventData) => void) {
  const fn = (eventName: NokeEvent) => (info: NokeEventData) => ({eventName, info})

  NokeEmitter.addListener(NokeEvent.Discovered, fn(NokeEvent.Discovered))
  NokeEmitter.addListener(NokeEvent.Connecting, fn(NokeEvent.Connecting))
  NokeEmitter.addListener(NokeEvent.Connected, fn(NokeEvent.Connected))
  NokeEmitter.addListener(NokeEvent.Syncing, fn(NokeEvent.Syncing))
  NokeEmitter.addListener(NokeEvent.Unlocked, fn(NokeEvent.Unlocked))
  NokeEmitter.addListener(NokeEvent.Disconnected, fn(NokeEvent.Disconnected))
  NokeEmitter.addListener(NokeEvent.Error, fn(NokeEvent.Error))
  NokeEmitter.addListener(NokeEvent.BluetoothStatusChanged, fn(NokeEvent.BluetoothStatusChanged))
  NokeEmitter.addListener(NokeEvent.Uploaded, fn(NokeEvent.Uploaded))
  NokeEmitter.addListener(NokeEvent.Shutdown, fn(NokeEvent.Shutdown))
  NokeEmitter.addListener(NokeEvent.ServiceConnected, fn(NokeEvent.ServiceConnected))
  NokeEmitter.addListener(NokeEvent.ServiceDisconnected, fn(NokeEvent.ServiceDisconnected))
}

const removeAllListeners = NokeEmitter.removeAllListeners

function addListener(eventName: NokeEvent, cb: () => void) {
  NokeEmitter.addListener(eventName, cb)
}

export default {
  ...RNNoke,
  fromEvent,
  addListener,
  removeAllListeners
}
