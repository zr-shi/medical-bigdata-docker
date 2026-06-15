from __future__ import annotations

import re
import time
from functools import lru_cache

import ctranslate2
import sentencepiece as spm
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="Medical NLP Lite", version="1.0.0")

CHINESE_RE = re.compile(r"[\u3400-\u9fff]")
GENE_RE = re.compile(
    r"(?<![A-Za-z0-9])(?:APOE|BRCA1|BRCA2|EGFR|KRAS|TP53|HER2|ALK|ROS1)(?![A-Za-z0-9])",
    re.I,
)

TERMS = {
    "disease": {
        "不稳定型心绞痛": "unstable angina",
        "冠状动脉粥样硬化性心脏病": "coronary atherosclerotic heart disease",
        "冠心病": "coronary heart disease",
        "高血压": "hypertension",
        "2型糖尿病": "type 2 diabetes",
        "糖尿病": "diabetes",
        "高脂血症": "hyperlipidemia",
        "白血病": "leukemia",
        "肺炎": "pneumonia",
        "脑梗塞": "cerebral infarction",
        "心肌梗死": "myocardial infarction",
        "狭窄": "stenosis",
    },
    "drug": {
        "阿司匹林": "aspirin",
        "氯吡格雷": "clopidogrel",
        "阿托伐他汀": "atorvastatin",
        "美托洛尔": "metoprolol",
        "二甲双胍": "metformin",
        "氨氯地平": "amlodipine",
        "伊马替尼": "imatinib",
    },
    "anatomy": {
        "心脏": "heart",
        "双肺": "lungs",
        "肺": "lung",
        "肝脏": "liver",
        "肾脏": "kidney",
        "脑": "brain",
        "腹部": "abdomen",
        "冠状动脉": "coronary artery",
        "前降支": "left anterior descending artery",
    },
}
ENGLISH_TERMS = {
    task: sorted(set(values.values()), key=len, reverse=True)
    for task, values in TERMS.items()
}


class TextRequest(BaseModel):
    text: str = Field(min_length=1, max_length=20000)


class AnalyzeRequest(TextRequest):
    task: str = Field(pattern="^(disease|drug|gene|anatomy)$")
    translate_chinese: bool = True


@lru_cache(maxsize=1)
def translator() -> ctranslate2.Translator:
    return ctranslate2.Translator("/models/zh-en/model", device="cpu", compute_type="int8")


@lru_cache(maxsize=1)
def tokenizer() -> spm.SentencePieceProcessor:
    return spm.SentencePieceProcessor(model_file="/models/zh-en/sentencepiece.model")


def translate_zh_en(text: str) -> str:
    chunks = [part.strip() for part in re.split(r"(?<=[。；！？\n])", text) if part.strip()]
    batches = [tokenizer().encode(chunk, out_type=str) for chunk in chunks]
    results = translator().translate_batch(
        batches, beam_size=1, max_decoding_length=512, repetition_penalty=1.05
    )
    return " ".join(
        re.sub(r"\s+", " ", "".join(result.hypotheses[0]).replace("▁", " ")).strip()
        for result in results
    )


def translate_if_needed(text: str) -> tuple[str, bool]:
    if not CHINESE_RE.search(text):
        return text, False
    return translate_zh_en(text), True


def add_unique(items: list[dict], text: str, label: str, start: int, end: int, normalized: str | None = None) -> None:
    if any(item["text"].lower() == text.lower() and item["label"] == label for item in items):
        return
    if normalized and any(
        item["label"] == label
        and item.get("normalized")
        and (
            item["normalized"] == normalized
            or item["normalized"] in normalized
            or normalized in item["normalized"]
        )
        for item in items
    ):
        return
    if any(item["label"] == label and start < item["end"] and end > item["start"] for item in items):
        return
    item = {"text": text, "label": label, "start": start, "end": end}
    if normalized:
        item["normalized"] = normalized
    items.append(item)


def extract_entities(source: str, translated: str, task: str) -> list[dict]:
    entities: list[dict] = []
    label = task.upper()
    if task == "gene":
        for content in (source, translated):
            for match in GENE_RE.finditer(content):
                add_unique(entities, match.group(), "GENE", match.start(), match.end())
        return entities
    for term, normalized in TERMS.get(task, {}).items():
        for match in re.finditer(re.escape(term), source, re.I):
            add_unique(entities, match.group(), label, match.start(), match.end(), normalized)
    lowered = translated.lower()
    for term in ENGLISH_TERMS.get(task, []):
        for match in re.finditer(rf"\b{re.escape(term)}\b", lowered):
            add_unique(
                entities, translated[match.start():match.end()], label,
                match.start(), match.end(), term
            )
    entities.sort(key=lambda item: (item["start"], -(item["end"] - item["start"])))
    return entities


@app.on_event("startup")
def warm_up() -> None:
    translate_zh_en("糖尿病")


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "service": "medical-nlp-lite",
        "version": "1.0.0",
        "translation": "Argos zh-en 83MB",
        "ner": "local medical rules",
    }


@app.post("/translate")
def translate(payload: TextRequest) -> dict:
    started = time.perf_counter()
    translated, used = translate_if_needed(payload.text.strip())
    return {
        "translated_text": translated,
        "translated": used,
        "elapsed_ms": round((time.perf_counter() - started) * 1000, 1),
    }


@app.post("/analyze")
def analyze(payload: AnalyzeRequest) -> dict:
    started = time.perf_counter()
    source = payload.text.strip()
    translated, used_translation = (
        translate_if_needed(source) if payload.translate_chinese else (source, False)
    )
    entities = extract_entities(source, translated, payload.task)
    return {
        "mode": "lite",
        "task": payload.task,
        "source_language": "zh" if used_translation else "en",
        "translated": used_translation,
        "translated_text": translated if used_translation else None,
        "entities": entities,
        "entity_count": len(entities),
        "elapsed_ms": round((time.perf_counter() - started) * 1000, 1),
        "model": "Argos CTranslate2 + local medical rules",
    }
