import { AdaptyPaywall } from 'react-native-adapty';
import { CreatePaywallViewParamsInput } from './types';
import { ViewController } from './view-controller';

export async function createPaywallView(
  paywall: AdaptyPaywall,
  params: CreatePaywallViewParamsInput = {},
): Promise<ViewController> {
  const controller = await ViewController.create(paywall, params);

  return controller;
}
