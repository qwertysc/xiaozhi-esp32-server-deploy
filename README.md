# xiaozhi-esp32-server 系统服务部署方案

## 前置条件

- JDK 21 + Maven（manager-api）
- Node.js 18+（manager-web）
- conda + Python 3.10（xiaozhi-server，依赖已装好）
- MySQL、Redis（manager-api 依赖）

## 使用方法

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
