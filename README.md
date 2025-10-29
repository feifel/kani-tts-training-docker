# Speech Slicer
A Dockerized Speech Processing Application. You can provide an audio file as input and it will split the audio file into chunks of max 5 seconds, optimized to fine tune TTS models. It also does STT to provide a metadata.csv file that contains the text for each of the generated audio chunks.

## How slicing is done
1. Split the audio on silent passages that are > 500ms
2. For chunks that are still longer than 5s use the longest silent passage to split the chunk further until no chunk is longer than 500ms, make sure that silence passages on the start and the end of each chunk is reduced to 100ms

## Build image
```bash
docker build -t speech-slicer:latest .
```

## Create container (one-time setup)
```bash
docker create -it --gpus all --name speech-slicer \
  -v hf_cache:/root/.cache/huggingface \
  -v "$(pwd)":/workspace \
  --workdir /workspace \
  speech-slicer:latest bash
```

## Start the container 
```bash
docker start -ai speech-slicer
```

## Split the audio files you want
Note: the first time it will download a 3 GByte LLM
```bash
cd kani-tts-training-wave2dataset
source "venv/bin/activate"
python chunk_and_transcribe.py \
  -i in/in.wav \
  -o out \
  --silence_duration 0.5 \
  --max_chunk_duration 5.0 \
  --model large-v3 \
  --device cuda \
  --format csv \
  --language de \
  --speaker Linda

python create_hf_dataset.py Linda
```

## Convert the dataset into a nano dataset
```bash
cd kani-tts-training-dataset2nano
source "venv/bin/activate"
python main.py
```

## Exit the terminal when done
```bash
exit
```

## Delete the container when needed
```bash
docker rm speech-slicer 
```

## Delete the image when needed
```bash
docker rmi speech-slicer:latest
```

## TODO
- test kani-tts-training-wave2dataset
- test kani-tts-training-dataset2nano
- add usage of kani-tts-training-finetune