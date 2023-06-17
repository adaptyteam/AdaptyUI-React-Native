<h1 align="center" style="border-bottom: none">
<b>
    <a href="https://adapty.io/?utm_source=github&utm_medium=referral&utm_campaign=AdaptySDK-iOS">
        <img src="https://adapty-portal-media-production.s3.amazonaws.com/github/logo-adapty-new.svg">
    </a>
</b>
<br>@adapty/react-native-ui
</h1>

<p align="center">
<a href="https://go.adapty.io/subhub-community-ios-rep"><img src="https://img.shields.io/badge/Adapty-discord-purple"></a>
</p>

**AdaptyUI** is an open-source framework that is an extension to the Adapty SDK that allows you to easily add purchase screens to your application. It’s 100% open-source, native, and lightweight.


### Requirements

- `react-native-adapty` `>=2.4.7`

### Installation

1. Add dependency to your project:
```sh
yarn add @adapty/react-native-ui
```
2. (iOS target) Install iOS pod
```sh
pod install --project-directory=ios/
```

### Usage

#### 0. Configure a paywall view in your Dashboard

Enable and configure no-code paywall as described in [the docs](https://docs.adapty.io/docs/paywall-builder-getting-started).

#### 1. Fetch a paywall

Fetch a paywall that has no-code paywall enabled as described in [the SDK documentation](https://docs.adapty.io/docs/displaying-products).

```tsx
import {adapty} from 'react-native-adapty';

try {
  const paywall = await adapty.getPaywall("YOUR_PAYWALL_ID");
} catch (error) {
  // handle the error
}
```

#### 2. Create & configure a view

Create a view with a fetched paywall

```tsx
import {createPaywallView} from '@adapty/react-native-ui';

const view = await createPaywallView(paywall);
```

Optionally, you can track any of the following events:
```tsx
view.registerEventHandlers({
  onCloseButtonPress() { 
    // ...
    return true;
  },
  onPurchaseCompleted() {
    // ...
    return true;
  },
  onRestoreCompleted() {
    // ...
    return true;
  },
  onProductSelected() { /* ... */ },
  onPurchaseStarted() { /* ... */ },
  onPurchaseCancelled() { /* ... */ },
  onPurchaseFailed() { /* ... */ },
  onRestoreFailed() { /* ... */ },
  onRenderingFailed() { /* ... */ },
  onLoadingProductsFailed() { /* ... */ },
});
```

Returning `true` from an event callback dismisses (closes) a paywall modal & removes all event listeners for this `view`. Note the places, where `return true;` is provided — these events close a paywall modal by default.

#### 3. Present a visual paywall

You can display and hide a modal using these methods consecutively:
```tsx
view.present(); // shows a view

view.dismiss(); // hides a view

```


### 3. Full Documentation and Next Steps

We recommend that you read the [full documentation](https://docs.adapty.io/docs/paywall-builder-getting-started). If you are not familiar with Adapty, then start [here](https://docs.adapty.io/docs).

## Contributing

- Feel free to open an issue, we check all of them or drop us an email at [support@adapty.io](mailto:support@adapty.io) and tell us everything you want.
- Want to suggest a feature? Just contact us or open an issue in the repo.

## Like AdaptyUI?

So do we! Feel free to star the repo ⭐️⭐️⭐️ and make our developers happy!

## License

AdaptyUI is available under the MIT license. [Click here](https://github.com/adaptyteam/AdaptyUI-React-Native/blob/main/LICENSE) for details.

---
