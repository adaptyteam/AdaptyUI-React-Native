import type {
  AdaptyProfile,
  AdaptyError,
  AdaptyPaywallProduct,
} from 'react-native-adapty';

export type ArgType<T> = T extends () => any
  ? void
  : T extends (arg: infer U) => any
  ? U
  : void;

/**
 * EventHandler callback should not return a promise,
 * because using `await` may postpone closing a paywall view.
 *
 * We don't want to block the UI thread.
 */
type EventHandlerResult = boolean | void;

/**
 * Hashmap of possible events to their callbacks
 *
 * @see {@link https://docs.adapty.io/docs/react-native-handling-events | [DOC] Handling View Events}
 */
export interface EventHandlers {
  /**
   * Called when a user taps the close button on the paywall view
   *
   * If you return `true`, the paywall view will be closed.
   * We strongly recommend to return `true` in this case.
   * @default true
   */
  onCloseButtonPress: () => EventHandlerResult;
  /**
   * Called when a user navigates back on Android
   *
   * If you return `true`, the paywall view will be closed.
   * We strongly recommend to return `true` in this case.
   * @default true
   */
  onAndroidSystemBack: () => EventHandlerResult;
  /**
   * Called when a user taps the product in the paywall view
   *
   * If you return `true` from this callback, the paywall view will be closed.
   */
  onProductSelected: (product: AdaptyPaywallProduct) => EventHandlerResult;
  /**
   * Called when a user taps the purchase button in the paywall view
   *
   * If you return `true` from this callback, the paywall view will be closed.
   */
  onPurchaseStarted: (product: AdaptyPaywallProduct) => EventHandlerResult;
  /**
   * Called if a user cancels the purchase
   *
   * If you return `true` from this callback, the paywall view will be closed.
   */
  onPurchaseCancelled: (product: AdaptyPaywallProduct) => EventHandlerResult;
  /**
   * Called when a purchase is completed
   *
   * If you return `true` from this callback, the paywall view will be closed.
   * We strongly recommend to return `true` in this case.
   * @default true
   *
   * @param {AdaptyProfile} profile - updated user profile
   */
  onPurchaseCompleted: (profile: AdaptyProfile) => EventHandlerResult;
  /**
   * Called if a purchase fails after a user taps the purchase button
   *
   * If you return `true` from this callback, the paywall view will be closed.
   *
   * @param {AdaptyError} error - AdaptyError object with error code and message
   */
  onPurchaseFailed: (error: AdaptyError) => EventHandlerResult;
  /**
   * Called when a user taps the restore button in the paywall view
   *
   * If you return `true` from this callback, the paywall view will be closed.
   */
  onRestoreStarted: () => EventHandlerResult;
  /**
   * Called when a purchase is completed
   *
   * If you return `true` from this callback, the paywall view will be closed.
   * We strongly recommend to return `true` in this case.
   * @default true
   *
   * @param {AdaptyProfile} profile - updated user profile
   */
  onRestoreCompleted: (profile: AdaptyProfile) => EventHandlerResult;
  /**
   * Called if a restore fails after a user taps the restore button
   *
   * If you return `true` from this callback, the paywall view will be closed.
   *
   * @param {AdaptyError} error - AdaptyError object with error code and message
   */
  onRestoreFailed: (error: AdaptyError) => EventHandlerResult;
  /**
   * Called if a paywall view fails to render.
   * This  should not ever happen, but if it does, feel free to report it to us.
   *
   * If you return `true` from this callback, the paywall view will be closed.
   *
   * @param {AdaptyError} error - AdaptyError object with error code and message
   */
  onRenderingFailed: (error: AdaptyError) => EventHandlerResult;
  /**
   * Called if a product list fails to load on a presented view,
   * for example, if there is no internet connection
   *
   * If you return `true` from this callback, the paywall view will be closed.
   *
   * @param {AdaptyError} error - AdaptyError object with error code and message
   */
  onLoadingProductsFailed: (error: AdaptyError) => EventHandlerResult;
  onAction: (action: any) => EventHandlerResult;
  onCustomEvent: (id: string) => EventHandlerResult;
  onUrlPress: (url: string) => EventHandlerResult;
}

/**
 * Additional options for creating a paywall view
 *
 * @see {@link https://docs.adapty.io/docs/paywall-builder-fetching | [DOC] Creating Paywall View}
 */
export interface CreatePaywallViewParamsInput {
  /**
   * `true` if you want to prefetch products before presenting a paywall view.
   */
  prefetchProducts?: boolean;
  /**
   * If you are going to use custom tags functionality, pass an object with tags and corresponding replacement values
   * 
   * ```
   * {
   *   'USERNAME': 'Bruce',
   *   'CITY': 'Philadelphia'
   * }
   * ```
   */
  customTags?: Record<string, string>;
}

export const DEFAULT_EVENT_HANDLERS: Partial<EventHandlers> = {
  onCloseButtonPress: () => true,
  onAndroidSystemBack: () => true,
  onRestoreCompleted: () => true,
  onPurchaseCompleted: () => true,
};
