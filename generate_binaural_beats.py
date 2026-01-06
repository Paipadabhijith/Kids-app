#!/usr/bin/env python3
"""
Binaural Beats Generator
Generates alpha (10Hz) and theta (6Hz) binaural beats audio files
"""

import numpy as np
import os
from pathlib import Path

try:
    from scipy.io import wavfile
    HAS_LIBRARIES = True
except ImportError:
    HAS_LIBRARIES = False
    print("Required libraries not found. Installing...")

def install_requirements():
    """Install required Python packages"""
    import subprocess
    import sys
    
    packages = ['numpy', 'scipy']
    for package in packages:
        print(f"Installing {package}...")
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', package, '--quiet'])

if not HAS_LIBRARIES:
    install_requirements()
    from scipy.io import wavfile

def generate_binaural_beat(carrier_freq, beat_freq, duration_seconds=600, sample_rate=44100, volume=0.3):
    """
    Generate binaural beat audio
    
    Args:
        carrier_freq: Base frequency (Hz) - typically 200 Hz
        beat_freq: Beat frequency (Hz) - difference between left and right
        duration_seconds: Length of audio in seconds
        sample_rate: Audio sample rate (Hz)
        volume: Amplitude (0.0 to 1.0)
    
    Returns:
        numpy array of stereo audio samples
    """
    # Calculate left and right frequencies
    left_freq = carrier_freq - (beat_freq / 2)
    right_freq = carrier_freq + (beat_freq / 2)
    
    # Generate time array
    t = np.linspace(0, duration_seconds, int(sample_rate * duration_seconds), False)
    
    # Generate sine waves for left and right channels
    left_channel = np.sin(2 * np.pi * left_freq * t) * volume
    right_channel = np.sin(2 * np.pi * right_freq * t) * volume
    
    # Apply fade in/out for smooth looping
    fade_samples = int(sample_rate * 2)  # 2 second fade
    fade_in = np.linspace(0, 1, fade_samples)
    fade_out = np.linspace(1, 0, fade_samples)
    
    # Apply fades
    left_channel[:fade_samples] *= fade_in
    left_channel[-fade_samples:] *= fade_out
    right_channel[:fade_samples] *= fade_in
    right_channel[-fade_samples:] *= fade_out
    
    # Combine into stereo array
    stereo_audio = np.column_stack((left_channel, right_channel))
    
    # Normalize to prevent clipping
    max_val = np.max(np.abs(stereo_audio))
    if max_val > 0:
        stereo_audio = stereo_audio / max_val * 0.8  # Keep at 80% to avoid clipping
    
    return stereo_audio

def save_as_wav(audio_array, output_path, sample_rate=44100):
    """
    Save numpy array as WAV file (works without ffmpeg)
    
    Args:
        audio_array: Stereo numpy array
        output_path: Output file path (will be saved as .wav)
        sample_rate: Sample rate in Hz
    """
    # Convert to 16-bit PCM
    audio_int16 = (audio_array * 32767).astype(np.int16)
    
    # Save as WAV
    wavfile.write(str(output_path), sample_rate, audio_int16)
    
    print(f"[OK] Created {output_path}")

def main():
    """Generate both binaural beat files"""
    # Get the assets/audio directory
    script_dir = Path(__file__).parent
    audio_dir = script_dir / "assets" / "audio"
    
    # Create directory if it doesn't exist
    audio_dir.mkdir(parents=True, exist_ok=True)
    
    print("Generating binaural beats audio files...")
    print(f"Output directory: {audio_dir}")
    print()
    
    # Generate Alpha 10Hz (for calm focus)
    print("Generating Alpha 10Hz (calm focus)...")
    alpha_audio = generate_binaural_beat(
        carrier_freq=200.0,
        beat_freq=10.0,
        duration_seconds=600,  # 10 minutes
        volume=0.3
    )
    alpha_path = audio_dir / "alpha_10hz.wav"
    save_as_wav(alpha_audio, alpha_path)
    
    # Generate Theta 6Hz (for wind-down)
    print("Generating Theta 6Hz (wind-down)...")
    theta_audio = generate_binaural_beat(
        carrier_freq=200.0,
        beat_freq=6.0,
        duration_seconds=600,  # 10 minutes
        volume=0.3
    )
    theta_path = audio_dir / "theta_6hz.wav"
    save_as_wav(theta_audio, theta_path)
    
    print()
    print("=" * 50)
    print("[SUCCESS] Successfully generated both audio files!")
    print(f"  - {alpha_path}")
    print(f"  - {theta_path}")
    print("=" * 50)
    print()
    print("Files are ready to use in your app!")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure Python is installed")
        print("2. Run: pip install numpy scipy")
        raise

