# kani tts training
This docker project contains everything for kani tts finetuning, which is needed to add custom voices for kani tts. To build your custom voice, you need a large audio speech file of 30-90 Minutes. That file than can be processed in 4 steps to build a custom voice:
1. The large audio speech as wave file is split into chunks of max 5 seconds, optimized to fine tune TTS models. It also does STT to provide a metadata.csv file that contains the transcription for each of the generated audio chunks. 
2. Convert those chunks into a huggingface dataset file
3. Convert that dataset to a nano dataset, which is a special encoding that makes kani-tts very fast and minimize the delay in TTS generation.
4. Run the actual fine-tuning step that creates the final model, that can be used by kani tts for inference, i.e. convert text to speech (TTS).

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

## 1. Split the audio files you want
**Prerequisite**: Ensure the audio file is placed in /data/0-source-audio
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
```
**Output**: Subfolder with your speakers name in /data/1-audio-chunks/<speaker>

## 2. Create the base dataset
**Prerequisite**: audio junks and manifest.csv in /data/1-audio-chunks/<speaker>
```bash
python create_base_dataset.py Linda
```
**Output**: nano dataset in /data/2-base-datasets/<speaker>

## 3. Convert the dataset into a nano dataset
**Prerequisites**: base dataset must be in /data/2-base-datasets/<speaker>
```bash
cd /workspace/2-dataset-to-nano
source "venv/bin/activate"
# befor run the next command, edit the config.yaml for your needs
python main.py
```
**Output**: nano dataset in /data/3-nano-datasets/<speaker>

## 4. Convert the nano dataset into a kani-tts-model
**Prerequisite**: nano dataset must be in /data/3-nano-datasets/<speaker>
```bash
cd /workspace/3-nano-to-kanitts
make login
# befor run the next command, edit the following config files:
# - dataset_config.yaml
# - experiments.yaml
make train
```
**Output**: /data/4-kani-tts-models/<speaker>

## 5. Test the new kani-tts-model
**Prerequisite**: Ensure the kani-tts-model is available in /data/4-kani-tts-models/<speaker>
```bash
cd /workspace/3-test-kanitts
make eval
```
**Output**: /data/5-kani-tts-output/<speaker>

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

# Modify the individual projects 
In case you want to modify the individual projects that are part of this docker file, then this section is for you.
1. Create the project folder: 
    ```bash
    mkdir -p projects
    cd projects
    ```   
2. Checkout the subprojects from their respective repositories:
    ```bash
    git clone https://github.com/feifel/kani-tts-training-wave2dataset.git 1-audio-to-dataset
    git clone https://github.com/feifel/kani-tts-training-dataset2nano.git 2-dataset-to-nano
    git clone https://github.com/feifel/kani-tts-training-finetune.git 3-nano-to-kanitts
    ```   
3. You can now start your IDE:
    ```bash
    deepagent-app 1-audio-to-dataset
    ```   
4. The container now needs to be started with the project folder mounted as a volume:
    ```bash
    cd ..    
    docker create -it --gpus all --name kani-tts-training-dev \
      -v "$(pwd)/data":/data \
      -v "$(pwd)/models":/root/.cache/huggingface \
      -v "$(pwd)/projects":/projects \
      kani-tts-training:latest

    docker start -ai kani-tts-training-dev
    ```
5. Inside the container, you then need to link the venv of the projects in /workspace to the projet in /project:
    ```bash
    ln -s /workspace/1-audio-to-dataset/venv /projects/1-audio-to-dataset/venv 
    ln -s /workspace/2-dataset-to-nano/venv /projects/2-dataset-to-nano/venv 
    ln -s /workspace/3-nano-to-kanitts/venv /projects/3-nano-to-kanitts/venv 
    ```
6. You can now modify the projects on your host with your IDE and test them on the docker image.
    ```bash
    cd /projects/1-audio-to-dataset
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
    ```


