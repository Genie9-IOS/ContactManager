//
//  ContactManager.swift
//  ContactManager
//
//  Created by Ahmad Almasri on 2/11/18.
//  Copyright © 2018 Ahmad Almasri. All rights reserved.
//

import Foundation
import Contacts

/**
 Result Enum
 
 - Success: Returns Array of Contacts
 - Error: Returns error
 */
public enum ContactsFetchResult {
    case Success(response: [CNContact])
    case Error(error: Error)
}

/**
 Result Enum
 
 - Success: Returns signal  Contact
 - Error: Returns error
 */
public enum ContactFetchResult {
    case Success(response: CNContact?)
    case Error(error: Error)
}

/**
 Result enum
 
 - Success: Returns Bool
 - Error: Returns error
 */
public enum ContactOperationResult {
    case Success(response: Bool)
    case Error(error: Error)
}



/**
 Result enum
 
 - Success: Returns Array of CNContact
 - Error: Returns error
 */
public enum VCardToContactResult {
    case Success(response: [CNContact])
    case Error(error: Error)
}

/**
 Result enum
 
 - Success: Returns Data object
 - Error: Returns error
 */
public enum ContactsToVCardResult {
    case Success(response: Data)
    case Error(error: Error)
}




class ContactManager{
    
    static let shared = ContactManager()
    
    
    /**
     Requests access to the user's contacts
     
     - Parameter requestGranted: Result as Bool
     */
    public func requestAccess(_ requestGranted: @escaping (Bool) -> ()) {
        CNContactStore().requestAccess(for: .contacts) { grandted, _ in
            requestGranted(grandted)
        }
    }
    
    /**
     Fetching Contacts from phone
    
     - Parameter completionHandler: Returns Either [CNContact] or Error.
     */
    public func fetchContacts(completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        let contactStore: CNContactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let fetchRequest: CNContactFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
        do {
            try contactStore.enumerateContacts(with: fetchRequest, usingBlock: {
                contact, _ in
                contacts.append(contact) })
            completionHandler(ContactsFetchResult.Success(response: contacts))
        } catch {
            completionHandler(ContactsFetchResult.Error(error: error))
        }
    }
    /**
     Get CNContact From Identifier
     
     - parameter identifier: A value that uniquely identifies a contact on the device.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    public func getContactFromID(Identifires identifiers: [String], completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        let contactStore: CNContactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let predicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            completionHandler(ContactsFetchResult.Success(response: contacts))
        } catch {
            completionHandler(ContactsFetchResult.Error(error: error))
        }
    }
    
    /**
     Add new Contact.
     
     - parameter mutContact: A mutable value object for the contact properties, such as the first name and the phone number of a contact.
     - parameter completionHandler: Returns Either Bool or Error.
     */
    public func addContact(Contact mutContact: CNMutableContact, completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        let store: CNContactStore = CNContactStore()
        let request: CNSaveRequest = CNSaveRequest()
        request.add(mutContact, toContainerWithIdentifier: nil)
        do {
            try store.execute(request)
            completionHandler(ContactOperationResult.Success(response: true))
        } catch {
            completionHandler(ContactOperationResult.Error(error: error))
        }
    }
    
    /**
     Updates an existing contact in the contact store.
     
     - parameter mutContact: A mutable value object for the contact properties, such as the first name and the phone number of a contact.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    public func updateContact(Contact mutContact: CNMutableContact, completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        let store: CNContactStore = CNContactStore()
        let request: CNSaveRequest = CNSaveRequest()
        request.update(mutContact)
        do {
            try store.execute(request)
            completionHandler(ContactOperationResult.Success(response: true))
        } catch {
            completionHandler(ContactOperationResult.Error(error: error))
        }
    }
    
    /**
     Deletes a contact from the contact store.
     
     - parameter mutContact: A mutable value object for the contact properties, such as the first name and the phone number of a contact.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    public func deleteContact(Contact mutContact: CNMutableContact, completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        let store: CNContactStore = CNContactStore()
        let request: CNSaveRequest = CNSaveRequest()
        request.delete(mutContact)
        do {
            try store.execute(request)
            completionHandler(ContactOperationResult.Success(response: true))
        } catch {
            completionHandler(ContactOperationResult.Error(error: error))
        }
    }
    /*
     Convert [CNContacts] TO CSV
     Returns the vCard representation of the specified contacts.
     
     - parameter contacts: Array of contacts.
     - parameter completionHandler: Returns Either Data or Error.
     */
    public func contactsToVCardConverter(contacts: [CNContact], completionHandler: @escaping (_ result: ContactsToVCardResult) -> ()) {
        
        var vcardFromContacts: Data = Data()
        do {
            try vcardFromContacts = CNContactVCardSerialization.data(with: contacts)
            completionHandler(ContactsToVCardResult.Success(response: vcardFromContacts))
        } catch {
            completionHandler(ContactsToVCardResult.Error(error: error))
        }
        
    }
    
    
    /**
     Convert CSV TO [CNContact]
     Returns the contacts from the vCard data.
     
     - parameter data: Data having contacts.
     - parameter completionHandler: Returns Either [CNContact] or Error.
     
     */
    public func VCardToContactConverter(data: Data, completionHandler: @escaping (_ result: VCardToContactResult) -> ()) {
        var contacts: [CNContact] = [CNContact]()
        do {
            try contacts = CNContactVCardSerialization.contacts(with: data) as [CNContact]
            completionHandler(VCardToContactResult.Success(response: contacts))
        } catch {
            completionHandler(VCardToContactResult.Error(error: error))
        }
    }
    
    /**
        Save contact into document
     
     - parameter data: Data having contacts.
     - parameter fileName: The name to which the file will be saved.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    public func saveContactInDocument(data: Data ,fileName:String = "contacts.contacts",
                                      completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            completionHandler(ContactOperationResult.Success(response: true))
            
        } catch {
            completionHandler(ContactOperationResult.Error(error: error))
            
        }
    }
    
    
    /**
     Get CNContact From Full name
     
     - parameter contact: A value that contact user 
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    public func contactIsExist(contact: CNContact, completionHandler: @escaping (_ result: ContactFetchResult) -> ()) {
        
        let contactStore: CNContactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: contact.givenName + " " + contact.familyName)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            completionHandler(ContactFetchResult.Success(response: contacts.first))
        } catch {
            completionHandler(ContactFetchResult.Error(error: error))
        }
    }
    
}

