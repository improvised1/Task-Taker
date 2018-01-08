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
    @IBOutlet weak var deleteButton: UIButton!
    var header: Header?
    var note: Note?
    var openHeaderIdentity: Int?
    var openNoteIdentity: Int?
    var isEdit: Bool?
    var doDelete = false;
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //setting background image
        self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
        
        //will use this later when implementing delete button
        if isEdit! {
            navigationItem.title = header?.name
            nameTextField.text = header?.name
            
            if !(header?.deletable)! {  //BUG FIX - placed here to make sure that there is even a header to check the deletable variable of
                deleteButton.isHidden = true;
            }
            
        } else {
            deleteButton.isHidden = true;
        }
        
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

    // MARK: Actions
    
    /*
    deleteClicked() method
    This method runs whenever deleteButton is clicked.
    This method will run an alert popup warning that deleting this section is permanent, and will give the user a cancel and delete option.  If they click delete, then we unwind to the main view controller, but first we set the variable doDelete to true, to signal that we should delete this header.  We use that variable because the returnToReminderList in main can't check identifiers.
    */
    @IBAction func deleteClicked(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete this item?", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        //adding delete button + its actions
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) { action in
            self.doDelete = true;
            self.performSegue(withIdentifier: "deleteSection", sender: self)     //return to main view with identifier "deleteSection"
        }
        alertController.addAction(deleteAction)
        
        //presenting alert message
        self.present(alertController, animated: true, completion: nil)
        
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
            
        } else {
            
            //creating a default note
            var collection = [Note]()
            let tempNote = Note(text: "", headerIdentity: openHeaderIdentity!, identity: openNoteIdentity!)
            collection += [tempNote]
            
            //take the words in the textbox as header name, default to blank
            let name = nameTextField.text ?? ""
            let notes = collection
            
            //creating the header and note thats to be passed to NoteCollectionViewController
            header = Header(name: name, notes: notes, identity: openHeaderIdentity!, deletable: true)
            note = tempNote
            
        }
        
    }

}




































