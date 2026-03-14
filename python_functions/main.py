#!/usr/bin/env python3
from __future__ import annotations
"""
Cloud Functions for Firebase - Seismograph Waveform Generator
Uses Obspy to fetch seismic data from multiple FDSN providers in parallel.

MEMORY OPTIMIZATIONS:
- Lazy loading of dependencies (deferred until needed)
- Limited provider queries (only try essential providers, not all 13)
- Reduced parallel operations to prevent memory spikes
- Lower resolution plots and downsampled audio
- Aggressive cleanup of temporary objects
- Memory-efficient data structures
"""

import asyncio
import base64
import gc
import io
import json
import math
import os
import random
import sys
from datetime import datetime, timedelta
from functools import lru_cache
from typing import Optional, Tuple

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app

# For cost control, you can set the maximum number of containers
set_global_options(max_instances=10)

initialize_app()

# Try to import optional dependencies, fall back gracefully if not available
OBSPY_AVAILABLE = False
MATPLOTLIB_AVAILABLE = False
NUMPY_AVAILABLE = False
WAV_AVAILABLE = False

# Lazy import functions - only load when actually needed
# Store imported classes at module level for lazy loading
_UTCDateTime = None
_Client = None
_ObsStream = None
_ObsTrace = None
_ObsInventory = None

def _get_obspy():
    """Lazy load Obspy to reduce initial memory footprint."""
    global OBSPY_AVAILABLE, _UTCDateTime, _Client, _ObsStream, _ObsTrace, _ObsInventory
    if OBSPY_AVAILABLE:
        return sys.modules.get('obspy')
    
    try:
        from obspy import UTCDateTime
        from obspy.clients.fdsn import Client
        from obspy import Stream, Trace, Inventory
        
        # Store classes at module level for lazy access
        _UTCDateTime = UTCDateTime
        _Client = Client
        _ObsStream = Stream
        _ObsTrace = Trace
        _ObsInventory = Inventory
        
        OBSPY_AVAILABLE = True
        return sys.modules.get('obspy')
    except ImportError as e:
        print(f"Failed to import Obspy: {e}")
        OBSPY_AVAILABLE = False
        return None

def _get_client_class():
    """Get the FDSN Client class, loading Obspy if needed."""
    _get_obspy()
    return _Client

def _get_stream_class():
    """Get the Obspy Stream class, loading Obspy if needed."""
    _get_obspy()
    return _ObsStream

def _get_trace_class():
    """Get the Obspy Trace class, loading Obspy if needed."""
    _get_obspy()
    return _ObsTrace

def _get_utc_datetime():
    """Get the UTCDateTime class, loading Obspy if needed."""
    _get_obspy()
    return _UTCDateTime

def _get_numpy():
    """Lazy load numpy to reduce initial memory footprint."""
    global NUMPY_AVAILABLE, np
    if NUMPY_AVAILABLE and np is not None:
        return np
    
    try:
        import numpy as np
        NUMPY_AVAILABLE = True
        return np
    except ImportError:
        NUMPY_AVAILABLE = False
        return None

def _get_matplotlib():
    """Lazy load matplotlib to reduce initial memory footprint."""
    global MATPLOTLIB_AVAILABLE
    if MATPLOTLIB_AVAILABLE:
        return sys.modules.get('matplotlib')
    
    try:
        import matplotlib
        matplotlib.use('Agg')  # Non-interactive backend
        from matplotlib import pyplot as plt
        MATPLOTLIB_AVAILABLE = True
        return sys.modules.get('matplotlib')
    except ImportError:
        MATPLOTLIB_AVAILABLE = False
        return None

# Initialize np placeholder (will be lazy-loaded)
np = None  # type: ignore

# FDSN Clients - initialized lazily with memory limit
_fdsn_clients = {}
MAX_CLIENTS = 3  # Limit number of cached clients to reduce memory
# Essential providers only (reduced from 13 to save memory)
FDSN_PROVIDERS = [
    "IRIS",   # USA - Primary (usually fastest and best coverage)
    "GFZ",    # Germany
    "EMSC",   # Europe-Mediterranean
    "SCEDC",  # Southern California (often has good data for US quakes)
    "NCEDC",  # Northern California
    "AUSPASS", # Australia
    "NOA",  # Greace 
    "GEONET",  # New Zeeland
    "INGV",  # Italy
    "IPGP", # France 
    "KOERI",  # Turkey
    "IESDMC",  # Iceland
    "ICGC",  # Colombia
    "ODC",  # Orphius
    "USP",  # Brazil
]
# Only query these providers for station lookups (not all 13)
STATION_PROVIDERS = ["IRIS", "GFZ", "EMSC", "GEONET", "SCEDC", "NCEDC", "NOA", "AUSPASS", "INGV", "IPGP", "TEXNET", "ICGC", "IESDMC", "KOERI", "ODC", "USP"]

def get_client(provider: str):
    """Get or create FDSN client for a provider.
    
    Memory optimization: Limit number of cached clients to prevent memory bloat.
    
    Args:
        provider: Provider name. Can be a built-in FDSN provider (IRIS, GFZ, etc.)
                  or a custom provider key from CUSTOM_FDSN_PROVIDERS.
    
    Returns:
        ObsPy FDSN Client, or None if the provider is not available.
    """
    # Check cache first
    if provider in _fdsn_clients:
        return _fdsn_clients[provider]
    
    # Memory protection: Don't create too many clients
    if len(_fdsn_clients) >= MAX_CLIENTS:
        # Reuse least recently used by clearing all and letting them rebuild
        # This prevents unbounded memory growth
        _fdsn_clients.clear()
        gc.collect()
    
    # Get the Client class via lazy loading
    Client = _get_client_class()
    if Client is None:
        print(f"Failed to load Client class for {provider}: Obspy not available")
        return None
    
    try:
        # Check if this is a custom provider
        if provider in CUSTOM_FDSN_PROVIDERS:
            custom_config = CUSTOM_FDSN_PROVIDERS[provider]
            # Create client with custom station and dataselect URLs using service_mappings
            client = Client(
                base_url=custom_config["base_url"],
                service_mappings=custom_config.get("service_mappings"),
                _discover_services=False,  # Skip built-in service discovery
            )
        else:
            # Use built-in provider
            client = Client(provider)
        
        _fdsn_clients[provider] = client
        return client
    except Exception as e:
        print(f"Failed to create client for {provider}: {e}")
        return None

# Preferred network codes for South African provider (SAFDSN)
# These networks have reliable data access from CGS stations
# Order matters: earlier networks will be tried first
PREFERRED_NETWORKS = ['A1', 'GT', 'II', 'ZA']

# Network priority mapping for sorting (lower number = higher priority)
NETWORK_PRIORITY = {network: idx for idx, network in enumerate(PREFERRED_NETWORKS)}

# Custom FDSN providers requiring explicit URL configuration
# These are regional providers not in ObsPy's built-in provider list
CUSTOM_FDSN_PROVIDERS = {
    # South Africa - Council for Geoscience (CGS) via quakewatch server
    # This server is hosted in South Africa and provides seismic data for the region
    "SAFDSN": {
        "base_url": "http://www.quakewatch.freeddns.org:3333/fdsnws/",
        "service_mappings": {
            "station": "http://www.quakewatch.freeddns.org:3333/fdsnws/station/1/",
            "dataselect": "http://www.quakewatch.freeddns.org:3333/fdsnws/dataselect/1/",
        },
        "description": "South Africa (QuakeWatch)",
    },
}

# Combined providers list: built-in + custom
# Custom providers will be checked after built-in ones for better global coverage
ALL_PROVIDERS = FDSN_PROVIDERS + list(CUSTOM_FDSN_PROVIDERS.keys())


def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate great circle distance between two points in km using Haversine formula."""
    earth_radius_km = 6371.0
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return earth_radius_km * c


async def _find_nearby_stations_async(latitude: float, longitude: float, time: datetime, max_stations: int = 10, provider_filter: str = None) -> list[dict]:
    """Find seismic stations near the earthquake location using multiple FDSN providers.
    
    Memory optimization: Query fewer providers (only essential ones), use smaller maxradius,
    and limit parallel operations to prevent memory spikes.
    
    Args:
        latitude: Earthquake latitude
        longitude: Earthquake longitude
        time: Earthquake time
        max_stations: Maximum number of stations to return (default 10)
        provider_filter: If set, only query this specific provider
    """
    obspy = _get_obspy()
    if not obspy or not OBSPY_AVAILABLE:
        return []
    
    UTCDateTime = _get_utc_datetime()
    if UTCDateTime is None:
        return []
    
    # Determine which providers to query - use limited set to save memory
    if provider_filter:
        providers_to_query = [provider_filter]
    else:
        # Use only essential providers (IRIS, GFZ, EMSC) - not all 13
        providers_to_query = STATION_PROVIDERS
    
    # Limit max_stations to prevent loading too much station data
    max_stations = min(max_stations, 10)
    
    async def query_provider(provider: str) -> list[dict]:
        """Query a single provider for stations."""
        stations = []
        try:
            client = get_client(provider)
            if not client:
                return stations
                
            print(f"Querying {provider} for stations...")
            start_time = UTCDateTime(time - timedelta(days=1))
            end_time = UTCDateTime(time + timedelta(days=1))
            
            # Use station level instead of response to reduce memory
            # Request fewer stations with smaller radius
            inventory = client.get_stations(
                latitude=latitude,
                longitude=longitude,
                maxradius=3,  # Reduced from 5 to limit results
                starttime=start_time,
                endtime=end_time,
                level="channel",  # Must use channel level to get location codes
                channel="BHZ,HHZ,SHZ",  # Request all Z channels to find available ones
            )
            
            # Process stations in a memory-efficient way
            for network in inventory:
                for station in network:
                    # Limit processing to first 3 channels per station
                    channel_count = 0
                    best_channel = None
                    for channel in station:
                        if channel.code.endswith('Z') and channel_count < 3:
                            best_channel = channel
                            channel_count += 1
                            break
                    
                    distance = _calculate_distance(
                        latitude, longitude,
                        station.latitude, station.longitude
                    )
                    
                    stations.append({
                        'network': network.code,
                        'station': station.code,
                        'latitude': station.latitude,
                        'longitude': station.longitude,
                        'elevation': station.elevation,
                        'distance_km': distance,
                        'channel': best_channel.code if best_channel else None,
                        'location': best_channel.location_code if best_channel else None,
                        'sample_rate': best_channel.sample_rate if best_channel else None,
                        'provider': provider,
                    })
                    
                    # Safety limit
                    if len(stations) >= max_stations * 3:
                        break
                if len(stations) >= max_stations * 3:
                    break
            
            # Clear inventory reference to free memory
            del inventory
            
        except Exception as e:
            print(f"Error querying {provider} for stations: {e}")
        
        return stations
    
    # Query only first 3 providers sequentially (not all in parallel)
    # This prevents memory spikes from loading multiple station inventories at once
    results = []
    for provider in providers_to_query[:3]:
        result = await query_provider(provider)
        results.append(result)
        # Early exit if we have enough stations
        total_stations = sum(len(r) for r in results)
        if total_stations >= max_stations:
            break
    
    # Collect all stations, avoiding duplicates
    # Keep stations from different providers as separate candidates
    # (a station may exist in multiple providers with different data availability)
    all_stations = []
    seen_keys = set()
    
    for result in results:
        if isinstance(result, list):
            for station in result:
                # Use (provider, network, station) as key to preserve regional variants
                key = (station['provider'], station['network'], station['station'])
                if key not in seen_keys:
                    seen_keys.add(key)
                    all_stations.append(station)
    
    # Sort stations: for SAFDSN provider, prefer by network priority first, then by distance
    if provider_filter == 'SAFDSN':
        def sort_key(station):
            network = station.get('network', '')
            # Get network priority (higher priority networks get lower sort value)
            network_priority = NETWORK_PRIORITY.get(network, 999)
            # Secondary sort by distance
            return (network_priority, station['distance_km'])
        all_stations.sort(key=sort_key)
    else:
        # Default: sort by distance only
        all_stations.sort(key=lambda x: x['distance_km'])
    
    return all_stations[:max_stations]


def _find_nearby_stations(latitude: float, longitude: float, time: datetime, max_stations: int = 10, provider_filter: str = None) -> list[dict]:
    """Synchronous wrapper for finding nearby stations.
    
    Args:
        latitude: Earthquake latitude
        longitude: Earthquake longitude
        time: Earthquake time
        max_stations: Maximum number of stations to return
        provider_filter: If set, only query this specific provider (e.g., 'SAFDSN')
    """
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # If already in async context, create new loop
            return asyncio.run(_find_nearby_stations_async(latitude, longitude, time, max_stations, provider_filter))
        else:
            return loop.run_until_complete(_find_nearby_stations_async(latitude, longitude, time, max_stations, provider_filter))
    except Exception:
        return asyncio.run(_find_nearby_stations_async(latitude, longitude, time, max_stations, provider_filter))


async def _fetch_waveform_async(
    provider: str,
    station_info: dict,
    earthquake_time: datetime,
    duration_seconds: int = 360  # 6 minutes: 60s before + 300s after earthquake
) -> Tuple[Optional[Stream], str]:
    """Fetch waveform data from a single FDSN provider.
    
    Memory optimization: Reduced duration, simplified response removal, aggressive cleanup.
    
    Args:
        provider: FDSN provider name
        station_info: Station information dictionary
        earthquake_time: Time of the earthquake
        duration_seconds: Duration of waveform to fetch (default 300s = 5 min)
    
    Returns:
        Tuple of (stream, provider) or (None, provider) if failed
    """
    obspy = _get_obspy()
    if not obspy or not OBSPY_AVAILABLE:
        return None, provider
    
    UTCDateTime = _get_utc_datetime()
    Stream = _get_stream_class()
    if UTCDateTime is None or Stream is None:
        return None, provider
    
    try:
        client = get_client(provider)
        if not client:
            return None, provider
            
        print(f"[{provider}] Fetching waveform from {station_info['network']}.{station_info['station']}.{station_info['location']}.{station_info['channel']}...")
        
        # Time window: 60s before to 300s after (6 min total)
        start_time = UTCDateTime(earthquake_time - timedelta(seconds=60))
        end_time = UTCDateTime(earthquake_time + timedelta(seconds=duration_seconds - 60))
        
        channel_priority = ['BHZ', 'HHZ', 'SHZ']
        # Handle location code properly
        location = station_info.get('location')
        location_code = '--' if not location else location
        
        for channel in channel_priority:
            try:
                stream = client.get_waveforms(
                    network=station_info['network'],
                    station=station_info['station'],
                    location=location_code,
                    channel=channel,
                    starttime=start_time,
                    endtime=end_time,
                )
                if len(stream) > 0:
                    # Try to get response, but skip if it fails (saves memory)
                    try:
                        inv_client = get_client(provider)
                        if inv_client:
                            # Get station-level inventory (lighter than response)
                            inv_start = UTCDateTime(earthquake_time - timedelta(hours=1))
                            inv_end = UTCDateTime(earthquake_time + timedelta(hours=1))
                            
                            inv = inv_client.get_stations(
                                network=station_info['network'],
                                station=station_info['station'],
                                location=location_code,
                                channel=channel,
                                starttime=inv_start,
                                endtime=inv_end,
                                level="response",  # Use station level, not response
                            )
                            
                            if inv and len(inv) > 0:
                                print(f"[{provider}] Removing response from waveform...")
                                stream.remove_response(inv, taper=0.01)
                                stream.detrend('demean')
                                print(f"[{provider}] Response removed successfully")
                                # Clean up inventory
                                del inv
                    except Exception as resp_err:
                        print(f"[{provider}] Warning: Could not remove response: {resp_err}")
                    
                    print(f"[{provider}] SUCCESS: Got waveform data")
                    return stream, provider
            except Exception as e:
                error_str = str(e).lower()
                if 'no data' in error_str or 'nodata' in error_str or '404' in error_str:
                    continue
                print(f"[{provider}] Error for channel {channel}: {e}")
                continue
        
        print(f"[{provider}] No waveform data available")
        return None, provider
        
    except Exception as e:
        print(f"[{provider}] Error: {e}")
        return None, provider


def _fetch_waveform_data(
    station_info: dict,
    earthquake_time: datetime,
    duration_seconds: int = 360
) -> Tuple[Optional[Stream], str]:
    """Fetch waveform data using MassDownloader-style approach.
    
    First tries the station's HOME provider (the provider that hosts this station),
    then falls back to other providers. This ensures regional stations hosted by
    regional providers get their data from those providers before trying others.
    
    Args:
        station_info: Station information dictionary (must include 'provider' key)
        earthquake_time: Time of the earthquake
        duration_seconds: Duration of waveform to fetch
    
    Returns:
        Tuple of (stream, provider_used) or (None, None) if all fail
    """
    if not OBSPY_AVAILABLE:
        return None, None
    
    # Get the station's home provider (the provider that provided station info)
    home_provider = station_info.get('provider', 'IRIS')
    
    # Build provider priority: home provider first, then others
    providers_to_try = [home_provider]
    for p in ALL_PROVIDERS:
        if p != home_provider:
            providers_to_try.append(p)
    
    print(f"[Waveform] Trying providers in priority order: {providers_to_try[:4]}...")
    
    # Try providers sequentially - home provider first
    location_code = station_info.get('location', '--')
    channel_code = station_info.get('channel', 'N/A')
    for provider in providers_to_try:
        print(f"[Waveform] Trying provider: {provider} for {station_info['network']}.{station_info['station']}.{location_code}.{channel_code}")
        
        stream, result_provider = asyncio.run(
            _fetch_waveform_async(provider, station_info, earthquake_time, duration_seconds)
        )
        
        if stream and len(stream) > 0:
            print(f"[Waveform] SUCCESS via {provider}")
            return stream, provider
        
        print(f"[Waveform] No data from {provider} for {station_info['network']}.{station_info['station']}.{location_code}.{channel_code}, trying next provider...")
    
    print(f"[Waveform] All providers failed for {station_info['network']}.{station_info['station']}.{location_code}.{channel_code}")
    return None, None


def _generate_mock_waveform(earthquake: dict, duration_seconds: int = 360) -> list:
    """Generate simulated waveform data based on earthquake properties.
    
    Memory optimization: Reduced sample rate and duration for smaller memory footprint.
    """
    magnitude = earthquake.get('magnitude', 4.0)
    # Use lower sample rate to reduce memory (10 Hz instead of 20 Hz)
    sample_rate = 10
    num_samples = sample_rate * duration_seconds
    
    # Wave characteristics based on magnitude
    base_amplitude = magnitude * 0.3
    frequency = 1.0 + random.random() * 2
    
    # P-wave and S-wave arrival times
    p_wave_arrival = 2.0 + random.random() * 3
    s_wave_arrival = p_wave_arrival + 3.0 + random.random() * 5
    
    # Pre-calculate values to avoid repeated computation
    two_pi = 2 * math.pi
    
    samples = []
    samples_append = samples.append  # Local reference for speed
    
    for i in range(num_samples):
        time_seconds = i / sample_rate
        amplitude = 0.0
        
        # Background noise
        amplitude += (random.random() - 0.5) * 0.05
        
        # P-wave
        if time_seconds >= p_wave_arrival:
            p_progress = time_seconds - p_wave_arrival
            p_envelope = min(1, p_progress / 10) * math.exp(-max(0, p_progress - 10) / 10)
            amplitude += math.sin(two_pi * frequency * time_seconds) * base_amplitude * 0.3 * p_envelope
        
        # S-wave
        if time_seconds >= s_wave_arrival:
            s_progress = time_seconds - s_wave_arrival
            s_envelope = min(1, s_progress / 20) * math.exp(-max(0, s_progress - 20) / 10)
            amplitude += math.sin(two_pi * frequency * 0.8 * time_seconds) * base_amplitude * s_envelope
        
        # Surface waves
        if time_seconds >= s_wave_arrival + 5:
            surface_progress = time_seconds - s_wave_arrival - 5
            surface_envelope = min(1, surface_progress / 30) * math.exp(-max(0, surface_progress - 30) / 15)
            amplitude += math.sin(two_pi * frequency * 0.5 * time_seconds) * base_amplitude * 0.5 * surface_envelope
        
        samples_append({
            'time': time_seconds,
            'amplitude': amplitude,
        })
    
    return samples


def _apply_nyquist_filter(stream: Optional[Stream], channel: str = None, sample_rate: float = None) -> Optional[Stream]:
    """Apply appropriate bandpass filter based on channel and sample rate to prevent Nyquist aliasing.
    
    Memory optimization: Uses lazy loading for Obspy.
    
    Filter rules:
    - BHZ at 20 SPS: bandpass 1-9 Hz (Nyquist = 10 Hz)
    - 40 SPS: bandpass 1-15 Hz
    - HHZ at 100 SPS: bandpass 1-15 Hz
    
    Args:
        stream: Obspy Stream with waveform data
        channel: Channel code (e.g., 'BHZ', 'HHZ', 'SHZ')
        sample_rate: Sample rate in samples per second (SPS)
    
    Returns:
        Filtered stream, or original stream if filtering not applicable.
    """
    if not stream or len(stream) == 0:
        return stream
    
    obspy = _get_obspy()
    if not obspy or not OBSPY_AVAILABLE:
        return stream
    
    try:
        # Determine sample rate from stream if not provided
        if sample_rate is None and len(stream) > 0:
            sample_rate = stream[0].stats.sampling_rate
        
        if sample_rate is None or sample_rate <= 0:
            return stream
        
        # Determine channel from stream if not provided
        if channel is None and len(stream) > 0:
            channel = stream[0].stats.channel
        
        # Calculate Nyquist frequency
        nyquist = sample_rate / 2.0
        
        # Determine filter parameters based on channel and sample rate
        freqmin = 1.0
        freqmax = None
        
        # Check if this is a BHZ channel at 20 SPS
        if channel and channel.startswith('BH') and sample_rate == 20:
            # BHZ at 20 SPS: bandpass 1-9 Hz (stay below Nyquist of 10 Hz)
            freqmin = 1.0
            freqmax = 9.0
            print(f"[Filter] BHZ at 20 SPS: applying bandpass {freqmin}-{freqmax} Hz (Nyquist={nyquist} Hz)")
        # Check for 40 SPS (any channel)
        elif sample_rate == 40:
            # 40 SPS: bandpass 1-15 Hz
            freqmin = 1.0
            freqmax = 19.0
            print(f"[Filter] 40 SPS: applying bandpass {freqmin}-{freqmax} Hz (Nyquist={nyquist} Hz)")
        # Check for HHZ/HHZ at 100 SPS
        elif channel and channel.startswith('HH') and sample_rate >= 100:
            # HHZ at 100 SPS: bandpass 1-15 Hz
            freqmin = 1.0
            freqmax = 49.0
            print(f"[Filter] HHZ at {sample_rate} SPS: applying bandpass {freqmin}-{freqmax} Hz (Nyquist={nyquist} Hz)")
        else:
            # Default: apply a safe bandpass based on Nyquist
            # Use 80% of Nyquist as upper limit to be safe
            freqmax = nyquist * 0.8
            if freqmax < freqmin:
                # Sample rate too low, skip filtering
                print(f"[Filter] Sample rate {sample_rate} too low for filtering (Nyquist={nyquist} Hz)")
                return stream
            print(f"[Filter] Default: applying bandpass {freqmin}-{freqmax:.1f} Hz (Nyquist={nyquist} Hz)")
        
        # Ensure freqmax doesn't exceed Nyquist
        if freqmax is not None and freqmax >= nyquist:
            freqmax = nyquist * 0.9
            print(f"[Filter] Adjusted freqmax to {freqmax:.1f} Hz to stay below Nyquist")
        
        # Apply bandpass filter with zero-phase filtering
        # Using zerophase=True and corner=4 for smoother filter response
        stream.filter('BANDPASS', freqmin=freqmin, freqmax=freqmax, zerophase=True, corners=4)
        print(f"[Filter] Applied bandpass filter: {freqmin}-{freqmax} Hz")
        
        return stream
        
    except Exception as e:
        print(f"[Filter] Error applying filter: {e}")
        return stream


def _create_waveform_audio(
    stream: Optional[Stream],
    earthquake: dict,
    mock_samples: Optional[list] = None,
    speed_factor: float = 100.0  # Increased to reduce memory usage (faster = fewer samples)
) -> str:
    """Create WAV audio from waveform data using Obspy.
    
    Memory optimization: Higher speed factor reduces sample count, simpler processing.
    
    Args:
        stream: Obspy Stream with waveform data
        earthquake: Earthquake info dict
        mock_samples: Fallback mock sample data
        speed_factor: Speed factor for playback (higher = faster, fewer samples)
    
    Returns:
        Base64 encoded WAV file.
    """
    obspy = _get_obspy()
    np_local = _get_numpy()
    
    if not obspy or not OBSPY_AVAILABLE or not np_local:
        return ""
    
    try:
        ObsStream = _get_stream_class()
        Trace = _get_trace_class()
        UTCDateTime = _get_utc_datetime()
        
        if ObsStream is None or Trace is None or UTCDateTime is None:
            return ""
        # Create a working stream
        audio_stream = ObsStream()
        
        # Use lower sample rate to reduce memory (22kHz is still CD quality)
        audio_sample_rate = 22050
        
        if stream and len(stream) > 0:
            # Process real data from Obspy
            # Use trim instead of full copy to save memory
            work_stream = stream.copy()
            work_stream.merge(fill_value=0)
            
            # Downsample more aggressively to reduce memory
            work_stream.interpolate(sampling_rate=audio_sample_rate / speed_factor)
            
            # Get the first trace
            trace = work_stream[0]
            
            # Ensure we have data - trim to max 60 seconds to limit memory
            if len(trace.data) > 0:
                # Limit to 360 seconds max (6 minutes of audio)
                max_samples = int(360 * audio_sample_rate / speed_factor)
                if len(trace.data) > max_samples:
                    trace.data = trace.data[:max_samples]
                
                trace.stats.sampling_rate = audio_sample_rate
                audio_stream.append(trace)
            
            # Clean up
            del work_stream
                
        elif mock_samples:
            # Generate audio from mock samples
            # Use lower sample rate for mock data too
            times = np_local.array([s['time'] for s in mock_samples])
            amplitudes = np_local.array([s['amplitude'] for s in mock_samples])
            
            # Resample to audio rate using linear interpolation (faster than cubic)
            duration = times[-1] - times[0]
            # Limit to 360 seconds max (6 minutes)
            duration = min(duration, 360)
            new_times = np_local.linspace(0, duration, int(duration * audio_sample_rate))
            
            # Use linear interpolation (faster and uses less memory)
            from scipy import interpolate
            interp_func = interpolate.interp1d(times, amplitudes, kind='linear', fill_value=0, bounds_error=False)
            new_amplitudes = interp_func(new_times)
            
            # Normalize to prevent clipping
            max_amp = np_local.max(np_local.abs(new_amplitudes))
            if max_amp > 0:
                new_amplitudes = new_amplitudes / max_amp * 0.8
            
            # Create trace
            trace = Trace(data=new_amplitudes.astype(np_local.float32))
            trace.stats.sampling_rate = audio_sample_rate
            trace.stats.starttime = UTCDateTime(0)
            audio_stream.append(trace)
        
        if len(audio_stream) == 0:
            return ""
        
        # Write to a temporary file
        import tempfile
        import os
        
        try:
            tmp_path = tempfile.mktemp(suffix='.wav')
            
            # Write WAV with lower sample rate
            audio_stream.write(tmp_path, format='WAV', width=2, rescale=True, framerate=audio_sample_rate)
            
            # Read the file and encode as base64
            with open(tmp_path, 'rb') as f:
                audio_base64 = base64.b64encode(f.read()).decode('utf-8')
            
            # Clean up temp file
            os.unlink(tmp_path)
            
            # Aggressive cleanup
            del audio_stream
            gc.collect()
            
            return audio_base64
        except Exception as e:
            print(f"Error writing WAV file: {e}")
            if 'tmp_path' in locals() and os.path.exists(tmp_path):
                try:
                    os.unlink(tmp_path)
                except:
                    pass
            return ""
        
    except Exception as e:
        print(f"Error creating audio: {e}")
        return ""


def _create_waveform_plot(
    stream: Optional[Stream],
    earthquake: dict,
    station_info: Optional[dict],
    mock_samples: Optional[list] = None
) -> str:
    """Create a waveform plot and return as base64 encoded PNG.
    
    Memory optimization: Lower resolution, smaller figure, aggressive cleanup.
    """
    # Try to ensure matplotlib is loaded - don't rely on cached availability flag
    if not MATPLOTLIB_AVAILABLE:
        matplotlib = _get_matplotlib()
        if matplotlib is None:
            print("[Plot] Matplotlib not available, cannot generate plot")
            return ""
    
    # Now try to import pyplot specifically
    plt = None
    try:
        from matplotlib import pyplot as plt
    except ImportError as e:
        print(f"[Plot] Failed to import pyplot: {e}")
        return ""
    
    if plt is None:
        print("[Plot] pyplot is None, cannot generate plot")
        return ""
    
    try:
        print("[Plot] Starting waveform plot generation...")
        
        # Use smaller figure size and lower DPI to reduce memory
        fig, ax = plt.subplots(figsize=(10, 4), dpi=72)  # Reduced from 14x6 @100
        
        # Time range: 60 seconds before to 300 seconds after earthquake (6 min total)
        eq_time = 60  # Earthquake marker at 60 seconds
        
        if stream and len(stream) > 0:
            # Process real data from Obspy
            work_stream = stream.copy()
            work_stream.merge(fill_value=0)
            
            # Get the data
            trace = work_stream[0]
            times = trace.times()
            data = trace.data
            
            # Downsample for plotting if too many points (saves memory)
            if len(data) > 5000:
                # Simple decimation for plotting
                step = len(data) // 5000
                times = times[::step]
                data = data[::step]
            
            # Normalize data
            if len(data) > 0:
                np_local = _get_numpy()
                if NUMPY_AVAILABLE and np_local is not None:
                    max_amp = max(abs(np_local.min(data)), abs(np_local.max(data)))
                else:
                    max_amp = max(abs(min(data)), abs(max(data)))
                if max_amp > 0:
                    data = data / max_amp * 5
            
            ax.plot(times, data, 'b-', linewidth=0.5, alpha=0.8)
            
            # Clean up
            del work_stream, trace, times, data
            
        elif mock_samples:
            # Use mock data
            times = [s['time'] for s in mock_samples]
            data = [s['amplitude'] for s in mock_samples]
            ax.plot(times, data, 'b-', linewidth=0.5, alpha=0.8)
            
        else:
            # No data available
            ax.text(0.5, 0.5, 'No waveform data available',
                   transform=ax.transAxes, ha='center', va='center',
                   fontsize=14, color='gray')
            ax.set_xlim(0, 300)
        
        # Add earthquake time marker (at 60 seconds)
        ax.axvline(x=eq_time, color='red', linestyle='--', linewidth=2, alpha=0.8)
        ax.text(eq_time + 2, ax.get_ylim()[1] * 0.9 if ax.get_ylim()[1] != 0 else 1, 'Earthquake',
               color='red', fontsize=10, fontweight='bold')
        
        # Formatting
        ax.set_xlabel('Time (seconds)', fontsize=11)
        ax.set_ylabel('Amplitude (normalized)', fontsize=11)
        ax.set_xlim(0, 360)  # 6 minutes total
        ax.grid(True, alpha=0.3)
        ax.axhline(y=0, color='black', linewidth=0.5)
        
        # Title with earthquake info
        magnitude = earthquake.get('magnitude', 'N/A')
        place = earthquake.get('place', 'Unknown location')
        ax.set_title(f'Seismogram - M{magnitude} {place}', fontsize=12, fontweight='bold')
        
        # Add station info if available
        if station_info:
            station_text = f"Station: {station_info['network']}.{station_info['station']}"
            distance_text = f"Distance: {station_info.get('distance_km', 0):.1f} km"
            info_text = f"{station_text} | {distance_text}"
            ax.text(0.01, 0.02, info_text, transform=ax.transAxes,
                   fontsize=8, verticalalignment='bottom',
                   bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
        
        plt.tight_layout()
        
        # Convert to base64 with lower quality
        buf = io.BytesIO()
        plt.savefig(buf, format='png', bbox_inches='tight', dpi=72)  # Lower DPI
        buf.seek(0)
        image_base64 = base64.b64encode(buf.read()).decode('utf-8')
        
        print(f"[Plot] Successfully generated plot, {len(image_base64)} bytes")
        
        # Clean up matplotlib resources
        plt.close(fig)
        del buf, fig, ax
        gc.collect()
        
        return image_base64
        
    except Exception as e:
        import traceback
        print(f"[Plot] Error creating plot: {e}")
        print(f"[Plot] Traceback: {traceback.format_exc()}")
        return ""


@https_fn.on_request()
def health(req: https_fn.Request) -> https_fn.Response:
    """Health check endpoint."""
    # Check actual availability by attempting lazy load
    obspy = _get_obspy()
    matplotlib = _get_matplotlib()
    numpy = _get_numpy()
    
    return https_fn.Response(
        json.dumps({
            "status": "ok",
            "obspy_available": OBSPY_AVAILABLE,
            "matplotlib_available": MATPLOTLIB_AVAILABLE,
            "numpy_available": NUMPY_AVAILABLE,
        }),
        mimetype="application/json"
    )


@https_fn.on_request()
def waveform(req: https_fn.Request) -> https_fn.Response:
    """
    Generate waveform plot for an earthquake.
    
    Expected request body:
    {
        "earthquake": {
            "id": "...",
            "magnitude": 4.5,
            "latitude": 34.0522,
            "longitude": -118.2437,
            "time": "2024-01-15T10:30:00Z",
            "place": "Los Angeles, CA"
        },
        "options": {
            "apply_filter": true,
            "filter_type": "bandpass",
            "freqmin": 0.5,
            "freqmax": 10.0
        }
    }
    
    Response:
    {
        "image": "base64_encoded_png...",
        "station": {...},
        "is_mock_data": false,
        "error_message": null,
        "samples": [...]  // Optional: raw samples for fallback
    }
    """
    try:
        # Parse request body
        if req.method != "POST":
            return https_fn.Response(
                json.dumps({"error": "Method not allowed"}),
                status=405,
                mimetype="application/json"
            )
        
        body = req.get_json(silent=True)
        if not body:
            return https_fn.Response(
                json.dumps({"error": "Invalid JSON body"}),
                status=400,
                mimetype="application/json"
            )
        
        earthquake = body.get('earthquake', {})
        options = body.get('options', {})
        
        # Validate required fields
        required_fields = ['latitude', 'longitude', 'time']
        for field in required_fields:
            if field not in earthquake:
                return https_fn.Response(
                    json.dumps({"error": f"Missing required field: {field}"}),
                    status=400,
                    mimetype="application/json"
                )
        
        # Parse earthquake time
        eq_time_str = earthquake['time']
        if isinstance(eq_time_str, str):
            eq_time = datetime.fromisoformat(eq_time_str.replace('Z', '+00:00'))
        else:
            eq_time = datetime.utcnow()
        
        # Find nearby stations
        # For South African region (lat -25 to -35, lon 16-33), try SAFDSN provider first
        # since many CGS stations are not accessible via other providers
        latitude = earthquake['latitude']
        longitude = earthquake['longitude']
        
        # Check if earthquake is in South African region
        is_south_africa = -35 <= latitude <= 16 and 16 <= longitude <= 33
        
        if is_south_africa:
            print("Earthquake in South Africa region, trying SAFDSN provider first...")
            # First, try SAFDSN with more stations (many CGS stations may not be accessible)
            safdsn_stations = _find_nearby_stations(
                latitude,
                longitude,
                eq_time,
                max_stations=10,  # Try more stations since many may be inaccessible
                provider_filter='SAFDSN'
            )
            
            if safdsn_stations:
                print(f"Found {len(safdsn_stations)} stations from SAFDSN provider")
                stations = safdsn_stations
            else:
                # No stations from SAFDSN, try all providers
                print("No stations from SAFDSN, trying all providers...")
                stations = _find_nearby_stations(latitude, longitude, eq_time, max_stations=10)
        else:
            # Default: query all providers
            stations = _find_nearby_stations(latitude, longitude, eq_time)
        
        station_info = None
        stream = None
        is_mock_data = False
        error_message = None
        samples = []
        
        if stations:
            # Try each station until we get waveform data (with provider fallback)
            # For SAFDSN, we iterate through ALL stations in radius since many CGS stations are not accessible
            for i, station in enumerate(stations):
                network = station.get('network', '')
                station_code = station.get('station', '')
                distance = station.get('distance_km', 0)
                provider = station.get('provider', '')
                
                print(f"Station {i+1}/{len(stations)}: {network}.{station_code} at {distance:.1f}km (provider: {provider})")
                
                # Use the fallback function that tries multiple providers
                stream, provider_used = _fetch_waveform_data(station, eq_time)
                
                if stream and len(stream) > 0:
                    station_info = station
                    station_info['data_provider'] = provider_used  # Track which provider gave us data
                    print(f"[+] SUCCESS: Found waveform data at {network}.{station_code} via {provider_used}")
                    break
                print(f"[-] No waveform data at {network}.{station_code}, trying next station...")
            
            if not stream:
                # No waveform data found, use mock
                print("No waveform data available from any station, using mock data")
                is_mock_data = True
                error_message = "No waveform data available from nearby stations"
                station_info = stations[0] if stations else None
        else:
            # No stations found - try using station lookup from each provider
            print("No stations found from primary query, trying fallback providers...")
            
            # Try to find stations using each FDSN provider as fallback (including custom)
            UTCDateTime = _get_utc_datetime()
            for provider in ALL_PROVIDERS:
                try:
                    client = get_client(provider)
                    if not client or UTCDateTime is None:
                        continue
                        
                    start_time = UTCDateTime(eq_time - timedelta(days=1))
                    end_time = UTCDateTime(eq_time + timedelta(days=1))
                    
                    inventory = client.get_stations(
                        latitude=earthquake['latitude'],
                        longitude=earthquake['longitude'],
                        maxradius=3.0,
                        starttime=start_time,
                        endtime=end_time,
                        level="channel",
                        channel="BH*,HH*,SH*",
                    )
                    
                    # Found stations from fallback provider
                    fallback_stations = []
                    for network in inventory:
                        for station in network:
                            distance = _calculate_distance(
                                earthquake['latitude'], earthquake['longitude'],
                                station.latitude, station.longitude
                            )
                            best_channel = None
                            for channel in station:
                                if channel.code.endswith('Z'):
                                    best_channel = channel
                                    break
                            if best_channel is None and len(station) > 0:
                                best_channel = station[0]
                            
                            fallback_stations.append({
                                'network': network.code,
                                'station': station.code,
                                'latitude': station.latitude,
                                'longitude': station.longitude,
                                'elevation': station.elevation,
                                'distance_km': distance,
                                'channel': best_channel.code if best_channel else None,
                                'location': best_channel.location_code if best_channel else None,
                                'sample_rate': best_channel.sample_rate if best_channel else None,
                                'provider': provider,
                            })
                    
                    if fallback_stations:
                        fallback_stations.sort(key=lambda x: x['distance_km'])
                        print(f"Found {len(fallback_stations)} stations from {provider}")
                        
                        # Try each fallback station
                        for station in fallback_stations[:10]:
                            stream, provider_used = _fetch_waveform_data(station, eq_time)
                            if stream and len(stream) > 0:
                                station_info = station
                                station_info['data_provider'] = provider_used
                                print(f"Got waveform from fallback: {station['network']}.{station['station']} via {provider_used}")
                                break
                        
                        if stream:
                            break
                            
                except Exception as e:
                    print(f"Fallback provider {provider} failed: {e}")
                    continue
            
            if not stream:
                print("No nearby stations found from any FDSN provider")
                is_mock_data = True
                error_message = "No nearby seismic stations found"
        
        # Generate mock samples for fallback display
        if is_mock_data or not stream:
            samples = _generate_mock_waveform(earthquake)
        
        # Apply Nyquist filter to stream if we have real data
        if stream and len(stream) > 0 and not is_mock_data:
            # Get channel and sample rate from station_info if available
            channel = station_info.get('channel') if station_info else None
            sample_rate = station_info.get('sample_rate') if station_info else None
            stream = _apply_nyquist_filter(stream, channel, sample_rate)
        
        # Create the waveform plot
        image_base64 = _create_waveform_plot(stream, earthquake, station_info, samples)
        
        # Generate WAV audio from the waveform data BEFORE cleaning up the stream
        audio_base64 = _create_waveform_audio(stream, earthquake, samples)
        
        # Clean up stream after audio generation to free memory
        if stream and len(stream) > 0:
            del stream
        gc.collect()
        
        if not image_base64:
            # Matplotlib not available, return mock samples instead
            is_mock_data = True
            error_message = "Plot generation failed, returning raw samples"
        has_audio = audio_base64 is not None and len(audio_base64) > 0
        
        if has_audio:
            print(f"Generated audio: {len(audio_base64)} bytes (base64)")
        else:
            print("Failed to generate audio")
        
        response_data = {
            "image": image_base64,
            "audio": audio_base64 if has_audio else "",
            "station": station_info,
            "is_mock_data": is_mock_data,
            "error_message": error_message,
            "samples": samples if not image_base64 else [],  # Include samples if no image
        }
        
        return https_fn.Response(
            json.dumps(response_data),
            mimetype="application/json"
        )
        
    except Exception as e:
        print(f"Error in waveform function: {e}")
        return https_fn.Response(
            json.dumps({
                "error": str(e),
                "is_mock_data": True,
                "image": "",
                "samples": [],
            }),
            status=500,
            mimetype="application/json"
        )



