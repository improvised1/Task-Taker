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
    
    var hasDate: Bool   //indicates if there are dateComponents
    var hasFar: Bool    //indicated if there is a far date, if there are a range of dates or just one in nearDate
    var hasForever: Bool    //indicates if there is no far date, but because it goes to infinity
    var deletable: Bool     //indicates if this header can be deleted or not, and so whether or not to displayy the delete button
    var notesAreCompleted: Bool = false     //indicates if this is the "completed notes" header.  This will always default to false.
    var headerShouldHide: Bool = false  //indicates if the header should dissapear when its empty
    var notesAreHidden: Bool = false    //indicates if the header has been selected and told to hide
    var isMiscellaneous: Bool = false
    var hasDynamicName: Bool = false   //indicates if the name should dynamically change (used for weekdays, where today+2 is wednesday today but thursday tomorrow
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("headers")
    
    //MARK: Types
    
    struct PropertyKey {
        
        static let name = "name"
        static let identity = "identity"
        static let nearDate = "nearDate"
        static let farDate = "farDate"
        static let hasForever = "hasForever"
        static let deletable = "deletable"
        static let notesAreCompleted = "notesAreCompleted"
        static let headerShouldHide = "headerShouldHide"
        static let notesAreHidden = "notesAreHidden"
        static let isMiscellaneous = "isMiscellaneous"
        
    }
    
    //MARK: Initialization
    
    //complete
    init(name: String, notes: [Note], identity: Int, nearDate: DateComponents, farDate: DateComponents, deletable: Bool) {
        
        self.name = name
        self.notes = notes
        self.identity = identity
        self.nearDate = nearDate
        self.farDate = farDate
        self.deletable = deletable
        
        self.hasDate = true
        self.hasFar = true
        self.hasForever = false
        
    }
    
    //missing a far date, has only a single date and not a range of them
    init(name: String, notes: [Note], identity: Int, nearDate: DateComponents, hasForever: Bool, deletable: Bool) {
        
        self.name = name
        self.notes = notes
        self.identity = identity
        self.nearDate = nearDate
        self.deletable = deletable
        
        self.hasDate = true
        self.hasFar = false
        self.hasForever = hasForever
        
    }
    
    //missing all dates, has no dates
    init(name: String, notes: [Note], identity: Int, deletable: Bool) {
        
        self.name = name
        self.notes = notes
        self.identity = identity
        self.deletable = deletable
        
        self.hasDate = false
        self.hasFar = false
        self.hasForever = false
        
    }
    
    /*
    the next 3 inits are for loading saved headers
    */
    //when there are no dates
    init(name: String, identity: Int, notesAreCompleted: Bool, headerShouldHide: Bool, notesAreHidden: Bool, isMiscellaneous: Bool, deletable: Bool) {
        
        let collection = [Note]()
        
        self.name = name
        self.notes = collection
        self.identity = identity
        self.deletable = deletable
        
        self.hasDate = false
        self.hasFar = false
        self.hasForever = false
        
        self.notesAreCompleted = notesAreCompleted
        self.headerShouldHide = headerShouldHide
        self.notesAreHidden = notesAreHidden
        self.isMiscellaneous = isMiscellaneous
        
    }
    
    //when there is only a near date
    init(name: String, identity: Int, nearDate: DateComponents, hasForever: Bool, notesAreCompleted: Bool, headerShouldHide: Bool, notesAreHidden: Bool, isMiscellaneous: Bool, deletable: Bool) {
        
        let collection = [Note]()
        
        self.name = name
        self.notes = collection
        self.identity = identity
        
        self.nearDate = nearDate
        self.deletable = deletable
        
        self.hasDate = true
        self.hasFar = false
        self.hasForever = hasForever
        
        self.notesAreCompleted = notesAreCompleted
        self.headerShouldHide = headerShouldHide
        self.notesAreHidden = notesAreHidden
        self.isMiscellaneous = isMiscellaneous
        
    }
    
    //when there are 2 dates
    init(name: String, identity: Int, nearDate: DateComponents, farDate: DateComponents, notesAreCompleted: Bool, headerShouldHide: Bool, notesAreHidden: Bool, isMiscellaneous: Bool, deletable: Bool) {
        
        let collection = [Note]()
        
        self.name = name
        self.notes = collection
        self.identity = identity
        
        self.nearDate = nearDate
        self.farDate = farDate
        self.deletable = deletable
        
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
    
    /*
     If i want a section to be named for the weekday it's on, then i have to dynamically calculate what day of the week it is each time.  This method will check if this header is to have a dynamic name (hasDynamicName), and if so will set self.name to be equal to the day of the week that it falls on.
    */
    func dynamicNameGenerator() {
        
        if (hasDynamicName) {
            
            //a section that uses dynamic names should only have a nearDate (single date component)
            let currentDate = Date()
            let dynamicDate = Calendar.current.date(byAdding: nearDate, to: currentDate)!
            
            let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
            let myComponents = myCalendar?.components(.weekday, from: dynamicDate)
            let weekDay = myComponents?.weekday     //weekDay is an integer 1 -> 7, where 1 is sunday and 7 saturday
            
            switch weekDay {
            case 1?: name = "Sunday"
            case 2?: name = "Monday"
            case 3?: name = "Tuesday"
            case 4?: name = "Wednesday"
            case 5?: name = "Thursday"
            case 6?: name = "Friday"
            case 7?: name = "Saturday"
            default: name = "Weekday"   //this should never occur
            }
            
        }
        
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(identity, forKey: PropertyKey.identity)
        aCoder.encode(nearDate, forKey: PropertyKey.nearDate)
        aCoder.encode(farDate, forKey: PropertyKey.farDate)
        aCoder.encode(hasForever, forKey: PropertyKey.hasForever)
        aCoder.encode(deletable, forKey: PropertyKey.deletable)
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
        
        let identity = aDecoder.decodeInteger(forKey: PropertyKey.identity)
        let hasForever = aDecoder.decodeBool(forKey: PropertyKey.hasForever)
        let deletable = aDecoder.decodeBool(forKey: PropertyKey.deletable)
        let notesAreCompleted = aDecoder.decodeBool(forKey: PropertyKey.notesAreCompleted)
        
        let nearDate = aDecoder.decodeObject(forKey: PropertyKey.nearDate) as? DateComponents
        let farDate = aDecoder.decodeObject(forKey: PropertyKey.farDate) as? DateComponents
        let notesAreHidden = aDecoder.decodeBool(forKey: PropertyKey.notesAreHidden)
        let headerShouldHide = aDecoder.decodeBool(forKey: PropertyKey.headerShouldHide)
        let isMiscellaneous = aDecoder.decodeBool(forKey: PropertyKey.isMiscellaneous)
        
        //must call the designated initializer
        //BUGFIX - doing nearDate != nil dosent work, as the dateComponents hold a value isLeapMonth that holds a value and so is non-nil.  So instead im testing that day is non-nil, but if you later transition to using months this could cause problems
        if (nearDate?.day != nil) && (farDate?.day != nil) {
            self.init(name: name, identity: identity, nearDate: nearDate!, farDate: farDate!, notesAreCompleted: notesAreCompleted, headerShouldHide: headerShouldHide, notesAreHidden: notesAreHidden, isMiscellaneous: isMiscellaneous, deletable: deletable)
        } else if (nearDate?.day != nil) {
            self.init(name: name, identity: identity, nearDate: nearDate!, hasForever: hasForever, notesAreCompleted: notesAreCompleted, headerShouldHide: headerShouldHide, notesAreHidden: notesAreHidden, isMiscellaneous: isMiscellaneous, deletable: deletable)
        } else {
            self.init(name: name, identity: identity, notesAreCompleted: notesAreCompleted, headerShouldHide: headerShouldHide, notesAreHidden: notesAreHidden, isMiscellaneous: isMiscellaneous, deletable: deletable)
        }
        
        
        
    }
    
}
















