import { EmitterSubscription, NativeEventEmitter } from 'react-native';
import { LogContext } from 'react-native-adapty/lib/dist/logger';
import { AdaptyProfileCoder } from 'react-native-adapty/lib/dist/internal/coders/AdaptyProfile';

import { MODULE_BRIDGE } from './bridge';
import type { ArgType, EventHandlers } from './types';
import { AdaptyError } from 'react-native-adapty';

type EventName = keyof EventHandlers;
// Type of an argument, that is expected for provided event
type CallbackArg<T extends EventName> = ArgType<EventHandlers[T]>;

// Requested data is passed in JSON["payload"]
// For all emitted events. Might be object or null
const DATA_KEY = 'payload';
// Emitting view ID is passed in JSON["_view_id"]
// So that no all visible views would emit this event
// Must be in every callback response in the form of UUID string
const VIEW_KEY = '_view_id';

/**
 * Parses unwrapped callback argument
 */
function decodeCallbackArgument(
  event: EventName,
  payload: object | null,
  ctx?: LogContext,
): CallbackArg<typeof event> {
  const log = ctx?.decode({ methodName: 'decodeCallbackArgument' });
  log?.start({ event, payload });

  switch (event) {
    // void
    case 'onCloseButtonPress':
    case 'onProductSelected':
    case 'onPurchaseStarted':
    case 'onPurchaseCancelled': {
      return undefined satisfies CallbackArg<typeof event>;
    }
    // AdaptyError
    case 'onPurchaseFailed':
    case 'onRestoreFailed':
    case 'onRenderingFailed':
    case 'onLoadingProductsFailed': {
      const error = AdaptyError.tryWrap(payload);
      return error satisfies CallbackArg<typeof event>;
    }
    // AdaptyProfile
    case 'onPurchaseCompleted':
    case 'onRestoreCompleted': {
      const coder = AdaptyProfileCoder.tryDecode(payload, ctx);
      const data = coder.toObject();
      return data satisfies CallbackArg<typeof event>;
    }
    default: {
      const eventName: never = event;
      throw new Error(`unknown event: ${eventName}`);
    }
  }
}

/**
 * @remarks
 * View emitter wraps NativeEventEmitter
 * and provides several modifications:
 * - Synthetic type restrictions to avoid misspelling
 * - Safe data deserialization with SDK decoders
 * - Logging emitting and deserialization processes
 * - Filters out events for other views by _id
 *
 * @internal
 */
export class ViewEmitter {
  private emitter;
  private listeners: EmitterSubscription[];
  private ctx: LogContext;

  private _viewId: string;

  constructor(_viewId: string) {
    this._viewId = _viewId;
    this.emitter = new NativeEventEmitter(MODULE_BRIDGE);
    this.listeners = [];

    this.ctx = new LogContext();
  }

  public addListener(
    event: EventName,
    callback: EventHandlers[EventName],
    onRequestClose: () => Promise<void>,
  ): EmitterSubscription {
    // Native layer emits callbacks with serialized args
    // This function deserializes & decodes args
    // All native callbacks are expected to return only 1 arg
    const unwrapNativeCallback = (argument: unknown): void => {
      const ctx = this.ctx;

      const log = ctx.event({ methodName: event });
      log.start(argument);

      // all events are expected to return JSON with view-id
      if (typeof argument !== 'string') {
        // TODO: custom error
        throw new Error('unknown view');
      }

      let json: object | null = null;
      try {
        json = JSON.parse(argument);
      } catch (error) {
        throw error;
      }

      if (json === null || !(VIEW_KEY in json)) {
        // TODO: custom error
        throw new Error('unknown view');
      }

      const viewId = json[VIEW_KEY];
      if (this._viewId !== viewId) {
        log.success({ skipped: true, _id: this._viewId, argument });
        return;
      }

      let payload: object | null = null;
      if (DATA_KEY in json) {
        const maybePayload = json[DATA_KEY];

        // object | null are valid
        if (typeof maybePayload !== 'object') {
          // TODO: custom error
          throw new Error('unexpected payload');
        }

        payload = maybePayload;
      }

      const result = decodeCallbackArgument(event, payload);

      const cb = callback as (arg: typeof result) => boolean;
      const closeRequest = cb.apply(null, [result]);

      if (closeRequest) {
        onRequestClose();
      }
    };

    const subscription = this.emitter.addListener(event, unwrapNativeCallback);
    this.listeners.push(subscription);

    return subscription;
  }

  public removeAllListeners(): void {
    this.listeners.forEach(listener => listener.remove());
    this.listeners = [];
  }
}
