# Python Waveform Processing Cloud Function

A Google Cloud Function (2nd Gen) that uses **Obspy** for advanced seismic waveform processing.

## Features

- Fetches real seismic data from IRIS FDSNWS
- Advanced filtering (bandpass, lowpass, highpass)
- Instrument response processing
- Automatic station selection by distance and quality
- Fallback to simulated data when needed

## Setup

1. **Install dependencies locally (for testing):**
   ```bash
   pip install -r requirements.txt
   ```

2. **Test locally:**
   ```bash
   python test_function.py
   ```

## Deployment

1. **Set your Google Cloud project:**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Deploy the function:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh us-central1
   ```

   Or manually:
   ```bash
   gcloud functions deploy waveform-processor \
     --runtime=python311 \
     --region=us-central1 \
     --source=. \
     --entry-point=waveform_processor \
     --trigger-http \
     --allow-unauthenticated \
     --memory=512MB \
     --timeout=120s
   ```

## API Usage

### Endpoint
```
POST https://REGION-PROJECT_ID.cloudfunctions.net/waveform-processor
```

### Request Body
```json
{
  "earthquake": {
    "id": "usgs12345678",
    "magnitude": 4.5,
    "latitude": 34.0522,
    "longitude": -118.2437,
    "time": "2024-01-15T10:30:00Z"
  },
  "options": {
    "apply_filter": true,
    "filter_type": "bandpass",
    "freqmin": 0.5,
    "freqmax": 10.0
  }
}
```

### Response
```json
{
  "samples": [
    {"time": 0.0, "amplitude": 0.001},
    {"time": 0.05, "amplitude": 0.002},
    ...
  ],
  "station": {
    "network": "IU",
    "station": "SLM",
    "channel": "BHZ",
    "latitude": 34.123,
    "longitude": -118.456,
    "distance_km": 45.2
  },
  "is_mock_data": false,
  "error_message": null
}
```

## Cost Considerations

- Cloud Functions: Free tier includes 2M invocations/month
- Network egress: May apply for IRIS API calls
- obspy dependencies increase cold start time

## Alternatives Considered

If costs become a concern, consider:
1. Cloud Run (pay-per-use, more flexible)
2. Keep Dart implementation (current approach)
3. Pre-process and cache waveform data