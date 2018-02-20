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
        
        ContactsManagerFacade.getContactsCount { (result) in
            switch  result {
                
            case .success(response: let count):
                print(count)
            case .error(error: let error):
                print(error)
            }
        
        }
    }
}

