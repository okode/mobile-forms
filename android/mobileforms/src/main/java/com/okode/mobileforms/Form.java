package com.okode.mobileforms;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Fragment;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AlphaAnimation;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.okode.mobileforms.utils.Files;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;


/**
 * You use the Form class to embed webform in your application. Form allows to create forms dynamically, through a form definition in JSON.
 * In order to make it work, you must put 'mobileforms' folder into your application assets folder.
 * Form is a Fragment, so it goes through this component lifecycles and needs to exists inside an activity, or a parent fragment.
 * It can be added programmatically or inflating a layout resource like other fragments.
 * By default, it is attached to the containing activity or parent fragment, so they must implement OnFormListener interface.
 * An example of the usage of this fragment from an activity, inflating it from layout:
 *
 * protected void onCreate(Bundle savedInstanceState) {
 * super.onCreate(savedInstanceState);
 * setContentView(R.layout.activity_form);
 * form = (Form) getSupportFragmentManager().findFragmentById(R.id.form);
 * if (savedInstanceState == null) {
 * form.setFormNamed("form1");
 * form.load();
 * }
 * Note that when adding the fragment programmatically, the FragmentTransaction is not synchronous by default, so the form will not be ready until onStart() is called.
 * Calls to methods before this state may fail.
 */
public class Form extends Fragment {


    //Forms directory and file extension
    private static final String FORMJSON_EXTENSION = "json";
    private static final String FORMJSON_DIRECTORY = "forms";

    //Path of index.mobileforms.html
    private static final String FORMHTML_URL = "file:///android_asset/mobileforms/index.mobileforms.html";

    //Save and restore state
    private static final String TAG_JSON_DATA = "jsonData";
    private static final String TAG_JSON_FORM = "jsonForm";
    private static final String TAG_PENDING_JS = "pendingJs";
    private static final String TAG_RESTORABLE_JS = "restorableJs";
    private static final String TAG_READ_ONLY = "readOnly";

    //JavaScript functions needed to initialise the form
    private static final String JS_FUNC_SET_JSON_FORM = "javascript:setJsonForm(%s)";
    private static final String JS_FUNC_SET_JSON_POPULATE_DATA = "javascript:setJsonPopulateData(%s)";
    private static final String JS_FUNC_INIT = "javascript:init()";

    //Headers used to difference the origin in onJsAlert
    private static final String ALERT_FORM_DATA_VALIDATED = "formDataValidated:";
    private static final String ALERT_FORM_DATA = "formData:";
    private static final String ALERT_UPDATE_FORM_DATA = "updateFormData:";
    private static final String ALERT_GET_FORM_ERRORS = "formErrors:";
    private static final String ALERT_IS_FORM_VALID = "isFormValid:";

    //Other JavaScript functions
    private static final String JS_FUNC_SET_READONLY_FORM = "javascript:setReadOnly(true)";
    private static final String JS_FUNC_SET_EDITABLE_FORM = "javascript:setReadOnly(false)";
    private static final String JS_FUNC_GET_FORM_DATA = "javascript:alert(\"" + ALERT_FORM_DATA + "\" +getFormData())";
    private static final String JS_FUNC_GET_FORM_DATA_VALIDATED = "javascript:alert(\"" + ALERT_FORM_DATA_VALIDATED + "\" + getFormDataValidated())";
    private static final String JS_FUNC_UPDATE_FORMDATA = "javascript:alert(\"" + ALERT_UPDATE_FORM_DATA + "\" + getFormData());";
    private static final String JS_FUNC_SET_POPULATEDATA = "javascript:populateWithData(%s)";
    private static final String JS_FUNC_ADD_CSS_FILE = "javascript:addCSS(\"%s\", %s)";
    private static final String JS_FUNC_ADD_JS_FILE = "javascript:addJS(\"%s\")";
    private static final String JS_FUNC_GET_FORM_ERRORS = "javascript:alert(\"" + ALERT_GET_FORM_ERRORS + "\" + getFormErrors())";
    private static final String JS_FUNC_IS_FORM_VALID = "javascript:alert(\"" + ALERT_IS_FORM_VALID + "\" + isFormValid())";

    //Strings that must be identified when redirecting a url
    private static final String URL_SCHEME = "mobileforms";
    private static final String URL_HOST = "event";
    private static final String URL_TEL = "tel:";
    private static final String URL_MAIL = "mailto:";

    //Query parameters of mmobile:// urls
    private static final String QUERY_ELEMENT = "element";
    private static final String QUERY_VALUE = "value";
    private static final String QUERY_TYPE = "type";

    //Types and values of query parameters
    private static final String TYPE_SUBMIT = "submit";
    private static final String TYPE_FOCUS_IN = "focus";
    private static final String TYPE_FOCUS_OUT = "focusout";
    private static final String TYPE_CHANGE = "change";
    private static final String TYPE_VALIDATE_ERROR = "validateerror";
    private static final String TYPE_LINK = "link";
    private static final String VALUE_VALID = "valid";
    private static final String VALUE_INVALID = "invalid";


    private WebView webView;
    private OnFormListener mListener;

    private boolean loadCalled;
    private boolean webViewLoaded;
    private boolean readOnly;
    private List<String> pendingJs;
    private List<String> restorableJs;
    private String jsonForm;
    private String jsonPopulateData;


    /**
     * Interface that the listener activity or fragment must implement in order to communicate with the Form Fragment.
     */
    public interface OnFormListener {
        /**
         * Tells the listener when the user submits valid form.
         *
         * @param formResult Form data as json String serialized.
         */
        public void onSubmit(String formResult);

        /**
         * Tells the listener the current form data without validate.
         *
         * @param formValues Form data as json String serialized.
         */
        public void onGetFormValues(String formValues);

        /**
         * Tells the listener when an event has occurred in the form.
         *
         * @param eventType The type of user event.
         * @param element   The form element name/id.
         * @param value     The current element value.
         */
        public void onEvent(FormEventType eventType, String element, String value);

        /**
         * Tells the listener the current form errors. formErrors contains the array 'requiredErrors' with the empty required element names
         * and the array 'validationErrors', with elements with errors and their respective error messages.
         *
         * @param formErrors Form errors as json String serialized.
         */
        public void onGetFormErrors(String formErrors);

        /**
         * Tells the listener if the current form is valid.
         *
         * @param isFormValid true if the form is valid, false otherwise.
         */
        public void onIsFormValid(boolean isFormValid);
    }

    /**
     * Initializes and returns a new Form Fragment. It is needed to put the fragment into a FragmentTransition.
     *
     * @return A new Form Fragment
     */
    public static Form newInstance() {
        return new Form();
    }

    /**
     * Types of events that can occur in the form.
     */
    public enum FormEventType {
        SUBMIT, SUBMIT_INVALID, FOCUS_IN, FOCUS_OUT, CHANGE, VALIDATE_ERROR, LINK, OTHER
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        pendingJs = new ArrayList<>();
        restorableJs = new ArrayList<>();
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        Fragment parentFragment = getParentFragment();
        //Child fragment, set the callbacks to the parent fragment
        if (parentFragment != null) {
            try {
                mListener = (OnFormListener) parentFragment;
            } catch (ClassCastException e) {
                throw new ClassCastException(parentFragment.toString()
                        + " must implement OnFormListener");
            }
        }
        //Normal fragment, set the callbacks to the activity
        else {
            try {
                mListener = (OnFormListener) activity;
            } catch (ClassCastException e) {
                throw new ClassCastException(activity.toString()
                        + " must implement OnFormListener");
            }
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        webView = new WebView(getActivity());
        webView.setVisibility(View.INVISIBLE);
        webView.getSettings().setJavaScriptEnabled(true);
        if (savedInstanceState != null) {
            jsonForm = savedInstanceState.getString(TAG_JSON_FORM);
            jsonPopulateData = savedInstanceState.getString(TAG_JSON_DATA);
            pendingJs = savedInstanceState.getStringArrayList(TAG_PENDING_JS);
            restorableJs = savedInstanceState.getStringArrayList(TAG_RESTORABLE_JS);
            readOnly = savedInstanceState.getBoolean(TAG_READ_ONLY);
            setReadOnlyMode(readOnly);
            load();
        }
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                initForm();
                AlphaAnimation animation1 = new AlphaAnimation(0.0f, 1.0f);
                animation1.setDuration(250);
                animation1.setFillAfter(true);
                webView.setVisibility(View.VISIBLE);
                webView.startAnimation(animation1);


            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                Uri uri = Uri.parse(url);
                boolean eventUrl = uri.getScheme().equals(URL_SCHEME) && uri.getHost().equals(URL_HOST);
                if (eventUrl) {
                    String element = uri.getQueryParameter(QUERY_ELEMENT);
                    String value = uri.getQueryParameter(QUERY_VALUE);
                    FormEventType eventType = getFormEventType(uri.getQueryParameter(QUERY_TYPE), value);
                    if(eventType == FormEventType.FOCUS_IN){
                        updateFormData();
                    }
                    if (mListener != null) {
                        if (eventType == FormEventType.SUBMIT) {
                            webView.loadUrl(JS_FUNC_GET_FORM_DATA_VALIDATED);
                        }

                        mListener.onEvent(eventType, element, value);
                    }
                    return true;
                } else if (url.startsWith(URL_TEL)) {
                    Intent intent = new Intent(Intent.ACTION_DIAL,
                            Uri.parse(url));
                    startActivity(intent);
                    return true;
                } else if (url.startsWith(URL_MAIL)) {
                    Intent intent = new Intent(Intent.ACTION_SENDTO, Uri.parse(url));
                    startActivity(intent);
                    return true;
                }

                return super.shouldOverrideUrlLoading(view, url);
            }
        });
        /*
        There are some issues reported with JavaScript interface in 2.3 versions. In order to avoid these problems, the JS calls that return a result are going to be thrown through alerts, with an identifier
        and captured in this callback. The identifier will be removed and the result processed.
         */
        webView.setWebChromeClient(
                new WebChromeClient() {
                    @Override
                    public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
                        if (message.startsWith(ALERT_FORM_DATA_VALIDATED)) {
                            message = message.replace(ALERT_FORM_DATA_VALIDATED, "");
                            if (mListener != null) {
                                mListener.onSubmit(message);
                            }
                            result.confirm();
                            return true;
                        } else if (message.startsWith(ALERT_FORM_DATA)) {
                            message = message.replace(ALERT_FORM_DATA, "");
                            if (mListener != null) {
                                mListener.onGetFormValues(message);
                            }
                            result.confirm();
                            return true;
                        } else if (message.startsWith(ALERT_UPDATE_FORM_DATA)) {
                            message = message.replace(ALERT_UPDATE_FORM_DATA, "");
                            jsonPopulateData = message;
                            result.confirm();
                            return true;
                        } else if (message.startsWith(ALERT_GET_FORM_ERRORS)) {
                            message = message.replace(ALERT_GET_FORM_ERRORS, "");
                            if (mListener != null) {
                                mListener.onGetFormErrors(message);
                            }
                            result.confirm();
                            return true;

                        } else if (message.startsWith(ALERT_IS_FORM_VALID)) {
                            message = message.replace(ALERT_IS_FORM_VALID, "");
                            boolean isFormValid = Boolean.parseBoolean(message);
                            if (mListener != null) {
                                mListener.onIsFormValid(isFormValid);
                            }
                            result.confirm();
                            return true;
                        }
                        return super.onJsAlert(view, url, message, result);


                    }
                }
        );
        return webView;
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(TAG_JSON_DATA, jsonPopulateData);
        outState.putString(TAG_JSON_FORM, jsonForm);
        outState.putStringArrayList(TAG_PENDING_JS, (ArrayList<String>) pendingJs);
        outState.putStringArrayList(TAG_RESTORABLE_JS, (ArrayList<String>) restorableJs);
        outState.putBoolean(TAG_READ_ONLY, readOnly);
    }

    /**
     * Sets the listener of the Form fragment. By default, the listener is set to the parent fragment (if exists) or to the activity otherwise, and attached to its lifecycle.
     * This method should be called only if that is not the desired behaviour. Setting the listener manually implies that the lifecycle should be also manually managed.
     *
     * @param listener listener that implements OnFormListener interface.
     */
    public void setmListener(OnFormListener listener) {
        mListener = listener;
    }


    /**
     * Sets form model loading json by name. The json file must be in the assets folder following this convention: assets/forms/{formName}.json.
     * This method or setForm method must be called before load().
     *
     * @param name The name of the file located in assets/forms folder, without including .json extension.
     */
    public void setFormNamed(String name) {
        if (loadCalled) {
             Log.w("MobileForms", "setFormNamed must be called before load");
        }
        InputStream json;
        try {
            json = getActivity().getAssets().open(String.format("%s/%s.%s", FORMJSON_DIRECTORY, name, FORMJSON_EXTENSION));
        } catch (IOException e) {
            Log.w("MobileForms", String.format("Form (json file) named %s not exists inside %s folder", name, FORMJSON_DIRECTORY));
            return;
        }

        jsonForm = Files.readTextFile(json);
    }

    /**
     * Sets form model from a json String serialized.
     * This method or setFormNamed method must be called before load().
     *
     * @param jsonString Json form model String serialized
     */
    public void setForm(String jsonString) {
        if (loadCalled) {
            Log.w("MobileForms", "setFormNamed must be called before load");
        }
        jsonForm = jsonString;
    }

    /**
     * Sets form data from a json String serialized.
     * The call to this method is optional, but if done, it must be before load().
     *
     * @param jsonString Json form data String serialized.
     */
    public void setPopulateData(String jsonString) {
        if (loadCalled) {
            Log.w("MobileForms", "setFormNamed must be called before load");
        }
        jsonPopulateData = jsonString;
    }

    /**
     * Loads the form. Methods newInstance() if the fragment is created programmatically, and setForm() or setFormNamed() must be called first.
     * In order to make it work, the folder 'mobileforms' have to be present in your assets folder.
     */
    public void load() {
        loadCalled = true;
        if (jsonForm == null) {
            Log.e("MobileForms", "JSON form is not defined, please use setFormNamed or setForm before load");
            return;
        }
        webView.loadUrl(FORMHTML_URL);
    }

    private void initForm() {
        // Set form
        webView.loadUrl(String.format(JS_FUNC_SET_JSON_FORM, jsonForm));
        // Populate form data with JSON (if it has been provided)
        if (jsonPopulateData != null) {
            webView.loadUrl(String.format(JS_FUNC_SET_JSON_POPULATE_DATA, jsonPopulateData));
        }
        // Init JS
        webView.loadUrl(JS_FUNC_INIT);
        pendingJs.removeAll(restorableJs);
        for (String js : pendingJs) {
            webView.loadUrl(js);
        }
        pendingJs.clear();
        for (String js : restorableJs) {
            webView.loadUrl(js);
        }
        webViewLoaded = true;

    }

    /**
     * Set if form is editable or not. Form can switch between these modes at anytime.
     *
     * @param readOnly true sets the form as read only. False sets the form editable.
     */
    public void setReadOnlyMode(boolean readOnly) {
        String js = readOnly ? JS_FUNC_SET_READONLY_FORM : JS_FUNC_SET_EDITABLE_FORM;
        if (webViewLoaded) {
            webView.loadUrl(js);
        } else {
            pendingJs.add(js);
        }
        this.readOnly = readOnly;
    }

    /**
     * Asks the form for the current values. The result will be delivered to the listener through onGetFormValues callback.
     */
    public void getFormData() {
        webView.loadUrl(JS_FUNC_GET_FORM_DATA);
    }

    /**
     * Sets form data passing json string serialized (once the form is loaded), overwriting current values.
     *
     * @param jsonString Json data String serialized.
     */
    public void setPopulateDataAsync(String jsonString) {
        String js = String.format(JS_FUNC_SET_POPULATEDATA, jsonString);
        if (webViewLoaded) {
            webView.loadUrl(js);
            webView.loadUrl(JS_FUNC_UPDATE_FORMDATA);
        } else {
            pendingJs.add(js);
            pendingJs.add(JS_FUNC_UPDATE_FORMDATA);
        }
    }


    /**
     * Adds custom css to form webview.
     *
     * @param cssFilePath       Path of the file. It must be located on assets folder. Example: forms/custom.css
     * @param overrideAllStyles True ignore previous form css properties, false preserves the previous values and adds new css
     */
    public void addCSSFile(String cssFilePath, boolean overrideAllStyles) {
        InputStream customCss;
        try {
            customCss = getActivity().getAssets().open(cssFilePath);
        } catch (IOException e) {
            Log.e("MobileForms", "Custom Css file was not found on assets/" + cssFilePath + ". Exception: " + e);
            return;
        }
            String cssData = Files.readTextFile(customCss);
            if (cssData == null) {
                Log.e("MobileForms", "Could not read CSS");
                return;
            }
            cssData = escapeJs(cssData);
            String js = String.format(JS_FUNC_ADD_CSS_FILE, cssData, overrideAllStyles);
            if (webViewLoaded) {
                webView.loadUrl(js);
            } else {
                pendingJs.add(js);
            }
            restorableJs.add(js);
    }

    /**
     * Adds custom js to form webview.
     *
     * @param jsFilePath Path of the file. It must be located on assets folder. Example: forms/custom.js
     */
    public void addJSFile(String jsFilePath) {
        InputStream customJs;
        try {
            customJs = getActivity().getAssets().open(jsFilePath);
        } catch (IOException e) {
            Log.e("MobileForms", "Custom Js file was not found on assets/" + jsFilePath + ". Exception: " + e);
            return;
        }

            String jsData = Files.readTextFile(customJs);
            if (jsData == null) {
                Log.e("MobileForms", "Could not read JS");
                return;
            }
            jsData = escapeJs(jsData);
            String js = String.format(JS_FUNC_ADD_JS_FILE, jsData);
            if (webViewLoaded) {
                webView.loadUrl(js);
            } else {
                pendingJs.add(js);
            }
            restorableJs.add(js);
    }

    /**
     * Get the current form errors. The result will be delivered to the listener through onGetFormErrors callback.
     */
    public void getFormErrors() {
        webView.loadUrl(JS_FUNC_GET_FORM_ERRORS);
    }

    /**
     * Checks if the current form is valid. The result will be delivered to the listener through onIsFormValid callback.
     */
    public void isFormValid() {
        webView.loadUrl(JS_FUNC_IS_FORM_VALID);
    }

    private void updateFormData() {
        webView.loadUrl(JS_FUNC_UPDATE_FORMDATA);
    }


    private FormEventType getFormEventType(String type, String value) {
        if (type.equals(TYPE_SUBMIT) && value.equals(VALUE_VALID)) {
            return FormEventType.SUBMIT;
        }
        if (type.equals(TYPE_SUBMIT) && value.equals(VALUE_INVALID)) {
            return FormEventType.SUBMIT_INVALID;
        }
        if (type.equals(TYPE_FOCUS_IN)) {
            return FormEventType.FOCUS_IN;
        }
        if (type.equals(TYPE_FOCUS_OUT)) {
            return FormEventType.FOCUS_OUT;
        }
        if (type.equals(TYPE_CHANGE)) {
            return FormEventType.CHANGE;
        }
        if (type.equals(TYPE_VALIDATE_ERROR)) {
            return FormEventType.VALIDATE_ERROR;
        }
        if (type.equals(TYPE_LINK)) {
            return FormEventType.LINK;
        }
        return FormEventType.OTHER;
    }

    private String escapeJs(String js) {
        String result = js;
        result = result.replace("\\", "\\\\");
        result = result.replace("\"", "\\\"");
        result = result.replace("\'", "\\\'");
        result = result.replace("\n", "\\n");
        result = result.replace("\r", "\\r");
        result = result.replace("\f", "\\f");
        return result;
    }

}
