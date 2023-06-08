import { AdaptyError, AdaptyPaywall } from 'react-native-adapty';
import { LogContext } from 'react-native-adapty/lib/dist/logger';
import { AdaptyPaywallCoder } from 'react-native-adapty/lib/dist/internal/coders/AdaptyPaywall';

import { CreatePaywallViewParamsInput, EventHandlers } from './types';
import { $call, MODULE_ARG_KEYS } from './bridge';
import { ViewEmitter } from './view-emitter';

/**
 * Provides methods to control created paywall view
 * @public
 */
export class ViewController {
  private $call = $call;
  private _id: string | null; // reference to a native view. UUID

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
    this._id = null;
  }

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

    const encodedPaywall = new AdaptyPaywallCoder(paywall).encode(ctx);
    const args = {
      [MODULE_ARG_KEYS.PAYWALL]: JSON.stringify(encodedPaywall),
      [MODULE_ARG_KEYS.PREFETCH_PRODUCTS]: params.prefetchProducts ?? true,
    };

    try {
      const result = await view.$call('create_view', args, ctx);

      view._id = result;

      log.success({ result });
      return view;
    } catch (nativeError) {
      const error = AdaptyError.tryWrap(nativeError);

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
   * @throws AdaptyError
   */
  public async present(): Promise<void> {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'present' });
    log.start({ _id: this._id });

    if (this._id === null) {
      log.failed({ error: 'no _id' });
      throw this.errNoViewReference();
    }

    const args = { [MODULE_ARG_KEYS.VIEW_ID]: this._id };

    try {
      const result = await this.$call('present_view', args, ctx);

      log.success({ result });
    } catch (nativeError) {
      const error = AdaptyError.tryWrap(nativeError);

      log.success({ error });
      throw error;
    }
  }

  /**
   * Dismisses a paywall view
   *
   * @throws AdaptyError
   */
  public async dismiss(): Promise<void> {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'dismiss' });
    log.start({ _id: this._id });

    if (this._id === null) {
      log.failed({ error: 'no _id' });
      throw this.errNoViewReference();
    }

    const args = { [MODULE_ARG_KEYS.VIEW_ID]: this._id };

    try {
      const result = await this.$call('dismiss_view', args, ctx);

      if (this.unsubscribeAllListeners) {
        this.unsubscribeAllListeners();
      }

      log.success({ result });
    } catch (nativeError) {
      const error = AdaptyError.tryWrap(nativeError);

      log.success({ error });
      throw error;
    }
  }

  /**
   * Creates a set of specific event listeners
   *
   *
   * @throws AdaptyError
   */
  public registerEventHandlers(eventHandlers: Partial<EventHandlers>) {
    const ctx = new LogContext();

    const log = ctx.call({ methodName: 'registerEventHandlers' });
    log.start({ _id: this._id });

    if (this._id === null) {
      throw this.errNoViewReference();
    }

    const viewEmitter = new ViewEmitter(this._id);

    Object.keys(eventHandlers).forEach(eventStr => {
      const event = eventStr as keyof EventHandlers;

      if (!eventHandlers.hasOwnProperty(event)) {
        return;
      }

      const handler = eventHandlers[
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
    // TODO: normar
    throw new Error('View reference not found');
  }
}
