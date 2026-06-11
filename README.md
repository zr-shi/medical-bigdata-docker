# 医疗大数据分析系统 Docker 部署版

这是一个只包含公开部署文件的仓库。业务系统、脱敏演示数据库和三节点 Hadoop 已打包为 Docker 镜像，不需要安装 Go、Node.js、MySQL、Hadoop，也不需要 VMware 虚拟机。

> 数据说明：公开数据库只包含脱敏演示数据，不包含原始患者姓名、身份证、电话、地址或本地数据库备份。

## 版本 1.1.0：就诊卡业务修复

- 患者管理的“就诊卡”窗口会显示患者姓名、患者编号和正确的空状态。
- 补齐脱敏演示患者的就诊卡数据，并修复旧演示数据中的乱码字段。
- 办卡、充值、挂失、补卡完成后会自动刷新当前患者的卡片列表。
- 启动脚本会自动执行安全、可重复的数据迁移，已有数据卷不需要删除。

已经下载过旧版本的用户，在项目目录重新运行启动命令即可保留数据并升级：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1
```

## 能运行什么

默认模式包含：

- 医疗大数据分析 Web 系统
- Go 后端
- MySQL 脱敏演示数据库
- Redis

完整大数据模式还包含：

- 三节点 Hadoop：HDFS + YARN + MapReduce
- Kafka + ZooKeeper
- Flink
- ClickHouse
- MinIO

目前镜像支持常见的 Intel/AMD 电脑和服务器，即 `linux/amd64`。

## 小白安装教程：Windows

### 第 1 步：安装 Docker Desktop

1. 打开 <https://www.docker.com/products/docker-desktop/>。
2. 下载并安装 Docker Desktop。
3. 安装完成后启动 Docker Desktop。
4. 等待左下角显示 Docker Engine 正在运行。

### 第 2 步：中国大陆网络先配置镜像加速（拉取成功的关键）

如果直接拉取 Docker Hub，可能出现以下错误：

```text
Image ... Interrupted
failed to copy: httpReadSeeker: failed open
production.cloudflare.docker.com ... EOF
```

这通常不是项目损坏，而是 Docker Hub 或 CloudFront 下载链路在当前网络中断。建议在首次启动前配置镜像加速：

1. 打开 Docker Desktop。
2. 进入 `Settings` → `Docker Engine`。
3. 如果编辑框里只有 `{}`，可以替换为下面的内容：

```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live"
  ]
}
```

如果原来的 JSON 中还有其他配置，不要全部删除，只需在最外层加入 `registry-mirrors` 字段，并注意前一个字段末尾需要有英文逗号。

4. 点击 `Apply & Restart`，等待 Docker Desktop 重启完成。

镜像站属于第三方公共服务，可用性可能随时间变化，仅建议用于拉取公开镜像。不要随意使用来源不明的镜像站。Docker 官方配置说明：<https://docs.docker.com/docker-hub/image-library/mirror/>。

### 第 3 步：下载本项目

不会使用 Git：

1. 点击 GitHub 页面右上角绿色的 `Code`。
2. 点击 `Download ZIP`。
3. 解压 ZIP。
4. 进入解压后的文件夹。

会使用 Git：

```powershell
git clone https://github.com/zr-shi/medical-bigdata-docker.git
cd medical-bigdata-docker
```

### 第 4 步：启动系统

在项目文件夹空白处按住 `Shift` 并点击鼠标右键，选择“在终端中打开”，执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1
```

脚本会自动拉取镜像并启动。首次运行需要下载约数 GB 文件，请耐心等待。

启动完成后，用浏览器打开：

<http://localhost>

登录账号：

```text
账号：admin
密码：123456
```

### 第 5 步：启动完整大数据环境

电脑建议至少有 10 GB 可用内存和 20 GB 可用磁盘，然后执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1 -Full
```

大数据页面：

| 服务 | 地址 |
| --- | --- |
| 主系统 | <http://localhost> |
| Flink | <http://localhost:8081> |
| HDFS | <http://localhost:9870> |
| YARN | <http://localhost:8088> |
| MapReduce History | <http://localhost:19888> |
| MinIO | <http://localhost:9001> |
| ClickHouse | <http://localhost:8123> |

## Linux / 云服务器

```bash
git clone https://github.com/zr-shi/medical-bigdata-docker.git
cd medical-bigdata-docker
chmod +x scripts/*.sh
./scripts/start-linux.sh
```

完整模式：

```bash
./scripts/start-linux.sh --full
```

如果是云服务器，还需要在云平台安全组中开放 Web 端口，并使用服务器公网 IP 访问。不要把 MySQL、Redis、HDFS RPC 等内部端口直接暴露到公网。

## 停止系统

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop-windows.ps1
```

Linux：

```bash
./scripts/stop-linux.sh
```

停止并删除全部数据：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop-windows.ps1 -DeleteData
```

删除数据后，下次启动会重新导入脱敏演示数据库。请勿在保存了重要数据时执行。

## 常见问题

### 提示 `no configuration file provided`

说明终端没有位于项目目录。请先进入包含 `compose.yaml` 的文件夹，再执行命令。使用本仓库的一键脚本时，脚本会自动定位项目目录。

### 端口 80 被占用

打开 `.env`，把：

```dotenv
APP_PORT=80
```

改成：

```dotenv
APP_PORT=8085
```

重新启动后访问 <http://localhost:8085>。

### Docker Hub 下载失败

默认配置使用 DaoCloud 镜像加速地址拉取公共基础组件。如果该地址在你的网络不可用，打开 `.env`，修改：

```dotenv
DOCKER_REGISTRY=docker.io
```

然后重新运行启动脚本。

如果错误信息包含 `production.cloudflare.docker.com`、`EOF` 或多个镜像显示 `Interrupted`，请优先按照上面的“第 2 步”配置 Docker Desktop 的 `registry-mirrors`，点击 `Apply & Restart` 后重新执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1
```

Docker 会继续下载尚未完成的镜像层，不需要删除项目或重新解压。

### MySQL 正常，但 backend 显示 `unhealthy`

如果输出类似：

```text
Container medical-bigdata-mysql-1    Healthy
Container medical-bigdata-backend-1  Error
dependency failed to start: backend is unhealthy
```

最常见原因是电脑里存在以前运行本项目留下的 MySQL 数据卷。MySQL 初始化密码只在数据卷第一次创建时生效；后来修改 `.env` 不会自动修改旧数据库的 root 密码。

如果以前使用的是本项目默认密码，请打开 `.env`，确认：

```dotenv
MYSQL_ROOT_PASSWORD=root123
```

保存后重新运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1
```

如果旧数据不需要保留，可以删除旧演示数据并全新初始化：

```powershell
docker compose --profile bigdata down --volumes
powershell -ExecutionPolicy Bypass -File .\scripts\start-windows.ps1
```

`down --volumes` 会永久删除本项目已有的 MySQL、Redis、Hadoop 等数据，只能在确认旧数据不需要时执行。

### 是否需要作者的电脑或虚拟机一直开机

不需要。镜像下载后，所有服务都运行在使用者自己的 Docker 中。只有希望提供一个固定公网网站时，部署该网站的云服务器需要保持开机。

## 安全提醒

- `.env` 已被 Git 忽略，不要把真实密码提交到 GitHub。
- 默认账号和密码只适合本地课程演示。
- 公网部署前必须修改 `.env` 中的数据库、JWT、MinIO 和 ClickHouse 密码。
- Hadoop 演示集群未启用生产级认证，不应直接暴露到公网。
- 本仓库不包含源代码、原始 SQL、真实患者数据或本地历史文件。

## Docker Hub 镜像

- `shizr/medicine-bigdata:mysql-1.1.0`
- `shizr/medicine-bigdata:backend-1.0.0`
- `shizr/medicine-bigdata:frontend-1.1.0`
- `shizr/medicine-bigdata:hadoop-3.4.1`

Docker Hub 没有二级文件夹功能，因此本项目使用一个仓库、多个标签来区分组件。以后其他项目可以继续创建独立仓库，例如 `shizr/另一个项目`，不会和本项目混在一起。

个人免费账户适合保存公开镜像，通常不需要为本课程项目付费。Docker Hub 会对镜像拉取频率、私有仓库和团队协作功能设置套餐限制，具体规则可能调整，请以 Docker 官方定价页面为准：<https://www.docker.com/pricing/>。
