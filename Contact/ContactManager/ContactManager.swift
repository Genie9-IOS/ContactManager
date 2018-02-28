//
//  ContactManager.swift
//  ContactManager
//
//  Created by Ahmad Almasri on 2/11/18.
//  Copyright © 2018 Ahmad Almasri. All rights reserved.
//

import Foundation
import Contacts
import UIKit
/**
 Represents the generic output result when working with contacts, such as fetching or adding (from vcard).
 
 - Author: Ahmad Almasri
 
 - success: Returns Array of Contacts
 - error: Returns error
 */
enum ContactsFetchResult {
    case success(response: [CNContact])
    case error(error: Error)
    case cancelled()
}

/**
 Represents the generic output result when working with a single contact, such as fetching a contact -to check the duplication-.
 
 - Author: Ahmad Almasri
 
 - success: Returns signal  Contact
 - error: Returns error
 */
enum ContactFetchResult {
    case success(response: CNContact?)
    case error(error: Error)
    
}

/**
 Represents the output result of working with operation tasks, such as add, update or delete.
 
 - Author: Ahmad Almasri
 
 - Success: Returns Bool
 - Error: Returns error
 */
enum ContactOperationResult {
    case success(response: Bool)
    case error(error: Error)
}

/**
 Represents the output result of converting the contacts to vcard format.
 - Author: Ahmad Almasri
 
 - Success: Returns Data object
 - Error: Returns error
 */
enum ContactsToVCardResult {
    case success(response: Data)
    case error(error: Error)
    case cancelled()
}

/**
 Represents the output result of contacts count.
 - Author: Ahmad Almasri
 
 - Success: Returns number of contacts
 - Error: Returns error
 */
enum ContactsCountResult {
    case success(response: Int)
    case error(error: Error)
}

/**
 Represents the contacts transaction type to be done when working with contacts.
 - Author: Ahmad Almasri
 
 - add: add new contacts
 - update: update contacts
 - delete: delete contacts
 */
private enum TransactionContact {
    case add, update, delete
}

/**
 Enum relation types from android
 - Author: Ahmad Almasri
 
 - other: custom label relation = 0
 - assistant:  assistant relation in android = 1
 - brother: brother relation in android = 2
 - child:  child relation in android = 3
 - domesticPartner:  domesticPartner relation in android = 4 Note: 4 and 10 same relation in ios
 - father:  father relation in android = 5
 - friend:  friend relation in android = 6
 - manager:  manager relation in android = 7
 - mother:  mother relation in android = 8
 - parent:  parent relation in android = 9
 - partner:  partner relation in android = 10
 - referredBy:  referredBy relation in android = 11  Note: not available ios used custom label
 - relative:  relative relation in android = 12  Note: not available ios used custom label
 - sister:  sister relation in android = 13
 - spouse:  spouse relation in android = 14
 */
private enum RelationType:String {
    case other = ""
    case assistant = "_$!<Assistant>!$_"
    case brother = "_$!<Brother>!$_"
    case child = "_$!<Child>!$_"
    case domesticPartner = "_$!<Parent>!$_"
    case father = "_$!<Father>!$_"
    case friend = "_$!<Friend>!$_"
    case manager = "_$!<Manager>!$_"
    case mother = "_$!<Mother>!$_"
    case parent = "_$!<Parent>!$_ "
    case partner = "_$!<Partner>!$_"
    case referredBy = "Referred By"
    case relative = "Relative"
    case sister = "_$!<Sister>!$_"
    case spouse = "_$!<Spouse>!$_"
    
    static  func getValue(_ hashValue:Int)->RelationType{
        switch hashValue {
        case 0:
            return .other
        case 1:
            return .assistant
        case 2:
            return .brother
        case 3:
            return .child
        case 4:
            return .domesticPartner
        case 5:
            return .father
        case 6:
            return .friend
        case 7:
            return .manager
        case 8:
            return .mother
        case 9:
            return .parent
        case 10:
            return .partner
        case 11:
            return .referredBy
        case 12:
            return .relative
        case 13:
            return .sister
        case 14:
            return .sister
        default:
            return .spouse
        }
    }
    
    
}

/**
 Enum Contact Event types from android
 - Author: Ahmad Almasri
 
 - anniversary:  anniversary Contact Event in android = 1
 - other: other Contact Event in android = 2
 - empty: custom label Contact Event = 0
 - birthday: other Contact Event in android = 3
 */
private enum ContactEventType:String{
    
    case anniversary = "_$!<Anniversary>!$_"
    case other = "_$!<Other>!$_"
    case empty = ""
    case birthday = "_$!<Birthday>!$_"
    
    static  func getValue(_ hashValue:Int)->ContactEventType{
        switch hashValue {
            
        case 1:
            return .anniversary
        case 2:
            return .other
        case 3:
            return .birthday
        default:
            return .empty
            
        }
    }
}
/**
 check regx group 1 type
 - Author: Ahmad Almasri
 
 - nickname: nickname cursor item type
 - relation: relation cursor item type
 - contact_event: contact_event cursor item type
 */
private enum CursorItem:String {
    case nickname
    case relation
    case contact_event
}
/**
 InfoType matching regx pattern type
 - Author: Ahmad Almasri
 
 - tel:  is tel using tel pattern
 - email: is email using email pattern
 - image: is image using image pattern
 */
private enum InfoType:String {
    case tel, email, image
}
/**
 Regex pattern
 
 - matchCursorPattern: match Cursor pattern
 - telPattern: match tel pattern
 - emailPattern: match email pattern
 - imagePattern: match image pattern
 */
private enum RegexVCard:String{
    case matchCursorPattern = "X-ANDROID-CUSTOM[;:].*vnd\\.android\\.cursor\\.item\\/(.*?);(.*)"
    case telPattern = "TEL;.*CHARSET=UTF-8[;,]ENCODING=QUOTED-PRINTABLE[:,](.*):"
    case emailPattern = "EMAIL;.*\\CHARSET=UTF-8[;,]ENCODING=QUOTED-PRINTABLE[:,](.*)\\:"
    case imagePattern = "PHOTO;ENCODING=.*JPEG:([\\s\\S]*?)(\\n\\n|END:VCARD|\\n\\r)"
}

/**
 custom Error code
 
 - accessDenied: Don't have permission
 */
private enum ErrorCode:Int {
    case accessDenied = 2000
}
/**
 This manager class is responsibile for any needed functionality to work with contacts, such as the CRUD transaction for all contacts as one chunk or as a single contact. Also, it handles the mapping of custom fields reveived from other platforms -such as Android so far-.
 
 - Author: Ahmad Almasri
 
 - Warning: By default, the accessing of the init of this class is denied, However, make sure to access this function by it *shared* property.
 */
class ContactManager {
    // TODO: name the dispatch queues labels.
    
    //MARK:- Declarations
    private var paused:Bool = false
    private var isCancelled = false
    private var pauseCondition:NSCondition!
    
    //MARK:- shared
    /// the singleton instance for accessing the manager.
    // (Ahmad Almasri) remove shared instance because this manager call from multiple operation
    // static let shared = ContactManager()
    
    //MARK:- Inits
    //  private init() {}
    
    //MARK:- Fetching
    /**
     Fetching Contacts from phone on Background thread
     - Author: Ahmad Almasri
     
     - Parameter completionHandler: Returns Either [CNContact] or Error.
     - Parameter result: enum type ContactsFetchResult.
     
     - Warning:If The user has more than one container (i.e. an Exchange and an iCloud account which both are used to store contacts), this would only load the contacts from the account that is configured as the default. Therefore, it would not load all contacts.
     
     for  get all the containers and iterate over them to extract all contacts from each of them
     */
    //TODO : Missing "This func needed locking thread because multiple call  "
    func fetchContactsOnBackgroundThread(completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        let concurrentQueue = DispatchQueue(label: getQueueLabel(#function))
        concurrentQueue.async {
            let contactStore = CNContactStore()
            var contacts = [CNContact]()
            var allContainers  = [CNContainer]()
            do {
                allContainers = try contactStore.containers(matching: nil)
                
                self.waitifPaused()
                if self.isCancelled{
                    completionHandler(ContactsFetchResult.cancelled())
                    return
                }
                
                for container in allContainers {
                    
                    self.waitifPaused()
                    if self.isCancelled{
                        completionHandler(ContactsFetchResult.cancelled())
                        return
                    }
                    
                    let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                    let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()
                        ,CNContactImageDataAvailableKey as CNKeyDescriptor
                        ,CNContactThumbnailImageDataKey as CNKeyDescriptor
                        ,CNContactImageDataKey as CNKeyDescriptor])
                    
                    self.waitifPaused()
                    if self.isCancelled{
                        completionHandler(ContactsFetchResult.cancelled())
                        return
                    }
                    
                    contacts.append(contentsOf: containerResults)
                }
                completionHandler(ContactsFetchResult.success(response: contacts))
            } catch {
                completionHandler(ContactsFetchResult.error(error: error))
            }
            
        }
    }
    
    /**
     Fetching Contacts from phone
     - Author: Ahmad Almasri
     
     - Parameter completionHandler: Returns Either [CNContact] or Error.
     - Parameter result: enum type ContactsFetchResult.
     
     - Warning:If The user has more than one container (i.e. an Exchange and an iCloud account which both are used to store contacts), this would only load the contacts from the account that is configured as the default. Therefore, it would not load all contacts .
     
     for  get all the containers and iterate over them to extract all contacts from each of them
     */
    func fetchContacts(completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        var allContainers  = [CNContainer]()
        
        do {
            allContainers = try contactStore.containers(matching: nil)
            
            self.waitifPaused()
            if isCancelled{
                
                completionHandler(ContactsFetchResult.cancelled())
                return
            }
            
            for container in allContainers {
                
                self.waitifPaused()
                if isCancelled{
                    completionHandler(ContactsFetchResult.cancelled())
                    return
                }
                
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
                
                self.waitifPaused()
                if isCancelled{
                    completionHandler(ContactsFetchResult.cancelled())
                    return
                }
                
                contacts.append(contentsOf: containerResults)
                
            }
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
     - parameter result: enum type ContactsFetchResult.
     */
    func getContactsByIdentifiers(_ identifiers: [String], completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let predicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
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
     - parameter result: enum type ContactFetchResult.
     */
    func getcContactByFullName(_ contact: CNContact, completionHandler: @escaping (_ result: ContactFetchResult) -> ()) {
        
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let predicate = CNContact.predicateForContacts(matchingName: contact.givenName + " " + contact.familyName)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            completionHandler(ContactFetchResult.success(response: contacts.first))
        } catch {
            completionHandler(ContactFetchResult.error(error: error))
        }
    }
    
    /**
     get number of contacts
     
     - Parameter completionHandler: completionHandler: Returns Either contactCount or Error
     - Parameter result: enum type ContactsCountResult.
     
     - Warning:If The user has more than one container (i.e. an Exchange and an iCloud account which both are used to store contacts), this would only load the contacts from the account that is configured as the default. Therefore, it would not load all contacts .
     
     for  get all the containers and iterate over them to extract all contacts from each of them
     */
    func getContactsCount(completionHandler: @escaping (_ result: ContactsCountResult) -> ()){
        
        let contactStore = CNContactStore()
        var contactsCount = 0
        var allContainers  = [CNContainer]()
        
        do {
            allContainers = try contactStore.containers(matching: nil)
            for container in allContainers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
                contactsCount += containerResults.count
            }
            completionHandler(ContactsCountResult.success(response: contactsCount))
        } catch {
            completionHandler(ContactsCountResult.error(error: error))
        }
        
    }
    
    //MARK:- Transaction
    /**
     Transaction Add OR Delete OR Update
     - Author: Ahmad Almasri
     - Parameters:
     - contacts:  Array of contacts.
     - transaction:  type of transaction (add , update , delete )
     - completionHandler: Returns Either Bool or Error.
     - result: enum type ContactOperationResult.
     */
    private func transactionContacts(_ contacts: [CNContact] , transaction:TransactionContact, completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        let store = CNContactStore()
        let request = CNSaveRequest()
        
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
     - parameter result: enum type ContactOperationResult.
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
     - parameter result: enum type ContactOperationResult.
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
     - parameter result: enum type ContactOperationResult.
     */
    func deleteContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()) {
        
        transactionContacts(contacts, transaction: .delete) { (result) in
            
            completionHandler(result)
        }
    }
    
    
    //MARK:- Conversions
    /*
     Convert [CNContacts] TO CSV
     Returns the vCard representation of the specified contacts.
     - Author: Ahmad Almasri
     
     - parameter contacts: Array of contacts.
     - parameter completionHandler: Returns Either Data or Error.
     - parameter result: enum type ContactsToVCardResult.
     */
    func contactsToVCardConverter(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactsToVCardResult) -> ()) {
        
        var vcardFromContacts = Data()
        do {
            self.waitifPaused()
            if self.isCancelled{
                completionHandler(ContactsToVCardResult.cancelled())
                return
            }
            try vcardFromContacts = data(contacts)
            
            self.waitifPaused()
            if self.isCancelled{
                completionHandler(ContactsToVCardResult.cancelled())
                return
            }
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
     - parameter result: enum type ContactsFetchResult.
     */
    func vCardToContactConverter(_ data: Data, completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        var contacts = [CNContact]()
        do {
            self.waitifPaused()
            if self.isCancelled{
                completionHandler(ContactsFetchResult.cancelled())
                return
            }
            try contacts = CNContactVCardSerialization.contacts(with: data) as [CNContact]
            
            self.waitifPaused()
            if self.isCancelled{
                completionHandler(ContactsFetchResult.cancelled())
                return
            }
            completionHandler(ContactsFetchResult.success(response: contacts))
        } catch {
            completionHandler(ContactsFetchResult.error(error: error))
        }
    }
    
    /**
     Convert contacts to data include images
     
     - Parameter contacts:  An array of contacts.
     - Returns: The data representing contacts.
     - Throws:  Error information.
     */
    func data( _ contacts: [CNContact]) throws -> Data {
        var contactData = Data()
        let contactsWithoutImages = contacts.filter({!$0.imageDataAvailable})
        self.waitifPaused()
        if self.isCancelled{
            
            return contactData
        }
        let data = try CNContactVCardSerialization.data(with: contactsWithoutImages)
        self.waitifPaused()
        if self.isCancelled{
            
            return contactData
        }
        contactData.append(data)
        for contact in  contacts.filter({$0.imageDataAvailable}) {
            self.waitifPaused()
            if self.isCancelled{
                
                return contactData
            }
            let data = try CNContactVCardSerialization.data(with: [contact])
            self.waitifPaused()
            if self.isCancelled{
                
                return contactData
            }
            if let base64imageString = contact.thumbnailImageData?.base64EncodedString(),
                let updatedData = CNContactVCardSerialization.vcardDataAppendingPhoto(vcard: data, photoAsBase64String: base64imageString) {
                contactData.append(updatedData)
            }
            
        }
        return contactData
    }
    
    // MARK:- Helper Methods:
    /**
     Save contact into document
     - Author: Ahmad Almasri
     
     - parameter data: Data having contacts.
     - parameter fileName: The name to which the file will be saved.
     - parameter completionHandler: Returns Either CNContact or Error.
     - parameter result: enum type ContactOperationResult.
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
    
    // MARK:- Main Transactions
    private  func waitifPaused(){
        if pauseCondition == nil {
            
            pauseCondition = NSCondition()
        }
        self.pauseCondition.lock()
        
        if paused {
            self.pauseCondition.wait()
        }
        self.pauseCondition.unlock()
    }
    
    func pause() {
        
        lockCondition(true)
    }
    func resume(){
        lockCondition(false)
    }
    
    private func lockCondition(_ pause:Bool){
        if pauseCondition == nil {
            
            pauseCondition = NSCondition()
        }
        self.pauseCondition.lock()
        self.paused = pause
        self.pauseCondition.signal()
        self.pauseCondition.unlock()
    }
    
    func setIsCancelled(_ isCancelled:Bool){
        
        self.isCancelled = isCancelled
    }
    
    private func getQueueLabel(_ functionName: String) -> String {
        let filePath = URL(fileURLWithPath: #file)
        let lastComponenet = filePath.lastPathComponent
        
        return "\(lastComponenet).\(functionName)"
    }
}


//MARK:- Serialization Image

extension CNContactVCardSerialization {
    
    /**
     Append Base64 image to VCard data
     
     - Parameters:
     - vcard: CNContact as Data
     - photo: Contact photo string base64
     - Returns: The data representing contacts include photo
     */
    class func vcardDataAppendingPhoto(vcard: Data, photoAsBase64String photo: String) -> Data? {
        let vcardAsString = String(data: vcard, encoding: .utf8)
        let vcardPhoto = "PHOTO;TYPE=JPEG;ENCODING=BASE64:".appending(photo)
        let vcardPhotoThenEnd = vcardPhoto.appending("\nEND:VCARD")
        if let vcardPhotoAppended = vcardAsString?.replacingOccurrences(of: "END:VCARD", with: vcardPhotoThenEnd) {
            return vcardPhotoAppended.data(using: .utf8)
        }
        return nil
        
    }
    
    
}


extension ContactManager {
    
    //MARK:- Parse VCard
    /**
     parseAndroidVCard convert vCard android format to ios format
     - Author: Ahmad Almasri
     
     - Parameter vCard: value of android vCard
     - Returns: vCard formatted  ios
     */
    func parseAndroidVCard(_ vCard:String)->String{
        
        let cursorItemResult = matchCursorItem(vCard)
        let telResult = matchInfo(cursorItemResult, infoType: .tel)
        let emailResult = matchInfo(telResult, infoType: .email)
        let imageResult = matchInfo(emailResult, infoType: .image)
        
        return imageResult
        
    }
    
    //MARK:- Matching
    /**
     Checks is supplied string matches the pattern.
     - Author: Ahmad Almasri
     
     - Parameters:
     - originalText: String to be matched to the pattern
     - pattern: A pattern to be used with Regex
     - Returns: array of matches include all groups and range
     */
    private func matching(_ originalText:String, pattern: String)->[NSTextCheckingResult]{
        
        var re: NSRegularExpression!
        do {
            re = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            
        }
        
        let matches = re.matches(in: originalText, options: [], range: NSRange(location: 0, length: originalText.utf16.count))
        return matches
    }
    
    /**
     matchCursorItem get matching and replace for ( nickname, relation , contact_event)
     - Author: Ahmad Almasri
     
     - Parameter originalText: String to be matched to the pattern
     - Returns: vCard after format ( nickname, relation , contact_event)
     */
    private func matchCursorItem(_ originalText:String)->String{
        let matchCursorPattern = RegexVCard.matchCursorPattern.rawValue
        var result = originalText
        let matches = matching(originalText, pattern: matchCursorPattern)
        var itemCount  = 0
        for match in matches.reversed()
        {
            let range = match.range(at: 0)
            let cursorItem = (originalText as NSString).substring(with: match.range(at: 1))
            let cursorItemValue = (originalText as NSString).substring(with: match.range(at: 2))
            //  let fullMatch = (originalText as NSString).substring(with: match.range(at: 0))
            
            switch cursorItem {
                
            case CursorItem.nickname.rawValue :
                
                result  = (result as NSString).replacingCharacters(in: range, with:
                    "NICKNAME:\(cursorItemValue.split(separator: ";").first ?? "")")
                
                break
                
            case CursorItem.relation.rawValue :
                
                result  = (result as NSString).replacingCharacters(in: range, with:
                    "\(getCursorItemValue(cursorItemValue,index:itemCount, cursorItemType: .relation))")
                itemCount += 1
                
                break
                
            case CursorItem.contact_event.rawValue :
                
                result  = (result as NSString).replacingCharacters(in: range, with:
                    "\(getCursorItemValue(cursorItemValue,index:itemCount, cursorItemType: .contact_event))")
                itemCount += 1
                
                break
                
            default:
                
                break
            }
            
        }
        
        return result
    }
    /**
     matchInfo get matching and replace for ( tel, email , images)
     - Author: Ahmad Almasri
     
     - Parameters:
     - originalText: String to be matched to the pattern
     - infoType: type of matching (tel , email or image)
     - Returns: vCard after format ( tel, email , images
     */
    private func matchInfo(_ originalText:String,infoType:InfoType)->String{
        var pattern = ""
        switch infoType {
        case .tel:
            pattern = RegexVCard.telPattern.rawValue
            break
        case .email:
            pattern = RegexVCard.emailPattern.rawValue
            break
        case .image:
            pattern = RegexVCard.imagePattern.rawValue
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
                let cursorItemFullValue = decodeQuotedPrintable(cursorItemFirstValue.replacingOccurrences(of: ")", with: ""))
                
                result = (result as NSString).replacingCharacters(in: range, with: "TEL;\(cursorItemFullValue):")
                
                break
            case .email:
                let cursorItemFirstValue = (cursorItem as NSString).components(separatedBy: ";").first ?? ""
                let cursorItemFullValue = decodeQuotedPrintable( cursorItemFirstValue.replacingOccurrences(of: ")", with: ""))
                
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
    /**
     getCursorItemValue convert format item (relation, contact event) from android to ios
     - Author: Ahmad Almasri
     
     - Parameters:
     - cursorItem: cursorItem value full fatching
     - index: item count 1,2,3...N
     - cursorItemType: fromat type (relation or contact event)
     - Returns: CursorItemValue ios format
     */
    private func getCursorItemValue(_ cursorItem: String, index:Int , cursorItemType:CursorItem) -> String {
        var result = [String]()
        let filteredComponenets = cursorItem.split(separator: ";")
        
        for name in filteredComponenets {
            result.append(decodeQuotedPrintable(String(name)))
        }
        
        if cursorItemType == CursorItem.relation {
            
            var abLabel = result.last
            if let relationIndex = Int(abLabel ?? "")  {
                abLabel = RelationType.getValue(relationIndex).rawValue
            }
            return "item\(index).X-ABRELATEDNAMES:\(result.first ?? "")\nitem\(index).X-ABLabel:\(abLabel ?? "")"
            
        }else{
            
            var abLabel = result.last
            if let relationIndex = Int(abLabel ?? "")  {
                abLabel = ContactEventType.getValue(relationIndex).rawValue
            }
            return "item\(index).X-ABDATE:\(result.first ?? "")\nitem\(index).X-ABLabel:\(abLabel ?? "")"
            
        }
    }
    
    
    //MARK:- Decoding
    /**
     Decode a quoted printable encoded string
     - Author: Ahmad Almasri
     
     - parameter string: String to decode
     - returns: Decoded string
     */
    private func decodeQuotedPrintable(_ string : String) -> String {
        
        var result =    string.replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "=", with: "%").removingPercentEncoding
        
        if (result ?? "").hasPrefix("X-") {
            
            result = (result! as NSString).replacingCharacters(in: NSRange.init(location: 0, length: 2), with: "")
        }
        return result == nil ? string : result!
    }
}


class ContactsManagerFacade {
    
    private let contactManager = ContactManager()
    
    func fetchContacts(completionHandler: @escaping (_ result: ContactsFetchResult) -> ()) {
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                
                self.contactManager.fetchContacts(completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
        }
    }
    
    func fetchContactsOnBackgroundThread(completionHandler: @escaping (_ result: ContactsFetchResult) -> ()){
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.fetchContactsOnBackgroundThread(completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
        }
    }
    
    func getContactsByIdentifiers(_ identifiers: [String], completionHandler: @escaping (_ result: ContactsFetchResult) -> ()){
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.getContactsByIdentifiers(identifiers, completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
        }
    }
    
    func getcContactByFullName(_ contact: CNContact, completionHandler: @escaping (_ result: ContactFetchResult) -> ()) {
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.getcContactByFullName(contact, completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
        }
    }
    
    func  addContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.addContact(contacts, completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
            
        }
    }
    
    func updateContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.updateContact(contacts, completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
            
        }
    }
    
    func deleteContact(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactOperationResult) -> ()){
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.deleteContact(contacts, completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
        }
    }
    
    func contactsToVCardConverter(_ contacts: [CNContact], completionHandler: @escaping (_ result: ContactsToVCardResult) -> ()){
        
        self.contactManager.contactsToVCardConverter(contacts, completionHandler: completionHandler)
        
    }
    
    func vCardToContactConverter(_ data: Data, completionHandler: @escaping (_ result: ContactsFetchResult) -> ()){
        
        self.contactManager.vCardToContactConverter(data, completionHandler: completionHandler)
    }
    
    func  parseAndroidVCard(_ vCard:String)->String{
        
        return self.contactManager.parseAndroidVCard(vCard)
        
    }
    
    func getContactsCount(completionHandler: @escaping (_ result: ContactsCountResult) -> ()){
        
        PermissionHandler.requestAccess { (granted) in
            if granted {
                self.contactManager.getContactsCount(completionHandler: completionHandler)
            }else{
                let error = NSError(domain: "Access Denied", code: ErrorCode.accessDenied.rawValue)
                completionHandler(.error(error: error))
            }
        }
    }
    
    func pause() {
        
        self.contactManager.pause()
    }
    func resume() {
        
        self.contactManager.resume()
    }
    func setIsCancelled(_ isCancelled:Bool){
        
        self.contactManager.setIsCancelled(isCancelled)
    }
}


struct PermissionHandler {
    
    //MARK:- Permission
    /**
     Requests access to the user's contacts
     - Author: Ahmad Almasri
     
     - Parameter requestGranted: Result as Bool
     
     - Note: any contacts functionality assumes that this method has been called and got granted as true, otherwise it would not be functional (roughtly speaking, all methods would return "Access Denied" error).
     */
    static func requestAccess(_ requestGranted: @escaping (Bool) -> ()) {
        
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            requestGranted(granted)
        }
    }
}

extension UIViewController {
    func showDialog(forError error: Error) {
        let error = error as NSError
        
        switch error.code {
        case ErrorCode.accessDenied.rawValue:
            print("don't have contact perrmission")
            break
        default:
            print("Unknown error code \(error.code) ")
            
            break
        }
    }
}
