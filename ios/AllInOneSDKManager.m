#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTLinkingManager.h>



@interface RCT_EXTERN_MODULE(AllInOneSDKManager, RCTLinkingManager)

RCT_EXTERN_METHOD(startTransaction:(NSString *)orderId
mid:(NSString *)mid
transactionToken:(NSString *)txnTkn
amount:(NSString *)amt
callbackUrl:(NSString *)url
isStaging: (BOOL)isStaging
restrictAppInvoke: (BOOL)restrictAppInvoke
urlScheme:(NSString *)urlScheme
withResolver:(RCTPromiseResolveBlock)resolve
withRejecter:(RCTPromiseRejectBlock)reject)
@end
