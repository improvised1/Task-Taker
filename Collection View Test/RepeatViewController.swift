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
    
    @IBOutlet weak var frequencyPicker: UIPickerView!
    @IBOutlet weak var everyLabel: UILabel!
    @IBOutlet weak var everyPicker: UIPickerView!
    
    let frequencyValues = ["Daily", "Weekly", "Monthly", "Yearly"]
    var selectedFrequency: String?
    var selectedEvery: Int?
    
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
        } else if (pickerView.tag == 1) {
            selectedEvery = row
            everyLabel.text = "Every \(String(row+1)) \(correctAdjective(frequencyTerm: selectedFrequency!))"
        }
        
    }
    
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
    
    // MARK: Generic Setup Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: FIX LATER
        //setting temp default values
        selectedFrequency = "Daily"
        selectedEvery = 1
        
        //setting both pickers to have different tags so i can tell them apart
        frequencyPicker.tag = 0
        everyPicker.tag = 1
        
        //setting background image
        self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
