# OpenMed 本地医疗 AI

本项目可选集成开源项目 [OpenMed](https://github.com/maziyarpanahi/openmed)，用于在本机提取疾病、药物、基因、解剖等医学实体，并识别或脱敏个人隐私信息。

## Windows 一键启动

在项目目录打开 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1 -LocalAI
```

如果还需要 Hadoop、Kafka、Flink 等完整大数据环境：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1 -Full -LocalAI
```

启动后登录系统，打开左侧“本地医疗 AI”。

医学实体提取默认使用“快速模式”：

- 中文文本先由 [Argos Translate](https://github.com/argosopentech/argos-translate) 的 83MB 中英模型和 [CTranslate2](https://github.com/OpenNMT/CTranslate2) 在本机翻译。
- 疾病、药物、基因和解剖实体由轻量医学词典校正并提取。
- 普通 CPU 上通常在一秒内完成，不再默认加载 434M 的 OpenMed 疾病模型。
- 需要更广泛识别时，可以手动切换到“OpenMed 精细模式”。

Argos 中英模型由 OPUS-MT 模型转换而来，模型许可为 CC BY 4.0。

## 隐私边界

- 模型推理在本机 Docker 容器完成，不调用第三方在线 AI API。
- OpenMed 不开放宿主机端口，只有本项目后端可通过 Docker 内部网络访问。
- 输入原文和分析结果默认不写入数据库。
- 首次使用某个模型时仍需从 Hugging Face 下载模型文件。
- 模型下载后保存在 Docker 卷 `openmed-models` 中，之后可离线使用已经缓存的模型。
- 当前固定镜像的 PII 接口支持 `en/fr/de/it/es/nl/hi/te/pt`，不包含中文，不能依赖它完整脱敏中文病历。
- AI 输出仅供辅助，必须由医务人员复核。

## 停止与清理

只停止 OpenMed：

```powershell
docker compose --profile local-ai stop openmed
```

删除模型缓存会释放磁盘空间，但下次需要重新下载：

```powershell
docker compose --profile local-ai down
docker volume rm medical-bigdata_openmed-models
```
