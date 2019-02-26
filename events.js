import {
  NativeEventEmitter,
  NativeModules
} from 'react-native'
import { Observable } from 'rxjs/Observable'

const { RNNoke } = NativeModules
const NokeEmitter = new NativeEventEmitter(RNNoke)

export const onEvent = function (eventName, callback) {
  NokeEmitter.addListener(eventName, callback)
  return this
}

export const fromNokeEvents = () => {
  if (!Observable) return {
    message: 'Missing rxjs'
  }

  return new Observable(observer => {
    onEvent('onNokeDiscovered', data => {
      observer.next({
        name: 'onNokeDiscovered',
        data
      })
    })

    onEvent('onNokeConnecting', data => {
      observer.next({
        name: 'onNokeConnecting',
        data
      })
    })

    onEvent('onNokeConnected', data => {
      observer.next({
        name: 'onNokeConnected',
        data
      })
    })

    onEvent('onNokeSyncing', data => {
      observer.next({
        name: 'onNokeSyncing',
        data
      })
    })

    onEvent('onNokeUnlocked', data => {
      observer.next({
        name: 'onNokeUnlocked',
        data
      })
    })

    onEvent('onNokeDisconnected', data => {
      observer.next({
        name: 'onNokeDisconnected',
        data
      })
    })

    onEvent('onError', data => {
      observer.next({
        name: 'onError',
        data
      })
    })

    onEvent('onBluetoothStatusChanged', data => {
      observer.next({
        name: 'onBluetoothStatusChanged',
        data
      })
    })

    onEvent('onDataUploaded', data => {
      observer.next({
        name: 'onDataUploaded',
        data
      })
    })

    onEvent('onNokeShutdown', data => {
      observer.next({
        name: 'onNokeShutdown',
        data
      })
    })
  })
}