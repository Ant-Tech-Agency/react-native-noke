import {
  NativeEventEmitter,
  NativeModules
} from 'react-native'
import { Observable } from 'rxjs/Observable'

const { RNNoke } = NativeModules
const NokeEmitter = new NativeEventEmitter(RNNoke)

export const addListener = function (eventName, callback) {
  NokeEmitter.addListener(eventName, callback)
  return this
}

export const removeAllListeners = NokeEmitter.removeAllListeners

export const fromNokeEvents = () => {
  if (!Observable) return {
    message: 'Missing rxjs'
  }

  return new Observable(observer => {
    addListener('onNokeDiscovered', data => {
      observer.next({
        name: 'onNokeDiscovered',
        data
      })
    })

    addListener('onNokeConnecting', data => {
      observer.next({
        name: 'onNokeConnecting',
        data
      })
    })

    addListener('onNokeConnected', data => {
      observer.next({
        name: 'onNokeConnected',
        data
      })
    })

    addListener('onNokeSyncing', data => {
      observer.next({
        name: 'onNokeSyncing',
        data
      })
    })

    addListener('onNokeUnlocked', data => {
      observer.next({
        name: 'onNokeUnlocked',
        data
      })
    })

    addListener('onNokeDisconnected', data => {
      observer.next({
        name: 'onNokeDisconnected',
        data
      })
    })

    addListener('onError', data => {
      observer.next({
        name: 'onError',
        data
      })
    })

    addListener('onBluetoothStatusChanged', data => {
      observer.next({
        name: 'onBluetoothStatusChanged',
        data
      })
    })

    addListener('onDataUploaded', data => {
      observer.next({
        name: 'onDataUploaded',
        data
      })
    })

    addListener('onNokeShutdown', data => {
      observer.next({
        name: 'onNokeShutdown',
        data
      })
    })
  })
}