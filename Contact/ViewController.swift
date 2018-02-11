//
//  ViewController.swift
//  ContactManager
//
//  Created by Ahmad Almasri on 2/11/18.
//  Copyright © 2018 Ahmad Almasri. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ContactManager.shared.requestAccess { (allow) in
            if allow {
                
                ContactManager.shared.fetchContacts(completionHandler: { (result) in
                    switch result {
                    case .Success(response: let contacts):
                      _ =  ContactManager.shared.getDeviceContact(contacts.first!)
                        
                        break
                        
                    case .Error(error:  let error):
                        
                        fatalError(error.localizedDescription)
                        break
                 
                    }
                })
            }
            
        }
    }

  

}

