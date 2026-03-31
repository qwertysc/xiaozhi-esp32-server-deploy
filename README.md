# xiaozhi-esp32-server 系统服务部署方案

## 前置条件

- JDK 21 + Maven（manager-api）
- Node.js 18+（manager-web）
- Python 3.10+（xiaozhi-server）
- MySQL、Redis（manager-api 依赖）

## 使用方法

```bash
# 1. 把项目放到 /opt/xiaozhi-esp32-server
git clone https://github.com/xinnan-tech/xiaozhi-esp32-server.git /opt/xiaozhi-esp32-server

# 2. 执行安装脚本
cd /opt/xiaozhi-esp32-server
sudo bash install-services.sh

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

## 自定义项目路径

如果项目不在 `/opt/xiaozhi-esp32-server`，修改：
1. 三个 `.service` 文件里的 `WorkingDirectory` 和 `ExecStart`
2. `install-services.sh` 里的 `PROJECT_DIR` 变量
