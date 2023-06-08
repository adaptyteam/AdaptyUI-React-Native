import type { AdaptyProfile, AdaptyError } from 'react-native-adapty';

export type ArgType<T> = T extends () => any
  ? void
  : T extends (arg: infer U) => any
  ? U
  : void;

// TODO: comments
export interface EventHandlers {
  /**
   *
   */
  onCloseButtonPress: () => boolean;
  onProductSelected: () => boolean;
  onPurchaseStarted: () => boolean;
  onPurchaseCancelled: () => boolean;
  onPurchaseCompleted: (profile: AdaptyProfile) => boolean;
  onPurchaseFailed: (error: AdaptyError) => boolean;
  onRestoreCompleted: (profile: AdaptyProfile) => boolean;
  onRestoreFailed: (error: AdaptyError) => boolean;
  onRenderingFailed: (error: AdaptyError) => boolean;
  onLoadingProductsFailed: (error: AdaptyError) => boolean;
}

// TODO: comments
export interface CreatePaywallViewParamsInput {
  /**
   *
   */
  prefetchProducts?: boolean;
}
