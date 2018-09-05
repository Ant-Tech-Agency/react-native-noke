import { Observable } from 'rxjs/Observable'

export const createNokeOptions = options => ({
  url: `https://v1.api.nokepro.com/lock/${options.url}`,
  method: 'POST',
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    Authorization: 'Bearer ' + options.token
  },
  body: options.body
})

export const addNokeDeviceOnce$ = (data) => Observable.create(observer => {
  RNNoke.addNokeDeviceOnce(data)
  .then(data => {
    observer.next(data)
  })
  .catch(err => {
    observer.error(err)
  })
  .finally(() => {
    observer.complete('done')
  })
})