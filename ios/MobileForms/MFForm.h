//
//  MFForm.h
//  MobileForms
//
//  Created by Pedro Jorquera on 12/2/16.
//  Copyright © 2016 Okode. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum { Submit, SubmitInvalid, FocusIn, FocusOut, Change, ValidateError, Link, Other } MFFormEventType;

#pragma mark - Delegate

/** The *MFFormDelegate* protocol defines methods that a delegate of a *MFForm* object can optionally implement to intervene when form content is loaded.
 */
@protocol MFFormDelegate <NSObject>

@optional

/** Tells the delegate when the user submit valid form
 @param data Form data as json string serialized
 */
- (void)MFFormResult:(NSString*)data;
/** Tells the delegate when event occurs on form
 @param eventType The type of user event
 @param element The form element name/id
 @param value The current element value
 */
- (void)MFFormEvent:(MFFormEventType)eventType element:(NSString*)element elementValue:(NSString*)value;

@end

#pragma mark - Interface

/** You use the *MFForm* class to embed webform in your application. *MFForm* allows create forms dynamically, through a form definition in JSON
 
 MFForm usage example with Objective-C:
 
        self.form = [[MFForm alloc] initControlledBy:self];
        self.form.delegate = self;
        [self.form setFormNamed:@"myFormFile"];
        [self.form load];
 
 MFForm usage example with Swift:
 
        self.form = MFForm(controlledBy: self);
        self.form.delegate = self
        self.form.setFormNamed("myFormFile")
        self.form.load()

 */
@interface MFForm : UIViewController <UIWebViewDelegate>

/** The receiver’s delegate
 */
@property (nonatomic, weak) id<MFFormDelegate> delegate;

#pragma mark - Constructor

/** Initializes and returns a newly object, adding form view to controller
 @param controller The view controller that includes form as view (Required)
 @return An initialized view object or8 nil if the object couldn't be created
 @see load
 */
- (id)initControlledBy:(UIViewController*)controller;

#pragma mark

/** Sets form model loading json by name (file must be inside referenced folder named 'forms')
 @param name The json form model filename (without .json extension)
 @see setForm:
 */
- (void)setFormNamed:(NSString*)name;

/** Sets form model passing json string serialized
 @param jsonString Json form model string serialized
 @see setFormNamed:
 */
- (void)setForm:(NSString*)jsonString;

/** Sets form data passing json string serialized (before load method be called)
 @param jsonString Json data string serialized
 @see setPopulateDataAsync:
 */
- (void)setPopulateData:(NSString*)jsonString;

/** Sets specified frame rectangle for the form view. The origin of the frame is relative to the parent controller view. By default, form frame is the same that parent controller
 @param frame The frame rectangle for the form view
 */
- (void)setFrame:(CGRect)frame;

/** Loads form. Must be called first initControlledBy:, and setFormNamed: or setForm:
 @see initControlledBy:
 @see setFormNamed:
 @see setForm:
 */
- (void)load;

#pragma mark

/** Sets if forms is readOnly or editable. Between modes can switch to anytime
 @param boolean true sets form as read only, false sets form as editable
 */
- (void)setReadOnlyMode:(BOOL)boolean;

/** Sets form data passing json string serialized (once the form is loaded), overwriting current values
 @param jsonString Json data string serialized
 @see setPopulateData:
 */
- (void)setPopulateDataAsync:(NSString*)jsonString;

/** Returns current form values (without validation)
 @return Json data string serialized
 */
- (NSString*)getFormValues;

/** Returns json with current errors. Json errors contains 'requireErrors' (array or null) with empty required element names, and 'validationErrors' (array or null) with elements with errors and their respective error messages
 @return Json string serialized
 */
- (NSString*)getFormErrors;

/** Returns true or false if form is currently valid
 @return boolean
 */
- (bool)isFormValid;

/** Adds custom css to form webview
 @param cssFilePath CSS file path (using pathForResource)
 @param override true ignore previous form css properties, false preserves the previous values and adds new css
 */
- (void)addCSSFile:(NSString*)cssFilePath overrideAllStyles:(bool)override;

/** Adds custom js to form webview
 @param jsFilePath JS file path (using pathForResource)
 */
- (void)addJSFile:(NSString*)jsFilePath;

@end
