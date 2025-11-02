import Foundation
import AppInvokeSDK
import UIKit
class EventEmitter {
    /// Shared Instance.
    public static var sharedInstance = EventEmitter()
    // ReactNativeEventEmitter is instantiated by React Native with the bridge.
    private static var eventEmitter: AllInOneSDKManager!
    private init() {}
    // When React Native instantiates the emitter it is registered here.
    func registerEventEmitter(eventEmitter: AllInOneSDKManager) {
        EventEmitter.eventEmitter = eventEmitter
    }
    func dispatch(name: String, body: Any?) {
      EventEmitter.eventEmitter.sendEvent(withName: name, body: body)
    }
    /// All Events which must be support by React Native.
    lazy var allEvents: [String] = {
        var allEventNames: [String] = ["responseIfNotInstalled", "responseIfPaytmInstalled"]
        // Append all events here
        return allEventNames
    }()
 
}
 

@objc(AllInOneSDKManager)
class AllInOneSDKManager:RCTEventEmitter, AIDelegate {
    var viewController = UIApplication.shared.windows.first?.rootViewController
    let appinvoke = AIHandler()
    var resolve: RCTPromiseResolveBlock?
    var reject: RCTPromiseRejectBlock?

    
    override static func moduleName() -> String! {
        return "AllInOneSDKManager"
    }
    
    override init() {
        super.init()
        EventEmitter.sharedInstance.registerEventEmitter(eventEmitter: self)
        NotificationCenter.default.addObserver(self, selector: #selector(getAppInvokeResponse(notification:)), name: NSNotification.Name(rawValue: "appInvokeNotification"), object: nil)
    }
    
    @objc func getAppInvokeResponse(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let url = userInfo["appInvokeNotificationKey"] as? String
            let response = self.separateDeeplinkParamsIn(url: url, byRemovingParams: nil)
            self.resolve?(response)
            self.resolve = nil
            self.reject = nil
        }
    }
    /// Base overide for RCTEventEmitter.
    ///
    /// - Returns: all supported events
    @objc open override func supportedEvents() -> [String] {
        return EventEmitter.sharedInstance.allEvents
    }
    
    func openPaymentWebVC(_ controller: UIViewController?) {
        if let vc = controller {
            DispatchQueue.main.async {[weak self] in
            self?.viewController?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    
    func didFinish(with status: AppInvokeSDK.AIPaymentStatus, response: [String : Any]) {
//        sendEvent(withName: "responseIfNotInstalled", body: response)
        self.resolve?(response)
        self.resolve = nil
        self.reject = nil

    }
    
    //  override func supportedEvents() -> [String]! {
    //    return ["responseIfNotInstalled"]
    //  }
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
  
    @objc(startTransaction:mid:transactionToken:amount:callbackUrl:isStaging:restrictAppInvoke:urlScheme:withResolver:withRejecter:)
    func startTransaction(_ orderId: String, mid: String, transactionToken: String, amount: String, callbackUrl: String?, isStaging: Bool, restrictAppInvoke: Bool, urlScheme: String, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejecter reject: @escaping RCTPromiseRejectBlock) {
        print("!!!!!!callbackUrl = \(callbackUrl)")
        self.resolve = resolve
        self.reject = reject

        DispatchQueue.main.async { [weak self] in
            
            guard let `self` = self else {
                return
            }
            
            var env:AppInvokeSDK.AIEnvironment = .production
        if isStaging {
            env = .staging
        } else {
            env = .production
        }
        self.appinvoke.setBridgeName(name: "ReactNative")
        self.appinvoke.restrictAppInvokeFlow(restrict: restrictAppInvoke)
            self.appinvoke.openPaytm(merchantId: mid, orderId: orderId, txnToken: transactionToken, amount: amount, callbackUrl: callbackUrl, delegate: self, environment: env, urlScheme: urlScheme)
        }
    }
    @objc func separateDeeplinkParamsIn(url: String?, byRemovingParams rparams: [String]?)  -> [String: String] {
        guard let url = url else {
            return [String : String]()
        }
        
        /// This url gets mutated until the end. The approach is working fine in current scenario. May need a revisit.
        var urlString = stringByRemovingDeeplinkSymbolsIn(url: url)
        
        var paramList = [String : String]()
        let pList = urlString.components(separatedBy: CharacterSet.init(charactersIn: "&?"))
        for keyvaluePair in pList {
            let info = keyvaluePair.components(separatedBy: CharacterSet.init(charactersIn: "="))
            if let fst = info.first , let lst = info.last, info.count == 2 {
                paramList[fst] = lst.removingPercentEncoding
                if let rparams = rparams, rparams.contains(info.first!) {
                    urlString = urlString.replacingOccurrences(of: keyvaluePair + "&", with: "")
                    //Please dont interchage the order
                    urlString = urlString.replacingOccurrences(of: keyvaluePair, with: "")
                }
            }
            if info.first == "response" {
                paramList["response"] = keyvaluePair.replacingOccurrences(of: "response=", with: "").removingPercentEncoding
            }
        }
        if let trimmedURL = pList.first {
            paramList["trimmedurl"] = trimmedURL
        }
        if let status = paramList["status"] {
            paramList["statusReason"] = addStatusString(status)
        }
        return paramList
    }
    
    private func addStatusString(_ status: String) -> String {
        switch status {
        case "PYTM_100":
            return "none"
        case "PYTM_101":
            return "initiated"
        case "PYTM_102":
            return "paymentMode"
        case "PYTM_103":
            return "paymentDeduction"
        case "PYTM_104":
            return "errorInParameter"
        case "PYTM_105":
            return "error"
        case "PYTM_106":
            return "cancel"
        default:
            return ""
        }
    }
    
    func  stringByRemovingDeeplinkSymbolsIn(url: String) -> String {
        var urlString = url.replacingOccurrences(of: "$", with: "&")
        
        /// This may need a revisit. This is doing more than just removing the deeplink symbol.
        if let range = urlString.range(of: "&"), urlString.contains("?") == false{
            urlString = urlString.replacingCharacters(in: range, with: "?")
        }
        return urlString
    }
 
}
