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
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(NoteCollectionReusableView.headerSelected(recognizer:)))
        recognizer.delegate = self
        self.addGestureRecognizer(recognizer)
        
    }
    
    //MARK: Action Methods
    
    /*
     headerSelected() method
     Whenever the header is tapped this method will fire.  It will toggle whether or not to display the notes that this header holds
    */
    @objc func headerSelected(recognizer: UITapGestureRecognizer) {
        
        headerDataClass?.notesAreHidden = !(headerDataClass?.notesAreHidden)!
        parentView?.collectionView?.reloadData()    //setImage() will be called when reloading, don't do it before then because then might have closed header but notes below
    
    }
    
    //MARK: Private Methods
    
    /*
     setImage() method
     This method will set the headerCell images to be open, and integrate into the images in the below noteCells, or to be closed as there are no notecells below it.  The notesAreHidden boolean in headerDataClass will be used to determine which set of images to use
     */
    func setImage() {
        
        if (headerDataClass?.notesAreHidden)! {
            leftImage.image = #imageLiteral(resourceName: "header_left_closed")
            centerImage.image = #imageLiteral(resourceName: "header_mid_closed")
            rightImage.image = #imageLiteral(resourceName: "header_right_closed")
        } else {
            leftImage.image = #imageLiteral(resourceName: "header_left")
            centerImage.image = #imageLiteral(resourceName: "header_mid")
            rightImage.image = #imageLiteral(resourceName: "header_right")
        }
        
    }
    
}
