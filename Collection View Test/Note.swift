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
    var repeatIdentity: Int?
    var activationDate: Date?
    var creationDate: Date
    var hasDate: Bool
    var hasRepeat: Bool = false
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
        static let repeatIdentity = "repeatIdentity"
        static let activationDate = "activationDate"
        static let creationDate = "creationDate"
        static let hasRepeat = "hasRepeat"
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
    
    //for setup from saved information with an activation date and repeatIdentity
    private init(text: String, headerIdentity: Int, identity: Int, repeatIdentity: Int, activationDate: Date, creationDate: Date, hasRepeat: Bool, checkboxClicked: Bool) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        self.repeatIdentity = repeatIdentity
        self.activationDate = activationDate
        
        self.creationDate = creationDate
        self.hasRepeat = hasRepeat
        self.checkboxClicked = checkboxClicked
        
        self.hasDate = true
        
    }
    
    //for setup from saved information with an activation date and WITHOUT repeatIdentity
    private init(text: String, headerIdentity: Int, identity: Int, activationDate: Date, creationDate: Date, hasRepeat: Bool, checkboxClicked: Bool) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        self.activationDate = activationDate
        
        self.creationDate = creationDate
        self.hasRepeat = hasRepeat
        self.checkboxClicked = checkboxClicked
        
        self.hasDate = true
        
    }
    
    //for setup from saved information WITHOUT an activation date but with repeatIdentity
    private init(text: String, headerIdentity: Int, identity: Int, repeatIdentity: Int, creationDate: Date, hasRepeat: Bool, checkboxClicked: Bool) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        self.repeatIdentity = repeatIdentity
        
        self.creationDate = creationDate
        self.hasRepeat = hasRepeat
        self.checkboxClicked = checkboxClicked
        
        self.hasDate = false
    
    }
    
    //for setup from saved information WITHOUT an activation date and WITHOUT a repeatIdentity
    private init(text: String, headerIdentity: Int, identity: Int, creationDate: Date, hasRepeat: Bool, checkboxClicked: Bool) {
        
        self.text = text
        self.headerIdentity = headerIdentity
        self.identity = identity
        
        self.creationDate = creationDate
        self.hasRepeat = hasRepeat
        self.checkboxClicked = checkboxClicked
        
        self.hasDate = false
        
    }
    
    //for setup from an existing note (creating a deep copy)
    init(note: Note) {
        
        self.text = note.text
        self.headerIdentity = note.headerIdentity
        self.identity = note.identity
        self.repeatIdentity = note.repeatIdentity
        self.activationDate = note.activationDate
        
        self.creationDate = Date()
        
        self.hasDate = note.hasDate
        self.hasRepeat = note.hasRepeat
        self.checkboxClicked = note.checkboxClicked
        
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(text, forKey: PropertyKey.text)
        aCoder.encode(headerIdentity, forKey: PropertyKey.headerIdentity)
        aCoder.encode(identity, forKey: PropertyKey.identity)
        aCoder.encode(repeatIdentity, forKey: PropertyKey.repeatIdentity)
        aCoder.encode(activationDate, forKey: PropertyKey.activationDate)
        aCoder.encode(creationDate, forKey: PropertyKey.creationDate)
        aCoder.encode(hasRepeat, forKey: PropertyKey.hasRepeat)
        aCoder.encode(checkboxClicked, forKey: PropertyKey.checkboxClicked)
        
    }
    
    //im note sure if what i marked as optional and required here makes sense, look back over this at some point
    required convenience init?(coder aDecoder: NSCoder) {
        
        let text = aDecoder.decodeObject(forKey: PropertyKey.text) as? String
        let headerIdentity = aDecoder.decodeInteger(forKey: PropertyKey.headerIdentity)
        let identity = aDecoder.decodeInteger(forKey: PropertyKey.identity)
        let repeatIdentity = aDecoder.decodeObject(forKey: PropertyKey.repeatIdentity) as? Int
        let activationDate = aDecoder.decodeObject(forKey: PropertyKey.activationDate) as? Date
        let creationDate = aDecoder.decodeObject(forKey: PropertyKey.creationDate) as? Date
        let hasRepeat = aDecoder.decodeBool(forKey: PropertyKey.hasRepeat)
        let checkboxClicked = aDecoder.decodeBool(forKey: PropertyKey.checkboxClicked)
        
        //must call the designated initializer
        
        if (activationDate != nil) {
            if (repeatIdentity != nil) {
                self.init(text: text!, headerIdentity: headerIdentity, identity: identity, repeatIdentity: repeatIdentity!, activationDate: activationDate!, creationDate: creationDate!, hasRepeat: hasRepeat, checkboxClicked: checkboxClicked)
            } else {
                self.init(text: text!, headerIdentity: headerIdentity, identity: identity, activationDate: activationDate!, creationDate: creationDate!, hasRepeat: hasRepeat, checkboxClicked: checkboxClicked)
            }
        } else {
            if (repeatIdentity != nil) {
                self.init(text: text!, headerIdentity: headerIdentity, identity: identity, repeatIdentity: repeatIdentity!, creationDate: creationDate!, hasRepeat: hasRepeat, checkboxClicked: checkboxClicked)
            } else {
                self.init(text: text!, headerIdentity: headerIdentity, identity: identity, creationDate: creationDate!, hasRepeat: hasRepeat, checkboxClicked: checkboxClicked)
            }
            
        }
        
    }
    
}

































