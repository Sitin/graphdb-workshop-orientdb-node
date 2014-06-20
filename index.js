/**
 * Created by sitin on 20.06.14.
 */


(function () {
    'use strict';

    // Export module contents
    var lib = module.exports = require('./lib');

    // Execute module if parent
    if (!module.parent) {
        lib();
    }
})();