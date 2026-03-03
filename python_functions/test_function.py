#!/usr/bin/env python3
"""
Test script for the waveform Cloud Function.
Can be run locally to test the API before deploying.
"""

import json
import sys

# Test earthquake data
TEST_EARTHQUAKE = {
    "earthquake": {
        "id": "test_usgs12345678",
        "magnitude": 4.5,
        "latitude": 34.0522,  # Los Angeles
        "longitude": -118.2437,
        "time": "2024-01-15T10:30:00Z"
    },
    "options": {
        "apply_filter": True,
        "filter_type": "bandpass",
        "freqmin": 0.5,
        "freqmax": 10.0
    }
}


def test_locally():
    """Test the function locally."""
    from main import app
    
    with app.test_client() as client:
        # Test health endpoint
        print("Testing health endpoint...")
        response = client.get('/health')
        print(f"  Status: {response.status_code}")
        print(f"  Response: {response.get_json()}")
        
        # Test waveform endpoint
        print("\nTesting waveform endpoint...")
        response = client.post('/waveform', json=TEST_EARTHQUAKE)
        print(f"  Status: {response.status_code}")
        
        result = response.get_json()
        if result:
            print(f"  Samples count: {len(result.get('samples', []))}")
            print(f"  Is mock data: {result.get('is_mock_data')}")
            print(f"  Station: {result.get('station')}")
            print(f"  Error: {result.get('error_message')}")
            
            if result.get('samples'):
                print(f"  First sample: {result['samples'][0]}")
                print(f"  Last sample: {result['samples'][-1]}")


def test_remote(function_url):
    """Test a deployed function."""
    import requests
    
    print(f"Testing deployed function at: {function_url}")
    
    # Test health
    response = requests.get(f"{function_url}/health")
    print(f"Health: {response.json()}")
    
    # Test waveform
    response = requests.post(f"{function_url}/waveform", json=TEST_EARTHQUAKE)
    result = response.json()
    print(f"Status: {response.status_code}")
    print(f"Samples: {len(result.get('samples', []))}")
    print(f"Is mock: {result.get('is_mock_data')}")
    print(f"Station: {result.get('station')}")


if __name__ == '__main__':
    if len(sys.argv) > 1:
        test_remote(sys.argv[1])
    else:
        test_locally()