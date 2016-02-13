//
//  MFForm.m
//  MobileForms
//
//  Created by Pedro Jorquera on 12/2/16.
//  Copyright © 2016 Okode. All rights reserved.
//

#import "MFForm.h"

#define FORMHTML_FILENAME                      @"index.mobileforms"
#define FORMHTML_EXTENSION                     @"html"
#define FORMHTML_DIRECTORY                     @"mobileforms"

#define FORMJSON_EXTENSION                     @"json"
#define FORMJSON_DIRECTORY                     @"forms"

#define JSFUNC_SET_JSON_FORM(JSON)             [NSString stringWithFormat:@"setJsonForm(%@);", JSON]
#define JSFUNC_SET_JSON_POPULATE_DATA(JSON)    [NSString stringWithFormat:@"setJsonPopulateData(%@);", JSON]
#define JSFUNC_INIT                            @"init();"

#define JSFUNC_SET_READONLY_FORM               @"setReadOnly(true);"
#define JSFUNC_SET_EDITABLE_FORM               @"setReadOnly(false);"
#define JSFUNC_GET_FORMDATA                    @"getFormData();"
#define JSFUNC_GET_FORMDATA_VALIDATED          @"getFormDataValidated();"
#define JSFUNC_GET_FORMERRORS                  @"getFormErrors();"
#define JSFUNC_IS_FORMVALID                    @"isFormValid();"
#define JSFUNC_SET_POPULATEDATA(P1)            [NSString stringWithFormat:@"populateWithData(%@);", P1]
#define JSFUNC_ADD_CSS(P1, P2)                 [NSString stringWithFormat:@"addCSS(\"%@\", %@);", P1, P2]
#define JSFUNC_ADD_JS(P1)                      [NSString stringWithFormat:@"addJS(\"%@\");", P1]

#define IS_SUBMIT_EVENT(type, value)           [type isEqualToString:@"submit"] && [value isEqualToString:@"valid"]
#define IS_SUBMIT_INVALID_EVENT(type, value)   [type isEqualToString:@"submit"] && [value isEqualToString:@"invalid"]
#define IS_FOCUS_IN_EVENT(type)                [type isEqualToString:@"focus"]
#define IS_FOCUS_OUT_EVENT(type)               [type isEqualToString:@"focusout"]
#define IS_CHANGE_EVENT(type)                  [type isEqualToString:@"change"]
#define IS_VALIDATE_ERROR_EVENT(type)          [type isEqualToString:@"validateerror"]
#define IS_LINK_EVENT(type)                    [type isEqualToString:@"link"]


@interface MFForm ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *jsonForm;
@property (nonatomic, strong) NSString *jsonPopulateData;
@property BOOL loadCalled;
@property BOOL webViewLoaded;
@property (nonatomic, strong) NSMutableArray *pendingJsCommands;

@end


@implementation MFForm

# pragma mark - Constructors

- (id)initControlledBy:(UIViewController*)controller
{
    self = [super init];
    
    if(controller == nil) {
        NSLog(@"MFForm error: controller is not defined");
        return nil;
    }
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [self.webView setBackgroundColor:[UIColor clearColor]];
    self.webView.delegate = self;
    
    // Customization (default)
    self.webView.alpha = 0.0;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    // Add webview to controller
    [controller.view addSubview:self.webView];
    
    self.webViewLoaded = NO;
    self.pendingJsCommands = [[NSMutableArray alloc] init];
    
    return self;
}

# pragma mark

- (void)setFormNamed:(NSString*)name
{
    if(self.loadCalled) {
        NSLog(@"MFForm warning: 'setFormNamed:name' must be called before 'load'");
    }
    
    NSString* bundlePath = [[NSBundle bundleForClass:self.class]
                            pathForResource:@"MobileForms" ofType:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString *jsonFile = [bundle pathForResource:name ofType:FORMJSON_EXTENSION inDirectory:FORMJSON_DIRECTORY];
    if([[NSFileManager defaultManager] fileExistsAtPath:jsonFile]) {
        self.jsonForm = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    } else {
        NSLog(@"MFForm error: Form (json file) named '%@' not exists inside 'forms' folder", name);
    }
}

- (void)setForm:(NSString*)jsonString
{
    if(self.loadCalled) {
        NSLog(@"MFForm warning: 'setForm:jsonString' must be called before 'load'");
    }
    self.jsonForm = jsonString;
}

- (void)setPopulateData:(NSString*)jsonString
{
    if(self.loadCalled) {
        NSLog(@"MFForm warning: 'setPopulateData:jsonString' must be called before 'load'");
    }
    self.jsonPopulateData = jsonString;
}

- (void)setFrame:(CGRect)frame
{
    if(self.loadCalled) {
        NSLog(@"MFForm warning: 'setFrame:frame' must be called before 'load'");
    }
    self.webView.frame = frame;
}

- (void)load
{
    if(self.jsonForm == nil) {
        NSLog(@"MFForm error: JSON form is not defined, please use setFormNamed:name or setForm:jsonString before load");
        return;
    }
    
    // Load HTML in webview
    NSString* bundlePath = [[NSBundle bundleForClass:self.class]
                            pathForResource:@"MobileForms" ofType:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *indexPath = [bundle pathForResource:FORMHTML_FILENAME ofType:FORMHTML_EXTENSION inDirectory:FORMHTML_DIRECTORY];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:indexPath]]];
}


# pragma mark

- (void)setReadOnlyMode:(BOOL)boolean
{
    NSString *jsString = (boolean ? JSFUNC_SET_READONLY_FORM : JSFUNC_SET_EDITABLE_FORM);
    if(self.webViewLoaded) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    } else {
        [self.pendingJsCommands addObject:jsString];
    }
}

- (void)setPopulateDataAsync:(NSString*)jsonString
{
    NSString *jsString = JSFUNC_SET_POPULATEDATA(jsonString);
    if(self.webViewLoaded) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    } else {
        [self.pendingJsCommands addObject:jsString];
    }
}

- (NSString*)getFormValues
{
    // Returns json values from webview (not validated)
    return [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_GET_FORMDATA];
}

- (NSString*)getFormErrors
{
    return [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_GET_FORMERRORS];
}

- (bool)isFormValid
{
    NSString *val = [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_IS_FORMVALID];
    if([val isEqualToString:@"true"]) {
        return true;
    } else {
        return false;
    }
}


- (void)addCSSFile:(NSString*)cssFilePath overrideAllStyles:(bool)override
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:cssFilePath]) {
        NSLog(@"MFForm error: addCSSFile:overrideAllStyles: fails, file not exists : %@", cssFilePath);
    }
    NSString *cssContent = [NSString stringWithContentsOfFile:cssFilePath encoding:NSUTF8StringEncoding error:nil];
    cssContent = [self escapeJavaScriptString:cssContent];
    
    NSString *jsString = JSFUNC_ADD_CSS(cssContent, (override ? @"true" : @"false"));
    if(self.webViewLoaded) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    } else {
        [self.pendingJsCommands addObject:jsString];
    }
}

- (void)addJSFile:(NSString*)jsFilePath
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:jsFilePath]) {
        NSLog(@"MFForm error: addJSFile: fails, file not exists : %@", jsFilePath);
    }
    NSString *jsContent = [NSString stringWithContentsOfFile:jsFilePath encoding:NSUTF8StringEncoding error:nil];
    jsContent = [self escapeJavaScriptString:jsContent];
    
    NSString *jsString = JSFUNC_ADD_JS(jsContent);
    if(self.webViewLoaded) {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    } else {
        [self.pendingJsCommands addObject:jsString];
    }
}



# pragma mark - WebView delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    bool callbackResultImplemented = [self.delegate respondsToSelector:@selector(MFFormResult:)];
    bool callbackEventImplemented = [self.delegate respondsToSelector:@selector(MFFormEvent:element:elementValue:)];
    bool eventUrl = self.delegate &&
    [[[request URL] scheme] isEqualToString:@"mobileforms"] &&
    [[[request URL] host] isEqualToString:@"event"];
    // eventUrl if request starts with mobileforms://event/
    if (eventUrl) {
        // event
        NSMutableDictionary *params = [self getUrlParams:[[[request URL] absoluteString] stringByRemovingPercentEncoding]]; // decoded url
        NSString *element = params[@"element"];
        NSString *value = params[@"value"];
        MFFormEventType eventType = [self getEventType:params[@"type"] value:value];
        
        // submit valid
        if(eventType == Submit && callbackResultImplemented) {
            // valid - returns json data
            NSString *data = [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_GET_FORMDATA_VALIDATED];
            [self.delegate MFFormResult:data];
        }
        // trigger all events
        if(callbackEventImplemented) {
            [self.delegate MFFormEvent:eventType element:element elementValue:value];
        }
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Set form
    [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_SET_JSON_FORM(self.jsonForm)];
    
    // Populate form data with JSON (if there has been provided)
    if(self.jsonPopulateData != nil) {
        [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_SET_JSON_POPULATE_DATA(self.jsonPopulateData)];
    }
    
    // Init JS
    [self.webView stringByEvaluatingJavaScriptFromString:JSFUNC_INIT];
    
    // Show webview animated
    [UIView animateWithDuration:0.25 animations:^(void) {
        self.webView.alpha = 1.0;
    }];
    // Execute pending JS commands
    if(self.pendingJsCommands != nil && [self.pendingJsCommands count] > 0) {
        for(NSString *command in self.pendingJsCommands) {
            [self.webView stringByEvaluatingJavaScriptFromString:command];
        }
        [self.pendingJsCommands removeAllObjects];
    }
    self.webViewLoaded = YES;
}

# pragma mark - Utils

- (NSMutableDictionary*)getUrlParams:(NSString*)url
{
    NSRange range = [url rangeOfString:@"?"];
    url = [[url substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [url componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    return params;
}

- (NSString *)escapeJavaScriptString:(NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    string = [string stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    string = [string stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    return string;
}

- (MFFormEventType)getEventType:(NSString*)type value:(NSString*)value
{
    if(IS_SUBMIT_EVENT(type, value)) {
        return Submit;
    }
    if(IS_SUBMIT_INVALID_EVENT(type, value)) {
        return SubmitInvalid;
    }
    if(IS_FOCUS_IN_EVENT(type)) {
        return FocusIn;
    }
    if(IS_FOCUS_OUT_EVENT(type)) {
        return FocusOut;
    }
    if(IS_CHANGE_EVENT(type)) {
        return Change;
    }
    if(IS_VALIDATE_ERROR_EVENT(type)) {
        return ValidateError;
    }
    if(IS_LINK_EVENT(type)) {
        return Link;
    }
    return Other;
}

@end
