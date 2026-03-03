#!/bin/bash
# Deploy script for Python Cloud Function
# Usage: ./deploy.sh YOUR_REGION

REGION=${1:-us-central1}
FUNCTION_NAME=waveform-processor

# Get project ID from environment variable or gcloud config
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null)}

if [ -z "$PROJECT_ID" ]; then
  echo "ERROR: Could not determine Google Cloud project ID."
  echo "Please either:"
  echo "  1. Set GOOGLE_CLOUD_PROJECT environment variable, or"
  echo "  2. Run 'gcloud config set project YOUR_PROJECT_ID' first"
  exit 1
fi

SERVICE_ACCOUNT=waveform-function@${PROJECT_ID}.iam.gserviceaccount.com

echo "Deploying $FUNCTION_NAME to $REGION..."

gcloud functions deploy $FUNCTION_NAME \
  --runtime=python313 \
  --region=$REGION \
  --source=. \
  --entry-point=waveform \
  --trigger-http \
  --allow-unauthenticated \
  --memory=1024MB \
  --timeout=600s \
  --max-instances=10 \
  --set-env-vars PYTHONUNBUFFERED=1

echo "Deployment complete!"
echo "Function URL: https://$REGION-$GOOGLE_CLOUD_PROJECT.cloudfunctions.net/$FUNCTION_NAME"
