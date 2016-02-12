// -------------------------------------------------------------------------------------------------
// UTILS

Date.prototype.toFormattedString = function(f) {
    f = f.replace(/yyyy/g, this.getFullYear());
    f = f.replace(/yy/g, String(this.getFullYear()).substr(2, 2));
    f = f.replace(/mm/g, String(this.getMonth() + 1).padLeft('0', 2));
    f = f.replace(/dd/g, String(this.getDate()).padLeft('0', 2));
    f = f.replace(/HH/g, String(this.getHours()).padLeft('0', 2));
    f = f.replace(/MM/g, String(this.getMinutes()).padLeft('0', 2));
    return f;
};

String.prototype.padLeft = function(value, size) {
    var x = this;
    while (x.length < size) {
        x = value + x;
    }
    return x;
};

var Utils = {};

Utils.isAndroid = function() {
    var ua = ua || navigator.userAgent;
    var match = ua.match(/Android\s([0-9\.]*)/);
    return match ? true : false;
};

Utils.androidVersion = function() {
    var ua = ua || navigator.userAgent;
    var match = ua.match(/Android\s([0-9\.]*)/);
    return match ? parseFloat(match[1]) : false;
};

Utils.isWindowsPhone = function() {
    var ua = ua || navigator.userAgent;
    var match = ua.match(/iemobile/i) || ua.match(/wpdesktop/i);
    return match ? true : false;
};

Utils.isValidDate = function(date) { // yyyy-mm-dd
    var bits = date.split('-');
    var d = new Date(bits[0], bits[1] - 1, bits[2]);
    return d && (d.getMonth() + 1) == bits[1] && d.getDate() == Number(bits[2]);
}

Utils.tabIndexFix = function() {
    $(":input").removeAttr('tabindex');
    $(":input").each(function(i) {
        $(this).attr('tabindex', i + 1);
    });
    var tabindex = 1; // start tabindex || 150 is last tabindex

    $(document).keypress(function(event) {
        var keycode = (event.keyCode ? event.keyCode : event.which);
        if (keycode == '13') { // onEnter
            tabindex++;
            $('[tabindex=' + tabindex + ']').focus();
            return false;
        }
    });

    $("input").click(function() { // if changing field manualy with click -
                                    // reset tabindex
        var input = $(this);
        tabindex = input.attr("tabindex");
    });
}