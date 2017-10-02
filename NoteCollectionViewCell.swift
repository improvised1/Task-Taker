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
    var note: Note?     //will hold the note that this cell holds
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
}
