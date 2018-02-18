//
//  ViewController.swift
//  ContactManager
//
//  Created by Ahmad Almasri on 2/11/18.
//  Copyright © 2018 Ahmad Almasri. All rights reserved.
//

import UIKit
import Contacts
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        
        if let filepath = Bundle.main.path(forResource: "cn", ofType: "contacts") {
           do {
               var contents = try String(contentsOfFile: filepath)
              // print(contents)
            
                contents = ContactManager.shared.parseAndroidVCard(contents)
            
              if  let data = contents.data(using: String.Encoding.utf8){

                ContactManager.shared.vCardToContactConverter(data, completionHandler: { (result) in

                    switch result {

                    case .success(response: let contacts):
                    //    print(contacts)
                        
                        ContactManager.shared.addContact(contacts, completionHandler: { (result) in

                            switch result {

                            case .success(response: let isSaved):
                                print(isSaved)
                                break

                            case .error(error: let error):
                                print(error)
                                break
                            }
                        })

                        break
                    case .error(error: let error):
                        print(error)
                        break

                    }
                })
                }
            } catch {

        }
       } else {

       }
    
    }
    
}

