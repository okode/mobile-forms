MobileForms
===========

Introduction
------------

MobileForms allows create forms dynamically, through a form definition in JSON, a form with amply definable fields, with all its attributes and validation rules, receiving callbacks for events in their fields (focus, change, ...), and submitted form (getting a JSON response with the model defined in the form).

MobileForms provides a native wrapper to generate form via a unique definition in JSON for iOS, Android and Windows Phone plataforms, having a native appearance each. The style/appearance on each platform can be defined with stylesheets (CSS) own, allowing you to change the appearance of certain elements (or form completly) in a specific platform or unifying all platforms with the same style.

JSON Form
---------

**Input json** (form definition)
```json
[
  [
    {
      "header":"Contact"
    },
    {
      "label":"Name",
      "type":"text",
      "name":"name"
    },
    {
      "label":"Lastname",
      "type":"text",
      "name":"lastname"
    },
    {
      "label":"Gender",
      "type":"select",
      "name":"gender",
      "filter":"Male|Female"
    },
    {
      "label":"Email",
      "type":"email",
      "name":"email",
      "filter":"^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$",
      "error":"Invalid email address",
      "description":"This field will be validated"
    }
  ],
  [
    {
      "submit":"Save contact"
    }
  ]
]
```

**Preview** (iOS / Android / WP)
TODO: Include picture here

**Output JSON** on submit /  **JSON to populate form**

```json
{
  "name" : "John",
  "lastname" : "Mock",
  "email" : "johnmock@gmail.com",
  "gender" : "male"
}
```

Fields
------

| Fields        | iOS | Android | WP    |
|---------------|:---:|:-------:|:-----:|
| `text`        | Yes | Yes     | Yes   |
| `password`    | Yes | Yes     | Yes   |
| `number`      | Yes | Yes     | Yes   |
| `date`        | Yes | Yes*    | Yes** |
| `time`        | Yes | Yes*    | Yes** |
| `tel`         | Yes | Yes     | Yes   |
| `email`       | Yes | Yes     | Yes   |
| `hidden`      | Yes | Yes     | Yes   |
| `textarea`    | Yes | Yes     | Yes   | 
| `range`       | Yes | Yes***  | Yes   |
| `select`      | Yes | Yes     | Yes   |
| `radio`       | Yes | Yes     | Yes   |
| `checkbox`    | Yes | Yes     | Yes   |

> \* Native picker with Android >= `4.4`, in previous, replaced by combos (`DD-MM-YYYY` / `HH:MM`)
> \*\* Native picket unsupported in WP, replaced by combos (`DD-MM-YYYY` / `HH:MM`)
> \*\*\* Android >= `4.4` full support. Previous versions, replaced by `number` field

Fields (advanced/custom)
------------------------

| Fields        | Description | Usage example |
|---------------|-------------|---------------|
| `phoneitem`   | Allows type - phone collection (key value pair). Returns <br>`"name":[{`<br>`"type":"Mobile",`<br>`"phone":"600500400"`<br>`}, ... ]` |  `{`<br>`"type":"phoneitem",`<br>`"name":"phoneItemList[]",`<br>`"nametype":"type",`<br>`"namephone":"phone",`<br>`"phonetypes":"Mobile|Home|Work|Other"`<br>`}` |
| `link`        | Allows a link with a javascript call and / or event to capture on mobile controller |       `{`<br>`"type":"link",`<br>`"name":"linkExample",`<br>`"value":"Open new window",`<br>`"onclick":"jsFunction();",`<br>`"event":"customEvent"`<br>`}`|

Attributes
----------

| Attributes    | Inputs      | ValidValues| Description        |
|---------------|-------------|------------|------------------------------------------------------|
| **`name`**    | * (req.)    | String     | Field name (model id)                                |
| **`type`**    | * (req.)    | String     | Some of the valid fields                             |
| `label`       | *           | String     | Label text outside the field/input                   |
| `placeholder` | *           | String     | Label text inside the field/input (with empty value) |
| `value`       | *           | String     | Initial value                                        |
| `filter`      | *           | String     | List of values in `select`and `radio`, and regex to validate input value in other fields. Example: `"^\\d{9,15}$"` (else error message)                 |
| `required`    | *           | 0 - 1      | As long as any required field without value, the submit button will disabled        |
| `error`       | *           | String     | Error message. It will be displayed under field fails to fulfill one of the validation conditions (`filter`, `max` or `min`) |
| `description` | *           | String     | You can display a description under the field, and may introduce some basic HTML tag|
| `textalign`   | *           | `left`<br>`right`<br>`center`   | Allows align text input (not `label`, `desc`, `error`) |
| `maxlength`   | text<br>password<br>number<br>tel<br>email<br>textarea  | Number   | Input length limitation   |
| `max`         | number<br>range<br>date<br>time    | Number   | Max value to be valid (else error message)     |
| `min`         | number<br>range<br>date<br>time    | Number   | Min value to be valid (else error message)     |
| `step`        | range       | Number     | Specifies the value granularity of the range’s value               |
| `checked`     | checkbox    | `true`<br>`false`  | Set initial checkbox checked or not |
| `dateformat`  | date        | `dd-mm-yyyy`<br>`mm-dd-yyyy`<br>`yyyy-mm-dd` | If device shows native date picker, device locale prevails. Default yyyy-mm-dd. **Return value always yyyy-mm-dd**  (HTML5 date input - RFC3339 full-date format) |
| `widthpercent`| *           | 0% - 100%    |(Extra) Using a percentage, the input will not occupy the entire width , you can align elements on the same line. Important: Specifying this option, the description and the error message are ignored |

Advanced usage
--------------

TODO: pending implementation

 - model structure (using name[])
 - inline inputs (compress form)
 - string format

JavaScript implementation
-------------------------

**Usage**

```html
    <script src="mmobileforms.libraries.js"></script>
    <script src="mmobileforms.utils.js"></script>
    <script src="mmobileforms.populator.js"></script>
    <script src="mmobileforms.builder.js"></script>
    <script src="mmobileforms.js"></script>
    <script>
        var params = {
            jsonForm : form1,
            ...
        };
        var mmobileform = new MMobileForms(params);
    </script>
```
**Params**

| Param              | Required | Default  |    |
|--------------------|:--------:|:---------|:---|
| `jsonForm`         | Yes      | `null`   | JSON. Form definition |
| `jsonPopulateData` | No       | `null`   | JSON. Form data to populate form |
| `readOnly`         | No       | `false`  | Boolean. `true` sets read-only form (`jsonPopulateData` required) |
| `formId`           | No       | `'form'` | String. To identify form tag by id |
| `formContainer`    | No       | `'body'` | Selector (jQuery). Form will be generated inside this html element |
| `successCallback`  | No       | `null`   | Function. callback(data).<br>`data` = json data (string) |
| `eventCallback`    | No       | `null`   | Function. callback(event, element, value).<br>`event` = event type (focus, change, submit, ...)<br>`element` = field name/id<br>`value` = current field value |

**Functions**

| Function                     |          |
|------------------------------|:---------|
| `getFormDataValidated()`     | Returns form JSON serialized (and validated), if form tried to be submitted |
| `getFormData()`              | Returns actual form JSON serialized (without validation) |
| `setReadOnly(bool)`          | Changes to read-only/editabled mode (`jsonPopulateData` required in read-only) |
| `populateWithData(JSON)`     | Sets async `jsonPopulateData` values and populate overwriting current form |


iOS implementation
------------------

```objective-c
#import "ViewController.h"
#import "MMobileForms.h"

@interface ViewController () <MMobileFormsDelegate>

@property (nonatomic, strong) MMobileForms *form;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // load jsonForm
    NSString *jsonFile = [[NSBundle mainBundle] pathForResource:@"myJsonForm" ofType:@"json"];
    NSString* jsonFormString = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];

    // init MMobileForm
    self.form = [[MMobileForms alloc] initForm:jsonFormString controller:self];
    self.form.delegate = self;
}

##### pragma mark - MMobileForms Delegate (optional)

- (void)mmobileFormsResult:(NSString*)data
{
    NSLog(@"mmobileFormsResult : %@", data); // submitted data
}

- (void)mmobileFormsEvent:(MMobileFormsEventType)eventType element:(NSString*)element elementValue:(NSString*)value
{
    if(eventType == ValidateError) {
        NSLog(@"mmobileFormsEvent : ValidateError in input: %@ value: '%@'", element, value);
    }
}

@end
```

**Constructors**

```objective-c
- (id)initForm:(NSString*)jsonForm controller:(UIViewController*)controller;
- (id)initForm:(NSString*)jsonForm populateData:(NSString*)jsonPopulateData controller:(UIViewController*)controller;
- (id)initForm:(NSString*)jsonForm populateData:(NSString*)jsonPopulateData controller:(UIViewController*)controller frame:(CGRect)frame;
```

**Functions**

```objective-c
- (void)setReadOnlyMode:(BOOL)boolean;
- (void)setBackgroundColor:(UIColor*)color;
- (void)populateWithData:(NSString*)jsonPopulateData;
- (void)addCSSFile:(NSString*)cssFilePath overrideAllStyles:(bool)override;
- (void)addJSFile:(NSString*)jsFilePath;
- (NSString*)getFormValues;
```

**Callbacks**

```objective-c
- (void)mmobileFormsResult:(NSString*)data;
- (void)mmobileFormsEvent:(MMobileFormsEventType)eventType element:(NSString*)element elementValue:(NSString*)value;
```

Android implementation
----------------------


```java
public class ViewController extends ActionBarActivity implements ViewController {

    private MmobileForms mmobileForms;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_demo);
        
        mmobileForms = findViewById(R.id.myForm);
        mmobileForms.setFormModel(getJsonModel("MMobileForms/formModel.json");
        mmobileForms.setController(this);
    }

    @Override
    public void mmobileFormsResult(String data){
        Log.d("MMobile forms data: ", data);
    }

    @Override
    public void mmobileFormsEvent(EventType eventType, String element, String value){
        if(eventType == EventType.VALIDATEERROR) {
            Log.d("MMobile forms event: ", String.format("ValidatError in input: %s value: %s", element, value));
        }
    }
}
```

**Constructors**

TODO: closing definition pending

**Functions**

TODO: closing definition pending

**Callbacks**

TODO: closing definition pending

Windows Phone implementation
----------------------------

**Usage**

```cs
public class MyView : ViewModelBase
{
    private MmobileForms _mmobileForms;
    
    public MmobileForms()
    {
        PropertyChanged += mmobileFormsEvent_PropertyChanged; 
        PropertyChanged += mmobileFormsEventError_PropertyChanged; 
    }
    
    private void mmobileFormsEvent_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        _mmobileForms.setFormModel(JsonConvert("MMobileForms/formModel.json"));
    }
    
    void mmobileFormsResult(string _data)
    {
        System.Diagnostics.Debug.WriteLine("MMobile forms data: ", _data);
    }
    
    void mmobileFormsEventError_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e, string elem, string value)
    { 
        if(e.PropertyName==VALIDATEERROR)
        System.Diagnostics.Debug.WriteLine("MMobile forms event ValidatError in input" + elem.ToString(), value.ToString());
    }
}
```

**Constructors**
TODO: closing definition pending

**Functions**
TODO: closing definition pending

**Callbacks**
TODO: closing definition pending