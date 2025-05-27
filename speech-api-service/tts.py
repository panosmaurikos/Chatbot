from elevenlabs.client import ElevenLabs


elevenlabs = ElevenLabs(
    api_key="your_elevenlabs_api_key_here" 
)

# Μετατροπή κειμένου σε ήχο
audio = elevenlabs.text_to_speech.convert(
    text="your_text_here", 
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    model_id="eleven_multilingual_v2",
    output_format="mp3_44100_128",
)

# Αποθήκευση σε αρχείο
with open("output.mp3", "wb") as f:
    for chunk in audio:
        f.write(chunk)

print("Save the file output.mp3")