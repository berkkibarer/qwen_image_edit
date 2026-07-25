# Use specific version of nvidia cuda image
FROM wlsdml1114/multitalk-base:1.7 AS runtime

# wget 설치 (URL 다운로드를 위해)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN pip install -U "huggingface_hub[hf_transfer]"
RUN pip install runpod websocket-client librosa

# Xet: HuggingFace Hub용 가속 다운로드 백엔드 (빌드 타임아웃 방지)
ENV HF_XET_HIGH_PERFORMANCE=1

# Set working directory
WORKDIR /

RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --no-cache-dir -r requirements.txt

RUN cd /ComfyUI/custom_nodes/ && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip install --no-cache-dir -r requirements.txt

RUN cd /ComfyUI/custom_nodes/ && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && \
    cd ComfyUI-KJNodes && \
    pip install --no-cache-dir -r requirements.txt

# Download models (hf CLI: huggingface-cli is deprecated/removed in huggingface_hub 1.x, use `hf` instead)
RUN mkdir -p /ComfyUI/models/diffusion_models /ComfyUI/models/loras /ComfyUI/models/text_encoders /ComfyUI/models/vae

RUN hf download Comfy-Org/Qwen-Image-Edit_ComfyUI \
    split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors \
    --local-dir /tmp/dl1 && \
    find /tmp/dl1 -name "qwen_image_edit_2511_fp8mixed.safetensors" -exec mv {} /ComfyUI/models/diffusion_models/ \; && \
    rm -rf /tmp/dl1

RUN hf download lightx2v/Qwen-Image-Edit-2511-Lightning \
    Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors \
    --local-dir /tmp/dl2 && \
    find /tmp/dl2 -name "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors" -exec mv {} /ComfyUI/models/loras/ \; && \
    rm -rf /tmp/dl2

RUN hf download Comfy-Org/Qwen-Image_ComfyUI \
    split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
    --local-dir /tmp/dl3 && \
    find /tmp/dl3 -name "qwen_2.5_vl_7b_fp8_scaled.safetensors" -exec mv {} /ComfyUI/models/text_encoders/ \; && \
    rm -rf /tmp/dl3

RUN hf download Comfy-Org/Qwen-Image_ComfyUI \
    split_files/vae/qwen_image_vae.safetensors \
    --local-dir /tmp/dl4 && \
    find /tmp/dl4 -name "qwen_image_vae.safetensors" -exec mv {} /ComfyUI/models/vae/ \; && \
    rm -rf /tmp/dl4

COPY . .
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
