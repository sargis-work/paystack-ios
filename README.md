# Paystack iOS SDK
<!-- [![Travis](https://img.shields.io/travis/paystackhq/paystack-ios/master.svg?style=flat)](https://travis-ci.org/paystackhq/paystack-ios) -->
[![CocoaPods](https://img.shields.io/cocoapods/v/Paystack.svg?style=flat)](http://cocoapods.org/?q=author%3Apaystack%20name%3Apaystack)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/l/Paystack.svg?style=flat)](https://github.com/paystackhq/paystack-ios/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/p/Paystack.svg?style=flat)](https://github.com/paystackhq/paystack-ios#)

The Paystack iOS SDK make it easy to collect your users' credit card details inside your iOS app. By creating tokens,
Paystack handles the bulk of PCI compliance by preventing sensitive card data from hitting your server.

This library helps collect card details on iOS and OSX, getting a token. This shoulders the burden of PCI compliance by helping you avoid the need to send
card data directly to your server. Instead you send to Paystack's server and get a token which you can charge once in your server-side code. This charge
returns an `authorization_code` if successful. Subsequent charges can then be made using the `authorization_code`.


## Requirements
Our SDK is compatible with iOS apps supporting iOS 8.0 and above. It requires Xcode 8.0+ to build the source.

You will also need to add Keychain Sharing entitlements for your app.

## Integration

We've written a [guide](GUIDE.md) that explains everything from installation, to charging cards and more.

## Example app

There is an example app included in the repository:
- Paystack iOS Example shows a minimal Swift integration with our iOS SDK using PSTCKPaymentCardTextField, a native credit card UI form component we provide. It uses a small example backend to make charges.

To build and run the example apps, open `Paystack.xcworkspace` and choose the appropriate scheme.

### Getting started with the Simple iOS Example App

Note: The example app requires Xcode 8.0 to build and run.

Before you can run the app, you need to provide it with your Paystack public key.

1. If you haven't already, sign up for a [Paystack account](https://dashboard.paystack.com/#/signup) (it takes seconds). Then go to https://dashboard.paystack.co/#/settings/developer.
2. Replace the `paystackPublicKey` constant in ViewController.swift (for the Sample app) with your Test Public Key.

#### Additional Setup if you will be testing chargeToken

1. Head to https://github.com/paystackhq/sample-charge-card-backend and click "Deploy to Heroku" (you may have to sign up for a Heroku account as part of this process). Provide your Paystack test secret key for the `PAYSTACK_TEST_SECRET_KEY` field under 'Env'. Click "Deploy for Free".
2. Replace the `backendChargeURLString` variable in the example iOS app with the app URL Heroku provides you with (e.g. "https://my-example-app.herokuapp.com")

### Making a test Charge

After completing the steps required above, you can make test payments through the app (use credit card number 4123 4501 3100 1381, along with 883 as cvc and any future expiration date) and then view the payments in your Paystack Dashboard!

And the return value from the backend will be displayed in your Output window.

## Misc. notes

### Handling errors

See [PaystackError.h](https://github.com/paystackhq/paystack-ios/blob/master/Paystack/PublicHeaders/PaystackError.h) for a list of error codes that may be returned from the Paystack API.


