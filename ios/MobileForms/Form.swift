//
// MobileForms
//
// Copyright (C) 2016 Okode (www.okode.com). All rights reserved.
//

import UIKit
import WebKit

let kFormHtmlFilename           = "index.mobileforms"
let kFormHtmlExtension          = "html"
let kFormHtmlDirectory          = "mobileforms"
let kJSFuncSetReadOnlyForm      = "setReadOnly(true);"
let kJSSetEditableForm          = "setReadOnly(false);"
let kJSFuncGetFormData          = "getFormData();"
let kJSFuncGetFormErrors        = "getFormErrors();"
let kJSFuncIsFormValid          = "isFormValid();"
let kJSFuncGetFormDataValidated = "getFormDataValidated();"
let kJSFuncInit                 = "init();"

public enum FormEventType { case Submit, SubmitInvalid, FocusIn, FocusOut, Change, ValidateError, Link, Other }

public protocol FormDelegate {
    func result(data: String)
    func event(eventType: FormEventType, element: String, value: String)
}

public class Form: UIView, WKNavigationDelegate {

    public var delegate: FormDelegate?
    public var layout = ""
    public var data   = ""

    var webView: WKWebView?
    var webViewLoaded = false
    
    var pendingJSCommands = [String]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init(coder : NSCoder) {
        super.init(coder:coder)!
        setup()
    }
    
    func setup() {
        webView = WKWebView(frame: frame)
        webView!.backgroundColor = UIColor.clearColor()
        webView!.alpha = 0.0
        webView!.navigationDelegate = self
        webView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight, .FlexibleTopMargin, .FlexibleBottomMargin]
        addSubview(webView!)
        webViewLoaded = false
    }

    public func load() {
        if(layout == "") {
            print("Form error: JSON form is not defined, please use setFormNamed:name or setForm:jsonString before load")
            return
        }
        
        let classForCoderBundle = NSBundle(forClass: self.classForCoder)
        var bundlePath = classForCoderBundle.pathForResource("MobileForms", ofType: "bundle")
        if (bundlePath == nil) {
            bundlePath = classForCoderBundle.pathForResource("MobileForms", ofType: "bundle", inDirectory: "Frameworks/MobileForms.framework")
        }
        let bundle = NSBundle(path: bundlePath!)
        let indexPath = bundle!.pathForResource(kFormHtmlFilename, ofType: kFormHtmlExtension, inDirectory: kFormHtmlDirectory)
        
        webView!.loadRequest(NSURLRequest(URL: NSURL(fileURLWithPath: indexPath!)))
        
    }
    
    public func setReadOnlyMode(readOnlyMode: Bool) {
        let jsString = (readOnlyMode ? kJSFuncSetReadOnlyForm : kJSSetEditableForm)
        if(webViewLoaded) {
            webView!.evaluateJavaScript(jsString, completionHandler: nil)
        } else {
            pendingJSCommands.append(jsString)
        }
    }
    
    func jsFuncSetPopulateData(data: String) -> String {
        return "populateWithData(\(data));"
    }
    
    func jsFuncAddCSS(name: String, data: String) -> String {
        return "addCSS(\"\(name)\", \(data));"
    }
    
    func jsFuncAddJS(javaScript: String) -> String {
        return "addJS(\"\(javaScript)\");"
    }
    
    func jsFuncSetJsonForm(json: String) -> String {
        return "setJsonForm(\(json));"
    }
    
    func jsFuncSetJsonPopulateData(json: String) -> String {
        return "setJsonPopulateData(\(json));"
    }
    
    public func setPopulateDataAsync(json: String) {
        let jsString = jsFuncSetPopulateData(json)
        if(webViewLoaded) {
            webView!.evaluateJavaScript(jsString, completionHandler: nil)
        } else {
            pendingJSCommands.append(jsString)
        }
    }
    
    public func requestFormValue(completionHandler: ((String?) -> Void)?) {
        webView!.evaluateJavaScript(kJSFuncGetFormData) { (formValue: AnyObject?, _: NSError?) -> Void in
            completionHandler?(formValue as? String)
        }
    }
    
    public func requestFormErrors(completionHandler: ((String?) -> Void)?) {
        webView!.evaluateJavaScript(kJSFuncGetFormErrors) { (formValue: AnyObject?, _: NSError?) -> Void in
            completionHandler?(formValue as? String)
        }
    }
    
    public func requestFormValid(completionHandler: ((Bool?) -> Void)?) {
        webView!.evaluateJavaScript(kJSFuncGetFormErrors) { (formValue: AnyObject?, _: NSError?) -> Void in
            completionHandler?((formValue as? String) == "true")
        }
    }
    
    public func addCSSFile(cssFilePath: String, overrideAllStyles: Bool) {
        if (!NSFileManager.defaultManager().fileExistsAtPath(cssFilePath)) {
            print("Form error: addCSSFile:overrideAllStyles: fails, file not exists : \(cssFilePath)")
        }
        let cssContent: String?
        do {
            cssContent = try String(contentsOfFile: cssFilePath, encoding: NSUTF8StringEncoding)
        } catch _ {
            cssContent = nil
        }
        let jsString = jsFuncAddCSS(cssContent!, data: overrideAllStyles ? "true" : "false")
        if (webViewLoaded) {
            webView!.evaluateJavaScript(jsString, completionHandler: nil)
        } else {
            pendingJSCommands.append(jsString)
        }
    }
    
    func escapeJavaScriptString(javaScript: String) -> String {
        var result = javaScript.stringByReplacingOccurrencesOfString("\"", withString: "\\\\")
        result = result.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        result = result.stringByReplacingOccurrencesOfString("\'", withString: "\\\'")
        result = result.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
        result = result.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
        return result;
    }
    
    public func addJSFile(jsFilePath: String) {
        if (!NSFileManager.defaultManager().fileExistsAtPath(jsFilePath)) {
            print("Form error: addJSFile: fails, file not exists : \(jsFilePath)")
        }
        var jsContent: String?
        do {
            jsContent = try String(contentsOfFile: jsFilePath, encoding: NSUTF8StringEncoding)
        } catch _ {
            jsContent = nil
        }
        jsContent = escapeJavaScriptString(jsContent!)
        let jsString = jsFuncAddJS(jsContent!)
        if (webViewLoaded) {
            webView!.evaluateJavaScript(jsString, completionHandler: nil)
        } else {
            pendingJSCommands.append(jsString)
        }
    }
    
    func getUrlParams(url: String) -> [String: String] {
        let range = url.rangeOfString("?")
        let urlParams = url.substringFromIndex((range?.startIndex.advancedBy(1))!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var params = [String: String]()
        for param in urlParams.componentsSeparatedByString("&") {
            let elts = param.componentsSeparatedByString("=")
            if (elts.count < 2) { continue }
            params[elts[0]] = elts[1]
        }
        return params
    }
    
    func isSubmitEvent(type: String, value: String) -> Bool {
        return (type == "submit" && value == "valid")
    }
    
    func isSubmitInvalidEvent(type: String, value: String) -> Bool {
        return (type == "submit" && value == "invalid")
    }
    
    func isFocusInEvent(type: String) -> Bool {
        return type == "focus"
    }

    func isFocusOutEvent(type: String) -> Bool {
        return type == "focusout"
    }

    func isChangeEvent(type: String) -> Bool {
        return type == "change"
    }
    
    func isValidateErrorEvent(type: String) -> Bool {
        return type == "validateerror"
    }

    func isLinkEvent(type: String) -> Bool {
        return type == "link"
    }
    
    func getEventType(type: String, value: String) -> FormEventType {
        if (isSubmitEvent(type, value: value)) {
            return FormEventType.Submit
        }

        if (isSubmitInvalidEvent(type, value: value)) {
            return FormEventType.SubmitInvalid
        }
        
        if (isFocusInEvent(type)) {
            return FormEventType.FocusIn
        }

        if (isFocusOutEvent(type)) {
            return FormEventType.FocusOut
        }

        if (isChangeEvent(type)) {
            return FormEventType.Change
        }

        if (isValidateErrorEvent(type)) {
            return FormEventType.ValidateError
        }
        
        if (isLinkEvent(type)) {
            return FormEventType.Link
        }

        return FormEventType.Other
    }
    
    public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        let request = navigationAction.request
        let eventUrl = (request.URL?.scheme == "mobileforms" && request.URL?.host == "event")
        if (eventUrl) {
            
            let params = getUrlParams((request.URL?.absoluteString.stringByRemovingPercentEncoding)!)
            let element = params["element"]
            let value = params["value"]
            let eventType = getEventType(params["type"]!, value: value!)
            
            if (eventType == FormEventType.Submit) {
                webView.evaluateJavaScript(kJSFuncGetFormDataValidated, completionHandler: {(result:AnyObject?, error: NSError?) -> Void in
                    let data = result as? String
                    self.delegate?.result(data!)
                })
            }

            delegate?.event(eventType, element: element!, value: value!)
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
        
        decisionHandler(WKNavigationActionPolicy.Allow)
        
    }

    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        webView.evaluateJavaScript(jsFuncSetJsonForm(layout)) { (_: AnyObject?, _: NSError?) -> Void in
            if (self.data != "") {
                webView.evaluateJavaScript(self.jsFuncSetJsonPopulateData(self.data), completionHandler: nil)
            }
            webView.evaluateJavaScript(kJSFuncInit, completionHandler: { (_: AnyObject?, _: NSError?) -> Void in
                UIView.animateWithDuration(0.25) { () -> Void in
                    webView.alpha = 1.0
                }
                
                // Execute pending JS commands
                if (self.pendingJSCommands.count > 0) {
                    for command in self.pendingJSCommands {
                        webView.evaluateJavaScript(command, completionHandler: nil)
                    }
                    self.pendingJSCommands.removeAll()
                }
                self.webViewLoaded = true
            })
        }
    }
    
}