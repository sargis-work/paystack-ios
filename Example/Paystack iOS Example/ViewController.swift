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
    
    // To set this up, see https://github.com/PaystackHQ/sample-charge-card-backend
    let backendURLString = "https://infinite-peak-60063.herokuapp.com"
    
    let capPrice : UInt = 7580 // this is in kobo (so 75Naira 80kobo);
    
    let card : PSTCKCard = PSTCKCard()
    
    // MARK: Overrides
    override func viewDidLoad() {
        // hide token label and email box
        tokenLabel.text=nil
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

        if cardDetailsForm.isValid {

            if backendURLString != "" {
                fetchAccessCodeAndChargeCard()
                return
            }
            showOkayableMessage("Backend not configured", message:"To run this sample, please configure your backend.")
            
            
        }

    }
    
    func outputOnLabel(str: String){
        if let former = tokenLabel.text {
            tokenLabel.text = former + "\n" + str
        } else {
            tokenLabel.text = str
        }
    }
    
    func fetchAccessCodeAndChargeCard(){
        if let url = URL(string: backendURLString  + "/new-access-code") {
            print(backendURLString  + "/new-access-code");
            let session = URLSession(configuration: URLSessionConfiguration.default)
            self.outputOnLabel(str: "Requesting access code")
            self.chargeCardButton.isEnabled = false;
            self.chargeCardButton.setTitle("Charging card...", for: UIControlState.disabled)
            session.dataTask(with: url, completionHandler: { data, response, error in
                let successfulResponse = (response as? HTTPURLResponse)?.statusCode == 200
                if successfulResponse && error == nil && data != nil{
                    // All was well
                    if let newCode = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
                        self.outputOnLabel(str: "access code: " + (newCode as String))
                        self.chargeWithSDK(newCode: newCode)
                    } else {
                        print("<Unable to read response>")
                    }
                } else {
                    if let e=error {
                        print(e.localizedDescription)
                        self.outputOnLabel(str: e.localizedDescription)
                    } else {
                        // There was no error returned though status code was not 200
                        print("There was an error communicating with your payment backend.")
                        self.outputOnLabel(str: "There was an error communicating with your payment backend.")
                    }
                    self.chargeCardButton.isEnabled = true;
                    self.chargeCardButton.setTitle("Charge card", for: UIControlState.disabled)

                    
                }
            }).resume()
            
            return
        }
    }
    
    func chargeWithSDK(newCode: NSString){
        let transactionParams = PSTCKTransactionParams.init();
        transactionParams.access_code = newCode as String;
        // use library to create charge and get its reference
        PSTCKAPIClient.shared().chargeCard(self.cardDetailsForm.cardParams, forTransaction: transactionParams, on: self, didEndWithError: { (error, reference) -> Void in
            self.outputOnLabel(str: "Charge errored")
            // what should I do if an error occured?
            print(error)
            if let errorDict = (error._userInfo as! NSDictionary?){
                if let errorString = errorDict.value(forKeyPath: "com.paystack.lib:ErrorMessageKey") as! String? {
                    if let reference=reference {
                        self.showOkayableMessage("An error occured while completing "+reference, message: errorString)
                        self.outputOnLabel(str: reference + ": " + errorString)
                    } else {
                        self.showOkayableMessage("An error occured", message: errorString)
                        self.outputOnLabel(str: errorString)
                    }
                }
            }
            self.chargeCardButton.isEnabled = true;
        }, didRequestValidation: { (reference) -> Void in
            self.outputOnLabel(str: "requested validation: " + reference)
        }, didTransactionSuccess: { (reference) -> Void in
            self.outputOnLabel(str: "succeeded: " + reference)
            self.chargeCardButton.isEnabled = true;
        })
        return
    }

   
}
