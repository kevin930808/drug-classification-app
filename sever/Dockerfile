FROM python:3.9-slim

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-dev \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# 複製依賴文件
COPY requirements.txt .

# 安裝 Python 依賴
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程序文件
COPY . .

# 暴露端口
EXPOSE 8000

# 設置環境變量
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# 啟動命令
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"] 