//
//  NoteCollectionViewController.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 5/22/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log

/*
 * Design notes
 *
 * Update Sequence
 *      - You'll often see updateNoteIdentities(), notesIntoHeaders(), and addDefaultNotes() called right after eachother.  These methods are involved in updating the displayed notes and are called whenever data is changed and what is presented therefore needs to be changed as well.
 */

class NoteCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    //MARK: Properties
    let reuseIdentifier = "NoteCell"
    let sectionInsets = UIEdgeInsetsMake(0, 20, 30, 20)    //top, left, bottom, right
    
    var notes = [Note]()
    var completedNotes = [Note]()
    var headers = [Header]()
    var headersDisplayed = [Header]()
    var repeatingNotes = [RepeatingNote]()
    
    var openHeaderIdentity: Int?
    var openNoteIdentity: Int?
    let currentDate = Date()
    let formatter = DateFormatter()
    var headersSystem: Int?     //holds a # that corresponds to a headers date system, like today-tommorow-this week-later, or today-this week-later
    
    //MARK: Setup Methods
    
    /*
     * viewDidLoad() method
     * This method runs at startup, and does various actions to set everything up.  These actions are explained within the method.
     */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //setting background image
        self.collectionView?.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
        
        //reloading the collection view whenver the app is opened or its orientation changed (since cell size dependent on screen width, need to re-load cells when orientation and width changes)
        NotificationCenter.default.addObserver(self, selector: #selector(actionsForEneringForeground), name: .UIApplicationWillEnterForeground , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(actionsForOrientationChange), name: .UIDeviceOrientationDidChange , object: nil)
        
        //adds a slight inset for all content
        //I added this because the top header came right up to the navigation bar which looked bad, this creates an inset between content -> collection view, not content -> content, and so only adds an inset between the navigation bar and top header, as i wanted
        collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        headersSystem = 1   //will need to add a default value or load a previously selected value, later
        
        //load any saved headers, otherwise create the basic headers system
        if let savedHeaders = loadHeaders() {
            headers += savedHeaders
        } else {
            createHeadersSystem()
        }
        
        //load any saved meals, otherwise load sample data
        if let savedNotes = loadNotes() {
            notes += savedNotes
        } else {
            loadSampleNotes()
        }
        
        if let savedCompletedNotes = loadCompletedNotes() {
            completedNotes += savedCompletedNotes
        }
        
        updateNoteIdentities()
        notesIntoHeaders()
        addDefaultNotes()
        
        if let savedRepeatingNotes = loadRepeatingNotes() {
            repeatingNotes = savedRepeatingNotes
            
            for repeatingNote in repeatingNotes {   //RepeatingNotes parent variable can't be saved, so we have to pass it a new copy of parent whenever we load it
                repeatingNote.parent = self
                repeatingNote.runCheckup()
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     * actionsForEnteringForeground() method
     * This method was registered as an observer for UIApplicationWillEnterForeground in viewDidLoad.  This means that whenever the users takes this program out of the background and returns to using it, this method runs.  This method
     * only calls notesIntoHeaders() to remove checked notes.  It's assumed that no date changes will occur when reloading from background rather then completely reloading.
     */
    @objc func actionsForEneringForeground() {
        notesIntoHeaders()
        self.collectionView?.reloadData()
    }
    
    /*
     * actionsForOrientationChange() method
     * This method was registered as an observer for UIDeviceOrientationDidChange in viewDidLoad.  This means that whenever the user flips there phone, changing orientation, this method runs.  All cells in this program has a width set
     * to be based off of the screen width, and when orientation flips that width changes, so we need to recalculate the size of every cell.
     */
    @objc func actionsForOrientationChange() {
        self.collectionView?.reloadData()
    }
    
    // MARK: - Navigation

    /*
     * prepare() method, for sender
     * This method automatically runs when any segue occurs.  The screen we're transitioning to will often need to receive data from this screen, and this method transfers that data.  Exactly what data it transfers and why is explained
     * in the switch-case statement for each segue type.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)   //not sure what role this fills
        
        switch(segue.identifier ?? "") {
            case "newSection":
            
                //will fill the var. openHeaderIdentity and openNoteIdentity in the destination Segue with the value of the next open identities
                findOpenHeaderIdentity()
                findOpenNoteIdentity()
                
                let destinationNavigationController = segue.destination as! UINavigationController
                let destinationViewController = destinationNavigationController.topViewController as! HeaderViewController
            
                destinationViewController.openHeaderIdentity = self.openHeaderIdentity
                destinationViewController.openNoteIdentity = self.openNoteIdentity
                destinationViewController.isEdit = false
            
            case "editSection":
            
                //finding the destination view controller
                let destinationNavigationController = segue.destination as! UINavigationController
                let destinationViewController = destinationNavigationController.topViewController as! HeaderViewController
            
                //finding the selected header data class
                let selectedButton = sender as! UIButton
                let headerCell = selectedButton.superview as? NoteCollectionReusableView
                let selectedHeader = headerCell?.headerDataClass
                
                //filling variables in destination with correct values
                destinationViewController.isEdit = true
                destinationViewController.header = selectedHeader
            
            case "editNote":
            
                /*
                Is determining the note in the noteCollectionViewCell that was selected and passing it to the destination, as well as either the activation date of this notes header or the closes date to the current day that the header can hold
                */
                
                //findind destination view controller
                let destinationNavigationController = segue.destination as! UINavigationController
                let destinationViewController = destinationNavigationController.topViewController as! NoteViewController
                
                //finding selected note
                let selectedButton = sender as! UIButton
                let noteCell = selectedButton.superview?.superview as? NoteCollectionViewCell
                let selectedNote = noteCell?.note
                
                //finding nearDate of header
                var headerNearDateComp: DateComponents?
                var headerNearDate: Date
                
                for tempHeader in headers {
                    if (selectedNote?.headerIdentity == tempHeader.identity) {
                        headerNearDateComp = tempHeader.nearDate
                    }
                }
            
                headerNearDate = Calendar.current.date(byAdding: headerNearDateComp!, to: currentDate)!
                
                destinationViewController.note = selectedNote   //passing date to destionation
                destinationViewController.headerNearDate = headerNearDate
                destinationViewController.noteCell = noteCell   //passing a copy of the noteCell
            
                //setting variables related to RepeatingNote's
                if (selectedNote?.repeatIdentity != nil) {
                    
                    let thisRepeatingNote = findRepeatingNoteWithidentity(identity: (selectedNote?.repeatIdentity)!)
                    destinationViewController.components = thisRepeatingNote.components
                    if (thisRepeatingNote.selectedButtons != nil) {
                        destinationViewController.selectedButtons = thisRepeatingNote.selectedButtons
                    }
                    
                }
 
            default:
                fatalError("Unexpected Segue Identifier, no code to deal with this segue; \(String(describing: segue.identifier))")


        }
        
    }
    
    /*
     * unwindToReminderList() method
     * this method automatically runs when returning to this view from another one.  It updates information if anything was changed/added elsewhere.  Exactly what it does for each type of view it can return from it explained inside.
     */
    @IBAction func unwindToReminderList(sender: UIStoryboardSegue) {
        
        print("Have arrived at unwindToReminderList()")
        
        if let sourceViewController = sender.source as? HeaderViewController {
            
            //if this section is to be deleted
            if sourceViewController.doDelete {
                
                //deleting this header from headers list
                let indexOfThis = headers.index(of: sourceViewController.header!)
                headers.remove(at: indexOfThis!)
                
                //deleting all notes of this header
                updateNoteIdentities()  //to make sure the right notes get deleted
                
                var deleteAtIndexes = [Int]()   //BUG FIX - if i delete notes as i find them i change the size of notes.count() but the for-loop dosent update, causing an out of bounds error
                for notesIndex in 0..<notes.count {
                    if (notes[notesIndex].headerIdentity == sourceViewController.header?.identity) {
                        deleteAtIndexes.append(notesIndex)
                    }
                }
                
                for atIndex in 0..<deleteAtIndexes.count {
                    notes.remove(at: deleteAtIndexes[atIndex] - atIndex)    // "- atIndex" because once i delete 1, next note is at -1 position
                }
                
                self.collectionView?.reloadData()
                
            //if an existing header was edited
            } else if sourceViewController.isEdit! {
                
                let newHeader = sourceViewController.header
                
                //replacing the old header with the new header
                for index in 0..<headers.count {
                    if (newHeader?.identity == headers[index].identity) {
                        headers[index] = newHeader!
                    }
                }
                
                self.collectionView?.reloadData()   //reloads the collectionView so it displays the new data
            
            //if a new header was made
            } else {
                
                let section = sourceViewController.header
                let note = sourceViewController.note
                
                //adds a new section
                headers.insert(section!, at: headers.count - 1)     //places the new header above header completedNotes but below everything else
                notes.append(note!)
                
                self.collectionView?.reloadData()   //reloads the collectionView so it displays the new data
                
            }
            
            //Save the headers 
            saveHeaders()
            
        } else if let sourceViewController = sender.source as? NoteViewController {
            
            let newNote = sourceViewController.note
            
            //finding the note with the same identity as the modified one, and changing that note to the modified one
            var fullnotes = notes + completedNotes
            
            for index in 0..<fullnotes.count {
                
                if fullnotes[index].identity == newNote?.identity {
                    
                    if (index < notes.count) {
                        notes[index] = newNote!
                    } else {
                        completedNotes[index - notes.count] = newNote!
                    }
                    
                    break
                }
                
            }
            
            print("1, right before repeating method start")
            
            //checking what, if any, work should be done concerning a RepeatingNote
            if (sourceViewController.repeatButton.isSelected && newNote?.repeatIdentity != nil) {   //an existing RepeatingNote may of been edited or reactivated
                
                print("2, this RepeatingNote it to be edited or reactivated")
                
                let newComponents = sourceViewController.components
                let thisRepeatingNote = findRepeatingNoteWithidentity(identity: (newNote?.repeatIdentity)!)
                
                if (thisRepeatingNote.active == false) {
                    //reactivate this repeatingNote
                    print("3, reactivating RepeatingNote")
                    newNote?.hasRepeat = true
                    reactivateRepeatingNotesWithidentity(repeatIdentity: (newNote?.repeatIdentity)!)
                    
                } else if (newComponents != thisRepeatingNote.components) {
                    print("3, editing RepeatingNote")
                    //this RepeatingNote was edited
                    //if newComponents use the start-from-weekdays things then i have to delete the old and create entirely new RepeatingNotes.  If the old RepeatingNote was a start-from-weekdays and new one isnt then delete old and create new, but with different creation method.  If both non!start-from-weekdays, then use RepeatingNotes edit() method
                    
                    let weekDayButtons = sourceViewController.selectedButtons
                    
                    if (weekDayButtons != nil) {    //delete old, create multiple new
                        
                        print("4, deleting singular/multile old and creating multiple new")
                        completeDeleteRepeatingNoteWithIdentity(repeatIdentity: (newNote?.repeatIdentity!)!, fromNote: newNote!)
                        createMutlipleRepeatingNotes(weekDayButtons: weekDayButtons!, originialNote: newNote!, components: newComponents, repeatIdentity: (newNote?.repeatIdentity)!)
                        
                    } else if (multipleRepeatingNotesForIdentity(repeatIdentity: (newNote?.repeatIdentity)!)) {    //delete old, create single new
                        
                        print("4, deleting multiple old and creating single new")
                        completeDeleteRepeatingNoteWithIdentity(repeatIdentity: (newNote?.repeatIdentity!)!, fromNote: newNote!)
                        
                        let notesArray: [Note] = [newNote!]
                        let newRepeatingNote = RepeatingNote(components: newComponents, repeatIdentity: (newNote?.repeatIdentity)!, notes: notesArray, parent: self)
                        repeatingNotes.append(newRepeatingNote)
                        
                    } else {    //delete neigher, edit the singular one to a singular new
                        
                        print("4, editing RepeatingNote to a singular format")
                        let thisRepeatingNote = findRepeatingNoteWithidentity(identity: (newNote?.repeatIdentity)!)
                        thisRepeatingNote.edit(newComponents: newComponents)
                        
                    }
                    
                }
                
            } else if (sourceViewController.repeatButton.isSelected && newNote?.repeatIdentity == nil) {    //create new RepeatingNote
                
                print("2, We're to create a new RepeatingNote")
                
                let components = sourceViewController.components
                let weekdayButtons = sourceViewController.selectedButtons
                let repeatingNoteIdentity = returnOpenRepeatingNoteIdentity()
                newNote?.repeatIdentity = repeatingNoteIdentity
                newNote?.hasRepeat = true
                
                if (weekdayButtons == nil) {    //create only a single new RepeatingNote
                    
                    let notesArray: [Note] = [newNote!]
                    
                    if (components == nil) {
                        print("components are nil")
                    } else {
                        print("components are not nil")
                    }
                    let newRepeatingNote = RepeatingNote(components: components, repeatIdentity: repeatingNoteIdentity, notes: notesArray, parent: self)
                    repeatingNotes.append(newRepeatingNote)
                    
                } else {    //create multiple RepeatingNotes, one starting from each selected weekday
                    
                    createMutlipleRepeatingNotes(weekDayButtons: weekdayButtons!, originialNote: newNote!, components: components, repeatIdentity: repeatingNoteIdentity)
                    
                }
                
            } else if (sourceViewController.repeatButton.isSelected == false && newNote?.repeatIdentity != nil) {    //a RepeatingNote was deactivated
            
                print("2, We're to delete a RepeatingNote")
                deleteRepeatingNotesWithIdentity(repeatIdentity: (newNote?.repeatIdentity)!, fromNote: newNote!)
                
            }
            
            //save any repeatingNotes that where created or modified
            saveRepeatingNotes()
                
            updateNoteIdentities()
            notesIntoHeaders()
            addDefaultNotes()
            
            self.collectionView?.reloadData()
            
            //save the notes
            saveCompletedNotes()
            saveNotes()
            
        }
        
        print("----- Have finished unwindToReminderList()")
        
    }

    // MARK: Cell and Section Creation Methods (formerly UICollectionViewDataSource)
    
    //number of sections
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        headersDisplayed.removeAll()    //empying of all previous values
        
        for tempHeader in headers {
            
            // ! [ if this header should hide when empty && [ this header is empty || this headers first note is a default note ]]
            if !(tempHeader.headerShouldHide && (tempHeader.notes.isEmpty || tempHeader.notes[0].text == "")) {
                headersDisplayed.append(tempHeader)
            }
        }
 
        return headersDisplayed.count
    }

    //number of cells
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if headersDisplayed[section].notesAreHidden == false {
            return headersDisplayed[section].notes.count
        } else {
            return 0
        }
        
    }

    //configures the cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! NoteCollectionViewCell
    
        //fetches the appropiate note
        let header = headersDisplayed[(indexPath as NSIndexPath).section]
        let note = header.notes[indexPath.row]
        
        //modifying the cell
        cell.textField.text = note.text
        cell.checkbox.setImage(#imageLiteral(resourceName: "emptyCheckbox"), for: UIControlState.normal)
        cell.checkbox.setImage(#imageLiteral(resourceName: "filledCheckbox"), for: UIControlState.selected)
        cell.checkbox.isSelected = note.checkboxClicked
        cell.note = note
        cell.setImage()
    
        if note.hasDate {
            cell.dateLabel.text = dateFormatter.string(from: note.activationDate!)
        } else {
            cell.dateLabel.text = ""
        }
        
        return cell
        
    }
    
    //configures the sections
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "NoteHeader", for: indexPath) as! NoteCollectionReusableView
        
        let section = headersDisplayed[(indexPath as NSIndexPath).section]
        
        section.dynamicNameGenerator()  //sets the name variable to the correct string
        header.titleLabel.text = section.name
        header.headerDataClass = section
        header.parentView = self
        header.setImage()
        
        return header
        
    }

    // MARK: Cell Size Methods
    
    //defines the size of each cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        //let header = headersDisplayed[(indexPath as NSIndexPath).section]
        //let note = header.notes[indexPath.row]
        
        let paddingSpace = sectionInsets.left * 2   //amount of space to leave open to each side
        let widthPerItem = view.frame.width - paddingSpace    //amount of space left for the cell, total space - padding space
        let heightPeritem: CGFloat = 70    //defined height of each cell
        
        return CGSize(width: widthPerItem, height: heightPeritem)
    }
    
    
    //defines the spacing between cells and headers, as in header -> cellFirst and cellLast -> nextHeader, but NOT cell -> cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    //defines the spacing between each cell, as in "cell 1 bottom" -> "cell 2 top", NOT cell -> header
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    //MARK: UITextFieldDelegate
    
    //not entirely sure if this can be merged into textFieldDidEndEditing, but is neccessary to resign first reponder status
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    //Will activate when you finish editing a text field
    //will save the new note and see if a new empty/default one neeeds to be added to the end
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        //finding the identity of the note used in this textField
        let cell = textField.superview?.superview as! NoteCollectionViewCell
        let noteIdentity = cell.note?.identity
        
        if (cell.textField.text == "") {
            
            //nothing was changed, so do nothing
            
        } else {    //the note was modified and now has text, should be made into a proper note
            
            //will go through all of the notes until it finds the one with an identity matching the note used in this textfield
            var noteIndex: Int?
            var selectedNote: Note?
            let fullNotes = notes + completedNotes
            
            for index in 0..<fullNotes.count {
                if (fullNotes[index].identity == noteIdentity) {
                    selectedNote = fullNotes[index]
                    noteIndex = index
                    break;
                }
            }
            
            //determining if the header the note is in has a date, and if so assigning it an activation date correlating to its headers activation date
            if !(selectedNote?.hasDate)! {
                
                var headerNearDateComp: DateComponents?
                var headerNearDate: Date
                
                for tempHeader in headers {
                    
                    if (selectedNote?.headerIdentity == tempHeader.identity) {
                        
                        //if the header has a date, but dosent hold a range of dates
                        if (tempHeader.hasDate && !tempHeader.hasFar && !tempHeader.hasForever) {
                            
                            headerNearDateComp = tempHeader.nearDate
                            headerNearDate = Calendar.current.date(byAdding: headerNearDateComp!, to: Date())!
                            selectedNote?.activationDate = headerNearDate
                            selectedNote?.hasDate = true
                            break
                        }
                    }
                }
            }
            
            //assigning normal variables
            selectedNote?.text = textField.text!
            
            //updating the note
            if (noteIndex! < notes.count) {
                notes[noteIndex!] = selectedNote!
            } else {
                completedNotes[noteIndex! - notes.count] = selectedNote!
            }
            
            //checking to see if new default notes are needed
            addDefaultNotes()
            
            //reloads the collectionView so it displays the new data
            self.collectionView?.reloadData()
            
            //saving notes
            saveNotes()
            
        }
        
    }
    
    //MARK: Actions
    
    /*
     * headerSelected() method
     * This method will run whenever a header is tapped.  It will change between displaying that headers notes and note displaying them.
     */
    func headerSelected(header: Header) {
        header.notesAreHidden = !header.notesAreHidden
        self.collectionView?.reloadData()
        
        //saving headers
        saveHeaders()
    }
    
    /*
     * checkboxSelected() method
     * This method runs whenever the checkbox in a note is selected.  What it does is explained inside (writing this blurb months after below, below it more accurate)
     */
    @IBAction func checkboxSelected(_ sender: UIButton) {
        
        let selectedButton = sender
        let noteCell = selectedButton.superview?.superview as? NoteCollectionViewCell
        let noteCellIdentity = noteCell?.note?.identity
        
        var selectedNote: Note?
        var indexOfSelected: Int?
        var fullNotes = notes + completedNotes
        
        //will go through the combined notes and completedNotes arrays until the selected note is found and placed in var. selectedNote
        for index in 0...fullNotes.count - 1 {
            if (fullNotes[index].identity == noteCellIdentity) {
                selectedNote = fullNotes[index]
                indexOfSelected = index
                break
            }
        }
        
        //swtiching note variables
        selectedNote?.checkboxClicked = !(selectedNote?.checkboxClicked)!  //switching the value of this variable
        noteCell?.checkbox.isSelected = (selectedNote?.checkboxClicked)!   //deciding button state based on previous variable
        
        //moving selectedNote to correct arrays and removing from incorrect arrays
        if (selectedNote?.checkboxClicked)! {    //if the box is now checked
            
            newCompletedNote(newNote: selectedNote!)
            notes.remove(at: indexOfSelected!)
            
        } else {    //if the box is now unchecked
            
            completedNotes.remove(at: (indexOfSelected! - notes.count))     //BUG FIX - since the index is from notes + completed notes, the index in completed notes is it - notes
            //SECOND BUG FIX - the above must be above noteUnchecked, that data is reloaded in the below method and thats neccessary to remove the unchecked note from display
            noteUnchecked(newNote: selectedNote!)
            
        }
        
        //save notes
        saveCompletedNotes()
        saveNotes()
        
    }
    
    //MARK: Headers creator and organizer methods
    
    /*
     * notesIntoHeaders() method
     * Will organize the notes into headers.  Unsure precisely how it functions, see comments in method
     */
    func notesIntoHeaders() {
        
        var addedNote = false   //new notes can be created in the following loop, if so we need to save notes at the end.  This tracks if we have to do that
        
        /*
         This is incredibly ugly
         This is a double for-loop that will go through every header index, and within that every note index.  Should the header and note identities match the note is added to var. tempCollection, which at the end will hold every note that goes to a certain header, and will be plugged into that header as its .notes value.
         Exceptions in the code:
            1 - the completedNotes header holds its notes value in var. completedNotes, not in var. notes
            2 - if the notes array is empty the notes for loop would be 0...-1, so the for-loop only runs if there are any notes to work with anyway
            3 - The default notes always go on the bottom, so its placed in a special holding variable and will be latched back onto var. tempCollection near the finish, so that it will be on the bottom
        */
        for headerIndex in 0...headers.count - 1 {
            
            if (headers[headerIndex].notesAreCompleted) {   //Exception 1
                headers[headerIndex].notes = completedNotes
                
            } else if (notes.isEmpty == false) {   //Exception 2
                
                var tempCollection = [Note]()
                var defaultNote: Note?
                var tempNote: Note
                
                for noteIndex in 0...notes.count - 1 {
                
                    tempNote = notes[noteIndex]
                
                    if tempNote.headerIdentity == headers[headerIndex].identity {
                        
                        if (tempNote.text.isEmpty == false) {   //Exception 3
                            tempCollection.append(tempNote)
                        } else {
                            defaultNote = tempNote
                        }
                        
                    }
                
                }   //end of for noteIndex
                
                if defaultNote == nil {     //if the default note is overridden to make a new note then none will be found and it will come out nil
                    findOpenNoteIdentity()
                    defaultNote = Note(text: "", headerIdentity: headers[headerIndex].identity, identity: openNoteIdentity!)
                    notes.append(defaultNote!)
                    addedNote = true
                }
                
                tempCollection.append(defaultNote!)
                headers[headerIndex].notes = tempCollection

            }   //end of else-if
            
        }   //end of for headerIndex
        
        if (addedNote) {
            //save notes
            saveNotes()
        }
        
    }
    
    /*
     * createHeadersSystem() method
     * Will create all of the headers and their date components.  Is part of initial setup.
     */
    func createHeadersSystem() {
        
        /*
         Will take the value of var. headersSystem to determine how the headers that hold dates with notes will be organized
         if var. headersSystem equals...
         1 - today-tommorrow-this week-additional
         */
        /*
         Is an unimportant feature and so skipped implementation, will implement later
         */
        
        switch headersSystem {
            
        case 1?:
            
            var nearDateComponents = DateComponents()
            var farDateComponents = DateComponents()
            let collection = [Note]()
            
            nearDateComponents.day = -7
            findOpenHeaderIdentity()
            let header1 = Header(name: "Over a week ago", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: true, deletable: false)
            header1.headerShouldHide = true
            headers.append(header1)
            
            nearDateComponents.day = -2
            farDateComponents.day = -6
            findOpenHeaderIdentity()
            let header2 = Header(name: "last week", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, farDate: farDateComponents, deletable: false)
            header2.headerShouldHide = true
            headers.append(header2)
            
            nearDateComponents.day = -1
            findOpenHeaderIdentity()
            let header3 = Header(name: "Yesterday", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            header3.headerShouldHide = true
            headers.append(header3)
            
            nearDateComponents.day = 0
            findOpenHeaderIdentity()
            let header4 = Header(name: "Today", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            headers.append(header4)
            
            nearDateComponents.day = 1
            findOpenHeaderIdentity()
            let header5 = Header(name: "Tomorrow", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            headers.append(header5)
            
            nearDateComponents.day = 2
            findOpenHeaderIdentity()
            let header6 = Header(name: "Today+2", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            header6.hasDynamicName = true
            headers.append(header6)
            
            nearDateComponents.day = 3
            findOpenHeaderIdentity()
            let header7 = Header(name: "Today+3", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            header7.hasDynamicName = true
            headers.append(header7)
            
            nearDateComponents.day = 4
            findOpenHeaderIdentity()
            let header8 = Header(name: "Today+4", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            header8.hasDynamicName = true
            headers.append(header8)
            
            nearDateComponents.day = 5
            findOpenHeaderIdentity()
            let header9 = Header(name: "Today+5", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            header9.hasDynamicName = true
            headers.append(header9)
            
            nearDateComponents.day = 6
            findOpenHeaderIdentity()
            let header10 = Header(name: "Today+6", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false, deletable: false)
            header10.hasDynamicName = true
            headers.append(header10)
            
            nearDateComponents.day = 7
            farDateComponents.day = 14
            findOpenHeaderIdentity()
            let header11 = Header(name: "Next Week", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, farDate: farDateComponents, deletable: false)
            headers.append(header11)
            
            nearDateComponents.day = 15
            findOpenHeaderIdentity()
            let header12 = Header(name: "over a week away", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: true, deletable: false)
            header12.isFinalHeader = true
            headers.append(header12)
            
            findOpenHeaderIdentity()
            let header13 = Header(name: "miscellaneous", notes: collection, identity: openHeaderIdentity!, deletable: false)
            header13.headerShouldHide = true
            header13.isMiscellaneous = true
            headers.append(header13)
            
            findOpenHeaderIdentity()
            let header14 = Header(name: "Completed Notes", notes: collection, identity: openHeaderIdentity!, deletable: false)
            header14.notesAreCompleted = true
            header14.notesAreHidden = true
            headers.append(header14)
            
            //save headers
            saveHeaders()           //once more options are implemented here consider moving to the end
            
        default:
            
            break
            
        }
        
    }
    
    /*
     * updateNoteIdentities() method
     * This method will go through every header and every note to see if their dates match.  If so the note's headerIdentity is updated to match the headers identity.
     */
    func updateNoteIdentities() {
        
        for headerIndex in 0...headers.count - 1 {
            if headers[headerIndex].hasDate {
                
                for notesIndex in 0...notes.count - 1 {
                    if notes[notesIndex].hasDate {
                        
                        //using the .mathes() method to determine if their dates match
                        if (headers[headerIndex].matches(passedDate: notes[notesIndex].activationDate!)) {
                            
                            notes[notesIndex].headerIdentity = headers[headerIndex].identity
                            
                        }
                        
                    }
                }
                
            }
        }
        
        //save notes
        saveNotes()
        
    }
    
    /*
     This method is similar to the above, but updates the headerIdentity of only a single note at a time
     */
    func updateNoteIdentity(note: Note) {
        
        for headerIndex in 0...headers.count - 1 {
            if headers[headerIndex].hasDate {
                
                if note.hasDate {
                    
                    //using the .mathes() method to determine if their dates match
                    if (headers[headerIndex].matches(passedDate: note.activationDate!)) {
                        
                        note.headerIdentity = headers[headerIndex].identity
                        break
                        
                    }
                }
            }
        }
        
    }
    
    //MARK: Private Methods
    
    /*
     * loadSampleNotes() method
     * If this is the first time this app is running, then this method will create a series of sample notes
     */
    func loadSampleNotes() {
        
        var activationDateComponents = DateComponents()
        var activationDate: Date
        
        findOpenNoteIdentity()
        activationDateComponents.day = -1
        activationDate = Calendar.current.date(byAdding: activationDateComponents, to: Date())!
        var note = Note(text: "See to your old events", headerIdentity: 0, identity: openNoteIdentity!, activationDate: activationDate)
        notes.append(note)
        
        findOpenNoteIdentity()
        activationDateComponents.day = 0
        activationDate = Calendar.current.date(byAdding: activationDateComponents, to: Date())!
        note = Note(text: "List off what to do today", headerIdentity: 0, identity: openNoteIdentity!, activationDate: activationDate)
        notes.append(note)
        
        findOpenNoteIdentity()
        activationDateComponents.day = 1
        activationDate = Calendar.current.date(byAdding: activationDateComponents, to: Date())!
        note = Note(text: "And watch events move up", headerIdentity: 0, identity: openNoteIdentity!, activationDate: activationDate)
        notes.append(note)
        
        //not going to save notes, if the user creates a note it will save, if they don't create a note and nothing saves this will load up anyway
        
    }
    
    /*
     * noteUnckeded() method
     * This is a helper method of checkBoxSelected() method.  This method runs when a checkbox is selected and checkBoxSelected() determines that its being unselected.
     * (1) If the note has an activation date sent it to its correct header, (2) else send it back to its originial dateless header, (3) else send it to the miscellaneous header if its originial header dosent exist any longer
     */
    func noteUnchecked(newNote: Note) {
        
        if (newNote.hasDate) {     //1
            
            notes.append(newNote)
            updateNoteIdentities()
            notesIntoHeaders()
            self.collectionView?.reloadData()
            
        } else {
            
            var foundHeader = false
            
            for tempHeader in headers {     //2
                
                if (newNote.headerIdentity == tempHeader.identity) {
                    foundHeader = true
                    break
                }
            }
            
            if (foundHeader == false) {     //3
                
                for tempHeader in headers {
                    if tempHeader.isMiscellaneous {
                        newNote.headerIdentity = tempHeader.identity
                        break
                    }
                }
                
            }
            
            //reorganizing notes with the right headerIdentities into there headers
            notes.append(newNote)
            notesIntoHeaders()
            self.collectionView?.reloadData()
            
        }
        
    }
    
    /*
     * findOpenHeaderIdentity() method
     * This method will find the next open header identity by going though every number 0 to headers.count() and checking if that identity is already taken.
     */
    func findOpenHeaderIdentity() {
        
        if (headers.count == 0) {   //to fix the for-loop glitch where it will be 0...-1
            openHeaderIdentity = 0
            
        } else {
            
            var doContinue = true
        
            //this for-loop will go through all possible identities until it finds one that is unused.  When it finds one doContinue is set to true, if it remains false then that identity is open
            for identity in 0...headers.count {
            
                doContinue = false
            
                for headerIndex in 0...(headers.count - 1) {
                
                    if identity == headers[headerIndex].identity {
                        doContinue = true
                        break;
                    }
                
                }   //end of for (headerIndex)
            
                if (doContinue == false) {
                    openHeaderIdentity = identity
                    break
                }
            
            }   //end of for (identity)
            
        }
        
    }

    /*
     * findOpenNoteIdentity() method
     * This method will find the next open note identity by going though every number 0 to notes.count() and checking if that identity is already taken.
     */
    func findOpenNoteIdentity() {
        
        let tempNotes = notes + completedNotes  //combining both notes arrays
        
        if (tempNotes.count == 0) {  //had a glitch where if this is the first note the for-index won't run, this fixes that
            openNoteIdentity = 0
            
        } else {
            
            var doContinue = true
            
            //this for-loop will go through all possible identities until it finds one that is unused.  When it finds one doContinue is set to true, if it remains false then that identity is open
            for identity in 0...tempNotes.count {
            
                doContinue = false
            
                for index in 0...tempNotes.count - 1 {
        
                    if identity == tempNotes[index].identity {
                        doContinue = true
                        break;
                    }
                
                }   //end of for (noteIndex)
            
                if (doContinue == false) {
                    openNoteIdentity = identity
                    break
                }
            
            }   //end of for (identity)
            
        }   //end of if-else loop
        
    }
    
    /*
     This method will find the next open note identity, but unlike the above method will return it, rather then using the weird instance variable system
    */
    func returnOpenNoteIdentity() -> Int {
        
        findOpenNoteIdentity()
        return openNoteIdentity!
        
    }
    
    /*
     This method will find the next open RepeatingNote identity by going through every number 0 to repeatingNotes.count() and checking if that identity is already taken
    */
    func returnOpenRepeatingNoteIdentity() -> Int {
    
        if (repeatingNotes.count == 0) {     //there was a glitch where if the array is empty 0...repeatingNotes.count-1 would be 0...-1, giving an error
            return 0
        } else {
            
            var doContinue = true
            
            //this for-loop will go through all possible identities until it finds one that is unused.  When it finds one doContinue is set to true, if it remains false then that identity is open
            for identity in 0...repeatingNotes.count {
                
                doContinue = false
                
                for index in 0...repeatingNotes.count - 1 {
                    if (identity == repeatingNotes[index].repeatIdentity) {
                        doContinue = true
                        break;
                    }
                }
                
                if (doContinue == false) {
                    return identity
                }
                
            }
            
        }
        
        return repeatingNotes.count //this should never run, but if we reach this point this will always be a safe identity
    
    }
    
    /*
     * addDefaultNote() method
     * This method will add a default, empty note to the header with the specified identity
     * This method should not be confused with addDefaultNotes().  The latter will check every header, see if it needs a default note, and adds one.  This one does so for only one header.
     */
    func addDefaultNote(headerIdentity: Int) {
        
        findOpenNoteIdentity()
        let tempNote = Note(text: "", headerIdentity: headerIdentity, identity: openNoteIdentity!)
        
        //going through all headers until we find the one with the same identity as our given identity, then adding the note to it
        for headerIndex in 0...headers.count - 1 {
            
            if (headers[headerIndex].identity == headerIdentity) {
                headers[headerIndex].notes.append(tempNote)
            }
            
        }
        
        notes.append(tempNote)
        
    }
    
    /*
     * addDefaultNotes() method
     * This method will go through every header and check if it has a default (empty) note at the end.  If not, it will add one.
     */
    func addDefaultNotes() {
        
        for headerIndex in 0...headers.count - 1 {
            
            // [ if the last note in the header is not empty || there are no notes in the header ] && this is not the header that holds completed notes
            if ((headers[headerIndex].notes.last?.text.isEmpty == false) || (headers[headerIndex].notes.isEmpty)) && headers[headerIndex].notesAreCompleted == false {
                
                findOpenNoteIdentity()
                let defaultNote = Note(text: "", headerIdentity: headers[headerIndex].identity, identity: openNoteIdentity!)
                headers[headerIndex].notes.append(defaultNote)
                notes.append(defaultNote)
                
            }
            
        }
        
    }
    
    /*
     * newCompletedNote() method
     * see below
     */
    //will add a new note to the completedNote array, but more importantly sort it to the correct position in that array depending on its activation or creation date
    func newCompletedNote(newNote: Note) {
        
        var newNoteDate: Date
        var oldNoteDate: Date
        var doContinue = true
        
        if (newNote.hasDate) {
            newNoteDate = newNote.activationDate!
        } else {
            newNoteDate = newNote.creationDate
        }
        
        /*
         These statements will attempt to find a position in completedNotes where the newNote is younger then everything in front of it but older then everything behind it.  There are some exceptions built into it for odd circumstances and figuring out what dates to complare.  
         A relatively basic sorting mechanism is used (just go through everything in order) since the newNote should usually go somewhere near the front.
         */
        if (completedNotes.isEmpty) {   //to avoid a glitch whereby the for statement will be 0...-1
            completedNotes.append(newNote)
            
        } else {
            
            for index in 0...completedNotes.count - 1 {
                
                if (completedNotes[index].hasDate) {
                    oldNoteDate = completedNotes[index].activationDate!
                } else {
                    oldNoteDate = completedNotes[index].creationDate
                }
                
                //if the new note has date farther in the future then the old date || if both dates are on the same day
                if (newNoteDate > oldNoteDate) || (Calendar.current.isDate(newNoteDate, inSameDayAs: oldNoteDate)) {
                    completedNotes.insert(newNote, at: index)   //will place the newNote at the oldNotes current position, and push it and everything else back one index
                    doContinue = false
                    break
                    
                }
                
            }   //end of for-loop
            
            //if doContinue is still true then newNote has a date behind every existing date and so should go on the end
            if doContinue {
                completedNotes.append(newNote)
            }
            
        }
        
    }   //end of method newCompletedNote
    
    /*
     This method will return true/false to indicate if the note nextNote should be created.  It should be created in every instance except the one specified below.
    */
    func shouldSpawnRepeatNote(currentNote: Note, nextNote: Note) -> Bool {
        
        //return false only if [header identity of both notes match] AND [the header with this identity is the final header]
        if (currentNote.headerIdentity == nextNote.headerIdentity) {
            
            let relevantHeader = findHeaderWithIdentity(identity: currentNote.headerIdentity)
            
            if (relevantHeader.isFinalHeader) {
                return false
            }
        }
        
        return true
        
    }
    
    /*
     Will return the header with the passed identity
    */
    func findHeaderWithIdentity(identity: Int) -> Header {
        
        for index in 0...headers.count-1 {
            if (headers[index].identity == identity) {
                return headers[index]
            }
        }
        
        return headers[0]   //should never run
        
    }
    
    /*
     Will find the RepeatingNote with the passed identity
    */
    func findRepeatingNoteWithidentity(identity: Int) ->  RepeatingNote {
        
        for index in 0...repeatingNotes.count-1 {
            if (repeatingNotes[index].repeatIdentity == identity) {
                print("found repeatingNote at index \(index), repeatingNotes[index].active: \(repeatingNotes[index].active)")
                return repeatingNotes[index]
            }
        }
        
        print("couldnt find RepeatingNote")
        return repeatingNotes[0]    //should never run
        
    }
    
    /*
     Will
    */
    func spawnNote(note: Note) {
        
        notes.append(note)
        
        notesIntoHeaders()
        addDefaultNotes()
        self.collectionView?.reloadData()
        
    }
    
    /*
     Will delete the passed note
    */
    func deleteNote(toDelete: Note) {
        
        for index in 0...notes.count-1 {
            if (notes[index].identity == toDelete.identity) {
                notes.remove(at: index)
                break
            }
        }
        
    }
    
    /*
     This method will find every RepeatingNote with the given identity and "delete it".  Note that the RepeatingNote itself is not deleted, but all of the notes that it automatically produced will be.
    */
    func deleteRepeatingNotesWithIdentity(repeatIdentity: Int, fromNote: Note) {
        
        for repeatingNote in repeatingNotes {
            if (repeatingNote.repeatIdentity == repeatIdentity) {
                repeatingNote.delete(fromNote: fromNote)
                print("repeatingNotes[index].active: \(repeatingNote.active)")
            }
        }
        
    }
    
    /*
     Unlike the above method, this one will completely delete the RepeatingNotes.  All notes before fromNote will remain but be disconected.
    */
    func completeDeleteRepeatingNoteWithIdentity(repeatIdentity: Int, fromNote: Note) {
        
        var indexCorrection = 0     //we'll be deleting elements from repeatingNotes but the below for-loop won't update to realize that.  So to keep index in range we'll be correcting it, -1 for each element removed.
        
        for index in 0...repeatingNotes.count {
            if (repeatingNotes[index - indexCorrection].repeatIdentity == repeatIdentity) {
                repeatingNotes[index].delete(fromNote: fromNote)
                repeatingNotes.remove(at: index - indexCorrection)
                indexCorrection -= 1
                
            }
            
        }
        
    }
    
    /*
     This method will reactivate every RepeatingNote with this identity by calling the RepeatingNotes .reactivate() method
    */
    func reactivateRepeatingNotesWithidentity(repeatIdentity: Int) {
        
        for repeatingNote in repeatingNotes {
            if (repeatingNote.repeatIdentity == repeatIdentity) {
                repeatingNote.reactivate()
            }
        }
        
    }
    
    /*
     This method will create mutiple new RepeatingNotes based off of information received from RepeatViewController and NoteViewController
     This code was once part of unwindToReminderList() and was moved here once we realized it may be used in other places
    */
    func createMutlipleRepeatingNotes(weekDayButtons: [Bool], originialNote: Note, components: DateComponents, repeatIdentity: Int) {
    
        let currentDate = Date()
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let myComponents = myCalendar?.components(.weekday, from: currentDate)
        let currentWeekDay = myComponents?.weekday     //weekDay is an integer 1 -> 7, where 1 is sunday and 7 saturday
        
        for weekDayInt in 1...7 {
            //the system i'm using treats weekdays as number 1...7, where 1 is sunday and 7 saturday.  weekdayButtons follows this convention, where index 0 is sunday and 7 is saturday.  weekDayInt is the identifier for the day of the week, and weekDayInt-1 is the index of weekdayButtons
            
            if (weekDayButtons[weekDayInt-1]) {
                
                //determinging the components to get this weekday from currentDate
                var differenceThisToToday = weekDayInt - currentWeekDay!
                
                if (differenceThisToToday < 0) {
                    differenceThisToToday += 7  //if i create a note on wednesday i dont want to start a repeat from last monday, but form next monday
                }
                
                //deriving the next date that has this weekday
                var thisComponents = DateComponents()
                thisComponents.day = differenceThisToToday
                let thisDate = Calendar.current.date(byAdding: thisComponents, to: currentDate)
                
                //creating a note with the correct start date
                let baseNote = Note(note: originialNote)
                baseNote.activationDate = thisDate
                baseNote.identity = returnOpenNoteIdentity()
                updateNoteIdentity(note: baseNote)
                
                //creating new RepeatingNote
                let notesArray: [Note] = [baseNote]
                
                let newRepeatingNote = RepeatingNote(components: components, repeatIdentity: repeatIdentity, notes: notesArray, parent: self)   //remember that all of these should have the same identity
                newRepeatingNote.selectedButtons = weekDayButtons
                repeatingNotes.append(newRepeatingNote)
                
            }
            
            
        }
        
    }
    
    /*
     This method will return true/false for whether or not there are multiple repeatingNotes with this identity.
     When the user selects to make a RepeatingNote starting that runs every monday, wednesday, and thursday, that's handles by creating 3 different but related RepeatingNotes that trigger once a week, each with one of those weekdays.  But they all have the same identity.  That is what this method checks for.
    */
    func multipleRepeatingNotesForIdentity(repeatIdentity: Int) -> Bool {
        
        var occurences: Int = 0
        
        for repeatingNote in repeatingNotes {
            if (repeatingNote.repeatIdentity == repeatIdentity) {
                occurences += 1
            }
        }
        
        if (occurences > 1) {
            return true
        } else {
            return false
        }
        
    }
    
    //MARK: Methods to do with saving and loading
    
    private func saveNotes() {
        
        NSKeyedArchiver.archiveRootObject(notes, toFile: Note.NotesArchiveURL.path)
        
    }
    
    private func saveCompletedNotes() {
    
        NSKeyedArchiver.archiveRootObject(completedNotes, toFile: Note.CompletedArchiveURL.path)
        
    }
    
    private func saveHeaders() {
        
       NSKeyedArchiver.archiveRootObject(headers, toFile: Header.ArchiveURL.path)
        
    }
    
    private func saveRepeatingNotes() {
        
        NSKeyedArchiver.archiveRootObject(repeatingNotes, toFile: RepeatingNote.ArchiveURL.path)
        
    }
    
    private func loadNotes() -> [Note]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: Note.NotesArchiveURL.path) as? [Note]
        
    }
    
    private func loadCompletedNotes() -> [Note]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: Note.CompletedArchiveURL.path) as? [Note]
        
    }
    
    private func loadHeaders() -> [Header]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: Header.ArchiveURL.path) as? [Header]
        
    }
    
    private func loadRepeatingNotes() -> [RepeatingNote]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: RepeatingNote.ArchiveURL.path) as? [RepeatingNote]
        
    }
    
}






























































