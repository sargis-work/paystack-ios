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
    let paystackPublicKey = "pk_live_2bf31d4aea08ab31f5d0cfd645c7e4f67025d259"
    
    // To set this up, see https://github.com/PaystackHQ/sample-charge-token-backend
    let backendChargeURLString = ""
    
    let capPrice : UInt = 7580 // this is in kobo (so 75Naira 80kobo);
    
    let card : PSTCKCard = PSTCKCard()
    
    // MARK: Overrides
    override func viewDidLoad() {
        // hide token label and email box
        tokenLabel.text=""
        tokenLabel.isHidden = true
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
        
    }
    
    
    // MARK: Properties
    @IBOutlet weak var cardDetailsForm: PSTCKPaymentCardTextField!
    @IBOutlet weak var chargeCardButton: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    
    // MARK: Actions
    @IBAction func cardDetailsChanged(_ sender: PSTCKPaymentCardTextField) {
        chargeCardButton.isEnabled = sender.isValid
    }
    
    @IBAction func chargeCard(_ sender: UIButton) {

        dismissKeyboardIfAny()
        
        // Make sure public key has been set
        if (paystackPublicKey == "" || !paystackPublicKey.hasPrefix("pk_")) {
            showOkayableMessage("You need to set your Paystack public key.", message:"You can find your public key at https://dashboard.paystack.co/#/settings/developer .")
            // You need to set your Paystack public key.
            return
        }
        Paystack.setDefaultPublicKey(paystackPublicKey)
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
            transactionParams.email = "ibrahim@paystack.com";
            
            // transactionParams.subaccount  = "ACCT_80d907euhish8d";
            // transactionParams.bearer  = "subaccount";
            // transactionParams.transaction_charge  = 280;
            
            /* MULTI CURRENCY SUPPORT */
            // transactionParams.currency  = "NGN";
            /* SUBSCRIPTION SUPPORT */
            // transactionParams.plan  = "PLN_sjkhdow898euj";
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyy hh:mm:ss +zzzz"
            transactionParams.reference = "ChargedFromiOSSDK@" + dateFormatter.string(from: Date.init()); // if not supplied, we will give one
//
            PSTCKAPIClient.shared().chargeCard(cardDetailsForm.cardParams, forTransaction: transactionParams, on: self, didEndWithError: { (error) -> Void in
                    // what should I do if an error occured?
                    print(error)
                    if let errorDict = (error._userInfo as! NSDictionary?){
                        if let errorString = errorDict.value(forKeyPath: "com.paystack.lib:ErrorMessageKey") as! String? {
                            self.showOkayableMessage("An error occured", message: errorString)
                        }
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

   
}

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
