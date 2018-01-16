//
//  RepeatingNote.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 1/10/18.
//  Copyright © 2018 Damon Cestaro. All rights reserved.
//

import UIKit

/*
 Design Notes
 
 - variable parent is required for alot of methods to run, but there where issues saving it, and so NoteCollectionViewController has to pass RepeatingNote a new copy of itself for parent each time we load a RepeatingNote.  Since parent won't exist for initialization from saving, as its set later, this means that two crucial variables, notes and nextNote, also can't be set until we receive parent.  This means that whenever loadRepeatingNotes is called in NoteCollectionViewController, it must be immediately followed by setting the parent variable and calling runCheckup() method, which will do additional setup work.
 */

class RepeatingNote: NSObject, NSCoding {
    
    //MARK: Properties
    var components = DateComponents()
    var repeatIdentity: Int
    var notes = [Note]()
    var lastNote: Note     //this is the last note (the one the farthest in the future) that this RepeatingNote has spawned
    var nextNote: Note?
    var parent: NoteCollectionViewController?   //note - this can't be saved so we created a massive workaround to it
    var selectedButtons: [Bool]?     //not actually used anywhere.  Is used when setting up the RepeatViewController and difficult to derive, so simply storing it here
    var identitiesOfNotes = [Int]()  //saving the notes array is incredibly difficult and unnecessary, we'll hold the identity of all notes we hold and and rebuild var notes from this
    
    var active: Bool
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("repeatingNotes")
    
    // MARK: Initialization
    
    init(components: DateComponents, repeatIdentity: Int, notes: [Note], parent: NoteCollectionViewController) {
        
        self.components = components
        self.repeatIdentity = repeatIdentity
        self.notes = notes  //should only be a single note at this stage
        self.lastNote = notes.last!
        self.parent = parent
        
        self.active = lastNote.hasRepeat    //this used to just be = True, but since this init is now used to set from loaded RepeatingNotes this must by dynamic
        
        super.init()
        createNextNote(currentNote: notes.last!)
        fillIdentitiesOfNotes()
        
    }
    
    //this init is for initializing from saved RepeatingNotes with selectedButtons
    private init(components: DateComponents, repeatIdentity: Int, lastNote: Note, selectedButtons: [Bool], identitiesOfNotes: [Int]) {
        
        self.components = components
        self.repeatIdentity = repeatIdentity
        self.lastNote = lastNote
        self.selectedButtons = selectedButtons
        self.identitiesOfNotes = identitiesOfNotes
        
        self.active = lastNote.hasRepeat
        
        super.init()
        self.notes = [lastNote]   //temp solution, we cant use fillNotesFromIdentitiesOfNotes until we can get parent, which happens after initialization
        
    }
    
    //this init is for initializing from saved RepeatingNotes WITHOUT selectedButtons
    private init(components: DateComponents, repeatIdentity: Int, lastNote: Note, identitiesOfNotes: [Int]) {
        
        self.components = components
        self.repeatIdentity = repeatIdentity
        self.lastNote = lastNote
        self.identitiesOfNotes = identitiesOfNotes
        
        self.active = lastNote.hasRepeat
        
        super.init()
        self.notes = [lastNote]   //temp solution, we cant use fillNotesFromIdentitiesOfNotes until we can get parent, which happens after initialization

        
    }
    
    // MARK: Private Methods
    
    //will do various setup things
    func runCheckup() {
        
        if (active) {
            fillNotesFromIdentitiesOfNotes()
            createNextNote(currentNote: lastNote)
        }
        
    }
    
    /*
     This method will assemble the next note that this RepeatingNote should spawn and check if this next note should be spawned.  If it does spawn the nextNote, it will check if another one should be spawned after that, and so calling this method will create all of the notes this RepeatingNote should have.
    */
    func createNextNote(currentNote: Note) {
        
        let newNote = Note(note: currentNote)
        newNote.identity = (parent?.returnOpenNoteIdentity())!
        newNote.activationDate = Calendar.current.date(byAdding: components, to: currentNote.activationDate!)
        parent?.updateNoteIdentity(note: newNote)    //updates the header identity
        newNote.checkboxClicked = false     //it should be false anyway, but just making sure to avoid weirdness
        
        if (parent?.shouldSpawnRepeatNote(currentNote: currentNote, nextNote: newNote))! {
            
            //if the note we created should be spawned, do so and continue creating a new one until you create one that should not be spawned
            parent?.spawnNote(note: newNote)
            notes.append(newNote)
            lastNote = newNote
            createNextNote(currentNote: lastNote)
            
        } else {
            
            //if this note should not be spawned then store it in nextNote until it can be spawned
            self.nextNote = newNote
            fillIdentitiesOfNotes() //because added new notes
            
        }
        
    }
    
    /*
     this method will be called whenever the "repeat" button in any of the notes in this thing is unselected, and so we will delete every note past the one that triggered the deletion.
    */
    func delete(fromNote: Note) {
        
        let toDeleteFrom = fromNote.activationDate
        
        //will go through every note and delete it if its date lies after toDeleteFrom, otherwise leave it alone but toggle its hasRepeat variable
        for note in notes {
            
            //if this notes activation date lies after the date to delete from
            if (note.activationDate?.compare(toDeleteFrom!) == .orderedDescending) {
                
                parent?.deleteNote(toDelete: note)  //delete note in parent
                
                for index in 0...identitiesOfNotes.count-1 {    //delete note here
                    if (identitiesOfNotes[index] == note.identity) {
                        identitiesOfNotes.remove(at: index)
                        break
                    }
                }
                
            } else {
                note.hasRepeat = false
            }
            
        }
        
        fillNotesFromIdentitiesOfNotes()
        lastNote = fromNote     //since true lastNote has been deleted
        self.active = false
        
    }
    
    /*
     This method will reactivate this method
     possible issue - i reactivate this method by grabbing the last existing note and creating new ones from there.  That could get ugly.
    */
    func reactivate() {
    
        self.active = true
        
        for note in notes {
            note.hasRepeat = true
        }
        
        createNextNote(currentNote: lastNote)
        
    }
    
    /*
     This method will edit the components of this RepeatingNote by finding the earliest non-checked note in this RepeatingNote, and deleting every note after that and creating new ones with new components from there
     ISSUE - what happens if someone tries to edit a note with no unckecked notes?  That can only happen if the RepeatingNote is not active, but would still cause a crash
    */
    func edit(newComponents: DateComponents) {
        
        var uncheckedNotes = [Note]()
        var earliestNote: Note
        
        //finding all unchecked notes
        for note in notes {
            if (note.checkboxClicked == false) {
                uncheckedNotes.append(note)
            }
        }
        
        earliestNote = uncheckedNotes.last!   //setting earliestNote to hold a random uncheckedNote, which one dosen't matter
        
        
        //finding earliest unchecked note
        for note in uncheckedNotes {
            //if this note lies after (farther in the future) then the earliest note
            if (note.activationDate?.compare(earliestNote.activationDate!) == .orderedDescending) {
                earliestNote = note
            }
        }
        
        delete(fromNote: earliestNote)
        components = newComponents
        createNextNote(currentNote: earliestNote)
        
    }
    
    /*
     will fill var identitiesOfNotes by going through every note and placing its identity in identitiesOfNotes
    */
    func fillIdentitiesOfNotes() {
        
        identitiesOfNotes.removeAll()
        
        for note in notes {
            identitiesOfNotes.append(note.identity)
        }
        
    }
    
    /*
     This method is designed to be run after loading.  Because var notes is an array of [Note], it's difficult to save.  Instead we save the identities of notes it holds and re-assemble var notes afterwords
     Note - this method went to crap after parent has to be made optional due to saving issues, and apparently you cant use + on two [Note]? arrays, so i had to double the for-loops
    */
    func fillNotesFromIdentitiesOfNotes() {
        
        notes.removeAll()
        
        if (parent?.completedNotes != nil) {
            for note in (parent?.completedNotes)! {
                if (identitiesOfNotes.contains(note.identity)) {
                    notes.append(note)
                }
            }
        }
        
        for note in (parent?.notes)! {
            if (identitiesOfNotes.contains(note.identity)) {
                notes.append(note)
            }
        }
        
    }
    
    //MARK: Saving and Loading Methods
    
    struct PropertyKey {
        
        static let components = "components"
        static let repeatIdentity = "repeatIdentity"
        static let lastNote = "lastNote"
        static let selectedButtons = "selectedButtons"
        static let identitiesOfNotes = "identitiesOfNotes"
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        fillIdentitiesOfNotes()
        
        aCoder.encode(components, forKey: PropertyKey.components)
        aCoder.encode(repeatIdentity, forKey: PropertyKey.repeatIdentity)
        aCoder.encode(lastNote, forKey: PropertyKey.lastNote)
        aCoder.encode(selectedButtons, forKey: PropertyKey.selectedButtons)
        aCoder.encode(identitiesOfNotes, forKey: PropertyKey.identitiesOfNotes)
        
    }
    
    //im note sure if what i marked as optional and required here makes sense, look back over this at some point
    required convenience init?(coder aDecoder: NSCoder) {
        
        let components = aDecoder.decodeObject(forKey: PropertyKey.components) as! DateComponents
        let repeatIdentity = aDecoder.decodeInteger(forKey: PropertyKey.repeatIdentity)
        let lastNote = aDecoder.decodeObject(forKey: PropertyKey.lastNote) as! Note
        let selectedButtons = aDecoder.decodeObject(forKey: PropertyKey.selectedButtons) as? [Bool]
        let identitiesOfNotes = aDecoder.decodeObject(forKey: PropertyKey.identitiesOfNotes) as! [Int]
        
        //must call the designated initializer
        
        if (selectedButtons != nil) {
            self.init(components: components, repeatIdentity: repeatIdentity, lastNote: lastNote, selectedButtons: selectedButtons!, identitiesOfNotes: identitiesOfNotes)
        } else {
            self.init(components: components, repeatIdentity: repeatIdentity, lastNote: lastNote, identitiesOfNotes: identitiesOfNotes)
        }
        
    }
    
}







































