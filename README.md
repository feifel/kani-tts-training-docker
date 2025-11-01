# kani tts training
This docker project contains everything for kani tts training, which is needed to add custom voices for kani tts. You can provide a large audio speech as wave file as input and it will split the audio file into chunks of max 5 seconds, optimized to fine tune TTS models. It also does STT to provide a metadata.csv file that contains the transcription for each of the generated audio chunks. 
In a second step you then convert those chunks into a huggingface dataset file. 
In the third step you then convert that dataset to a nano dataset, which is a special encoding that makes kani-tts very fast and minimize the delay in TTS generation.
The last step is the fine-tuning step that creates the final model, that can be used by kani tts for inference, i.e. convert text to speech (TTS).

## How slicing is done
1. Split the audio on silent passages that are > 500ms
2. For chunks that are still longer than 5s use the longest silent passage to split the chunk further until no chunk is longer than 5s, make sure that silence passages on the start and the end of each chunk is reduced to 100ms

## Build image
```bash
docker build -t kani-tts-training:latest .
```

## Create container (one-time setup)
```bash
docker create -it --gpus all --name kani-tts-training \
  -v "$(pwd)/data":/data \
  -v "$(pwd)/models":/root/.cache/huggingface \
  kani-tts-training:latest
```

## Start the container 
```bash
docker start -ai kani-tts-training
```

## Split the audio files you want
Note: the first time it will download a 3 GByte LLM
```bash
mkdir -p /data/0-source-audio
cd /workspace/1-audio-to-dataset
source "venv/bin/activate"
python chunk_and_transcribe.py \
  -i /data/0-source-audio/Linda.wav \
  -o /data/1-audio-chunks/Linda \
  --silence_duration 0.5 \
  --max_chunk_duration 5.0 \
  --model large-v3 \
  --device cuda \
  --format csv \
  --language de \
  --speaker Linda

python create_hf_dataset.py -i /data/1-audio-chunks/Linda -o /data/2-base-datasets/Linda
```



## Convert the dataset into a nano dataset
```bash
cd /workspace/2-dataset-to-nano
source "venv/bin/activate"
# edit the config.yaml
python main.py
```

## Exit the terminal when done
```bash
exit
```

## Delete the container when needed
```bash
docker rm kani-tts-training
```

## Delete the image when needed
```bash
docker rmi kani-tts-training:latest
```

## TODO
- test kani-tts-training-wave2dataset
- test kani-tts-training-dataset2nano
- add usage of kani-tts-training-finetune

