//
//  NoteCollectionViewCell.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 7/21/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit

class NoteCollectionViewCell: UICollectionViewCell {
    
    //MARK: Properties
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var checkbox: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var leftImage: UIImageView!
    @IBOutlet weak var centerImage: UIImageView!
    @IBOutlet weak var rightImage: UIImageView!
    var note: Note?     //will hold the note that this cell holds
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    //MARK: Private Methods
    
    /*
     setImage() method
     This method will set the notes cell image to be open on the bottom if another note is below it and closed on the bottom if its the last note.  The last notecell will have an empty textField and no other ones will, so that will be used to identify the last notecell.
    */
    func setImage() {
        
        if (textField.text == "") {
            leftImage.image = #imageLiteral(resourceName: "note_left_open")
            centerImage.image = #imageLiteral(resourceName: "note_mid_open")
            rightImage.image = #imageLiteral(resourceName: "note_right_open")
        } else {
            leftImage.image = #imageLiteral(resourceName: "note_left")
            centerImage.image = #imageLiteral(resourceName: "note_mid")
            rightImage.image = #imageLiteral(resourceName: "note_right")
        }
        
    }
    
}
