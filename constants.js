import { Platform } from 'react-native'

export const constants = {
    CONN_STATE_DISCONNECTED: 0,
    CONN_STATE_DISCOVERED: 1,
    CONN_STATE_CONNECTING: 2,
    CONN_STATE_CONNECTED: 3,
    CONN_STATE_SYNCING: 4,
    CONN_STATE_UNLOCKED: 5,

    LOCK_STATE_UNKNOWN: -1,
    LOCK_STATE_UNLOCKED: 0,
    LOCK_STATE_UNSHACKLED: 1,
    LOCK_STATE_LOCKED: 2,

    // iOS only
    UNKNOWN: 0,
    RESETTING: 1,
    UNSUPPORTED: 2,
    UNAUTHORIZED: 3,

    // android only
    SCAN_MODE_CONNECTABLE: 21,
    SCAN_MODE_CONNECTABLE_DISCOVERABLE: 23,
    SCAN_MODE_NONE: 20,
    STATE_CONNECTED: 2,
    STATE_CONNECTING: 1,
    STATE_DISCONNECTED: 0,
    STATE_DISCONNECTING: 3,
    STATE_TURNING_OFF: 13,
    STATE_TURNING_ON: 11,

    STATE_OFF: Platform.select({
        ios: 4,
        android: 10
    }),
    STATE_ON: Platform.select({
        ios: 5,
        android: 12
    }),

    //API Errors
    SUCCESS: 0, //that's not an error
    API_ERROR_INTERNAL_SERVER: 1,
    API_ERROR_API_KEY: 2,
    API_ERROR_INPUT: 3,
    API_ERROR_REQUEST_METHOD: 4,
    API_ERROR_INVALID_ENPOINT: 5,
    API_ERROR_COMPANY_NOT_FOUND: 6,
    API_ERROR_LOCK_NOT_FOUND: 7,
    API_ERROR_UNKNOWN: 99,

    //GO Library Errors
    GO_ERROR_UNLOCK: 100,
    GO_ERROR_UPLOAD: 101,

    //Noke Device Errors (200 + error code)
    //DEVICE_SUCCESS                       : 260, //that's not an error
    DEVICE_ERROR_INVALID_KEY: 261,
    DEVICE_ERROR_INVALID_CMD: 262,
    DEVICE_ERROR_INVALID_PERMISSION: 263,
    DEVICE_SHUTDOWN_RESULT: 264,
    DEVICE_ERROR_INVALID_DATA: 265,
    DEVICE_BATTERY_RESULT: 266,
    DEVICE_ERROR_INVALID_RESULT: 267,
    DEVICE_ERROR_FAILED_TO_LOCK: 268,
    DEVICE_ERROR_FAILED_TO_UNLOCK: 269,
    DEVICE_ERROR_FAILED_TO_REMOVE_SHACKLE: 270,
    DEVICE_ERROR_UNKNOWN: 299,

    //Noke Device Manager Service Errors
    ERROR_LOCATION_PERMISSIONS_NEEDED: 300,
    ERROR_LOCATION_SERVICES_DISABLED: 301,
    ERROR_BLUETOOTH_DISABLED: 302,
    ERROR_BLUETOOTH_GATT: 303,
    ERROR_INVALID_NOKE_DEVICE: 304,
    ERROR_GPS_ENABLED: 305,
    ERROR_NETWORK_ENABLED: 306,
    ERROR_BLUETOOTH_SCANNING: 307,
    ERROR_MISSING_API_KEY: 308,
    ERROR_INVALID_OFFLINE_KEY: 309,
    ERROR_JSON_UPLOAD: 315,
    ERROR_MISSING_UPLOAD_URL: 316,
}