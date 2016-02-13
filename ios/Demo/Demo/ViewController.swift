//
//  ViewController.swift
//  Demo
//
//  Created by Pedro Jorquera on 13/2/16.
//  Copyright © 2016 Okode. All rights reserved.
//

import UIKit
import MobileForms

class ViewController: UIViewController, MFFormDelegate {

    var form: MFForm!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form = MFForm(controlledBy: self)
        form.delegate = self
        
        let filepath = NSBundle.mainBundle().pathForResource("form", ofType: "json", inDirectory: "json")
        do {
            let contents = try NSString(contentsOfFile: filepath!, usedEncoding: nil) as String
            form.setForm(contents)
            form.load()
        } catch { }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

