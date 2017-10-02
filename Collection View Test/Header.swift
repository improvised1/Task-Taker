//
//  Header.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 6/7/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log

class Header: NSObject, NSCoding {
    
    //MARK: Properties
    
    var name: String
    var notes = [Note]()
    var identity: Int
    var nearDate = DateComponents()
    var farDate = DateComponents()
    var color: String
    
    var hasDate: Bool   //indicates if there are dateComponents
    var hasFar: Bool    //indicated if there is a far date, if there are a range of dates or just one in nearDate
    var hasForever: Bool    //indicates if there is no far date, but because it goes to infinity
    var notesAreCompleted: Bool = false     //indicates if this is the "completed notes" header.  This will always default to false.
    var headerShouldHide: Bool = false  //indicates if the header should dissapear when its empty
    var notesAreHidden: Bool = false    //indicates if the header has been selected and told to hide
    var isMiscellaneous: Bool = false
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("headers")
    
    //MARK: Types
    
    struct PropertyKey {
        
        static let name = "name"
        static let identity = "identity"
        static let nearDate = "nearDate"
        static let farDate = "farDate"
        static let color = "Color"
        static let hasForever = "hasForever"
        static let notesAreCompleted = "notesAreCompleted"
        static let headerShouldHide = "headerShouldHide"
        static let notesAreHidden = "notesAreHidden"
        static let isMiscellaneous = "isMiscellaneous"
        
    }
    
    //MARK: Initialization
    
    //complete
    init(name: String, notes: [Note], identity: Int, nearDate: DateComponents, farDate: DateComponents) {
        
        self.name = name
        self.notes = notes
        self.identity = identity
        self.nearDate = nearDate
        self.farDate = farDate
        self.color = "orange"
        
        self.hasDate = true
        self.hasFar = true
        self.hasForever = false
        
    }
    
    //missing a far date, has only a single date and not a range of them
    init(name: String, notes: [Note], identity: Int, nearDate: DateComponents, hasForever: Bool) {
        
        self.name = name
        self.notes = notes
        self.identity = identity
        self.nearDate = nearDate
        self.color = "orange"
        
        self.hasDate = true
        self.hasFar = false
        self.hasForever = hasForever
        
    }
    
    //missing all dates, has no dates
    init(name: String, notes: [Note], identity: Int) {
        
        self.name = name
        self.notes = notes
        self.identity = identity
        self.color = "orange"
        
        self.hasDate = false
        self.hasFar = false
        self.hasForever = false
        
    }
    
    /*
    the next 3 inits are for loading saved headers
    */
    //when there are no dates
    init(name: String, identity: Int, color: String, notesAreCompleted: Bool, headerShouldHide: Bool, notesAreHidden: Bool, isMiscellaneous: Bool) {
        
        let collection = [Note]()
        
        self.name = name
        self.notes = collection
        self.identity = identity
        self.color = color
        
        self.hasDate = false
        self.hasFar = false
        self.hasForever = false
        
        self.notesAreCompleted = notesAreCompleted
        self.headerShouldHide = headerShouldHide
        self.notesAreHidden = notesAreHidden
        self.isMiscellaneous = isMiscellaneous
        
    }
    
    //when there is only a near date
    init(name: String, identity: Int, nearDate: DateComponents, hasForever: Bool, color: String, notesAreCompleted: Bool, headerShouldHide: Bool, notesAreHidden: Bool, isMiscellaneous: Bool) {
        
        let collection = [Note]()
        
        self.name = name
        self.notes = collection
        self.identity = identity
        self.color = color
        
        self.nearDate = nearDate
        
        self.hasDate = true
        self.hasFar = false
        self.hasForever = hasForever
        
        self.notesAreCompleted = notesAreCompleted
        self.headerShouldHide = headerShouldHide
        self.notesAreHidden = notesAreHidden
        self.isMiscellaneous = isMiscellaneous
        
    }
    
    //when there are 2 dates
    init(name: String, identity: Int, nearDate: DateComponents, farDate: DateComponents, color: String, notesAreCompleted: Bool, headerShouldHide: Bool, notesAreHidden: Bool, isMiscellaneous: Bool) {
        
        let collection = [Note]()
        
        self.name = name
        self.notes = collection
        self.identity = identity
        self.color = color
        
        self.nearDate = nearDate
        self.farDate = farDate
        
        self.hasDate = true
        self.hasFar = true
        self.hasForever = false
        
        self.notesAreCompleted = notesAreCompleted
        self.headerShouldHide = headerShouldHide
        self.notesAreHidden = notesAreHidden
        self.isMiscellaneous = isMiscellaneous
        
    }
    
    //MARK: Private Methods
    
    /*
    will see if a passed date lies within the range of dates this header is designed to respond to/hold
    */
    func matches(passedDate: Date) -> Bool {
        
        //let currentDate = Date()
        //let dateFormatter = DateFormatter() //neccessary for formatting?
        //dateFormatter.dateStyle = DateFormatter.Style.full
        
        /*
         These if statements will first check to make sure that this header has a date / date-range, and will then figure out what type it has and do the proper calculations
        */
        if hasDate {
            
            //let currentDate = Date()
            let currentDate = Date()
            let trueNear = Calendar.current.date(byAdding: nearDate, to: currentDate)!
            //FIXED - For some reson == and <= aren't working in Xcode, so whenever i would use those im insted using Calendar.current.isDate and copious or statements.
            if (hasForever) {
                
                if (((trueNear < currentDate) && (passedDate < trueNear)) || ((trueNear > currentDate) && ((passedDate > trueNear) || Calendar.current.isDate(passedDate, inSameDayAs: trueNear)))) {
                    return true
                } else {
                    return false
                }
                
            } else if (hasFar) {
                
                let trueFar = Calendar.current.date(byAdding: farDate, to: currentDate)!
                
                //since <= and == are broken i have to do this way overcomplicated thing
                if (((trueNear < passedDate) || Calendar.current.isDate(trueNear, inSameDayAs: passedDate)) && ((passedDate < trueFar) || Calendar.current.isDate(trueFar, inSameDayAs: passedDate))) || (((trueNear > passedDate) || Calendar.current.isDate(trueNear, inSameDayAs: passedDate)) && ((passedDate > trueFar) || Calendar.current.isDate(trueFar, inSameDayAs: passedDate))) {
                    return true
                } else {
                    return false
                }
                
            } else {
                
                if (Calendar.current.isDate(passedDate, inSameDayAs: trueNear)) {
                    return true
                } else {
                    return false
                }
                
            }
        
        } else {
            return false
        }
        
    }   //end of matches method
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(identity, forKey: PropertyKey.identity)
        aCoder.encode(nearDate, forKey: PropertyKey.nearDate)
        aCoder.encode(farDate, forKey: PropertyKey.farDate)
        aCoder.encode(color, forKey: PropertyKey.color)
        aCoder.encode(hasForever, forKey: PropertyKey.hasForever)
        aCoder.encode(notesAreCompleted, forKey: PropertyKey.notesAreCompleted)
        aCoder.encode(headerShouldHide, forKey: PropertyKey.headerShouldHide)
        aCoder.encode(notesAreHidden, forKey: PropertyKey.notesAreHidden)
        aCoder.encode(isMiscellaneous, forKey: PropertyKey.isMiscellaneous)
        
    }
    
    //im note sure if what i marked as optional and required here makes sense, look back over this at some point
    required convenience init?(coder aDecoder: NSCoder) {
        
        //The following are required variables of a Note object, if they cannot be decoded then the initializer should fail
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("unable to decode the name for the header object", log: OSLog.default, type: .debug)
            return nil
        }
        
        //BUGFIX - gives an error when i delete the "as? (var)" but complains when i dont.  The exact bugwording was "needs optional", maybe look up later
        guard let identity = aDecoder.decodeInteger(forKey: PropertyKey.identity) as? Int else {
            os_log("unable to decode the identity for the header object", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let hasForever = aDecoder.decodeBool(forKey: PropertyKey.hasForever) as? Bool else {
            os_log("unable to decode the hasForever for the note object", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let notesAreCompleted = aDecoder.decodeBool(forKey: PropertyKey.notesAreCompleted) as? Bool else {
            os_log("unable to decode the notesAreCompleted for the note object", log: OSLog.default, type: .debug)
            return nil
        }
        
        //the following are optional variables of a Note object
        
        let nearDate = aDecoder.decodeObject(forKey: PropertyKey.nearDate) as? DateComponents
        let farDate = aDecoder.decodeObject(forKey: PropertyKey.farDate) as? DateComponents
        let color = aDecoder.decodeObject(forKey: PropertyKey.color) as? String
        let notesAreHidden = aDecoder.decodeBool(forKey: PropertyKey.notesAreHidden)
        let headerShouldHide = aDecoder.decodeBool(forKey: PropertyKey.headerShouldHide)
        let isMiscellaneous = aDecoder.decodeBool(forKey: PropertyKey.isMiscellaneous)
        
        //must call the designated initializer
        //BUGFIX - doing nearDate != nil dosent work, as the dateComponents hold a value isLeapMonth that holds a value and so is non-nil.  So instead im testing that day is non-nil, but if you later transition to using months this could cause problems
        if (nearDate?.day != nil) && (farDate?.day != nil) {
            self.init(name: name, identity: identity, nearDate: nearDate!, farDate: farDate!, color: color!, notesAreCompleted: notesAreCompleted, headerShouldHide: headerShouldHide, notesAreHidden: notesAreHidden, isMiscellaneous: isMiscellaneous)
        } else if (nearDate?.day != nil) {
            self.init(name: name, identity: identity, nearDate: nearDate!, hasForever: hasForever, color: color!, notesAreCompleted: notesAreCompleted, headerShouldHide: headerShouldHide, notesAreHidden: notesAreHidden, isMiscellaneous: isMiscellaneous)
        } else {
            self.init(name: name, identity: identity, color: color!, notesAreCompleted: notesAreCompleted, headerShouldHide: headerShouldHide, notesAreHidden: notesAreHidden, isMiscellaneous: isMiscellaneous)
        }
        
        
        
    }
    
}
















