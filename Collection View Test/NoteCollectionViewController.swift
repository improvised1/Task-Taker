//
//  NoteCollectionViewController.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 5/22/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log


class NoteCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {

    //MARK: Properties
    let reuseIdentifier = "NoteCell"
    let sectionInsets = UIEdgeInsetsMake(20, 20, 20, 20)    //top, left, bottom, right
    
    var notes = [Note]()
    var completedNotes = [Note]()
    var headers = [Header]()
    
    var headersDisplayed = [Header]()
    var openHeaderIdentity: Int?
    var openNoteIdentity: Int?
    let currentDate = Date()
    let formatter = DateFormatter()
    var headersSystem: Int?     //holds a # that corresponds to a headers date system, like today-tommorow-this week-later, or today-this week-later
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //reloading the collection view whenver the app is opened or its orientation changed (since cell size dependent on screen width, need to re-load cells when orientation and width changes)
        NotificationCenter.default.addObserver(self, selector: #selector(actionsForEneringForeground), name: .UIApplicationWillEnterForeground , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(actionsForOrientationChange), name: .UIDeviceOrientationDidChange , object: nil)

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
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
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Was registered an as observer for UIApplicationWillEnterForeground in viewDidLoad
    func actionsForEneringForeground() {
        print("notification received, running actionsForEneringForeground() method")
        notesIntoHeaders()  //need to run this method to move any checked notes out of its headers notes variable
        self.collectionView?.reloadData()
    }
    
    func actionsForOrientationChange() {
        print("notification received, running actionsForOrientationChange() method")
        self.collectionView?.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
                destinationViewController.color = (selectedHeader?.color)!
            
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
                
                //passing date to destionation
                destinationViewController.note = selectedNote
                destinationViewController.headerNearDate = headerNearDate
 
            default:
                fatalError("Unexpected Segue Identifier, no code to deal with this segue; \(String(describing: segue.identifier))")


        }
        
    }
    
    //This method determines what happens when you return to this view, A.K.A.
    //This method deals with creating new sections and notes
    @IBAction func unwindToReminderList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? HeaderViewController {
            
            //if an existing header was edited or if a new one was made
            if sourceViewController.isEdit! {
                
                let newHeader = sourceViewController.header
                
                //replacing the old header with the new header
                for index in 0..<headers.count {
                    if (newHeader?.identity == headers[index].identity) {
                        headers[index] = newHeader!
                    }
                }
                
                self.collectionView?.reloadData()   //reloads the collectionView so it displays the new data
                
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
            
            updateNoteIdentities()
            notesIntoHeaders()
            addDefaultNotes()
            
            self.collectionView?.reloadData()
            
            //save the notes
            saveCompletedNotes()
            saveNotes()
            
        }
        
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
    
        if note.hasDate {
            cell.dateLabel.text = dateFormatter.string(from: note.activationDate!)
        } else {
            cell.dateLabel.text = ""
        }
        
        return cell
        
    }
    
    //configures the sections
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        var header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "NoteHeader", for: indexPath) as! NoteCollectionReusableView
        
        let section = headersDisplayed[(indexPath as NSIndexPath).section]
        
        header.titleLabel.text = section.name
        header.headerDataClass = section
        header.parentView = self
        header = assignImages(headerCell: header)
        
        
        return header
        
    }

    // MARK: Cell Size Methods
    
    //defines the size of each cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * 2   //amount of space to leave open to each side
        let widthPerItem = view.frame.width - paddingSpace    //amount of space left for the cell, total space - padding space
        let heightPeritem: CGFloat = 51    //defined height of each cell (its total feature in storyboard have a height of 50.5
        
        return CGSize(width: widthPerItem, height: heightPeritem)
    }
    
    //defines the margins (padding space) around this cell
    //Educated guess - seems to affect spacing between header and cells, no cell -> cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    //defines the spacing between each cell, as in "cell 1 bottom" -> "cell 2 top"
    //Ecucated guess - seems to affect spacing between cells and other cells, not cells -> header
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.bottom
    }
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
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
    
    //will be activated when a header is tapped, it will switch whether their notes should be displayed or not
    func headerSelected(header: Header) {
        header.notesAreHidden = !header.notesAreHidden
        self.collectionView?.reloadData()
        
        //saving headers
        saveHeaders()
    }
    
    //will activate when the checkbox is selected in one of the notes
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
        
        //moving selectetNote to correct arrays and removing from incorrect arrays
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
    
    //will organize notes into headers
    //has a glitch where if array notes is empty the seconf for-loop will be 0...-1.  Added a default not in createHeadersSystem to deal with that
    //
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
    Will take the value of var. headersSystem to determine how the headers that hold dates with notes will be organized
    if var. headersSystem equals...
    1 - today-tommorrow-this week-additional
    */
    /*
     Is an unimportant feature and so skipped implementation, will implement later
    */
    func createHeadersSystem() {
        
        switch headersSystem {
            
        case 1?:
            
            var nearDateComponents = DateComponents()
            var farDateComponents = DateComponents()
            let collection = [Note]()
            
            nearDateComponents.day = -7
            findOpenHeaderIdentity()
            let header1 = Header(name: "Over a week ago", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: true)
            header1.headerShouldHide = true
            headers.append(header1)
            
            nearDateComponents.day = -2
            farDateComponents.day = -6
            findOpenHeaderIdentity()
            let header2 = Header(name: "last week", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, farDate: farDateComponents)
            header2.headerShouldHide = true
            headers.append(header2)
            
            nearDateComponents.day = -1
            findOpenHeaderIdentity()
            let header3 = Header(name: "Yesterday", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false)
            header3.headerShouldHide = true
            headers.append(header3)
            
            nearDateComponents.day = 0
            findOpenHeaderIdentity()
            let header4 = Header(name: "Today", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false)
            headers.append(header4)
            
            nearDateComponents.day = 1
            findOpenHeaderIdentity()
            let header5 = Header(name: "Tomorrow", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: false)
            headers.append(header5)
            
            nearDateComponents.day = 2
            farDateComponents.day = 6
            findOpenHeaderIdentity()
            let header6 = Header(name: "This week", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, farDate: farDateComponents)
            headers.append(header6)
            
            nearDateComponents.day = 7
            findOpenHeaderIdentity()
            let header7 = Header(name: "over a week away", notes: collection, identity: openHeaderIdentity!, nearDate: nearDateComponents, hasForever: true)
            headers.append(header7)
            
            findOpenHeaderIdentity()
            let header9 = Header(name: "miscellaneous", notes: collection, identity: openHeaderIdentity!)
            header9.headerShouldHide = true
            header9.isMiscellaneous = true
            headers.append(header9)
            
            findOpenHeaderIdentity()
            let header8 = Header(name: "Completed Notes", notes: collection, identity: openHeaderIdentity!)
            header8.notesAreCompleted = true
            header8.notesAreHidden = true
            headers.append(header8)
            
            //save headers
            saveHeaders()           //once more options are implemented here consider moving to the end
            
        default:
            
            break
            
        }
        
    }
    
    //will update note identities to match the header with the same activation date
    func updateNoteIdentities() {
        
        /*
         Will go through every headers index and every notes index and use the headers .matches method to see if the note belongs in that header
        */
        for headerIndex in 0...headers.count - 1 {
            
            if headers[headerIndex].hasDate {
                
                for notesIndex in 0...notes.count - 1 {
                    
                    if notes[notesIndex].hasDate {
                        
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
    
    //MARK: Private Methods
    
    //will create a series of sample notes
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
    
    
    func noteUnchecked(newNote: Note) {
        
        /*
         (1) If the note has an activation date sent it to its correct header, (2) else send it back to its originial dateless header, (3) else send it to the miscellaneous header if its originial header dosent exist any longer
         */
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
    
    //will find the next open header identity
    func findOpenHeaderIdentity() {
        
        if (headers.count == 0) {   //to fix the if-statement glitch where it will be 0...-1
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

    //will find the next open note identity
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
    
    //Not fully functional, what happens if we're creating a default note in a header that has dates?
    //same problem below
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
    
    //will go through all headers and add default notes if they don't exist
    //has same problem as above
    func addDefaultNotes() {
        
        /*
         will go through every header and check that the last note is empty.  If its not, add a new default note to that header
         */
        
        for headerIndex in 0...headers.count - 1 {
            
            // [ if the last note in the header is not empty || there are no notes in the heade ] && this is not the header that holds completed notes
            if ((headers[headerIndex].notes.last?.text.isEmpty == false) || (headers[headerIndex].notes.isEmpty)) && headers[headerIndex].notesAreCompleted == false {
                
                findOpenNoteIdentity()
                let defaultNote = Note(text: "", headerIdentity: headers[headerIndex].identity, identity: openNoteIdentity!)
                headers[headerIndex].notes.append(defaultNote)
                notes.append(defaultNote)
                
            }
            
        }
        
    }
    
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
    
    func assignImages(headerCell: NoteCollectionReusableView) -> NoteCollectionReusableView {
        
        headerCell.editButton.setImage(#imageLiteral(resourceName: "pencilEdit"), for: UIControlState.normal)
        
        switch headerCell.headerDataClass?.color {
            
            case "light blue"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "lbleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "lbcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "lbright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "lbpencil"), for: UIControlState.normal)
            
            case "dark green"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "dgleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "dgcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "dgright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "dgpencil"), for: UIControlState.normal)
            
            case "dark blue 1"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "db1left")
                headerCell.centerImage.image = #imageLiteral(resourceName: "db1center")
                headerCell.rightImage.image = #imageLiteral(resourceName: "db1right")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "db1pencil"), for: UIControlState.normal)

            case "dark blue 2"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "db2left")
                headerCell.centerImage.image = #imageLiteral(resourceName: "db2center")
                headerCell.rightImage.image = #imageLiteral(resourceName: "db2right")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "db2pencil"), for: UIControlState.normal)
            
            case "red"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "rleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "rcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "rright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "rpencil"), for: UIControlState.normal)
            
            case "yellow"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "yleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "ycenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "yright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "ypencil"), for: UIControlState.normal)
            
            case "green"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "gleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "gcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "gright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "gpencil"), for: UIControlState.normal)
            
            case "orange"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "orleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "orcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "orright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "orpencil"), for: UIControlState.normal)
            
            case "hot pink"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "hpleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "hpcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "hpright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "hppencil"), for: UIControlState.normal)
            
            case "purple"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "pleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "pcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "pright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "ppencil"), for: UIControlState.normal)
            
            case "grey"?:
                headerCell.leftImage.image = #imageLiteral(resourceName: "greleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "grecenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "greright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "grepencil"), for: UIControlState.normal)
            
            default:
                headerCell.leftImage.image = #imageLiteral(resourceName: "orleft")
                headerCell.centerImage.image = #imageLiteral(resourceName: "orcenter")
                headerCell.rightImage.image = #imageLiteral(resourceName: "orright")
                headerCell.editButton.setImage(#imageLiteral(resourceName: "orpencil"), for: UIControlState.normal)

            
        }
        
        return(headerCell)
        
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
    
    private func loadNotes() -> [Note]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: Note.NotesArchiveURL.path) as? [Note]
        
    }
    
    private func loadCompletedNotes() -> [Note]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: Note.CompletedArchiveURL.path) as? [Note]
        
    }
    
    private func loadHeaders() -> [Header]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: Header.ArchiveURL.path) as? [Header]
        
    }
    
}






























































