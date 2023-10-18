import type { EventHandlers } from './types';
import { $bridge } from './bridge';
import { EmitterSubscription } from 'react-native';

type EventName = keyof EventHandlers;

// Emitting view ID is passed in JSON["_view_id"]
// So that no all visible views would emit this event
// Must be in every callback response in the form of UUID string
// const KEY_VIEW = 'view_id';

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
  #viewId: string;

  constructor(viewId: string) {
    this.#viewId = viewId;
    $bridge.addEventListener;
  }

  public addListener(
    event: EventName,
    callback: EventHandlers[EventName],
    onRequestClose: () => Promise<void>,
  ): EmitterSubscription {
    // Native layer emits callbacks with serialized args
    // This function deserializes & decodes args
    // All native callbacks are expected to return only 1 arg
    return $bridge.addRawEventListener(event, arg => {
      arg;
      callback(this.#viewId as any);
      onRequestClose();
      // const ctx = this.#ctx;
      // const log = ctx.event({ methodName: event });
      // log.start(arg);
      // // all events are expected to return JSON with view-id
      // if (typeof arg !== 'string') {
      //   // TODO: custom error
      //   throw new Error('unknown view');
      // }
      // let json: object | null = null;
      // try {
      //   json = JSON.parse(arg);
      // } catch (error) {
      //   throw error;
      // }
      // if (json === null || !(KEY_VIEW in json)) {
      //   // TODO: custom error
      //   throw new Error('unknown view');
      // }
      // const viewId = json[KEY_VIEW];
      // if (this.#viewId !== viewId) {
      //   log.success({ skipped: true, _id: this.#viewId, argument: arg });
      //   return;
      // }
      // let payload: object | null = null;
      // if (DATA_KEY in json) {
      //   const maybePayload = json[DATA_KEY];
      //   // object | null are valid
      //   if (typeof maybePayload !== 'object') {
      //     // TODO: custom error
      //     throw new Error('unexpected payload');
      //   }
      //   payload = maybePayload;
      // }
      // const result = decodeCallbackArgument(event, payload);
      // const cb = callback as (arg: typeof result) => boolean;
      // const closeRequest = cb.apply(null, [result]);
      // if (closeRequest) {
      //   onRequestClose();
      // }
    });
  }

  removeAllListeners = $bridge.removeAllEventListeners;
}
