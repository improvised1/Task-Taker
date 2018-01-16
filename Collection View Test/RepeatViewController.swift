//
//  RepeatViewController.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 1/9/18.
//  Copyright © 2018 Damon Cestaro. All rights reserved.
//

import UIKit

class RepeatViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    //MARK: Properties

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var frequencyPicker: UIPickerView!
    @IBOutlet weak var everyLabel: UILabel!
    @IBOutlet weak var everyPicker: UIPickerView!
    //all of the buttons
    @IBOutlet weak var buttonsLabel: UILabel!
    @IBOutlet weak var monButton: UIButton!
    @IBOutlet weak var tueButton: UIButton!
    @IBOutlet weak var wedButton: UIButton!
    @IBOutlet weak var thurButton: UIButton!
    @IBOutlet weak var friButton: UIButton!
    @IBOutlet weak var satButton: UIButton!
    @IBOutlet weak var sunButton: UIButton!
    
    let frequencyValues = ["Daily", "Weekly", "Monthly", "Yearly"]
    var selectedFrequency: String?
    var selectedEvery: Int?
    var noteActivationDate: Date?   //set by the NoteViewController before segue
    
    // MARK: UIPickerView Functions
    
    /*
     defines the number of columns the picker views will have
    */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /*
     Defines what each row in the picker views will hold
    */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if (pickerView.tag == 0) {
            return frequencyValues[row]
            
        } else if (pickerView.tag == 1) {
            if (row <= 999) {
                return String(row+1)    //row +1 since we want 1...999, not 0...998
            }
            
        } else {
            fatalError("No UIPickerView with this tag")
        }
        
        return "SomethingWentWrong"    //shut the errors up please
        
    }
    
    /*
     Defines the number of components in each picker view
    */
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if (pickerView.tag == 0) {
            return frequencyValues.count
        } else if (pickerView.tag == 1) {
            return 999
        } else {
            fatalError("No UIPickerView with this tag")
        }
        
        return 0    //shut the errors up please
        
    }
    
    /*
     Will run whenever a new value is selected in one of the picker views
    */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if (pickerView.tag == 0) {
            
            selectedFrequency = frequencyValues[row]
            
            if (selectedFrequency == "Weekly") {
                setButtonsHidden(setTo: false)
            } else {
                setButtonsHidden(setTo: true)
            }
            
        } else if (pickerView.tag == 1) {
            selectedEvery = row+1
            everyLabel.text = "Every \(String(row+1)) \(correctAdjective(frequencyTerm: selectedFrequency!))"
        }
        
    }
    
    // MARK: Private Functions
    
    /*
     This is a helper method to pickerView(didSelectRow)
     this method will take selectedFrequency in and modify the string to better fit what we need.  For example, Daily -> Days.  This is for when we're set to monthly, we'll say "you will do this note 5 times a month", but need to be able to infer "months" from nothing but "monthly"
    */
    func correctAdjective(frequencyTerm: String) -> String {
        
        switch frequencyTerm {
        case "Daily": return "days"
        case "Weekly": return "weeks"
        case "monthly": return "months"
        case "yearly": return "years"
        default: return "days"
        }
        
        
    }
    
    /*
     This method will set all of the weekday-setting buttons to be hidden or not hidden, depending on what boolean value is passed
    */
    func setButtonsHidden(setTo: Bool) {
        
        buttonsLabel.isHidden = setTo
        monButton.isHidden = setTo
        tueButton.isHidden = setTo
        wedButton.isHidden = setTo
        thurButton.isHidden = setTo
        friButton.isHidden = setTo
        satButton.isHidden = setTo
        sunButton.isHidden = setTo
    }
    
    // MARK: Generic Setup Functions
    
    override func viewDidLoad() {
        
        print("beggining viewDidLoad() of RepeatViewController")
        
        super.viewDidLoad()

        //setting default values
        if (selectedFrequency == nil) {
            selectedFrequency = "Daily"
        }
        if (selectedEvery == nil) {
            selectedEvery = 1
        }
        
        //selecting the correct row in both picker views
        frequencyPicker.selectRow(frequencyValues.index(of: selectedFrequency!)!, inComponent: 0, animated: false)
        everyPicker.selectRow(selectedEvery!-1, inComponent: 0, animated: false)
        
        //deciding wether or not to hid buttons
        if (selectedFrequency != "Weekly") {
            setButtonsHidden(setTo: true)
        }
        
        //setting both pickers to have different tags so i can tell them apart
        frequencyPicker.tag = 0
        everyPicker.tag = 1
        
        //setting background image
        self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
        
        //setting the button chosen on the NoteViewController we segued from, to selected
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let myComponents = myCalendar?.components(.weekday, from: noteActivationDate!)
        let currentWeekDay = myComponents?.weekday     //weekDay is an integer 1 -> 7, where 1 is sunday and 7 saturday
        
        switch currentWeekDay {
        case 1?: sunButton.isSelected = true
        case 2?: monButton.isSelected = true
        case 3?: tueButton.isSelected = true
        case 4?: wedButton.isSelected = true
        case 5?: thurButton.isSelected = true
        case 6?: friButton.isSelected = true
        case 7?: satButton.isSelected = true
        default: break
        }
        
        print("ended viewDidLoad() of RepeatViewController")
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    /*
     This method is attached to the cancel UIBarButton in the repeat view controller
     This method will dismiss this view and return to the previous one
     */
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /*
     This method will run whenever we segue back to the originial screen.  In practice, this means that it will run whenever the save button is clicked.  This method runs automatically.
     This method will create and pass the information necessary to create a repeatingNote back to the originial view.  As of now, the only information we have that is necessary to initialize a RepeatingNote is the components, so we'll create and pass that back.  If the user selected multiple weekday buttons we'll handle that by creating a unique but related RepeatingNote from each weekday, so we'll also pass back info on what weekdays where selected
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        //creating the RepeatingNote classes, which will pass to earlier method, which will pass them to the main view
        let destinationViewController = segue.destination as! NoteViewController
        
        var components = DateComponents()
        
        switch selectedFrequency {
        case "Daily"?: components.day = selectedEvery
        case "Weekly"?: components.day = selectedEvery!*7
        case "Monthly"?: components.month = selectedEvery
        case "Yearly"?: components.year = selectedEvery
        default: break  //should never run, if does do nothing
        }
        destinationViewController.components = components
        
        if (selectedFrequency == "Weekly") {
            let selectedButtons: [Bool] = [sunButton.isSelected, monButton.isSelected, tueButton.isSelected, wedButton.isSelected, thurButton.isSelected, friButton.isSelected, satButton.isSelected]
            destinationViewController.selectedButtons = selectedButtons
        }
        
    }

}
