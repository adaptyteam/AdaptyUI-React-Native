import { NativeModules } from 'react-native';
import { LogContext } from 'react-native-adapty/lib/dist/logger';

// Collection of keys that are expected as arguments in the native layer
export const MODULE_ARG_KEYS = Object.freeze({
  PAYWALL: 'paywall',
  PREFETCH_PRODUCTS: 'prefetch_products',
  VIEW_ID: 'view_id',
});
type ModuleArg = (typeof MODULE_ARG_KEYS)[keyof typeof MODULE_ARG_KEYS];
type ArgsMap = Record<ModuleArg, string | boolean>;

// Set of available handlers on a native side
export type BridgeMethodName = 'present_view' | 'dismiss_view' | 'create_view';

// RN searches connected native modules with a provided name
// Native classes that perform bridge communication in this library
// must have the same name
export const MODULE_NAME = 'RNAUICallHandler';
export const MODULE_BRIDGE = NativeModules[MODULE_NAME];

// Name of the exposed function, that routes all other handlers
export const HANDLER_FN_NAME = 'handle';

// Just a type clarification
const $callNativeMethod = NativeModules[MODULE_NAME][HANDLER_FN_NAME] as (
  methodName: BridgeMethodName,
  args: Partial<ArgsMap>,
) => Promise<string | null>;

// Exposed function to access public handles on a native side
export async function $call(
  method: BridgeMethodName,
  args: Partial<ArgsMap>,
  ctx?: LogContext,
): Promise<string | null> {
  const log = ctx?.bridge({ methodName: 'call' });
  log?.start({ method, args });

  try {
    const response = await $callNativeMethod(method, args);

    log?.success({ response });
    return response;
  } catch (error) {
    log?.success({ error });
    throw error;
  }
}
