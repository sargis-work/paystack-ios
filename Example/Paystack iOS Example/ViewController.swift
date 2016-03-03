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
    let paystackPublishableKey = ""
    
    // To set this up, see https://github.com/PaystackHQ/sample-charge-token-backend
    let backendChargeURLString = ""
    
    let capPrice : UInt = 10000 // this is in kobo (so 100 Naira); 
    
    let card : PSTCKCard = PSTCKCard()
    
    // MARK: Overrides
    override func viewDidLoad() {
        // hide token label and email box
        tokenLabel.text=""
        tokenLabel.hidden = true
        chargeTokenButton.hidden=true
        emailText.hidden=true
        requestTokenButton.enabled = false
        // clear text from card details
        // comment these to use the sample data set
        super.viewDidLoad();
    }
    
    // MARK: Helpers
    func showOkayableMessage(title: String, message: String){
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert
        )
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
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
    
    var tokenString: String? {
        return tokenLabel.text
    }
    
    var emailAddress: String? {
        return emailText.text
    }
    
    
    // MARK: Actions
    @IBAction func cardDetailsChanged(sender: PSTCKPaymentCardTextField) {
        requestTokenButton.enabled = sender.valid
    }
    @IBAction func requestToken(sender: UIButton) {
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
        if cardDetailsForm.valid {
            PSTCKAPIClient.sharedClient().createTokenWithCard(cardDetailsForm.cardParams) { (token, error) -> Void in
                if let error = error  {
                    print(error.description)
                }
                else if let token = token {
                    self.tokenLabel.text = token.tokenId
                    self.tokenLabel.hidden = false
                    self.chargeTokenButton.hidden=false
                    self.emailText.hidden=false
                }
            }
        }
        
    }
    
    @IBAction func chargeToken(_: UIButton) {
        dismissKeyboardIfAny()
        if let _ = tokenString {
            if let e = emailAddress{
                if e.isEmail{
                    
                    if backendChargeURLString != "" {
                        if let url = NSURL(string: backendChargeURLString  + "/charge") {
                            
                            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
                            let request = NSMutableURLRequest(URL: url)
                            request.HTTPMethod = "POST"
                            let postBody = "token=\(tokenString!)&amountinkobo=\(capPrice)&email=\(emailAddress!)"
                            let postData = postBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                            session.uploadTaskWithRequest(request, fromData: postData, completionHandler: { data, response, error in
                                let successfulResponse = (response as? NSHTTPURLResponse)?.statusCode == 200
                                if successfulResponse && error == nil && data != nil{
                                    // All was well
                                    let newStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                                    print(newStr)
                                } else {
                                    if let e=error {
                                        print(e.description)
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

