//
//  ViewController.swift
//  Paystack iOS Exampe (Simple)
//

import UIKit
import Paystack

class ViewController: UIViewController, PSTCKPaymentCardTextFieldDelegate {
    
    // MARK: REPLACE THESE
    // Replace these values with your application's keys
    // Find this at https://dashboard.paystack.co/#/settings/developer
    let paystackPublishableKey = "pk_live_2bf31d4aea08ab31f5d0cfd645c7e4f67025d259"
    
    // To set this up, see https://github.com/PaystackHQ/sample-charge-token-backend
    let backendChargeURLString = ""
    
    let capPrice : UInt = 7580 // this is in kobo (so 75Naira 80kobo);
    
    let card : PSTCKCard = PSTCKCard()
    
    // MARK: Overrides
    override func viewDidLoad() {
        // hide token label and email box
        tokenLabel.text=""
        tokenLabel.isHidden = true
        chargeTokenButton.isHidden=true
        emailText.isHidden=true
        requestTokenButton.isEnabled = false
        chargeCardButton.isEnabled = false
        // clear text from card details
        // comment these to use the sample data set
        super.viewDidLoad();
    }
    
    // MARK: Helpers
    func showOkayableMessage(_ title: String, message: String){
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func dismissKeyboardIfAny(){
        // Dismiss Keyboard if any
        cardDetailsForm.resignFirstResponder()
        emailText.resignFirstResponder()
        
    }
    
    
    // MARK: Properties
    @IBOutlet weak var requestTokenButton: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    @IBOutlet weak var chargeTokenButton: UIButton!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var cardDetailsForm: PSTCKPaymentCardTextField!
    @IBOutlet weak var chargeCardButton: UIButton!
    
    var tokenString: String? {
        return tokenLabel.text
    }
    
    var emailAddress: String? {
        return emailText.text
    }
    
    
    // MARK: Actions
    @IBAction func cardDetailsChanged(_ sender: PSTCKPaymentCardTextField) {
        requestTokenButton.isEnabled = sender.isValid
        chargeCardButton.isEnabled = sender.isValid
    }

    @IBAction func requestToken(_ sender: UIButton) {
        dismissKeyboardIfAny()
        
        
//        card.validateCardReturningError()
        
        // Make sure public key has been set
        if (paystackPublishableKey == "" || !paystackPublishableKey.hasPrefix("pk_")) {
            showOkayableMessage("You need to set your Paystack publishable key.", message:"You can find your publishable key at https://dashboard.paystack.co/#/settings/developer .")
            // You need to set your Paystack publishable key.
            return
        }
        Paystack.setDefaultPublishableKey(paystackPublishableKey)
        // use library to create token request and return a token
        if cardDetailsForm.isValid {
            self.requestTokenButton.isEnabled = false;
            PSTCKAPIClient.shared().createToken(withCard: cardDetailsForm.cardParams) { (token, error) -> Void in
                if let error = error  {
                    print(error)
                    if let errorString = (error._userInfo as! NSDictionary?)?.description {
                        self.showOkayableMessage("An error occured", message: errorString)
                    }
                    self.requestTokenButton.isEnabled = true;
                }
                else if let token = token {
                    self.tokenLabel.text = token.tokenId
                    self.tokenLabel.isHidden = false
                    self.requestTokenButton.isEnabled = true;
                    self.chargeTokenButton.isHidden=false
                    self.emailText.isHidden=false
                }
            }
            self.requestTokenButton.setTitle("Requesting token...", for: UIControlState.disabled)
        }
        
    }
    
    @IBAction func chargeCard(_ sender: UIButton) {

        dismissKeyboardIfAny()
        
        // Make sure public key has been set
        if (paystackPublishableKey == "" || !paystackPublishableKey.hasPrefix("pk_")) {
            showOkayableMessage("You need to set your Paystack publishable key.", message:"You can find your publishable key at https://dashboard.paystack.co/#/settings/developer .")
            // You need to set your Paystack publishable key.
            return
        }
        Paystack.setDefaultPublishableKey(paystackPublishableKey)
        // use library to create charge and get its reference
        if cardDetailsForm.isValid {
            self.chargeCardButton.isEnabled = false;
            
            let transactionParams = PSTCKTransactionParams.init();
            // charging 75naira, 80kobo
            transactionParams.amount = 7580;
            
            do {
                try transactionParams.setCustomFieldValue("iOS SDK", displayedAs: "Paid Via");
                try transactionParams.setCustomFieldValue("Paystack hats", displayedAs: "To Buy");
                try transactionParams.setMetadataValue("iOS SDK", forKey: "paid_via");
            } catch {
                print(error);
            }
            
            // set an email
            transactionParams.email = "";
            
            // transactionParams.subaccount  = "ACCT_80d907euhish8d";
            // transactionParams.bearer  = "subaccount";
            // transactionParams.transaction_charge  = 280;

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyy hh:mm:ss +zzzz"
            transactionParams.reference = "ChargedFromiOSSDK@" + dateFormatter.string(from: Date.init()); // if not supplied, we will give one
//
            PSTCKAPIClient.shared().chargeCard(cardDetailsForm.cardParams, forTransaction: transactionParams, on: self, didEndWithError: { (error) -> Void in
                    // what should I do if an error occured?
                    print(error)
                    if let errorString = (error._userInfo as! NSDictionary?)?.description {
                        self.showOkayableMessage("An error occured", message: errorString)
                    }
                    self.chargeCardButton.isEnabled = true;
                }, didRequestValidation: { (reference) -> Void in
                    self.tokenLabel.text = "requested validation: " + reference
                    self.tokenLabel.isHidden = false
                }, didTransactionSuccess: { (reference) -> Void in
                    self.tokenLabel.text = "succeeded: " + reference
                    self.tokenLabel.isHidden = false
                    self.chargeCardButton.isEnabled = true;
            })
            self.chargeCardButton.setTitle("Charging card...", for: UIControlState.disabled)
            
        }

    }

    @IBAction func chargeToken(_: UIButton) {
        dismissKeyboardIfAny()
        if let _ = tokenString {
            if let e = emailAddress{
                if e.isEmail{
                    
                    if backendChargeURLString != "" {
                        if let url = URL(string: backendChargeURLString  + "/charge") {
                            
                            let session = URLSession(configuration: URLSessionConfiguration.default)
                            let request = NSMutableURLRequest(url: url)
                            request.httpMethod = "POST"
                            let postBody = "token=\(tokenString!)&amountinkobo=\(capPrice)&email=\(emailAddress!)"
                            let postData = postBody.data(using: String.Encoding.utf8, allowLossyConversion: false)
                            session.uploadTask(with: request as URLRequest, from: postData, completionHandler: { data, response, error in
                                let successfulResponse = (response as? HTTPURLResponse)?.statusCode == 200
                                if successfulResponse && error == nil && data != nil{
                                    // All was well
                                    let newStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                                    print(newStr ?? "<Unable to read response>")
                                } else {
                                    if let e=error {
                                        print(e.localizedDescription)
                                    } else {
                                        // There was no error returned though status code was not 200
                                        print("There was an error communicating with your payment backend.")
                                    }
                                    
                                }
                            }).resume()
                            
                            return
                        }
                    }
                    showOkayableMessage("Backend not configured", message:"You created a token! Its value is \(tokenString!). Now configure your backend to accept this token and complete a charge.")
                    return
                }
            }
            showOkayableMessage("Email not provided", message:"You should enter a valid email!")
            return
            
        }
        showOkayableMessage("Token not obtained", message:"You need to create a token before calling charge.")
    }
    
    
}

