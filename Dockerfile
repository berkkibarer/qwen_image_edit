# Use specific version of nvidia cuda image
FROM wlsdml1114/multitalk-base:1.7 AS runtime

# wget 설치 (URL 다운로드를 위해)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN pip install -U "huggingface_hub[hf_transfer]"
RUN pip install runpod websocket-client librosa

# hf_transfer: HuggingFace Hub용 가속 다운로드 백엔드 (빌드 타임아웃 방지)
ENV HF_HUB_ENABLE_HF_TRANSFER=1

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

# Download models (huggingface-cli + hf_transfer: already-installed pip package, no new apt dependency)
RUN mkdir -p /ComfyUI/models/diffusion_models /ComfyUI/models/loras /ComfyUI/models/text_encoders /ComfyUI/models/vae

RUN huggingface-cli download Comfy-Org/Qwen-Image-Edit_ComfyUI \
    split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors \
    --local-dir /tmp/dl1 && \
    mv /tmp/dl1/split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors /ComfyUI/models/diffusion_models/ && \
    rm -rf /tmp/dl1

RUN huggingface-cli download lightx2v/Qwen-Image-Edit-2511-Lightning \
    Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors \
    --local-dir /tmp/dl2 && \
    mv /tmp/dl2/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors /ComfyUI/models/loras/ && \
    rm -rf /tmp/dl2

RUN huggingface-cli download Comfy-Org/Qwen-Image_ComfyUI \
    split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
    --local-dir /tmp/dl3 && \
    mv /tmp/dl3/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors /ComfyUI/models/text_encoders/ && \
    rm -rf /tmp/dl3

RUN huggingface-cli download Comfy-Org/Qwen-Image_ComfyUI \
    split_files/vae/qwen_image_vae.safetensors \
    --local-dir /tmp/dl4 && \
    mv /tmp/dl4/split_files/vae/qwen_image_vae.safetensors /ComfyUI/models/vae/ && \
    rm -rf /tmp/dl4

COPY . .
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
