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
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    var note: Note?     //will only be updated if the user clicks save
    var activationDate: Date?
    var headerNearDate: Date?   //will hold the headers activation date, which will be the default activation date
    var hasDate: Bool?
    var hasRepeat: Bool?
    var noteCell: NoteCollectionViewCell?
    
    //RepeatingNotes Properties, values will be set inside of the RepeatViewController
    var components = DateComponents()
    var selectedButtons: [Bool]?
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //setting background image
        self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
        
        //setting this class as the textfields delegate
        nameTextField.delegate = self
        
        //updating text in the view controller
        activationDate = note?.activationDate
        navigationItem.title = note?.text ?? "New Reminder"  //displays the text in this note as the view controllers title, else defaulting to "New Reminder"
        nameTextField.text = note?.text
        hasDate = (note?.hasDate)!
        
        //setting variables
        hasRepeat = note?.hasRepeat
        
        //setting button images
        datePickerButton.setImage(#imageLiteral(resourceName: "emptyCheckbox"), for: UIControlState.normal)
        datePickerButton.setImage(#imageLiteral(resourceName: "filledCheckbox"), for: UIControlState.selected)
        datePickerButton.isSelected = hasDate!
        
        repeatButton.setImage(#imageLiteral(resourceName: "emptyCheckbox"), for: UIControlState.normal)
        repeatButton.setImage(#imageLiteral(resourceName: "filledCheckbox"), for: UIControlState.selected)
        repeatButton.isSelected = hasRepeat!
        
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
        
        //setting default components value if components is otherwise empty
        if (components.day == nil && components.month == nil && components.year == nil) {
            components.day = 1
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
        
        switch(segue.identifier ?? "") {
            case "setRepeat":   //set up a RepeatViewController
            
                let destinationNavigationController = segue.destination as! UINavigationController
                let destinationViewController = destinationNavigationController.topViewController as! RepeatViewController
            
                destinationViewController.noteActivationDate = datePicker.date
                
                if (components.day != 0 && (components.day)! % 7 == 0) {     //if selectedFrequency should be Weekly then components.day is perfectly divisible by 7
                    destinationViewController.selectedFrequency = "Weekly"
                    destinationViewController.selectedEvery = (components.day)! % 7
                } else if (components.day != 0) {
                    destinationViewController.selectedFrequency = "Daily"
                    destinationViewController.selectedEvery = components.day
                } else if (components.month != 0) {
                    destinationViewController.selectedFrequency = "Monthly"
                    destinationViewController.selectedEvery = components.month
                } else if (components.year != 0) {
                    destinationViewController.selectedFrequency = "Yearly"
                    destinationViewController.selectedEvery = components.year
                }
                
            default:    //returning to CollectionView
                
                //will only continue past this point if the save button was pressed, otherwise give an error
                guard let button = sender as? UIBarButtonItem, button === saveButton else {
                    return
                }
                
                //will only update the note if the user clicked save
                note?.text = nameTextField.text!
                note?.activationDate = activationDate
                note?.hasDate = self.hasDate!
                note?.hasRepeat = self.hasRepeat!
            
        }
        
    }
 
    //this method allows us to rewind to this viewController form a later one
    @IBAction func unwindToNoteViewController(sender: UIStoryboardSegue) {
    
    }
    
    //MARK: Private Methods
    
    //will activate whenever the value in datePicker is changed, and will change var. activationDate to match that date
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        activationDate = datePicker.date
    }
    
    //will activate when repeatButton is clicked
    @IBAction func repeatButtonSelected(_ sender: Any) {
        
        repeatButton.isSelected = !repeatButton.isSelected
        hasRepeat = repeatButton.isSelected
        
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







































