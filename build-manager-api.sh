#!/usr/bin/env bash
set -euo pipefail

# ============================================
# manager-api 打包脚本（Maven → JAR）
# ============================================

PROJECT_DIR="${1:-/opt/xiaozhi-esp32-server}"
API_DIR="${PROJECT_DIR}/main/manager-api"

if [ ! -d "${API_DIR}" ]; then
    echo "❌ 目录不存在: ${API_DIR}"
    exit 1
fi

echo "==> 项目目录: ${PROJECT_DIR}"
echo "==> manager-api: ${API_DIR}"

# ---------- 检查 JDK ----------
if ! java -version 2>&1 | grep -q "version"; then
    echo "❌ 未检测到 JDK，请先安装 JDK 21"
    exit 1
fi
echo "    JDK: $(java -version 2>&1 | head -1)"

# ---------- 检查 Maven ----------
if ! command -v mvn &>/dev/null; then
    echo "❌ 未检测到 Maven，请先安装"
    exit 1
fi
echo "    Maven: $(mvn -version 2>&1 | head -1)"

# ---------- 打包 ----------
echo "==> 开始打包 manager-api..."
cd "${API_DIR}"

mvn clean package -DskipTests -q

# ---------- 验证 ----------
JAR_FILE="${API_DIR}/target/manager-api.jar"
# Spring Boot 默认生成的 JAR 文件名带版本号，找到并重命名
ORIGINAL_JAR=$(find "${API_DIR}/target" -name "*.jar" -not -name "*original*" -not -name "*sources*" | head -1)

if [ -z "${ORIGINAL_JAR}" ]; then
    echo "❌ 打包失败，未找到 JAR 文件"
    exit 1
fi

if [ "${ORIGINAL_JAR}" != "${JAR_FILE}" ]; then
    cp "${ORIGINAL_JAR}" "${JAR_FILE}"
fi

JAR_SIZE=$(du -h "${JAR_FILE}" | cut -f1)
echo "✅ 打包完成: ${JAR_FILE} (${JAR_SIZE})"

# ---------- 使用说明 ----------
echo ""
echo "========================================"
echo "  打包完成"
echo "========================================"
echo ""
echo "JAR 文件: ${JAR_FILE}"
echo ""
echo "手动测试运行:"
echo "  java -Xms256m -Xmx512m -jar ${JAR_FILE} --spring.profiles.active=dev"
echo ""
echo "如果已安装 systemd 服务，重启生效:"
echo "  sudo systemctl restart xiaozhi-manager-api"
echo "========================================"
