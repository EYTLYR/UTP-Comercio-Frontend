import wave
import struct
import math
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
os.makedirs(OUTPUT_DIR, exist_ok=True)
SAMPLE_RATE = 44100

def write_wav(filename, samples, sample_rate=SAMPLE_RATE):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)  # mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        # convert float samples (-1.0 to 1.0) to 16-bit PCM
        raw_data = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            raw_data.extend(struct.pack("<h", val))
        wav_file.writeframes(raw_data)
    print(f"Generated {filename} ({len(samples)/sample_rate:.2f}s)")

def generate_dialing():
    # Ringback tone: 440Hz + 480Hz tone for 1.8 seconds, followed by 2.2 seconds of silence (total 4.0s)
    total_sec = 4.0
    tone_sec = 1.8
    total_samples = int(SAMPLE_RATE * total_sec)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        if t < tone_sec:
            # envelope to prevent click at start and end
            fade_in = min(1.0, t / 0.05)
            fade_out = min(1.0, (tone_sec - t) / 0.05)
            env = fade_in * fade_out
            val = (0.5 * math.sin(2 * math.pi * 440 * t) + 0.5 * math.sin(2 * math.pi * 480 * t)) * 0.4 * env
            samples.append(val)
        else:
            samples.append(0.0)
    write_wav("call_dialing.wav", samples)

def generate_ringtone():
    # Pleasant musical chime sequence for incoming call:
    # Pentatonic melody: E5 (659.25), G#5 (830.61), B5 (987.77), E6 (1318.51)
    notes = [
        (659.25, 0.0, 0.35),
        (830.61, 0.25, 0.35),
        (987.77, 0.50, 0.45),
        (1318.51, 0.85, 0.65),
        (987.77, 1.40, 0.35),
        (1318.51, 1.65, 0.80),
        # second phrase
        (830.61, 2.40, 0.35),
        (987.77, 2.65, 0.35),
        (1318.51, 2.90, 0.45),
        (1661.22, 3.25, 0.90),
    ]
    total_sec = 4.5
    total_samples = int(SAMPLE_RATE * total_sec)
    samples = [0.0] * total_samples

    for freq, start_time, dur in notes:
        start_idx = int(start_time * SAMPLE_RATE)
        dur_samples = int(dur * SAMPLE_RATE)
        for i in range(dur_samples):
            idx = start_idx + i
            if idx >= total_samples:
                break
            t = i / SAMPLE_RATE
            # Perceptual bell/marimba decay: rapid attack, exponential decay + harmonic
            env = math.exp(-4.5 * t)
            # fundamental + octave overtone
            tone = (math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(2 * math.pi * freq * 2 * t) + 0.15 * math.sin(2 * math.pi * freq * 3 * t))
            samples[idx] += tone * env * 0.35

    write_wav("call_ringtone.wav", samples)

def generate_call_ended():
    # Three short descending beeps: 480Hz, 440Hz, 400Hz (0.12s on, 0.08s off)
    samples = []
    freqs = [480, 440, 400]
    for freq in freqs:
        # Beep
        beep_samples = int(0.12 * SAMPLE_RATE)
        for i in range(beep_samples):
            t = i / SAMPLE_RATE
            fade = min(1.0, i / (0.01 * SAMPLE_RATE)) * min(1.0, (beep_samples - i) / (0.01 * SAMPLE_RATE))
            val = math.sin(2 * math.pi * freq * t) * 0.4 * fade
            samples.append(val)
        # Silence
        silence_samples = int(0.08 * SAMPLE_RATE)
        samples.extend([0.0] * silence_samples)
    write_wav("call_ended.wav", samples)

def generate_sos_alarm():
    # Emergency Siren: Alternating high/low tone with aggressive presence (780Hz <-> 1040Hz)
    total_sec = 3.0
    total_samples = int(SAMPLE_RATE * total_sec)
    samples = []
    period = 0.5  # cycle every 0.5s
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        cycle_pos = (t % period) / period
        # European ambulance style siren
        freq = 780 if cycle_pos < 0.5 else 1040
        # Add a rich square-sine overtone for urgency
        harmonic = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
        samples.append(harmonic * 0.45)
    write_wav("sos_alarm.wav", samples)

def generate_sos_countdown():
    # Distinct punchy warning pulse (1000Hz beep with quick decay)
    dur = 0.15
    total_samples = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-18 * t)
        val = math.sin(2 * math.pi * 1050 * t) * env * 0.5
        samples.append(val)
    write_wav("sos_countdown.wav", samples)

def generate_message_pop():
    # Modern clean UI notification bubble
    dur = 0.12
    total_samples = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Frequency chirp 800Hz -> 1300Hz
        freq = 800 + (1300 - 800) * (t / dur)
        env = math.sin(math.pi * (t / dur)) ** 1.5
        val = math.sin(2 * math.pi * freq * t) * env * 0.4
        samples.append(val)
    write_wav("message_pop.wav", samples)

if __name__ == "__main__":
    generate_dialing()
    generate_ringtone()
    generate_call_ended()
    generate_sos_alarm()
    generate_sos_countdown()
    generate_message_pop()
    print("All sounds generated successfully!")
