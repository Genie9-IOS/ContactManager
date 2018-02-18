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
 - Author: Ahmad Almasri
 
 - success: Returns Array of Contacts
 - Error: Returns error
 */
enum ContactsFetchResult {
    case success(response: [CNContact])
    case error(error: Error)
}

/**
 Result Enum
 - Author: Ahmad Almasri
 
 - Success: Returns signal  Contact
 - Error: Returns error
 */
enum ContactFetchResult {
    case success(response: CNContact?)
    case error(error: Error)
}

/**
 Result enum
 - Author: Ahmad Almasri
 
 - Success: Returns Bool
 - Error: Returns error
 */
enum ContactOperationResult {
    case success(response: Bool)
    case error(error: Error)
}



/**
 Result enum
 - Author: Ahmad Almasri
 
 - Success: Returns Data object
 - Error: Returns error
 */
enum ContactsToVCardResult {
    case success(response: Data)
    case error(error: Error)
}
/**
 enuum  Transaction
 - Author: Ahmad Almasri
 
 - add: add new contacts
 - update: update contacts
 - delete: delete contacts
 */
enum TransactionContact{
    case add , update , delete
}


// add doc
class ContactManager {
    
    //MARK:- shared
    static let shared = ContactManager()
    
    private init(){}
    
    //MARK:- Permission
    /**
     Requests access to the user's contacts
     - Author: Ahmad Almasri
     
     - Parameter requestGranted: Result as Bool
     */
    func requestAccess(_ requestGranted: @escaping (Bool) -> ()) {
        
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            requestGranted(granted)
        }
    }
    
    
    
    //MARK:- Fetching
    /**
     Fetching Contacts from phone
     - Author: Ahmad Almasri
     
     - Parameter completionHandler: Returns Either [CNContact] or Error.
     */
    func fetchContacts(completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        let contactStore: CNContactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        
        let fetchRequest: CNContactFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
        do {
            try contactStore.enumerateContacts(with: fetchRequest, usingBlock: {
                contact, _ in
                contacts.append(contact)
                
            })
            completionHandler(ContactsFetchResult.success(response: contacts))
        } catch {
            completionHandler(ContactsFetchResult.error(error: error))
        }
    }
    
    /**
     Get CNContact From Identifier
     - Author: Ahmad Almasri
     
     - parameter identifiers: A value that uniquely identifies a contact on the device.
     - parameter completionHandler: Returns Either [CNContact] or Error.
     */
    func getContactFromID(_ identifiers: [String], completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        let contactStore: CNContactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let predicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            completionHandler(ContactsFetchResult.success(response: contacts))
        } catch {
            completionHandler(ContactsFetchResult.error(error: error))
        }
    }
    
    /**
     Get CNContact From Full name
     - Author: Ahmad Almasri
     
     - parameter contact: A value that contact user
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    func getcContactByFullName(_ contact: CNContact, completionHandler: @escaping (_ result: ContactFetchResult) -> ()) {
        
        let contactStore: CNContactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: contact.givenName + " " + contact.familyName)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            completionHandler(ContactFetchResult.success(response: contacts.first))
        } catch {
            completionHandler(ContactFetchResult.error(error: error))
        }
    }
    
    //MARK:- Transaction
    
    /// Transaction Add OR Delete OR Update
    ///      - Author: Ahmad Almasri
    /// - Parameters:
    ///   - contacts:  Array of contacts.
    ///   - transaction:  type of transaction (add , update , delete )
    ///   - completionHandler: Returns Either Bool or Error.
    private func transactionContacts(_ contacts: [CNContact] , transaction:TransactionContact, completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        let store: CNContactStore = CNContactStore()
        let request: CNSaveRequest = CNSaveRequest()
        
        func executeRequest(){
            do {
                try store.execute(request)
                completionHandler(ContactOperationResult.success(response: true))
            } catch let error {
                completionHandler(ContactOperationResult.error(error: error))
            }
        }
        
        func addContact(){
            
            for contact in contacts{
                
                if let mutContact = contact.mutableCopy() as? CNMutableContact{
                    request.add(mutContact, toContainerWithIdentifier: nil)
                }
            }
            executeRequest()
        }
        
        func deleteContact(){
            
            for contact in contacts{
                if let mutContact = contact.mutableCopy() as? CNMutableContact{
                    request.delete(mutContact)
                }
            }
            
            executeRequest()
        }
        
        func updateContact(){
            
            for contact in contacts{
                if let mutContact = contact.mutableCopy() as? CNMutableContact{
                    request.update(mutContact)
                }
            }
            executeRequest()
        }
        
        switch transaction {
        case .add:
            addContact()
            break
        case .update:
            updateContact()
            break
        case .delete:
            deleteContact()
            break
     
        }
        
    }
    
    /**
     Add new Contact.
     - Author: Ahmad Almasri
     
     - parameter contacts: Array of contacts [CN]CNContact.
     - parameter completionHandler: Returns Either Bool or Error.
     */
    func addContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        
        transactionContacts(contacts, transaction: .add) { (result) in
            
            completionHandler(result)
        }
        
    }
    
    /**
     Updates an existing contact in the contact store.
     - Author: Ahmad Almasri
     
     - parameter contacts: Array of contacts [CN]CNContact.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    func updateContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        
        transactionContacts(contacts, transaction: .update) { (result) in
            
            completionHandler(result)
        }
        
    }
    
    /**
     Deletes a contact from the contact store.
     - Author: Ahmad Almasri
     
     - parameter contacts: Array of contacts [CN]CNContact.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    func deleteContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        
        transactionContacts(contacts, transaction: .delete) { (result) in
            
            completionHandler(result)
        }
    }
    
    
    //MARK:- Conversion
    /*
     Convert [CNContacts] TO CSV
     Returns the vCard representation of the specified contacts.
     - Author: Ahmad Almasri
     
     - parameter contacts: Array of contacts.
     - parameter completionHandler: Returns Either Data or Error.
     */
    func contactsToVCardConverter(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactsToVCardResult) -> ()) {
        
        var vcardFromContacts: Data = Data()
        do {
            try vcardFromContacts = CNContactVCardSerialization.data(with: contacts)
            completionHandler(ContactsToVCardResult.success(response: vcardFromContacts))
        } catch {
            completionHandler(ContactsToVCardResult.error(error: error))
        }
        
    }
    
    
    /**
     Convert CSV TO [CNContact]
     Returns the contacts from the vCard data.
     - Author: Ahmad Almasri
     
     - parameter data: Data having contacts.
     - parameter completionHandler: Returns Either [CNContact] or Error.
     
     */
    func vCardToContactConverter(_ data: Data, completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        var contacts: [CNContact] = [CNContact]()
        do {
            try contacts = CNContactVCardSerialization.contacts(with: data) as [CNContact]
            completionHandler(ContactsFetchResult.success(response: contacts))
        } catch {
            completionHandler(ContactsFetchResult.error(error: error))
        }
    }
    
    
    /**
     Save contact into document
     - Author: Ahmad Almasri
     
     - parameter data: Data having contacts.
     - parameter fileName: The name to which the file will be saved.
     - parameter completionHandler: Returns Either CNContact or Error.
     */
    func saveContactInDocument(_ data: Data ,fileName:String = "contacts.contacts",
                               completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            print("file path \(fileURL.absoluteString)")
            
            try data.write(to: fileURL)
            completionHandler(ContactOperationResult.success(response: true))
            
        } catch {
            completionHandler(ContactOperationResult.error(error: error))
        }
    }
    
    
}















extension ContactManager{
    
    //MARK:- Enums
    
    private enum RelationType:String {
        case other, assistant, brother, child, domesticPartner, father
        , friend, manager, mother, parent, partner, referredBy, relative
        , sister, spouse
        
    }
    
    private enum ContactEventType:String{
        case anniversary, other, birthday
    }
    
    private enum CursorItem:String {
        case nickname, relation, contact_event
    }
    private enum InfoType:String {
        case tel, email, image
    }
 
    
    func parseAndroidVCard(_ vCard:String)->String{
        
        let cursorItemResult = matchCursorItem(vCard)
        let telResult = matchInfo(cursorItemResult, infoType: .tel)
        let emailResult = matchInfo(telResult, infoType: .email)
        let imageResult = matchInfo(emailResult, infoType: .image)
        
        return imageResult
        
    }
    
    
    
    private func matching(_ originalText:String, pattern: String)->[NSTextCheckingResult]{
        
        var re: NSRegularExpression!
        do {
            re = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            
        }
        
        let matches = re.matches(in: originalText, options: [], range: NSRange(location: 0, length: originalText.utf16.count))
        return matches
    }

    private func matchCursorItem(_ originalText:String)->String{
        let matchCursorPattern = "X-ANDROID-CUSTOM[;:].*vnd\\.android\\.cursor\\.item\\/(.*?);(.*)"
        var result = originalText
        let matches = matching(originalText, pattern: matchCursorPattern)
        var itemRelationCount  = 0
        var itemContactEventCount  = 0
        for match in matches.reversed()
        {
            let range = match.range(at: 0)
            let cursorItem = (originalText as NSString).substring(with: match.range(at: 1))
            let cursorItemValue = (originalText as NSString).substring(with: match.range(at: 2))
            //  let fullMatch = (originalText as NSString).substring(with: match.range(at: 0))
            
            switch cursorItem {
            case CursorItem.nickname.rawValue :
                result  = (result as NSString).replacingCharacters(in: range, with: "NICKNAME:\(cursorItemValue.split(separator: ";").first ?? "")")
                break
            case CursorItem.relation.rawValue :
                result  = (result as NSString).replacingCharacters(in: range, with: "\(getCursorItemValue(cursorItemValue,index:itemRelationCount, cursorItemType: .relation))")
                itemRelationCount += 1
                break
            case CursorItem.contact_event.rawValue :
                result  = (result as NSString).replacingCharacters(in: range, with: "\(getCursorItemValue(cursorItemValue,index:itemRelationCount, cursorItemType: .contact_event))")
                itemContactEventCount += 1
                break
            default:
                break
            }
            
        }
        return result
    }
    private func matchInfo(_ originalText:String,infoType:InfoType)->String{
        var pattern = ""
        switch infoType {
        case .tel:
            pattern = "TEL;.*CHARSET=UTF-8[;,]ENCODING=QUOTED-PRINTABLE[:,](.*):"
            break
        case .email:
            pattern = "EMAIL;.*\\CHARSET=UTF-8[;,]ENCODING=QUOTED-PRINTABLE[:,](.*)\\:"
            break
        case .image:
            pattern = "PHOTO;ENCODING=.*JPEG:([\\s\\S]*?)(\\n\\n|END:VCARD|\\n\\r)"
            break
      
        }
        var result = originalText
        let matches = matching(originalText, pattern: pattern)
        
        for match in matches.reversed() {
            
            let range = match.range(at: 0)
            let cursorItem = (originalText as NSString).substring(with: match.range(at: 1))
            
            switch infoType{
            case .tel:
                let cursorItemFirstValue = (cursorItem as NSString).components(separatedBy: ";").first ?? ""
                let cursorItemFullValue = decodeQuotedPrintable(message: cursorItemFirstValue.replacingOccurrences(of: ")", with: ""))
            
                result = (result as NSString).replacingCharacters(in: range, with: "TEL;\(cursorItemFullValue):")
                
                break
            case .email:
                let cursorItemFirstValue = (cursorItem as NSString).components(separatedBy: ";").first ?? ""
                let cursorItemFullValue = decodeQuotedPrintable(message: cursorItemFirstValue.replacingOccurrences(of: ")", with: ""))
                
                result = (result as NSString).replacingCharacters(in: range, with: "EMAIL;\(cursorItemFullValue):")
                
                break
            case .image:
                 let cursorItemFullValue = String(cursorItem.filter { !" \n\t\r".contains($0) })
                result = (result as NSString).replacingCharacters(in: range, with: "PHOTO;ENCODING=BASE64;JPEG:\(cursorItemFullValue)")
                break
                
            }
            
            
        }
        return result
    }
    
    private func getCursorItemValue(_ cursorItem: String, index:Int , cursorItemType:CursorItem) -> String {
        var result = [String]()
        let filteredComponenets = cursorItem.split(separator: ";")
        
        for name in filteredComponenets {
            result.append(decodeQuotedPrintable(message:String(name)))
        }
        
        if cursorItemType == CursorItem.relation {
            
            return "item\(index).X-ABRELATEDNAMES:\(result.first ?? "")\nitem\(index).X-ABLabel:\(result.last ?? "")"
            
        }else{
            
            return "item\(index).X-ABDATE:\(result.first ?? "")\nitem\(index).X-ABLabel:\(result.last ?? "")"
            
        }
    }
    
    
    private func decodeQuotedPrintable(message : String) -> String {
        
        var result =    message.replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "=", with: "%").removingPercentEncoding
        // takes a String or a literal
        if (result ?? "").hasPrefix("X-") {
            
            result = (result! as NSString).replacingCharacters(in: NSRange.init(location: 0, length: 2), with: "")
        }
        return result == nil ? message : result!
    }
}

