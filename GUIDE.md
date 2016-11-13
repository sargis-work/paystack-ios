# Guide

If you want to build a mobile app like [Afro](http://www.getafrocab.com) and enable people to make purchases directly in your app, our iOS and [Android](https://github.com/PaystackHQ/paystack-android) libraries can help.

Accepting payments in your app after collecting card information can be acieved in either of two ways, which we'll cover in this guide. The `authorization code` from either option can be used on your server in future to charge the cards.

#### Option 1 - Charge the card directly from App
- Charging the credit card and get the transaction `reference`
- Verifying the transaction on your server which provides an `authorizaton code` if successful

or

#### Option 2 - Tokenize on App, charge on server
- Converting the credit card information to a _**single-use**_ `token`
- Sending this token to your server to create a charge which provides an `authorizaton code` if successful

## Getting Started

### Step 1: Install the library

#### Manual installation

We also publish our SDK as a static framework that you can copy directly into your app without any additional tools:

- Head to our [releases page](https://github.com/PaystackHQ/paystack-ios/releases/) and download the framework that's right for you.
- Unzip the file you downloaded.
- In Xcode, with your project open, click on 'File' then 'Add files to "Project"...'.
- Select Paystack.framework in the directory you just unzipped.
- Make sure 'Copy items if needed' is checked.
- Click 'Add'.
- In your project settings, go to the "Build Settings" tab, and make sure -ObjC is present under "Other Linker Flags".

#### Using [CocoaPods](https://cocoapods.org/)

We recommend using [CocoaPods](https://cocoapods.org/) to install the Paystack iOS library, since it makes it easy to keep your app's dependencies up to date.

If you haven't set up Cocoapods before, their site has installation instructions. Then, add pod 'Paystack' to your Podfile, and run pod install.

(Don't forget to use the .xcworkspace file to open your project in Xcode, instead of the .xcodeproj file, from here on out.)

#### Using Carthage

We also support installing our SDK using Carthage. You can simply add github "paystackhq/paystack-ios" to your Cartfile, and follow the Carthage installation instructions.

### Step 2: Configure API keys

First, you'll want to configure Paystack with your publishable API key. We recommend doing this in your `AppDelegate`'s `application:didFinishLaunchingWithOptions:` method so that it'll be set for the entire lifecycle of your app.

```Swift
// AppDelegate.swift

import Paystack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Paystack.setDefaultPublishableKey("pk_test_xxxx")
        return true
    }
}
```

```Objective-C
// AppDelegate.m

#import "AppDelegate.h"
#import <Paystack/Paystack.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Paystack setDefaultPublishableKey:@"pk_test_xxxxx"];
    return YES;
}

@end
```

We've placed a test publishable API key as the PaystackPublishableKey constant in the above snippet. You'll need to swap it out with your live publishable key in production. You can see all your API keys in your dashboard.

### Step 3: Collecting credit card information

#### Test Mode

When you're using your test publishable key, our libraries give you the ability to test your payment flow without having to charge real credit cards.

If you're building your own form or using `PSTCKPaymentCardTextField`, using the card number `4123450131001381` with CVC `883` (along with any future expiration date) will accomplish the same effect.

At some point in the flow of your app, you'll want to obtain payment details from the user. There are two ways to do this. You can (in increasing order of complexity):

- Use our pre-built form component, `PSTCKPaymentCardTextField`, to collect new credit card details
- Build your own credit card form from scratch

#### Using PSTCKPaymentCardTextField

To use our pre-built form component, we'll create a view controller called `PaymentViewController` and add a `PSTCKPaymentCardTextField` property to the view controller.

```Swift
// PaymentViewController.swift

class PaymentViewController: UIViewController, PSTCKPaymentCardTextFieldDelegate {
    let paymentTextField = PSTCKPaymentCardTextField()
}
```

```Objective-C
// PaymentViewController.m

#import "PaymentViewController.h"

@interface PaymentViewController ()<PSTCKPaymentCardTextFieldDelegate>
@property(nonatomic) PSTCKPaymentCardTextField *paymentTextField;
@end
```

Next, let's instantiate the `PSTCKPaymentCardTextField`, set the `PaymentViewController` as its `PSTCKPaymentCardTextFieldDelegate`, and add it to our view.

```Swift
// PaymentViewController.swift

override func viewDidLoad() {
    super.viewDidLoad();
    paymentTextField.frame = CGRectMake(15, 15, CGRectGetWidth(self.view.frame) - 30, 44)
    paymentTextField.delegate = self
    view.addSubview(paymentTextField)
}
```

```Objective-C
// PaymentViewController.m

- (void)viewDidLoad {
    [super viewDidLoad];
    self.paymentTextField = [[PSTCKPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 15, CGRectGetWidth(self.view.frame) - 30, 44)];
    self.paymentTextField.delegate = self;
    [self.view addSubview:self.paymentTextField];
}
```

This will add an `PSTCKPaymentCardTextField` to the controller to accept card numbers, expiration dates, and CVCs. It'll format the input, and validate it on the fly.

When the user enters text into this field, the `paymentCardTextFieldDidChange:` method will be called on our view controller. In this callback, we can enable a save button that allows users to submit their valid cards if the form is valid:

```Swift
func paymentCardTextFieldDidChange(textField: PSTCKPaymentCardTextField) {
    // Toggle navigation, for example
    saveButton.enabled = textField.isValid
}
```

```Objective-C
- (void)paymentCardTextFieldDidChange:(PSTCKPaymentCardTextField *)textField { {
    // Toggle navigation, for example
    self.saveButton.enabled = textField.isValid;
}
```

#### Building your own form

If you build your own payment form, you'll need to collect at least your customers' card numbers, CVC and expiration dates.

### Step 4: Assembling Card information into `PSTCKCardParams`

If you're using `PSTCKPaymentCardTextField`, simply call its `cardParams` property to get the assembled card data.

```Swift
let cardParams = paymentTextField.cardParams as PSTCKCardParams
```

```Objective-C
PSTCKCardParams cardParams = [paymentTextField cardParams];
```

If you are using your own form, you can assemble the data into an `PSTCKCardParams` object thus:

```Swift
let cardParams = PSTCKCardParams.init();

// then set parameters thus from card
cardParams.number = card.number
cardParams.cvc = card.cvc
cardParams.expYear = card.expYear
cardParams.expMonth = card.expMonth

// or directly
cardParams.number = "2963781976222"
cardParams.cvc = "289"
cardParams.expYear = 2018
cardParams.expMonth = 9
```

```Objective-C
PSTCKCardParams cardParams = [[PSTCKCardParams alloc] init];

// then set parameters thus from card
cardParams.number = [card number];
cardParams.cvc = [card cvc];
cardParams.expYear = [card expYear];
cardParams.expMonth = [card expMonth];

// or directly
cardParams.number = "2963781976222";
cardParams.cvc = "289";
cardParams.expYear = 2018;
cardParams.expMonth = 9;
```

### Step 4: Getting payments

Our libraries shoulder the burden of PCI compliance by helping you avoid the need to send card data directly to your server. Instead, our libraries send credit card data directly to our servers, where we can charge them or create tokens which you charge on your server.


#### Step 4 Option 1: Charge Card

If you choose the `chargeCard` route, we charge cards you send using parameters provided in your `PSTCKTransactionParams`. Assemble Transaction parameters into `PSTCKTransactionParams`, and send them along with the `cardParams` to get a charge.

```Swift
@IBAction func charge(sender: UIButton) {
    // cardParams already fetched from our view or assembled by you
    let transactionParams = PSTCKTransactionParams.init();

    transactionParams.amount = 1390;
    do {
        try transactionParams.setCustomFieldValue("iOS SDK", displayedAs: "Paid Via");
        try transactionParams.setCustomFieldValue("Paystack hats", displayedAs: "To Buy");
        try transactionParams.setMetadataValue("iOS SDK", forKey: "paid_via");
    } catch {
        print(error);
    }
    transactionParams.email = "e@ma.il";

    // check https://developers.paystack.co/docs/split-payments-overview for details on how these work
    // transactionParams.subaccount  = "ACCT_80d907euhish8d";
    // transactionParams.bearer  = "subaccount";
    // transactionParams.transaction_charge  = 280;

    // if a reference is not supplied, we will give one
    // transactionParams.reference = "ChargedFromiOSSDK@"

    PSTCKAPIClient.shared().chargeCard(cardParams, forTransaction: transactionParams, on: viewController,
               didEndWithError: { (error) -> Void in
                handleError(error)
            }, didRequestValidation: { (reference) -> Void in
                // an OTP was requested, transaction has not yet succeeded
            }, didTransactionSuccess: { (reference) -> Void in
                // transaction may have succeeded, please verify on server
        })
}
```

```Objective-C
- (IBAction)charge:(UIButton *)sender {
    // cardParams already fetched from our view or assembled by you

    PSTCKTransactionParams transactionParams = [[PSTCKTransactionParams alloc] init];

    transactionParams.amount = 1390;
    transactionParams.email = @"e@ma.il";

    // check https://developers.paystack.co/docs/split-payments-overview for details on how these work
    // transactionParams.subaccount  = @"ACCT_80d907euhish8d";
    // transactionParams.bearer  = @"subaccount";
    // transactionParams.transaction_charge  = 280;

    // if a reference is not supplied, we will give one
    // transactionParams.reference = "ChargedFromiOSSDK@"

    [[PSTCKAPIClient sharedClient] chargeCard:cardParams
                               forTransaction:transactionParams
                                           on: viewController,
                              didEndWithError:^(NSError *error){
                                                [self handleError:error];
                                            }
                         didRequestValidation: ^(NSString *reference){
                                                // an OTP was requested, transaction has not yet succeeded
                                            }
                        didTransactionSuccess: ^(NSString *reference){
                                                // transaction may have succeeded, please verify on server
      }];

}
```

#### Step 4 Option 2: Using Tokens

If you choose the `createToken` route, we convert cards sent to tokens. You should charge these tokens later in your server-side code to get an authorization code.

```Swift
@IBAction func save(sender: UIButton) {
    // cardParams Fetched from our view or built by you
    if let card = cardParams as? PSTCKCardParams {
        PSTCKAPIClient.sharedClient().createTokenWithCard(card) { (token, error) -> Void in
            if let error = error  {
                handleError(error)
            }
            else if let token = token {
                ...
            }
        }
    }
}
```

```Objective-C
- (IBAction)save:(UIButton *)sender {
    // cardParams Fetched from our view or built by you
    [[PSTCKAPIClient sharedClient]
     createTokenWithCard:cardParams
     completion:^(PSTCKToken *token, NSError *error) {
         if (error) {
             [self handleError:error];
         } else {
            // call your createBackendChargeWithToken function
            // A sample is presented in step 6
         }
     }];
}
```

In the example above, we're calling `createTokenWithCard:` when a save button is tapped. The important thing to ensure is the createToken isn't called before the user has finished entering their card details.

Handling error messages and showing activity indicators while we're creating the token is up to you.

### Step 6 Option 1: Sending the reference to your server

The blocks you gave to `chargeCard` will be called whenever Paystack returns with a reference (or error). You'll need to send the reference off to your server so you can verify the transactions.

Here's how it looks:

```Swift
// ViewController.swift

func verifyCharge(reference: String) {
    let url = NSURL(string: "https://example.com/verify")!
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    let postBody = "reference=reference"
    let postData = postBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    session.uploadTaskWithRequest(request, fromData: postData, completionHandler: { data, response, error in
        let successfulResponse = (response as? NSHTTPURLResponse)?.statusCode == 200
        if successfulResponse && error == nil && data != nil{
            // All was well
            let newStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(newStr) // All we did here is log it to the output window
        } else {
            if let e=error {
                print(e.description)
            } else {
                // There was no error returned though status code was not 200
                print("There was an error communicating with your payment backend.")
                // All we did here is log it to the output window
            }

        }
    }).resume()
}
```

```Objective-C
// ViewController.m

- (void)verifyCharge:(String *)reference
                           {
    NSURL *url = [NSURL URLWithString:@"https://example.com/verify"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *body     = [NSString stringWithFormat:@"reference=%@", reference];
    request.HTTPBody   = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data,
                                   NSURLResponse *response,
                                   NSError *error) {
                   if (error) {
                       ...
                   } else {
                       ...
                   }
               }];
    [task resume];
}

```

On the server, you just need to implement an endpoint that will accept the parameter: `reference`. Make sure any communication with your server is SSL secured to prevent eavesdropping.

### Step 6 Option 2: Sending the token to your server

The block you gave to `createToken` will be called whenever Paystack returns with a token (or error). You'll need to send the token off to your server so you can, for example, charge the card.

Here's how it looks:

```Swift
// ViewController.swift

func createBackendChargeWithToken(token: PSTCKToken, amountinkobo: Int, emailAddress: String) {
    let url = NSURL(string: "https://example.com/token")!
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    let postBody = "token=\(token.tokenId!)&amountinkobo=\(amountinkobo)&email=\(emailAddress!)"
    let postData = postBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    session.uploadTaskWithRequest(request, fromData: postData, completionHandler: { data, response, error in
        let successfulResponse = (response as? NSHTTPURLResponse)?.statusCode == 200
        if successfulResponse && error == nil && data != nil{
            // All was well
            let newStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(newStr) // All we did here is log it to the output window
        } else {
            if let e=error {
                print(e.description)
            } else {
                // There was no error returned though status code was not 200
                print("There was an error communicating with your payment backend.")
                // All we did here is log it to the output window
            }

        }
    }).resume()
}
```

```Objective-C
// ViewController.m

- (void)createBackendChargeWithToken:(PSTCKToken *)token,
                            (NSInt *) amountinkobo,
                            (NSString *) emailAddress
                           {
    NSURL *url = [NSURL URLWithString:@"https://example.com/token"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *body     = [NSString stringWithFormat:@"token=%@&amountinkobo=%@&email=%@", token.tokenId, amountinkobo, emailAddress];
    request.HTTPBody   = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data,
                                   NSURLResponse *response,
                                   NSError *error) {
                   if (error) {
                       ...
                   } else {
                       ...
                   }
               }];
    [task resume];
}

```

On the server, you just need to implement an endpoint that will accept the parameters `token`, `email` and `amountinkobo`. Make sure any communication with your server is SSL secured to prevent eavesdropping.

--------------------

### Step 6 Option 1: Implement verification on your server
Verify a charge by calling our REST API. An `authorization_code` will be returned once the card has been charged successfully. You can learn more about our API [here](https://developers.paystack.co/docs/getting-started).

 **Endpoint:** GET: https://api.paystack.co/transaction/verify

 **Documentation:** https://developers.paystack.co/docs/verify-transaction

 **Parameters:**

 - reference - the transaction reference

**Example**

```bash
   $ curl https://api.paystack.co/transaction/verify/ChargedFromiOSSDK%40 \
    -H "Authorization: Bearer SECRET_KEY" \
    -H "Content-Type: application/json" \
    -X GET

```
### Step 6 Option 2: Implement payment on your server
Create a charge by calling our REST API. An `authorization_code` will be returned once the _single-use_ token has been charged successfully. You can learn more about our API [here](https://developers.paystack.co/docs/getting-started).

 **Endpoint:** POST: https://api.paystack.co/transaction/charge_token

 **Documentation:** https://developers.paystack.co/docs/charge-token

 **Parameters:**

 - token - the token you want to charge (required)
 - reference - unique reference
 - email  - customer's email address (required)
 - amount - Amount in Kobo (required)

**Example**

```bash
   $ curl https://api.paystack.co/transaction/charge_token \
    -H "Authorization: Bearer SECRET_KEY" \
    -H "Content-Type: application/json" \
    -d '{"token": "PSTK_r4ec2m75mrgsd8n9", "email": "customer@email.com", "amount": 10000, "reference": "amutaJHSYGWakinlade256"}' \
    -X POST

```
### Using the [Paystack-PHP library](https://github.com/yabacon/paystack-php) or [Paystack PHP class](https://github.com/yabacon/paystack-class)
```php
list($headers, $body, $code) = $paystack->transaction->chargeToken([
                'reference'=>'amutaJHSYGWakinlade256',
                'token'=>'PSTK_r4ec2m75mrgsd8n9',
                'email'=>'customer@email.com',
                'amount'=>10000 // in kobo
              ]);

// check if authorization code was generated
if ((intval($code) === 200) && array_key_exists('status', $body) && $body['status']) {
    // body contains Array with data similar to result below
    $authorization_code = $body['authorization']['authorization_code'];
    // save the authorization_code so you may charge in future
} else {
    // invalid body was returned
    // handle this or troubleshoot
    throw new \Exception('Transaction Initialise returned non-true status');
}

```

**Result**
```json
    {  
        "status": true,
        "message": "Charge successful",
        "data": {
            "amount": 10000,
            "transaction_date": "2016-01-26T15:34:02.000Z",
            "status": "success",
            "reference": "amutaJHSYGWakinlade256",
            "domain": "test",
            "authorization": {
            "authorization_code": "AUTH_d47nbp3x",
            "card_type": "visa",
            "last4": "1111",
            "bank": null
        },
        "customer": {
            "first_name": "John",
            "last_name": "Doe",
            "email": "customer@email.com"
        },
        "plan": 0
    }
```

### Charging Returning Customers
See details for charging returning customers [here](https://developers.paystack.co/docs/charging-returning-customers).
