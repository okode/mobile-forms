//
// MobileForms - Demo
//
// Copyright (C) 2016 Okode (www.okode.com). All rights reserved.
//

import UIKit
import MobileForms

class ViewController: Form, FormDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        let filepath = NSBundle.mainBundle().pathForResource("form", ofType: "json", inDirectory: "json")
        do {
            let contents = try NSString(contentsOfFile: filepath!, usedEncoding: nil) as String
            setForm(contents)
            loadForm()
        } catch { }
    }

    func result(data: String) {
        print("Result: \(data)")
    }
    
    func event(eventType: FormEventType, element: String, value: String) {
        print("Event: \(eventType), Element: \(element), Value: \(value)")
    }

    
}

