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
    const viewId = this.#viewId;
    callback;

    return $bridge.addEventListener(event, function (arg) {
      console.log(`[UIEVENT]: ${event}; \n\targ: ${arg}; \n\t`);
      const eventView = this.rawValue['view'] ?? null;
      if (viewId !== eventView) {
        return;
      }
      const cb = callback as (argument: typeof arg) => boolean;

      const shouldClose = cb.apply(null, [arg]);

      if (shouldClose) {
        onRequestClose();
      }
    });
  }

  removeAllListeners = $bridge.removeAllEventListeners;
}
