#!/usr/bin/env bash
set -euo pipefail

# ============================================
# xiaozhi-esp32-server 系统服务安装脚本
# ============================================

PROJECT_DIR="${1:-/opt/xiaozhi-esp32-server}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_USER="${SUDO_USER:-$(whoami)}"

echo "==> 项目目录: ${PROJECT_DIR}"
echo "==> 运行用户: ${SERVICE_USER}"

# ---------- 0. 修正项目目录权限 ----------
echo "==> 修正项目目录权限..."
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${PROJECT_DIR}"

# ---------- 1. 安装 manager-api 依赖 ----------
echo "==> 检查 JDK 21..."
if ! java -version 2>&1 | grep -q "21"; then
    echo "    未检测到 JDK 21，尝试安装..."
    if command -v apt &>/dev/null; then
        apt update -qq && apt install -y openjdk-21-jdk maven
    elif command -v yum &>/dev/null; then
        yum install -y java-21-openjdk maven
    else
        echo "    ⚠️  无法自动安装，请手动安装 JDK 21 和 Maven"
    fi
fi

# ---------- 2. 安装 manager-web 依赖 ----------
echo "==> 安装 manager-web 依赖..."
su - "${SERVICE_USER}" -s /bin/bash -c "cd ${PROJECT_DIR}/main/manager-web && npm install --production 2>/dev/null || npm install"

# ---------- 3. 检测 xiaozhi-server conda 环境 ----------
echo "==> 检测 conda 环境..."
CONDA_BIN="$(command -v conda 2>/dev/null || true)"
if [ -z "${CONDA_BIN}" ]; then
    for p in /root/miniconda3/bin/conda /home/*/miniconda3/bin/conda /opt/conda/bin/conda /root/anaconda3/bin/conda; do
        [ -f "${p}" ] && CONDA_BIN="${p}" && break
    done
fi

XIAOZHI_PYTHON=""
if [ -n "${CONDA_BIN}" ]; then
    CONDA_DIR="$(dirname "$(dirname "${CONDA_BIN}")")"
    ENV_DIR="${CONDA_DIR}/envs/xiaozhi-esp32-server"
    if [ -d "${ENV_DIR}" ]; then
        XIAOZHI_PYTHON="${ENV_DIR}/bin/python"
        echo "    检测到 conda 环境: ${ENV_DIR}"
    else
        echo "    ⚠️  未找到 conda 环境 xiaozhi-esp32-server，请确认已创建"
    fi
else
    echo "    ⚠️  未检测到 conda"
fi

# ---------- 4. 安装 systemd 服务文件 ----------
echo "==> 安装 systemd 服务..."
for svc in xiaozhi-manager-api xiaozhi-manager-web xiaozhi-server; do
    cp "${SCRIPT_DIR}/${svc}.service" "/etc/systemd/system/${svc}.service"
    # 替换用户
    sed -i "s|^User=.*|User=${SERVICE_USER}|g" "/etc/systemd/system/${svc}.service"
    sed -i "s|^Group=.*|Group=${SERVICE_USER}|g" "/etc/systemd/system/${svc}.service"
    echo "    ✅ ${svc}.service"
done

# 更新 xiaozhi-server 的 Python 路径
if [ -n "${XIAOZHI_PYTHON}" ]; then
    sed -i "s|/opt/conda/envs/xiaozhi-esp32-server/bin/python|${XIAOZHI_PYTHON}|g" /etc/systemd/system/xiaozhi-server.service
fi

systemctl daemon-reload

# ---------- 5. 完成 ----------
echo ""
echo "========================================"
echo "  ✅ 安装完成"
echo "========================================"
echo ""
echo "运行用户: ${SERVICE_USER}"
echo ""
echo "启动服务:"
echo "  sudo systemctl start xiaozhi-manager-api"
echo "  sudo systemctl start xiaozhi-manager-web"
echo "  sudo systemctl start xiaozhi-server"
echo ""
echo "设置开机自启:"
echo "  sudo systemctl enable xiaozhi-manager-api xiaozhi-manager-web xiaozhi-server"
echo ""
echo "查看日志:"
echo "  sudo journalctl -u xiaozhi-manager-api -f"
echo "  sudo journalctl -u xiaozhi-manager-web -f"
echo "  sudo journalctl -u xiaozhi-server -f"
echo ""
echo "⚠️  注意:"
echo "  1. 确保 MySQL 和 Redis 已启动"
echo "  2. 配置 main/manager-api/src/main/resources/application-dev.yml"
echo "  3. 配置 main/xiaozhi-server/data/.config.yaml"
echo "========================================"
