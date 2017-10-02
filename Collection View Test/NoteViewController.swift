//
//  NoteViewController.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 6/8/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log

class NoteViewController: UIViewController, UITextFieldDelegate {

    //MARK: Properties
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    var note: Note?     //will only be updated if the user clicks save
    var activationDate: Date?
    var headerNearDate: Date?   //will hold the headers activation date, which will be the default activation date
    var hasDate: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setting this class as the textfields delegate
        nameTextField.delegate = self
        
        //updating text in the view controller
        activationDate = note?.activationDate
        navigationItem.title = note?.text ?? "New Reminder"  //displays the text in this note as the view controllers title, else defaulting to "New Reminder"
        nameTextField.text = note?.text
        hasDate = (note?.hasDate)!
        
        datePickerButton.setImage(#imageLiteral(resourceName: "emptyCheckbox"), for: UIControlState.normal)
        datePickerButton.setImage(#imageLiteral(resourceName: "filledCheckbox"), for: UIControlState.selected)
        datePickerButton.isSelected = hasDate!
        
        //updating datePicker
        if (hasDate)! {
            datePicker.setDate(activationDate!, animated: false)
        } else {
            datePicker.isHidden = true
        }
        
        //enabling the saveButton only if the text isn't blank
        if (note?.text.isEmpty)! {
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
    
    // MARK: - Navigation

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // will allow you to configure a view controller before presenting it
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        //will only continue past this point if the save button was pressed, otherwise give an error
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            
            os_log("The save button was note pressed, cancelling", log: OSLog.default, type: .debug)
            return
            
        }
        
        //will only update the note if the user clicked save
        note?.text = nameTextField.text!
        note?.activationDate = activationDate
        note?.hasDate = self.hasDate!
        
    }
 
    //MARK: Private Methods
    
    //will activate whenever the value in datePicker is changed, and will change var. activationDate to match that date
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        activationDate = datePicker.date
    }
    
    //will activate when the datePickerButton is clicked
    @IBAction func datePickerButtonSelected(_ sender: UIButton) {
        
        datePickerButton.isSelected = !datePickerButton.isSelected  //switching the value of the checkbox
        
        if (datePickerButton.isSelected) {
            datePicker.isHidden = false
            hasDate = true
            
            if (activationDate == nil) {
                activationDate = headerNearDate
            }
            
            datePicker.setDate(activationDate!, animated: true)
            
        } else {
            datePicker.isHidden = true
            hasDate = false
            
        }
        
    }
    
}







































