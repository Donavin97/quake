const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

admin.initializeApp();

// Haversine formula to calculate distance between two points in km
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of Earth in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  return distance;
}

function getBearing(lat1, lon1, lat2, lon2) {
  const lat1Rad = lat1 * Math.PI / 180;
  const lat2Rad = lat2 * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;

  const y = Math.sin(dLon) * Math.cos(lat2Rad);
  const x = Math.cos(lat1Rad) * Math.sin(lat2Rad) -
    Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);
  const bearing = Math.atan2(y, x) * 180 / Math.PI;
  return (bearing + 360) % 360;
}

function bearingToDirection(bearing) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  const index = Math.floor(((bearing + 22.5) % 360) / 45);
  return directions[index];
}

// Helper function to format time ago string
function getTimeAgo(timestamp) {
  const now = Date.now();
  const diff = now - timestamp;
  
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  
  if (days > 0) {
    return days === 1 ? '1 day ago' : `${days} days ago`;
  } else if (hours > 0) {
    return hours === 1 ? '1 hour ago' : `${hours} hours ago`;
  } else if (minutes > 0) {
    return minutes === 1 ? '1 minute ago' : `${minutes} minutes ago`;
  } else {
    return seconds <= 1 ? 'just now' : `${seconds} seconds ago`;
  }
}

// Helper function to format distance string
function getDistanceText(distanceKm) {
  if (distanceKm < 1) {
    return `${Math.round(distanceKm * 1000)} m away`;
  } else if (distanceKm < 10) {
    return `${distanceKm.toFixed(1)} km away`;
  } else {
    return `${Math.round(distanceKm)} km away`;
  }
}

// Helper for reverse geocoding using Nominatim
const reverseGeocode = async (lat, lon) => {
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/reverse', {
      params: {
        format: 'jsonv2',
        lat: lat,
        lon: lon,
        addressdetails: 1,
        'accept-language': 'en' // Request results in English
      },
      headers: {
        'User-Agent': 'QuakeTrackApp/1.0'
      }
    });

    if (response.status === 200 && response.data) {
      const data = response.data;
      const address = data.address;
      const featLat = parseFloat(data.lat);
      const featLon = parseFloat(data.lon);

      if (address) {
                    let locationName = '';
                    let primaryPlace = null;
        
                    // Ordered list of keys to check for the most specific "place"
                    const placeKeys = [
                      'industrial', 'amenity', 'building',
                      'hamlet', 'isolated_dwelling', 'suburb', 'village', 'town', 'city',
                      'county', 'state', 'province', 'country'
                    ];
        
                    for (const key of placeKeys) {
                      if (address[key] && typeof address[key] === 'string' && address[key].length > 0) {
                        primaryPlace = address[key];
                        break;
                      }
                    }
        
                    const finalState = address.county || address.state || address.province || '';
                    const finalCountry = address.country || '';
        
                    if (primaryPlace && primaryPlace.length > 0) {
                      locationName = primaryPlace;
                      // Append state/province if different from primaryPlace and not empty
                      if (finalState.length > 0 && !locationName.includes(finalState)) {
                        locationName += `, ${finalState}`;
                      }
                      // Append country if different from state/province and not empty
                      if (finalCountry.length > 0 && !locationName.includes(finalCountry)) {
                        locationName += `, ${finalCountry}`;
                      }
                    } else if (finalState.length > 0) {
                      locationName = `${finalState}`;
                      if (finalCountry.length > 0 && finalCountry !== finalState) {
                        locationName += `, ${finalCountry}`;
                      }
                    } else {
                      locationName = finalCountry.length > 0 ? finalCountry : 'Unknown';
                    }
        
                    let result = null;
                    if (!isNaN(featLat) && !isNaN(featLon)) {
                      const distance = getDistance(featLat, featLon, lat, lon);
                      if (distance > 1.0) {
                        const bearing = getBearing(featLat, featLon, lat, lon);
                        const direction = bearingToDirection(bearing);
                        result = `${Math.round(distance)} km ${direction} of ${locationName}`;
                      }
                    }
        
                    result = result ?? locationName; // Use the constructed locationName if result is null
                    return result;      }
      return data.display_name;
    }
  } catch (error) {
    console.error(`Geocoding error for ${lat}, ${lon}:`, error.message);
  }
  return null;
};

// Function to get current time in the user's timezone
function getUserLocalTime(timezone) {
  if (!timezone) {
    return null; // No timezone specified, use caller-provided time
  }
  
  try {
    // Use Intl to get the current time components in the user's timezone
    const now = new Date();
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
      hour12: false,
      weekday: 'short'
    });
    
    const parts = formatter.formatToParts(now);
    const getPart = (type) => parts.find(p => p.type === type)?.value;
    
    // Create a new date object with the timezone-adjusted components
    // Note: This is a simplified approach - we extract the hour/minute in the target timezone
    const hour = parseInt(getPart('hour') || '0');
    const minute = parseInt(getPart('minute') || '0');
    const second = parseInt(getPart('second') || '0');
    
    // Get weekday: convert short name to number (0=Sun, 6=Sat)
    const weekdayStr = getPart('weekday');
    const dayMap = {'Sun': 0, 'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6};
    const weekday = dayMap[weekdayStr] ?? now.getDay();
    
    // Create local date object with correct time in user timezone
    const localDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute, second);
    
    // Adjust day if needed (handle day boundary)
    const today = now.getDay();
    let dayOffset = weekday - today;
    if (dayOffset > 3) dayOffset -= 7; // Handle wrap-around
    if (dayOffset < -3) dayOffset += 7;
    localDate.setDate(localDate.getDate() + dayOffset);
    
    return localDate;
  } catch (e) {
    console.log(`Invalid timezone ${timezone}, using server time:`, e.message);
    return null;
  }
}

// Function to check if current time is within quiet hours for a specific profile
function isDuringQuietHoursForProfile(profile, currentTime) {
  if (!profile.quietHoursEnabled) {
    return false; // Quiet hours not enabled for this profile
  }

  // Convert current time to user's local time using their timezone
  // If no timezone is set, use the time passed in (server time as fallback)
  let userTime = getUserLocalTime(profile.timezone);
  if (!userTime) {
    userTime = currentTime;
  }
  
  const currentHour = userTime.getHours();
  const currentMinute = userTime.getMinutes();
  const currentDay = userTime.getDay(); // 0 = Sunday, 6 = Saturday

  const quietStartHour = profile.quietHoursStart[0];
  const quietStartMinute = profile.quietHoursStart[1];
  const quietEndHour = profile.quietHoursEnd[0];
  const quietEndMinute = profile.quietHoursEnd[1];
  const quietDays = profile.quietHoursDays;

  if (!quietDays.includes(currentDay)) {
    return false; // Not a quiet day for this profile
  }

  const currentTotalMinutes = currentHour * 60 + currentMinute;
  const quietStartTotalMinutes = quietStartHour * 60 + quietStartMinute;
  const quietEndTotalMinutes = quietEndHour * 60 + quietEndMinute;

  if (quietStartTotalMinutes < quietEndTotalMinutes) {
    return currentTotalMinutes >= quietStartTotalMinutes && currentTotalMinutes < quietEndTotalMinutes;
  } else {
    return currentTotalMinutes >= quietStartTotalMinutes || currentTotalMinutes < quietEndTotalMinutes;
  }
}

// Helper function to determine if a notification should be sent for a given profile
function shouldSendNotificationForProfile(earthquake, userLocation, profile, currentTime) {
  const earthquakeMagnitude = earthquake.magnitude;
  const earthquakeLatitude = earthquake.latitude;
  const earthquakeLongitude = earthquake.longitude;
  
  if (earthquakeMagnitude < profile.minMagnitude) {
    // Check if global magnitude override applies
    if (!(profile.globalMinMagnitudeOverrideQuietHours > 0 && earthquakeMagnitude >= profile.globalMinMagnitudeOverrideQuietHours)) {
      return false; // Magnitude too low for this profile
    }
  }

  let shouldSend = false;

  // 1. Check for Global Minimum Magnitude Override (for this profile)
  if (profile.globalMinMagnitudeOverrideQuietHours > 0 && earthquakeMagnitude >= profile.globalMinMagnitudeOverrideQuietHours) {
    shouldSend = true;
  }

  // 2. Check for Always Notify Radius (for this profile)
  if (!shouldSend && profile.alwaysNotifyRadiusEnabled && profile.alwaysNotifyRadiusValue > 0 && userLocation) {
    const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
    if (distance <= profile.alwaysNotifyRadiusValue) {
      shouldSend = true;
    }
  }

  // 3. Regular Radius check (if radius is set and not worldwide for this profile)
  if (!shouldSend && profile.radius > 0 && userLocation) {
    const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
    if (distance > profile.radius) {
      return false; // Outside requested notification radius for this profile
    }
  }
  
  // 4. Quiet Hours / Emergency Logic (for this profile)
  if (!shouldSend) {
    if (isDuringQuietHoursForProfile(profile, currentTime)) {
      if (earthquakeMagnitude >= profile.emergencyMagnitudeThreshold && userLocation) {
        const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
        if (distance <= profile.emergencyRadius) {
          shouldSend = true;
        }
      } else {
        shouldSend = false; // During quiet hours, and not an emergency for this profile
      }
    } else {
      shouldSend = true; // Not during quiet hours for this profile
    }
  }

  return shouldSend;
}

const sendNotification = async (earthquake) => {
  try {
    const earthquakeMagnitude = earthquake.magnitude;
    const earthquakeLatitude = earthquake.latitude;
    const earthquakeLongitude = earthquake.longitude;
    
    // Calculate earthquake geohash
    const eqHash = geohash.encode(earthquakeLatitude, earthquakeLongitude, 10);
    const eqPrefix2 = eqHash.substring(0, 2); // ~1250km area
    
    console.log(`Processing notification for ${earthquake.id}. Magnitude: ${earthquakeMagnitude}. Geohash: ${eqHash} (Prefix: ${eqPrefix2})`);

    const usersCollection = admin.firestore().collection('users');
    // For now, we keep the geohash query based on a single user location if available.
    // More advanced logic might involve querying based on all profile locations.
    const baseQuery = usersCollection.where('preferences.notificationsEnabled', '==', true);

    const usersSnapshot = await baseQuery.get();
    
    const recipientTokens = [];

    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      const userId = doc.id;
      const fcmToken = userData.fcmToken;
      const userLocation = userData.location; // Assuming a primary user location if profiles have specific ones

      if (!fcmToken || !userData.preferences) return;

      const preferences = userData.preferences;
      const currentTime = new Date();
      const matchingProfiles = []; // Collect all profiles that match for this user

      // Check if user has notification profiles
      if (preferences.notificationProfiles && preferences.notificationProfiles.length > 0) {
        for (const profile of preferences.notificationProfiles) {
            const profileLocation = { latitude: profile.latitude, longitude: profile.longitude, geohash: geohash.encode(profile.latitude, profile.longitude, 10) };

            // Debug logging for profile check
            console.log(`Checking profile '${profile.name}' for user ${userId}. EqMag: ${earthquakeMagnitude}, MinMag: ${profile.minMagnitude}, Radius: ${profile.radius}`);

            if (shouldSendNotificationForProfile(earthquake, profileLocation, profile, currentTime)) {
                console.log(`MATCHED profile '${profile.name}' for user ${userId}.`);
                matchingProfiles.push(profile.name); // Collect matching profile name
                // DO NOT BREAK: Continue checking other profiles
            }
        }
      } else {
        // Fallback to old preferences logic for backward compatibility
        let shouldSend = false;

        if (earthquakeMagnitude < (preferences.minMagnitude || 0)) {
          if (!(preferences.globalMinMagnitudeOverrideQuietHours > 0 && earthquakeMagnitude >= preferences.globalMinMagnitudeOverrideQuietHours)) {
            // If magnitude is too low and no global override, then don't send
          } else {
            shouldSend = true; // Global override applies
          }
        } else {
          shouldSend = true; // Magnitude is fine
        }
        
        if (!shouldSend) { // If magnitude was not enough, no need to check further
            // Re-evaluate the logic here to ensure it's fully equivalent to old one
        } else {
            // Check for Always Notify Radius
            if (preferences.alwaysNotifyRadiusEnabled && preferences.alwaysNotifyRadiusValue > 0 && userLocation) {
                const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
                if (distance <= preferences.alwaysNotifyRadiusValue) {
                    shouldSend = true;
                } else {
                    shouldSend = false;
                }
            }
            // Regular Radius check (if radius is set and not worldwide)
            if (shouldSend && preferences.radius > 0 && userLocation) {
                const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
                if (distance > preferences.radius) {
                    shouldSend = false; // Outside requested notification radius
                }
            }

            // Quiet Hours / Emergency Logic
            if (shouldSend) {
                if (isDuringQuietHoursForProfile(preferences, currentTime)) {
                    if (earthquakeMagnitude >= preferences.emergencyMagnitudeThreshold && userLocation) {
                        const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
                        if (distance <= preferences.emergencyRadius) {
                            shouldSend = true;
                        } else {
                            shouldSend = false; // During quiet hours, not emergency, too far
                        }
                    } else {
                        shouldSend = false; // During quiet hours, not emergency, mag too low
                    }
                } else {
                    shouldSend = true; // Not during quiet hours
                }
            }
        }

        if (shouldSend) {
            matchingProfiles.push('Default Profile'); // Indicate old logic matched
        }
      }
      
      if (matchingProfiles.length > 0) {
        // Calculate distance for this user
        let distanceText = '';
        let distanceKm = null;
        
        if (userLocation) {
          distanceKm = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
          // Include distance if within 100km
          if (distanceKm <= 100) {
            distanceText = ` · ${getDistanceText(distanceKm)}`;
          }
        }

        // Construct notification body based on matching profiles
        let notificationBody;
        if (matchingProfiles.length === 1) {
          notificationBody = `Matches your "${matchingProfiles[0]}" filter.${distanceText}`;
        } else {
          notificationBody = `Matches your filters: ${matchingProfiles.join(', ')}.${distanceText}`;
        }

        recipientTokens.push({ token: fcmToken, userId: userId, notificationBody: notificationBody });
      }
    });      const magnitudeText = earthquake.source === 'SEC' 
      ? earthquake.magnitude.toFixed(2) 
      : earthquake.magnitude.toFixed(1);

    // Get time ago string
    const timeAgo = getTimeAgo(earthquake.time);

    // Use different sound for large earthquakes (magnitude >= 6.0)
    const soundName = earthquake.magnitude >= 6.0 ? 'earthquake_large' : 'earthquake';

    const messagePayload = {        data: {
        title: 'New Earthquake Alert!',
        body: `Magnitude ${magnitudeText} (${earthquake.source}) ${timeAgo} near ${earthquake.place}`, // This will be overwritten by specific notificationBody
        earthquake: JSON.stringify(earthquake),
        mapUrl: `https://www.google.com/maps/search/?api=1&query=${earthquake.latitude},${earthquake.longitude}`,
        sound: soundName
      },
      android: {
        priority: 'high',
      }
    };

    if (recipientTokens.length === 0) {
      console.log('No eligible recipients found in Firestore for earthquake:', earthquake.id);
    } else {
      const messages = recipientTokens.map(r => ({
        token: r.token,
        data: {
            ...messagePayload.data,
            body: `Magnitude ${magnitudeText} (${earthquake.source}) ${timeAgo} near ${earthquake.place}. ${r.notificationBody}`, // Use specific body
            isTargeted: 'true' // Explicitly mark as targeted for client-side priority
        },
        android: messagePayload.android
      }));

      // Send messages in batches of 500 (Firebase limit for sendEach)
      const BATCH_SIZE = 500;
      for (let i = 0; i < messages.length; i += BATCH_SIZE) {
        const batch = messages.slice(i, i + BATCH_SIZE);
        const response = await admin.messaging().sendEach(batch);

        console.log(`Batch ${Math.floor(i / BATCH_SIZE) + 1} sent: ${response.successCount} successful, ${response.failureCount} failed.`);

        if (response.failureCount > 0) {
          const cleanupPromises = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const invalidUserId = recipientTokens[i + idx].userId;
              
              if (resp.error.code === 'messaging/invalid-registration-token' ||
                  resp.error.code === 'messaging/registration-token-not-registered' ||
                  resp.error.code === 'messaging/unregistered') {
                console.log(`Removing invalid FCM token for user ${invalidUserId}.`);
                cleanupPromises.push(
                  admin.firestore().collection('users').doc(invalidUserId).update({
                    fcmToken: admin.firestore.FieldValue.delete()
                  })
                );
              }
            }
          });
          if (cleanupPromises.length > 0) {
            await Promise.all(cleanupPromises);
          }
        }
      }
    }

    // ONLY send targeted notifications to specific devices based on their Firestore profile settings.
    // Topic-based broadcasting has been disabled to ensure notifications only go to users
    // whose Firestore profile filters match the earthquake criteria.
    // The direct token-based sending above already handles this filtering correctly.

  } catch (error) {
    console.error('Error sending notifications for earthquake:', earthquake.id, error);
  }
};


const createEarthquakeNotifier = (source, apiUrl, dataTransformer) => {
  return functions.pubsub.schedule('every 2 minutes').onRun(async () => {
    const lastTimestampRef = admin.database().ref(`last_timestamps/${source}`);
    const lastTimestampSnapshot = await lastTimestampRef.once('value');
    let lastTimestamp = lastTimestampSnapshot.val() || 0;

    try {
      const response = await axios.get(apiUrl);
      const earthquakes = dataTransformer(response.data);
      let maxTimestamp = lastTimestamp;

      for (const earthquakeData of earthquakes) {
        if (earthquakeData.time > lastTimestamp) {
          // Geocode for better place description
          const betterPlace = await reverseGeocode(earthquakeData.latitude, earthquakeData.longitude);
          if (betterPlace) {
            earthquakeData.place = betterPlace;
          }
          await sendNotification(earthquakeData);
          if (earthquakeData.time > maxTimestamp) {
            maxTimestamp = earthquakeData.time;
          }
        }
      }
      await lastTimestampRef.set(maxTimestamp);
    } catch (error) {
      console.error(`Error fetching earthquake data from ${source}:`, error);
    }
  });
};

const sources = [
  {
    name: 'usgs',
    url: 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson',
    transformer: (data) => {
      return data.features.map(earthquake => {
        const { properties, geometry, id } = earthquake;
        const { mag, place, time } = properties;
        const [longitude, latitude, depth] = geometry.coordinates;
        return {
          id: id,
          magnitude: parseFloat(mag),
          place: place,
          time: time,
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          depth: parseFloat(depth || 0),
          source: 'USGS',
        };
      });
    }
  },
  {
    name: 'emsc',
    url: 'https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=50&nodata=404',
    transformer: (data) => {
      return data.features.map(earthquake => {
        const { properties, geometry, id } = earthquake;
        const { mag, flynn_region, time, depth } = properties;
        const [longitude, latitude] = geometry.coordinates;
        const timeInMillis = Date.parse(time);
        return {
          id: id,
          magnitude: parseFloat(mag),
          place: flynn_region,
          time: timeInMillis,
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          depth: parseFloat(depth || 0),
          source: 'EMSC'
        };
      });
    }
  },
  {
    name: 'sec',
    url: 'http://quakewatch.freeddns.org:8080/fdsnws/event/1/query?limit=50&format=json',
    transformer: (data) => {
      if (!data.seiscomp || !data.seiscomp.events) return [];
      return data.seiscomp.events.map(event => {
        return {
          id: event.eventID,
          magnitude: parseFloat(event.mag),
          place: event.region,
          time: Date.parse(event.otime),
          latitude: parseFloat(event.lat),
          longitude: parseFloat(event.lon),
          depth: parseFloat(event.depth || 0),
          source: 'SEC'
        };
      });
    }
  }
];

const usgsSource = sources.find(s => s.name === 'usgs');
const emscSource = sources.find(s => s.name === 'emsc');
const secSource = sources.find(s => s.name === 'sec');

exports.usgsNotifier = createEarthquakeNotifier(usgsSource.name, usgsSource.url, usgsSource.transformer);
exports.emscNotifier = createEarthquakeNotifier(emscSource.name, emscSource.url, emscSource.transformer);
exports.secNotifier = createEarthquakeNotifier(secSource.name, secSource.url, secSource.transformer);
