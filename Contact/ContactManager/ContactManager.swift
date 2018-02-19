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
        
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        
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
    
    //MARK:- Transaction
    
    /// Transaction Add OR Delete OR Update
    ///      - Author: Ahmad Almasri
    /// - Parameters:
    ///   - contacts:  Array of contacts.
    ///   - transaction:  type of transaction (add , update , delete )
    ///   - completionHandler: Returns Either Bool or Error.
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
        
        var vcardFromContacts = Data()
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
        
        var contacts = [CNContact]()
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

