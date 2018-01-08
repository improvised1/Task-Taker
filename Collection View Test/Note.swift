//
//  Note.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 5/25/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log

class Note: NSObject, NSCoding {
    
    //MARK: Properties
    
    var text: String
    var headerIdentity: Int
    var identity: Int
    var activationDate: Date?
    var creationDate: Date
    var hasDate: Bool
    var checkboxClicked: Bool
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let NotesArchiveURL = DocumentsDirectory.appendingPathComponent("notes")
    static let CompletedArchiveURL = DocumentsDirectory.appendingPathComponent("completed notes")
    
    //MARK: Types
    
    struct PropertyKey {
        
        static let text = "text"
        static let headerIdentity = "headerIdentity"
        static let identity = "identity"
        static let activationDate = "activationDate"
        static let creationDate = "creationDate"
        static let checkboxClicked = "checkboxClicked"
        
    }
    
    //MARK: Initialization
    
    //complete initialization
    init(text: String, headerIdentity: Int, identity: Int, activationDate: Date) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        self.activationDate = activationDate
        
        self.creationDate = Date()
        
        self.hasDate = true
        self.checkboxClicked = false
        
    }
    
    //for notes with no associated date
    init(text: String, headerIdentity: Int, identity: Int) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        
        self.creationDate = Date()
        
        self.hasDate = false
        self.checkboxClicked = false
        
    }
    
    //for setup from saved information with an acitvation date
    init(text: String, headerIdentity: Int, identity: Int, activationDate: Date, creationDate: Date, checkboxClicked: Bool) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        self.activationDate = activationDate
        
        self.creationDate = creationDate
        self.checkboxClicked = checkboxClicked
        
        self.hasDate = true
        
    }
    
    //for setup from saved information withOUT an acitvation date
    //only set this up because im not sure how the above would reace to a var. activationDate = nil.  If it would work without breaking delete this
    init(text: String, headerIdentity: Int, identity: Int, creationDate: Date, checkboxClicked: Bool) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        
        self.creationDate = creationDate
        self.checkboxClicked = checkboxClicked
        
        self.hasDate = false
    
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(text, forKey: PropertyKey.text)
        aCoder.encode(headerIdentity, forKey: PropertyKey.headerIdentity)
        aCoder.encode(identity, forKey: PropertyKey.identity)
        aCoder.encode(activationDate, forKey: PropertyKey.activationDate)
        aCoder.encode(creationDate, forKey: PropertyKey.creationDate)
        aCoder.encode(checkboxClicked, forKey: PropertyKey.checkboxClicked)
        
    }
    
    //im note sure if what i marked as optional and required here makes sense, look back over this at some point
    required convenience init?(coder aDecoder: NSCoder) {
        
        let text = aDecoder.decodeObject(forKey: PropertyKey.text) as? String
        let headerIdentity = aDecoder.decodeInteger(forKey: PropertyKey.headerIdentity)
        let identity = aDecoder.decodeInteger(forKey: PropertyKey.identity)
        let activationDate = aDecoder.decodeObject(forKey: PropertyKey.activationDate) as? Date
        let creationDate = aDecoder.decodeObject(forKey: PropertyKey.creationDate) as? Date
        let checkboxClicked = aDecoder.decodeBool(forKey: PropertyKey.checkboxClicked)
        
        //must call the designated initializer
        
        if (activationDate != nil) {
            self.init(text: text!, headerIdentity: headerIdentity, identity: identity, activationDate: activationDate!, creationDate: creationDate!, checkboxClicked: checkboxClicked)
        } else {
            self.init(text: text!, headerIdentity: headerIdentity, identity: identity, creationDate: creationDate!, checkboxClicked: checkboxClicked)
        }
        
    }
    
}

































