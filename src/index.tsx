import { NativeModules } from 'react-native';

type ReactNativePaytmAllinoneType = {
  startTransaction(
    orderId: string,
    mid: string,
    txnToken: string,
    amount: string,
    callbackUrl: string,
    isStaging: boolean,
    restrictAppInvoke: boolean,
    urlScheme: String
  ): Promise<any>;
};

const { AllInOneSDKManager } = NativeModules;

export default AllInOneSDKManager as ReactNativePaytmAllinoneType;
