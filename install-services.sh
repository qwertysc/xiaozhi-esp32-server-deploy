#!/usr/bin/env bash
set -euo pipefail

# ============================================
# xiaozhi-esp32-server 系统服务安装脚本
# ============================================

PROJECT_DIR="${1:-/opt/xiaozhi-esp32-server}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_USER="xiaozhi"

echo "==> 项目目录: ${PROJECT_DIR}"
echo "==> 服务用户: ${SERVICE_USER}"

# ---------- 1. 创建用户 ----------
if ! id "${SERVICE_USER}" &>/dev/null; then
    echo "==> 创建用户 ${SERVICE_USER}..."
    useradd --system --shell /usr/sbin/nologin --home-dir "${PROJECT_DIR}" "${SERVICE_USER}"
else
    echo "==> 用户 ${SERVICE_USER} 已存在，跳过"
fi

# ---------- 2. 设置目录权限 ----------
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${PROJECT_DIR}"
chmod -R 750 "${PROJECT_DIR}"

# ---------- 3. 安装 manager-api 依赖 ----------
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

# ---------- 4. 安装 manager-web 依赖 ----------
echo "==> 安装 manager-web 依赖..."
su - "${SERVICE_USER}" -s /bin/bash -c "cd ${PROJECT_DIR}/main/manager-web && npm install --production 2>/dev/null || npm install"

# ---------- 5. 安装 xiaozhi-server 依赖 ----------
echo "==> 跳过 conda/pip 安装（假设已手动完成）"

# 自动检测 conda 环境路径并更新 service 文件
CONDA_BIN="$(command -v conda 2>/dev/null || true)"
if [ -z "${CONDA_BIN}" ]; then
    for p in /root/miniconda3/bin/conda /home/*/miniconda3/bin/conda /opt/conda/bin/conda /root/anaconda3/bin/conda; do
        [ -f "${p}" ] && CONDA_BIN="${p}" && break
    done
fi

if [ -n "${CONDA_BIN}" ]; then
    CONDA_DIR="$(dirname "$(dirname "${CONDA_BIN}")")"
    ENV_DIR="${CONDA_DIR}/envs/xiaozhi-esp32-server"
    if [ -d "${ENV_DIR}" ]; then
        echo "    检测到 conda 环境: ${ENV_DIR}"
        sed -i "s|/opt/conda/envs/xiaozhi-esp32-server|${ENV_DIR}|g" /etc/systemd/system/xiaozhi-server.service
    else
        echo "    ⚠️  未找到 conda 环境 xiaozhi-esp32-server，请确认已创建"
    fi
else
    echo "    ⚠️  未检测到 conda，请手动修改 xiaozhi-server.service 中的 Python 路径"
fi

# ---------- 6. 安装 systemd 服务文件 ----------
echo "==> 安装 systemd 服务..."
for svc in xiaozhi-manager-api xiaozhi-manager-web xiaozhi-server; do
    cp "${SCRIPT_DIR}/${svc}.service" "/etc/systemd/system/${svc}.service"
    echo "    ✅ ${svc}.service"
done

systemctl daemon-reload

# ---------- 7. 完成 ----------
echo ""
echo "========================================"
echo "  ✅ 安装完成"
echo "========================================"
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
