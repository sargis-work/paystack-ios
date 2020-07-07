//
//  AddressViewController.swift
//  Paystack iOS Example
//
//  Created by Jubril Olambiwonnu on 6/21/20.
//  Copyright © 2020 Paystack. All rights reserved.
//

import UIKit
import Paystack

class AddressViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet var streetField: UITextField!
    @IBOutlet var cityField: UITextField!
    @IBOutlet var stateField: UITextField!
    @IBOutlet var zipField: UITextField!
    let stateInput = UIPickerView()
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var states = [PSTCKState]()
    var transaction = ""
    
    @IBOutlet var paymentButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        stateInput.dataSource = self
        stateInput.delegate = self
        stateField.inputView = stateInput
        print("country count \(states.count)")
        
    }
    
    @IBAction func onCancelButtonTap(_ sender: Any) {
       
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stateInput.reloadAllComponents()
    }
    
    @IBAction func onButtonTap(_ sender: Any) {
        PSTCKAPIClient.shared().chargeWithAVS(transaction: transaction, street: streetField.text!, city: cityField.text!, zip: zipField.text!, state: stateField.text!, completion: { reference, error in
            guard let reference = reference else {
                if let vc = self.presentingViewController as? ViewController {
                    vc.error = error
                }
                print(error?.localizedDescription)
                return
            }
            
            print(reference)
            if let vc = self.presentingViewController as? ViewController {
                vc.ref = reference
                   }
            self.dismiss(animated: true)
        })
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return states[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return states.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
}
