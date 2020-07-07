//
//  PSTCKAPIClientExtension.swift
//  PaystackiOS
//
//  Created by Jubril Olambiwonnu on 6/19/20.
//  Copyright © 2020 Paystack, Inc. All rights reserved.
//

import Foundation

@objc extension PSTCKAPIClient {
    
    /// Call this method after you collect billing information
    /// - Parameters:
    ///   - transaction: The transaction ID
    ///   - street: The customer's street
    ///   - city: The customer's city
    ///   - zip: The customer's zip code
    ///   - state: The customer's state
    ///   - completion: Callback containing either the payment reference or an error
    public func chargeWithAVS(transaction: String, street: String, city: String, zip: String, state: String, completion: @escaping (String?, Error?) -> Void ) {
        let bodyJSON: [String : Any] = [
            "trans" :  transaction,
            "address" : street,
            "city" : city,
            "zip_code" : zip,
            "state" : state
        ]
        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        let data = PSTCKFormEncoder.formEncryptedData(forDict: bodyJSON, usePublicKey: self.publicKey!, onThisDevice: deviceID)
        PSTCKAPIPostRequest<PSTCKTransaction>.start(with: self, endpoint: "charge/avs", method: "POST", post: data, serializer: PSTCKTransaction() , completion: { response, error in
            self.setProcessingStatus(false)
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(response?.reference, nil)
        })
    }
    
     public func fetchStates(country: String, completion: @escaping ([PSTCKState], Error?) -> Void) {
        let url = URL(string: "https://api.paystack.co/address_verification/states?country=\(country)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion([PSTCKState](), error)
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
                guard responseJSON["status"] as? Bool == true else {
                    print(responseJSON["message"] as? String ?? "Message is nil")
                    return
                }
                if let data = responseJSON["data"] as? [[String : Any]] {
                    let states = data.compactMap{PSTCKState(dict: $0)}
                    completion(states, nil)
                }
            }
        }).resume()
    }
    
    
}


@objc public class PSTCKState: NSObject {
    public var name: String
    public var abbreviation: String
    
    init(name: String, abb: String) {
        self.name = name
        self.abbreviation = abb
    }
    
    init?(dict: [String : Any]) {
        if let name = dict["name"] as? String, let abb = dict["abbreviation"] as? String {
            self.name = name
            self.abbreviation = abb
            return
        }
       return nil
    }
}



