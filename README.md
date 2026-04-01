# xiaozhi-esp32-server 系统服务部署方案

## 架构

三个系统服务：
- **xiaozhi-manager-api** — Spring Boot 后端 API（JAR 方式运行）
- **xiaozhi-manager-web** — Vue 前端（npm run serve）
- **xiaozhi-server** — Python 语音交互服务（conda 环境）

## 前置条件

- JDK 21 + Maven（manager-api 打包用）
- Node.js 18+（manager-web）
- conda + Python 3.10（xiaozhi-server，依赖已装好）
- MySQL、Redis（manager-api 依赖，建议用 Docker）

## 使用方法

### 方式一：一键安装（推荐）

```bash
# 1. 克隆部署脚本
git clone https://github.com/qwertysc/xiaozhi-esp32-server-deploy.git
cd xiaozhi-esp32-server-deploy

# 2. 执行安装脚本（项目路径作为参数）
sudo bash install-services.sh /opt/xiaozhi-esp32-server
```

脚本会自动：
- 检测当前登录用户作为服务运行用户
- 检测 conda 环境路径并写入 service 文件
- 检查并安装 JDK 21 + Maven
- **打包 manager-api 为 JAR**
- 安装 manager-web 的 npm 依赖
- 安装三个 systemd 服务

```bash
# 3. 启动服务
sudo systemctl start xiaozhi-manager-api
sudo systemctl start xiaozhi-manager-web
sudo systemctl start xiaozhi-server

# 4. 设置开机自启
sudo systemctl enable xiaozhi-manager-api xiaozhi-manager-web xiaozhi-server
```

### 方式二：仅重新打包 manager-api

如果只是更新了 manager-api 代码，不需要重新安装所有服务：

```bash
sudo bash build-manager-api.sh /opt/xiaozhi-esp32-server
sudo systemctl restart xiaozhi-manager-api
```

## 服务管理

```bash
# 查看状态
sudo systemctl status xiaozhi-manager-api
sudo systemctl status xiaozhi-manager-web
sudo systemctl status xiaozhi-server

# 查看日志
sudo journalctl -u xiaozhi-manager-api -f
sudo journalctl -u xiaozhi-manager-web -f
sudo journalctl -u xiaozhi-server -f

# 重启
sudo systemctl restart xiaozhi-manager-api
sudo systemctl restart xiaozhi-manager-web
sudo systemctl restart xiaozhi-server
```

## manager-api 运行方式

已从 `mvn spring-boot:run` 改为 `java -jar` 方式：

| 对比 | Maven 运行 | JAR 运行 |
|------|-----------|---------|
| 启动速度 | 慢（需编译） | 快（直接运行） |
| 依赖 | 需要 Maven | 只需 JDK |
| 内存占用 | 高（Maven 开销） | 低 |
| JVM 参数 | 难以精细控制 | 可配置 -Xms/-Xmx |

默认 JVM 配置：`-Xms256m -Xmx512m`，可在 `xiaozhi-manager-api.service` 中调整。

## 文件说明

```
xiaozhi-esp32-server-deploy/
├── install-services.sh           # 一键安装脚本（打包+安装服务）
├── build-manager-api.sh          # 仅打包 manager-api 脚本
├── xiaozhi-manager-api.service   # manager-api systemd 服务文件
├── xiaozhi-manager-web.service   # manager-web systemd 服务文件
├── xiaozhi-server.service        # xiaozhi-server systemd 服务文件
└── README.md
```
