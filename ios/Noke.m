#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"

@interface RCT_EXTERN_MODULE(Noke, RCTEventEmitter)
    RCT_EXTERN_METHOD(
                    isInitialized:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject
                    )
    RCT_EXTERN_METHOD(initService)
    RCT_EXTERN_METHOD(
                    unlock:(NSArray)commands
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject
                    )
    RCT_EXTERN_METHOD(
                    unlockOffline:(NSString)key
                    withCommand:(NSString)command
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject
                    )
    RCT_EXTERN_METHOD(
                    change:(NSString)mac
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject
                    )

    RCT_EXTERN_METHOD(removeAll)
    RCT_EXTERN_METHOD(startScan)
    RCT_EXTERN_METHOD(stopScan)
    RCT_EXTERN_METHOD(disconnectCurrent)
    RCT_EXTERN_METHOD(
                    getDeviceInfo:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject
                    )
@end

