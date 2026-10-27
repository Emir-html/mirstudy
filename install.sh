#!/usr/bin/env bash
# =====================================================================
#  МирСтади — установка сервера одной командой (Ubuntu 22.04 / 24.04):
#     sudo bash -c "$(curl -fsSL https://emir-html.github.io/mirstudy/install.sh)"
#  Скрипт спросит:
#    1) токен GitHub ТОЛЬКО ДЛЯ ЧТЕНИЯ закрытого репозитория Emir-html/mirstudy-src
#       (по нему сервер скачивает сайт и потом сам обновляется);
#    2) домен, почту и пароль владельца, токен бота Telegram — это спросит setup.sh.
#  Все секреты вводятся скрыто и остаются только на сервере (/etc/mirstudy, доступ — только root).
# =====================================================================
set -euo pipefail
REPO="${MS_REPO:-Emir-html/mirstudy-src}"
BR="${MS_BRANCH:-server}"
[ "$(id -u)" -eq 0 ] || { echo "Нужно от root: sudo bash -c \"\$(curl -fsSL https://emir-html.github.io/mirstudy/install.sh)\""; exit 1; }

echo "МирСтади — установка сервера"
echo
echo "Шаг 1. Токен GitHub только для чтения (github.com → Settings → Developer settings →"
echo "        Fine-grained tokens → Generate new token: Repository access → Only select → $REPO;"
echo "        Permissions → Contents: Read-only). Токен вводится скрыто, никому его не отправляйте."
read -rsp "Токен GitHub: " TOKEN </dev/tty; echo
[ -n "$TOKEN" ] || { echo "Токен не введён."; exit 1; }

export DEBIAN_FRONTEND=noninteractive
if ! command -v curl >/dev/null || ! command -v unzip >/dev/null || ! command -v python3 >/dev/null; then
  apt-get update -y >/dev/null; apt-get install -y curl unzip python3 ca-certificates >/dev/null
fi

API="https://api.github.com/repos/$REPO"
HDR=(-H "Authorization: Bearer $TOKEN" -H "X-GitHub-Api-Version: 2022-11-28")
echo "▶ Проверяю доступ и ищу последнюю версию…"
FULL="$(curl -fsS --max-time 30 "${HDR[@]}" -H "Accept: application/vnd.github.sha" "$API/commits/$BR")" || {
  echo "✗ Не получилось. Проверьте токен: доступ к $REPO, Contents: Read-only."; exit 1; }

umask 077; mkdir -p /etc/mirstudy
printf 'REPO=%q\nTOKEN=%q\n' "$REPO" "$TOKEN" > /etc/mirstudy/autoupdate.env
chmod 600 /etc/mirstudy/autoupdate.env; umask 022

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "▶ Скачиваю версию ${FULL:0:12}…"
curl -fsSL --max-time 900 "${HDR[@]}" -o "$WORK/pkg.zip" "$API/zipball/$FULL"
unzip -q "$WORK/pkg.zip" -d "$WORK"
DIR="$(find "$WORK" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[ -f "$DIR/setup.sh" ] || { echo "✗ В пакете нет setup.sh"; exit 1; }
echo
echo "Шаг 2. Настройка сайта"
bash "$DIR/setup.sh" "${1:-}" </dev/tty
echo "${FULL:0:12}" > /opt/mirstudy/.commit
