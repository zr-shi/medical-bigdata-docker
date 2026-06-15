FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    fastapi==0.115.12 \
    uvicorn==0.34.3 \
    ctranslate2==4.6.0 \
    sentencepiece==0.2.0

RUN curl -fsSL -o /tmp/zh-en.argosmodel \
    https://argos-net.com/v1/translate-zh_en-1_9.argosmodel \
    && mkdir -p /models/zh-en /tmp/argos \
    && unzip -q /tmp/zh-en.argosmodel -d /tmp/argos \
    && cp -r /tmp/argos/translate-zh_en-1_9/model /models/zh-en/model \
    && cp /tmp/argos/translate-zh_en-1_9/sentencepiece.model /models/zh-en/sentencepiece.model \
    && rm -rf /tmp/argos /tmp/zh-en.argosmodel

COPY app.py /app/app.py

EXPOSE 8090

HEALTHCHECK --interval=20s --timeout=5s --start-period=15s --retries=10 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8090/health', timeout=3)"

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8090", "--workers", "1"]
