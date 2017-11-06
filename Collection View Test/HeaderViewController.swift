//
//  HeaderViewController.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 6/8/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log

class HeaderViewController: UIViewController, UITextFieldDelegate {

    //MARK: Properties
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var datePicker: UIDatePicker!
    var header: Header?
    var note: Note?
    var openHeaderIdentity: Int?
    var openNoteIdentity: Int?
    var color: String = ""
    var isEdit: Bool?
    
    @IBOutlet weak var dateRangeText: UILabel!
    @IBOutlet weak var dateSystemStack: UIStackView!    //will implement later, for now is always hidden
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if isEdit! {
            
            navigationItem.title = header?.name
            nameTextField.text = header?.name
            
            dateSystemStack.isHidden = true
            
        } else {
            
            dateRangeText.isHidden = true
            dateSystemStack.isHidden = true
            
        }
        
        dateRangeText.isHidden = true   //temporarily disabling this feature
        
        //setting this class as the textfields delegate
        nameTextField.delegate = self
        
        //enables the save button only if the textfield isnt blank
        if (note?.text == "") {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    
    //activates whenever the text is changed
    //will deactivate the save button if the textfield is empty
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //determining the new text (old text + new text at correct range)
        var text = textField.text! as NSString
        text = text.replacingCharacters(in: range, with: string) as NSString
        
        if (text.isEqual(to: "")) {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
        
        return true     //If this was false then the users new text would be rejected.  Any text is allowed, so this is always true
        
    }
    
    //will resign the textfields first responder status, closing the keyboard and returning the view controller to promenance
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    //MARK: Actions
    
    @IBAction func redButtonSelected(_ sender: UIButton) {
        color = "red"
    }
    
    @IBAction func orangeButtonSelected(_ sender: Any) {
        color = "orange"
    }
    
    @IBAction func yellowButtonSelected(_ sender: Any) {
        color = "yellow"
    }
    
    @IBAction func greenButtonSelected(_ sender: Any) {
        color = "green"
    }
    
    @IBAction func darkGreenButtonSelected(_ sender: Any) {
        color = "dark green"
    }
    
    @IBAction func lightBlueButtonSelected(_ sender: Any) {
        color = "light blue"
    }
    //lighter
    @IBAction func darkBlue2ButtonSelected(_ sender: Any) {
        color = "dark blue 2"
    }
    //darker
    @IBAction func darkBlue1ButtonSelected(_ sender: Any) {
        color = "dark blue 1"
    }
    
    @IBAction func purpleButtonSelected(_ sender: Any) {
        color = "purple"
    }
    
    @IBAction func pinkButtonSelected(_ sender: Any) {
        color = "hot pink"
    }
    
    @IBAction func greyButtonSelected(_ sender: Any) {
        color = "grey"
    }
    
    // MARK: - Navigation

    //activated when the cancel UIBarButtonItem is clicked
    //will return you to the collectionView
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // will allow you to configure a view controller before presenting it
    // creates the header that you gave the data for in this view so that it can be called on in the main view controller
    //------------------------------ Reorganize this to look nicer
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        //will only continue past this point if the save button was pressed, otherwise give an error
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            
            return
            
        }
        
        if isEdit! {
            
            //updating the header
            header?.name = nameTextField.text!
            header?.color = color
            
        } else {
            
            //creating a default note
            var collection = [Note]()
            let tempNote = Note(text: "", headerIdentity: openHeaderIdentity!, identity: openNoteIdentity!)
            collection += [tempNote]
            
            //take the words in the textbox as header name, default to blank
            let name = nameTextField.text ?? ""
            let notes = collection
            
            //creating the header and note thats to be passed to NoteCollectionViewController
            header = Header(name: name, notes: notes, identity: openHeaderIdentity!)
            header?.color = color
            note = tempNote
            
        }
        
        
        
    }

}




































