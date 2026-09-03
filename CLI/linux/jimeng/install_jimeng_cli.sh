#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v curl >/dev/null 2>&1; then
    echo "错误：未找到 curl，请先安装 curl。"
    exit 1
fi

echo "正在安装/更新 dreamina CLI..."
curl -fsSL https://jimeng.jianying.com/cli | bash

export PATH="$HOME/.local/bin:$PATH"
PROFILE_PATH="$HOME/.profile"
if ! grep -Fqx 'export PATH="$HOME/.local/bin:$PATH"' "$PROFILE_PATH" 2>/dev/null; then
    printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE_PATH"
fi

DREAMINA_BIN="$(command -v dreamina || true)"
if [ -z "$DREAMINA_BIN" ]; then
    DREAMINA_BIN="$(find "$HOME" -maxdepth 4 -type f -name dreamina -print -quit 2>/dev/null || true)"
fi
if [ -z "$DREAMINA_BIN" ]; then
    echo "安装完成后没有找到 dreamina CLI。"
    exit 2
fi

mkdir -p "$ROOT_DIR/API"
ENV_PATH="$ROOT_DIR/API/.env"
TMP_ENV="$(mktemp)"
trap 'rm -f "$TMP_ENV"' EXIT
if [ -f "$ENV_PATH" ]; then
    grep -vE '^(JIMENG_USE_WSL|DREAMINA_BIN)=' "$ENV_PATH" > "$TMP_ENV" || true
fi
printf 'JIMENG_USE_WSL=0\nDREAMINA_BIN=%s\n' "$DREAMINA_BIN" >> "$TMP_ENV"
mv "$TMP_ENV" "$ENV_PATH"
trap - EXIT

echo "dreamina 已安装：$DREAMINA_BIN"
"$DREAMINA_BIN" --version || true
echo "已更新 $ENV_PATH"
echo "下一步执行：CLI/linux/jimeng/login_jimeng_cli.sh"
