/**
 * Valid list of expected parameters to the handlers
 * Must be the same as
 * - iOS RNAConstants.ParamKey
 * @internal
 */
export const ParamKeys = [
  'paywall',
  'locale',
  'prefetch_products',
  'view_id',
] as const;
export type ParamKey = (typeof ParamKeys)[number];

/**
 * Valid list of callable bridge handlers
 * Must be the same as
 * - iOS RNAConstants.MethodName
 * @internal
 */
export const MethodNames = [
  'present_view',
  'dismiss_view',
  'create_view',
] as const;
export type MethodName = (typeof MethodNames)[number];
