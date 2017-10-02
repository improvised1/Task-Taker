//
//  NoteCollectionReusableView.swift
//  Collection View Test
//
//  Created by Damon Cestaro on 6/7/17.
//  Copyright © 2017 Damon Cestaro. All rights reserved.
//

import UIKit
import os.log

class NoteCollectionReusableView: UICollectionReusableView, UIGestureRecognizerDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var leftImage: UIImageView!
    @IBOutlet weak var centerImage: UIImageView!
    @IBOutlet weak var rightImage: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    var headerDataClass: Header?     //will hold the Header data class that his header displays
    var parentView: NoteCollectionViewController?   //solely exists so i can reload the main view when the notes are hidden
    
    //MARK: Color Buttons
    
    
    override func awakeFromNib() {
        os_log("method (awakeFromNib) in reusableView started running", log: OSLog.default, type: .debug)
        
        super.awakeFromNib()
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(NoteCollectionReusableView.headerSelected(recognizer:)))
        recognizer.delegate = self
        self.addGestureRecognizer(recognizer)
        
        os_log("method (awakeFromNib stopped running", log: OSLog.default, type: .debug)
    }
    
    func headerSelected(recognizer: UITapGestureRecognizer) {
        os_log("method (headerSelected) in reusableViewstarted running", log: OSLog.default, type: .debug)
        
        headerDataClass?.notesAreHidden = !(headerDataClass?.notesAreHidden)!
        parentView?.collectionView?.reloadData()
        
        os_log("method (headerSelected) stopped running", log: OSLog.default, type: .debug)
    
    }
    
}
