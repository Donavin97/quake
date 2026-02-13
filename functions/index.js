import admin from 'firebase-admin';
import { earthquakeNotifier } from './earthquake_notifier.js';
import { emscNotifier } from './emsc_notifier.js';
import { usgsNotifier } from './usgs_notifier.js';

admin.initializeApp();

export { earthquakeNotifier, emscNotifier, usgsNotifier };
