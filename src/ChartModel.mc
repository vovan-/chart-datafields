// -*- mode: Javascript;-*-

using Toybox.Math as Math;
using Toybox.System as System;
using Toybox.Application as App;

class ChartModel {
    var ignore_sd = null;

    var current = null;
    var values_size = 150; // Must be even
    var values;
    var range_mult;
    var range_mult_max;
    var range_expand = false;
    var range_mult_count = 0;
    var range_mult_count_not_null = 0;
    var next = 0;

    var min;
    var max;
    var min_i;
    var max_i;
    var mean;
    var sd;

    function initialize() {
        set_range_minutes(2.5);
    }

    function get_values() {
        return values;
    }

    function get_range_minutes() {
        return (values.size() * range_mult / 60);
    }

    function set_range_minutes(range) {
        var new_mult = range * 60 / values_size;
        if (new_mult != range_mult) {
            range_mult = new_mult;
            values = new [values_size];
            update_stats();
        }
    }

    function set_max_range_minutes(range) {
        range_mult_max = range * 60 / values_size;
    }

    function set_range_expand(re) {
        range_expand = re;
    }

    // i.e. ignore values more than i standard deviations from the mean
    function set_ignore_sd(i) {
        ignore_sd = i;
    }

    function get_current() {
        return current;
    }

    function get_min() {
        return min;
    }

    function get_max() {
        return max;
    }

    function get_min_i() {
        return min_i;
    }

    function get_max_i() {
        return max_i;
    }

    function get_min_max_interesting() {
        return max != -99999999 and min != max;
    }

    function get_mean() {
        return mean;
    }

    function get_sd() {
        return sd;
    }

    function get_range_label() {
        var range = get_range_minutes();
        if (range < 60) {
            return fmt_num_label(range) + " MINUTES";
        }
        else {
            return fmt_num_label(range / 60) + " HOURS";
        }
    }

    // Grr printf
    function fmt_num_label(num) {
        var before = num.toNumber();
        var after = (num * 10).toNumber() % 10;
        return after == 0 ? before : (before + "." + after);
    }

    function new_value(new_value) {
        current = new_value;
        if (current != null) {
            next += current;
            range_mult_count_not_null++;
        }
        range_mult_count++;
        if (range_mult_count >= range_mult) {
            var expand = range_expand && range_mult < range_mult_max &&
                values[0] == null && values[1] != null;

            for (var i = 1; i < values.size(); i++) {
                values[i-1] = values[i];
            }
            values[values.size() - 1] = range_mult_count_not_null == 0 ?
                null : (next / range_mult_count_not_null);
            next = 0;
            range_mult_count = 0;
            range_mult_count_not_null = 0;

            if (expand) {
                do_range_expand();
            }

            update_stats();
        }
    }

    function do_range_expand() {
        var sz = values.size();
        for (var i = sz - 1; i >= sz / 2; i--) {
            var old_i = i * 2 - sz;
            var total = 0;
            var n = 0;
            for (var j = old_i; j < old_i + 2; j++) {
                if (values[j] != null) {
                    total += values[j];
                    n++;
                }
            }
            values[i] = (n > 0) ? total / n : null;
        }
        for (var i = 0; i < sz / 2; i++) {
            values[i] = null;
        }
        range_mult *= 2;
    }

    function update_stats() {
        min = 99999999;
        max = -99999999;
        min_i = 0;
        max_i = 0;

        var m = 0f;
        var s = 0f;
        var total = 0f;
        var n = 0;

        for (var i = 0; i < values.size(); i++) {
            var item = values[i];
            if (item != null) {
                // Welford
                n++;
                var m2 = m;
                m += (item - m2) / n;
                s += (item - m2) * (item - m);
                total += item;
            }
        }
        if (n == 0) {
            mean = null;
            sd = null;
        }
        else {
            mean = total / n;
            sd = Math.sqrt(s / n);
        }

        var ignore = null;
        if (sd != null && ignore_sd != null) {
            ignore = ignore_sd * sd;
        }

        for (var i = 0; i < values.size(); i++) {
            var item = values[i];
            if (item != null) {
                if (ignore != null &&
                    (item > mean + ignore || item < mean - ignore)) {
                    continue;
                }
                if (item < min) {
                    min_i = i;
                    min = item;
                }
                
                if (item > max) {
                    max_i = i;
                    max = item;
                }
            }
        }
    }
}
