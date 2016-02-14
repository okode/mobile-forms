//
// MobileForms - Demo
//
// Copyright (C) 2016 Okode (www.okode.com). All rights reserved.
//

import UIKit
import MobileForms

class ViewController: UIViewController, FormDelegate {
    
    var form: Form!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form = Form(controller: self)
        form.delegate = self
        
        let filepath = NSBundle.mainBundle().pathForResource("form", ofType: "json", inDirectory: "json")
        do {
            let contents = try NSString(contentsOfFile: filepath!, usedEncoding: nil) as String
            form.setForm(contents)
            form.load()
        } catch { }
    }

    func result(data: String) {
        print("Result: \(data)")
    }
    
    func event(eventType: FormEventType, element: String, value: String) {
        print("Event: \(eventType), Element: \(element), Value: \(value)")
    }

    
}

