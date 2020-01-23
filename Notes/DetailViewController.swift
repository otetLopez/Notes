//
//  DetailViewController.swift
//  Notes
//
//  Created by otet_tud on 1/16/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var navigationbar: UINavigationItem!
    @IBOutlet weak var datefld: UITextField!
    @IBOutlet weak var mapfld: UITextField!
    
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            navigationbar.title = detail.getTitle()
            datefld.text = detail.getDate()
            mapfld.text = detail.getAddress()
            
            if let label = detailDescriptionLabel {
                label.text = detail.getTitle()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        datefld.isUserInteractionEnabled = false
        //mapfld.isUserInteractionEnabled = false
        configureView()
    }

    var detailItem: Note? {
        didSet {
            // Update the view.
            
            configureView()
        }
    }
    
    @IBAction func mapviewfldpressed(_ sender: Any) {
        mapfld.endEditing(true)
        self.performSegue(withIdentifier: "viewmap", sender: self)
    }
    
}

