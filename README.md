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
Our SDK is compatible with iOS apps supporting iOS 7.0 and above. It requires Xcode 7.0+ to build the source.

## Integration

We've written a [guide](GUIDE.md) that explains everything from installation, to creating payment tokens and more.

## Example app

There is an example app included in the repository:
- Paystack iOS Example shows a minimal Swift integration with our iOS SDK using PSTCKPaymentCardTextField, a native credit card UI form component we provide. It uses a small example backend to make charges.

To build and run the example apps, open `Paystack.xcworkspace` and choose the appropriate scheme.

### Getting started with the Simple iOS Example App

Note: The example app requires Xcode 7.0 to build and run.

Before you can run the app, you need to provide it with your Paystack publishable key.

1. If you haven't already, sign up for a [Paystack account](https://dashboard.paystack.com/#/signup) (it takes seconds). Then go to https://dashboard.paystack.co/#/settings/developer.
2. Replace the `paystackPublishableKey` constant in ViewController.swift (for the Sample app) with your Test Publishable Key.
3. Head to https://github.com/paystackhq/sample-charge-token-backend and click "Deploy to Heroku" (you may have to sign up for a Heroku account as part of this process). Provide your Paystack test secret key for the `PAYSTACK_TEST_SECRET_KEY` field under 'Env'. Click "Deploy for Free".
4. Replace the `backendChargeURLString` variable in the example iOS app with the app URL Heroku provides you with (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app (use credit card number 4123 4501 3100 1381, along with 883 as cvc and any future expiration date) and then view the payments in your Paystack Dashboard! 

And the return value from the backend will be displayed in your Output window.

## Running the tests

1. Open Paystack.xcworkspace
1. Choose the "iOS Tests" or "OS X Tests" scheme
1. Run Product -> Test

## Misc. notes

### Handling errors

See [PaystackError.h](https://github.com/paystackhq/paystack-ios/blob/master/Paystack/PublicHeaders/PaystackError.h) for a list of error codes that may be returned from the Paystack API.

### Validating PSTCKCards

You have a few options for handling validation of credit card data on the client, depending on what your application does.  Client-side validation of credit card data is not required since our API will correctly reject invalid card information, but can be useful to validate information as soon as a user enters it, or simply to save a network request.

The simplest thing you can do is to populate an `PSTCKCard` object and, before sending the request, call `- (BOOL)validateCardReturningError:` on the card.  This validates the entire card object, but is not useful for validating card properties one at a time.

To validate `PSTCKCard` properties individually, you should use the following:

 - (BOOL)validateNumber:error:
 - (BOOL)validateCvc:error:
 - (BOOL)validateExpMonth:error:
 - (BOOL)validateExpYear:error:

These methods follow the validation method convention used by [key-value validation](http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/KeyValueCoding/Articles/Validation.html).  So, you can use these methods by invoking them directly, or by calling `[card validateValue:forKey:error]` for a property on the `PSTCKCard` object.

When using these validation methods, you will want to set the property on your card object when a property does validate before validating the next property.  This allows the methods to use existing properties on the card correctly to validate a new property.  For example, validating `5` for the `expMonth` property will return YES if no `expYear` is set.  But if `expYear` is set and you try to set `expMonth` to 5 and the combination of `expMonth` and `expYear` is in the past, `5` will not validate.  The order in which you call the validate methods does not matter for this though.
