#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$ROOT_DIR"
export PATH="$HOME/.local/bin:$PATH"

DREAMINA_BIN="$(command -v dreamina || true)"
if [ -z "$DREAMINA_BIN" ]; then
    echo "未找到 dreamina CLI，请先执行 CLI/linux/jimeng/install_jimeng_cli.sh"
    exit 1
fi

echo "正在生成即梦 OAuth Device Flow 登录信息..."
LOGIN_TEXT="$("$DREAMINA_BIN" login --headless 2>&1 || true)"
printf '%s\n' "$LOGIN_TEXT"

DEVICE_CODE="$(printf '%s\n' "$LOGIN_TEXT" | sed -nE 's/^[[:space:]]*device_code[[:space:]]*[:=][[:space:]]*//p' | head -n 1 | tr -d '\r')"
VERIFY_URI="$(printf '%s\n' "$LOGIN_TEXT" | sed -nE 's/^[[:space:]]*verification_uri[[:space:]]*[:=][[:space:]]*//p' | head -n 1 | tr -d '\r')"
if [ -z "$DEVICE_CODE" ]; then
    echo "没有解析到 device_code，请重新执行登录命令并手动复制 device_code。"
    exit 2
fi

echo
echo "请在本地浏览器打开下面的 verification_uri 完成授权："
echo "$VERIFY_URI"
echo
read -r -p "浏览器显示授权成功后，按 Enter 开始确认登录态..."

DEADLINE=$((SECONDS + 300))
CHECKED_IN=false
while (( SECONDS < DEADLINE )); do
    if CHECK_OUTPUT="$("$DREAMINA_BIN" login checklogin "--device_code=$DEVICE_CODE" --poll=0 2>&1)"; then
        printf '%s\n' "$CHECK_OUTPUT"
        CHECKED_IN=true
        break
    fi
    printf '%s\n' "$CHECK_OUTPUT"
    echo "尚未完成登录，2 秒后重试..."
    sleep 2
done

if [ "$CHECKED_IN" != true ]; then
    echo "登录确认超时，请重新执行此脚本生成新的 device_code。"
    exit 3
fi

echo "登录确认成功，正在检查积分..."
"$DREAMINA_BIN" user_credit
