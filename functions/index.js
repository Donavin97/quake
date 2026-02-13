const earthquakeNotifier = require('./earthquake_notifier');
const emscNotifier = require('./emsc_notifier');
const usgsNotifier = require('./usgs_notifier');

exports.earthquakeNotifier = earthquakeNotifier.earthquakeNotifier;
exports.emscNotifier = emscNotifier.emscNotifier;
exports.usgsNotifier = usgsNotifier.usgsNotifier;
