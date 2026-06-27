# Use the official Python 3.8 image from the Docker Hub
FROM python:3.8-slim

# Set the working directory inside the container
WORKDIR /app

# Install dependencies and essential tools
RUN apt-get update && \
    apt-get install -y git ffmpeg build-essential python3-dev wget && \
    apt-get clean

# Clone the SadTalker repository
RUN git clone https://github.com/OpenTalker/SadTalker.git /app/SadTalker

# Change to the SadTalker directory
WORKDIR /app/SadTalker

COPY app/ /app/SadTalker

# Install PyTorch with CUDA support and other dependencies
RUN pip install torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 boto3 runpod==1.6.0 --extra-index-url https://download.pytorch.org/whl/cu118 && \
    pip install -r requirements.txt

# Pre-download model checkpoints into the image so the worker never needs to
# fetch them at runtime (faster, cheaper cold starts; works without a volume)
RUN mkdir -p /app/SadTalker/checkpoints /app/SadTalker/gfpgan/weights && \
    wget -q -O /app/SadTalker/checkpoints/mapping_00109-model.pth.tar https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_00109-model.pth.tar && \
    wget -q -O /app/SadTalker/checkpoints/mapping_00229-model.pth.tar https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_00229-model.pth.tar && \
    wget -q -O /app/SadTalker/checkpoints/SadTalker_V0.0.2_256.safetensors https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/SadTalker_V0.0.2_256.safetensors && \
    wget -q -O /app/SadTalker/checkpoints/SadTalker_V0.0.2_512.safetensors https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/SadTalker_V0.0.2_512.safetensors && \
    wget -q -O /app/SadTalker/gfpgan/weights/alignment_WFLW_4HG.pth https://github.com/xinntao/facexlib/releases/download/v0.1.0/alignment_WFLW_4HG.pth && \
    wget -q -O /app/SadTalker/gfpgan/weights/detection_Resnet50_Final.pth https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth && \
    wget -q -O /app/SadTalker/gfpgan/weights/GFPGANv1.4.pth https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth && \
    wget -q -O /app/SadTalker/gfpgan/weights/parsing_parsenet.pth https://github.com/xinntao/facexlib/releases/download/v0.2.2/parsing_parsenet.pth

# Set the entrypoint
CMD ["python", "-u", "/app/SadTalker/handler.py"]
