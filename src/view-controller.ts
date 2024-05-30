import { AdaptyError, AdaptyPaywall } from 'react-native-adapty';
import { LogContext, LogScope } from 'react-native-adapty/dist/logger';
import { AdaptyPaywallCoder } from 'react-native-adapty/dist/coders/adapty-paywall';

import { $bridge, ParamMap } from './bridge';
import { ViewEmitter } from './view-emitter';

import {
  CreatePaywallViewParamsInput,
  DEFAULT_EVENT_HANDLERS,
  EventHandlers,
} from './types';
import { MethodName } from './types/bridge';

/**
 * Provides methods to control created paywall view
 * @public
 */
export class ViewController {
  /**
   * Intended way to create a ViewController instance.
   * It prepares a native controller to be presented
   * and creates reference between native controller and JS instance
   */
  static async create(
    paywall: AdaptyPaywall,
    params: CreatePaywallViewParamsInput,
  ): Promise<ViewController> {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'createController' });
    log.start({ paywall, params });

    const view = new ViewController();

    const body = new ParamMap();

    const coder = new AdaptyPaywallCoder();
    body.set('paywall', JSON.stringify(coder.encode(paywall)));

    body.set('prefetch_products', params.prefetchProducts ?? true);
    if (params.customTags) {
      body.set('custom_tags', JSON.stringify(params.customTags));
    }

    const result = await view.handle<string>('create_view', body, ctx, log);

    view.id = result;
    return view;
  }

  private id: string | null; // reference to a native view. UUID
  private unsubscribeAllListeners: null | (() => void) = null;

  /**
   * Since constructors in JS cannot be async, it is not
   * preferred to create ViewControllers in direct way.
   * Consider using @link{ViewController.create} instead
   *
   * @remarks
   * Creating ViewController this way does not let you
   * to make native create request and set _id.
   * It is intended to avoid usage
   *
   * @internal
   */
  private constructor() {
    this.id = null;
  }

  private async handle<T>(
    method: MethodName,
    params: ParamMap,
    ctx: LogContext,
    log: LogScope,
  ): Promise<T> {
    try {
      const result = await $bridge.request(method, params, ctx);

      log.success(result);
      return result as T;
    } catch (error) {
      /*
       * Success because error was handled validly
       * It is a developer task to define which errors must be logged
       */
      log.success({ error });
      throw error;
    }
  }

  /**
   * Presents a paywall view as a full-screen modal
   *
   * @remarks
   * Calling `present` upon already visible paywall view
   * would result in an error
   *
   * @throws {AdaptyError}
   */
  public async present(): Promise<void> {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'present' });
    log.start({ _id: this.id });

    if (this.id === null) {
      log.failed({ error: 'no _id' });
      throw this.errNoViewReference();
    }

    const body = new ParamMap();
    body.set('view_id', this.id);

    const result = await this.handle<void>('present_view', body, ctx, log);
    return result;
  }

  /**
   * Dismisses a paywall view
   *
   * @throws {AdaptyError}
   */
  public async dismiss(): Promise<void> {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'dismiss' });
    log.start({ _id: this.id });

    if (this.id === null) {
      log.failed({ error: 'no id' });
      throw this.errNoViewReference();
    }

    const body = new ParamMap();
    body.set('view_id', this.id);

    await this.handle<void>('dismiss_view', body, ctx, log);

    if (this.unsubscribeAllListeners) {
      this.unsubscribeAllListeners();
    }
  }

  /**
   * Creates a set of specific view event listeners
   *
   * @see {@link https://docs.adapty.io/docs/react-native-handling-events | [DOC] Handling View Events}
   *
   * @remarks
   * It registers only requested set of event handlers.
   * Your config is assigned into three event listeners {@link DEFAULT_EVENT_HANDLERS},
   * that handle default closing behavior.
   * - `onCloseButtonPress`
   * - `onAndroidSystemBack`
   * - `onRestoreCompleted`
   * - `onPurchaseCompleted`
   *
   * If you want to override these listeners, we strongly recommend to return `true`
   * from your custom listener to retain default closing behavior.
   *
   * @param {Partial<EventHandlers> | undefined} [eventHandlers] - set of event handling callbacks
   * @returns {() => void} unsubscribe - function to unsubscribe all listeners
   */
  public registerEventHandlers(
    eventHandlers: Partial<EventHandlers> = DEFAULT_EVENT_HANDLERS,
  ): () => void {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'registerEventHandlers' });
    log.start({ _id: this.id });

    if (this.id === null) {
      throw this.errNoViewReference();
    }

    const finalEventHandlers: Partial<EventHandlers> = {
      ...DEFAULT_EVENT_HANDLERS,
      ...eventHandlers,
    };

    // DIY way to tell TS that original arg should not be used
    const deprecateVar = (_target: unknown): _target is never => true;
    if (!deprecateVar(eventHandlers)) {
      return () => {};
    }

    const viewEmitter = new ViewEmitter(this.id);

    Object.keys(finalEventHandlers).forEach(eventStr => {
      const event = eventStr as keyof EventHandlers;

      if (!finalEventHandlers.hasOwnProperty(event)) {
        return;
      }

      const handler = finalEventHandlers[
        event
      ] as EventHandlers[keyof EventHandlers];

      viewEmitter.addListener(event, handler, () => this.dismiss());
    });

    const unsubscribe = () => viewEmitter.removeAllListeners();

    // expose to class to be able to unsubscribe on dismiss
    this.unsubscribeAllListeners = unsubscribe;

    return unsubscribe;
  }

  private errNoViewReference(): AdaptyError {
    // TODO: Make a separate error type once AdaptyError is refactored
    throw new Error('View reference not found');
  }
}
