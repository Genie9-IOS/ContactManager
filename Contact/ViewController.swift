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
        
        ContactsManagerFacade.fetchContacts { result in
            switch result {
            case .success(response: let contacts):
                print(contacts)
                break
            case .error(error: let error):
                print(error)
                self.showDialog(forError: error)
                break
            }
        }
        
        ContactManager.shared.requestAccess { (isAA) in
            if isAA {
                
                ContactManager.shared.fetchContacts(completionHandler: { (result) in
                    
                })
            }else{
                
            }
        }
    }
}


extension UIViewController {
    func showDialog(forError: Error) {
        // checked what is the error code
        print("showing a dialog for contact perrmission")
    }
}
