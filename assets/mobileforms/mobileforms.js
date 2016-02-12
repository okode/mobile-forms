function MobileForms(params) {
    
    var jsonResult = null;

    // default params
    var formContainer = 'body';
    var formId = 'form';
    var readOnly = false;
    var jsonForm = null;
    var jsonPopulateData = null;
    var eventCallback = null;
    var successCallback = null;
    var isMobile = false;
    //
    var init = function(params) {
        // params
        if(params) {
            readOnly = params.readOnly ? params.readOnly : readOnly;
            formId = params.formId ? params.formId : formId;
            formContainer = params.formContainer ? params.formContainer : formContainer;
            jsonForm = params.jsonForm ? params.jsonForm : null;
            jsonPopulateData = params.jsonPopulateData ? params.jsonPopulateData : null;
            eventCallback = params.eventCallback ? params.eventCallback : null;
            successCallback = params.successCallback ? params.successCallback : null;
            isMobile = params.isMobile ? true : false;
        }
        if(jsonForm == null) {
            $.error('MobileForms error: jsonForm is null');
        }
        // Build form fields, validators, ...
        $(formContainer).MobileFormsBuilder({
            id : formId,
            fields : jsonForm
        }, formReadyCallback, submitFormCallback, eventManager);
    };





    // ---------------------------------------------------------------------------------------------
    // PUBLIC
    // getFormDataValidated (form validated or null)
    
    this.getFormDataValidated = function() {
        return jsonResult;
    };
    
    // ---------------------------------------------------------------------------------------------
    // PUBLIC
    // getFormData (current values without validation)
    
    this.getFormData = function() {
        return $('#'+formId).serializeJSON();
    };
    
    // ---------------------------------------------------------------------------------------------
    // PUBLIC
    // setReadOnly
    
    this.setReadOnly = function(val) {
        if(val === true || val == "true" || val == "True" || val == "TRUE") {
            setReadOnlyForm();
        } else {
            setEditableForm();
        }
    };
    
    // ---------------------------------------------------------------------------------------------
    // PUBLIC
    // populateWithData
    
    this.populateWithData = function(data) {
        if(data != "JSON_POPULATE_DATA") {
            $('#'+formId).MobileFormsPopulator(data);
        }
    };

    // ---------------------------------------------------------------------------------------------
    // PUBLIC
    // isFormValid
    
    this.isFormValid = function() {
        $(':input').change().blur();
        var submitDisabled = $('input[type="submit"]').hasClass('disabled');
        return !submitDisabled;
    };

    // ---------------------------------------------------------------------------------------------
    // PUBLIC
    // getFormErrors
    
    this.getFormErrors = function() {      
        $(':focus').blur();
        var requiredErrs = null;
        var validationErrs = null;
        // required
        $(':input').filter('[required]').each(function() {
            if($(this).val() == null || $(this).val() == "") {
                if(requiredErrs == null) { requiredErrs = ''; }
                requiredErrs += '"' + $(this).attr('name') + '",';
            }
        });
        if(requiredErrs != null) {
            requiredErrs = requiredErrs.substring(0, requiredErrs.length - 1);
            requiredErrs = '['+requiredErrs+']';
        }
        // validation
        $('p.error_mesg').each(function() {
            if(validationErrs == null) { validationErrs = ''; }
            var message = $(this).text();
            var inputName = $(this).siblings(':input').last().attr('name');
            validationErrs += '{"element":"'+inputName+'","message":"'+message+'"},';
        });
        if(validationErrs != null) {
            validationErrs = validationErrs.substring(0, validationErrs.length - 1);
            validationErrs = '['+validationErrs+']';
        }
        // result
        return '{"requiredErrors":'+requiredErrs+',"validationErrors":'+validationErrs+'}';
    };
    
    
    
    

    // ---------------------------------------------------------------------------------------------
    // eventManager

    eventManager = function(event, element, value) {
        if(isMobile) {
            var eventUrl = 'event/?type=' + event + '&element=' + element + '&value=' + value;
            
            // windows phone
            if (typeof window.external != 'undefined' 
                && typeof window.external.notify != 'undefined') {
                window.external.notify(eventUrl);
            } else {
                var iframe = document.createElement("IFRAME");
                iframe.setAttribute("src", 'mobileforms://' + eventUrl);
                document.body.appendChild(iframe);
                iframe.parentNode.removeChild(iframe);
            }
        }
        if(eventCallback != null) {
            eventCallback(event, element, value);
        }
    };





    // ---------------------------------------------------------------------------------------------
    // formReadyCallback
    
    formReadyCallback = function(form) {
        if(jsonPopulateData != null) {
            // Populate form data
            self.populateWithData(jsonPopulateData);
        }
        if(readOnly) {
            // Set read only form mode
            self.setReadOnly(readOnly);
        }
        // Dynamic tabIndex (android and wp)
        Utils.tabIndexFix();
        // Android css helper
        if(Utils.isAndroid()) {
            if (Utils.androidVersion() < 4.4) {
                $('body').addClass('androidNotChromium');
            } else {
                $('body').addClass('androidChromium');
            }
        }
        // WindowsPhone focus fix
        if(Utils.isWindowsPhone()) {
            $("input, textarea").focus(function () {
                var formScrollTop = $("#form").scrollTop();
                var activeElementOffsetTop = $(document.activeElement).parent().offset().top;
                var formOffsetTop = $("#form").offset().top;
                $('#form').animate({
                        scrollTop: formScrollTop + activeElementOffsetTop - formOffsetTop
                    },{
                        duration: 500,
                        specialEasing: {
                            width: 'linear',
                            height: 'easeOutBounce'
                        }
                });
            });
        }
    };

    // ---------------------------------------------------------------------------------------------
    // submitFormCallback
    
    submitFormCallback = function(form) {
        jsonResult = form.serializeJSON();
        if(successCallback) {
            successCallback(jsonResult);
        }
    };
    
    // ---------------------------------------------------------------------------------------------
    // setReadOnlyForm
    
    setReadOnlyForm = function() {
        if(jsonPopulateData != null) {
            $("form, form input, form select, form textarea").blur();
            $('form, form input, form select, form textarea').each(function() {
                if ($(this).not(':disabled, :hidden')) {
                    $(this).addClass('readOnlyMode').attr('disabled', true);
                }
            });
            $('input[type="checkbox"]').each(function() {
                if (!$(this).is(':checked')) {
                    $(this).parent().parent().addClass('readOnlyModeHidden')
                        .css('display', 'none');
                }
            });
            $('input[type="radio"]').each(function() {
                if (!$(this).is(':checked')) {
                    $(this).parent().addClass('readOnlyModeHidden')
                        .css('display', 'none');
                }
            });
            $(':input').not(':hidden').each(function() {
                if (!$(this).attr('json-populated')) {
                    $(this).parent('div').addClass('readOnlyModeHidden')
                        .css('display', 'none');
                }
            });
            $('.radios').each(function() {
                if ($('.radio:visible', this).length == 0) {
                    $(this).parent('div').addClass('readOnlyModeHidden')
                        .css('display', 'none');
                }
            });
            $('fieldset > div:not(.readOnlyModeHidden)').each(
                function() {
                    var totalDivChilds = $('> div', this).length;
                    var hiddenDivChilds = 
                        $('> div.inputContainer.readOnlyModeHidden', this).length;
                    if (totalDivChilds > 0 && totalDivChilds == hiddenDivChilds) {
                        $(this).addClass('readOnlyModeHidden').css('display', 'none');
                    }
                });
            $('fieldset').each(function() {
                if ($(this).children('div:visible').length == 0) {
                    $(this).addClass('readOnlyModeHidden').css('display', 'none');
                }
            });
            $('fieldset').each(function() {
                if ($('> div:not(.readOnlyModeHidden)', this).length == 0) {
                    $(this).addClass('readOnlyModeHidden').css('display', 'none');
                }
            });
        
            $('input[type="tel"].readOnlyMode').each(function() {
                var val = $(this).val();
                if (val != null && val != "") {
                    var a = $('<a></a>').addClass('telInputReadOnly')
                                .attr('href', 'tel:' + val);
                    $(this).after(a);
                }
            });
            $('input[type="email"].readOnlyMode').each(function() {
                var val = $(this).val();
                if (val != null && val != "") {
                    var a = $('<a></a>').addClass('emailInputReadOnly')
                                .attr('href', 'mailto:' + val);
                    $(this).after(a);
                }
            });
        
            /* hide default placeholder in empty inputs yyyy-mm-dd | --:-- */
            $('input[type="date"], input[type="time"]').each(function() {
                if ($(this).val() == "" || $(this).val() == null) {
                    $(this).css('opacity', 0);
                }
            });
            readOnly = true;
        } else {
            $.error('MobileForms error: setReadOnlyForm failed, jsonPopulateData is null');
        }

    };
    
    // ---------------------------------------------------------------------------------------------
    // setEditableForm
    
    setEditableForm = function() {
        $('form, form input, form select, form textarea').each(function() {
            if ($(this).hasClass('readOnlyMode')) {
                $(this).removeClass('readOnlyMode').attr('disabled', false);
            }
        });
        $('.readOnlyModeHidden').each(function() {
            $(this).removeClass('readOnlyModeHidden').css('display', 'block');
        });
        $('.telInputReadOnly, .emailInputReadOnly').remove();
        /* show default placeholder in empty inputs yyyy-mm-dd | --:-- */
        $('input[type="date"], input[type="time"]').each(function() {
            if ($(this).val() == "" || $(this).val() == null) {
                $(this).css('opacity', 1);
            }
        });
        readOnly = false;
    };
    
    

    var self = this;
    init(params);
}