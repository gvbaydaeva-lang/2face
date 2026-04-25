#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) не найден. Установите gh и повторите."
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Использование: ./publish.sh <repo-name> [public|private]"
  exit 1
fi

REPO_NAME="$1"
VISIBILITY="${2:-public}"

if [ "$VISIBILITY" != "public" ] && [ "$VISIBILITY" != "private" ]; then
  echo "Видимость должна быть public или private"
  exit 1
fi

echo "Проверка авторизации GitHub..."
gh auth status >/dev/null

echo "Создание репозитория и push..."
gh repo create "$REPO_NAME" --"$VISIBILITY" --source=. --remote=origin --push

echo "Включение GitHub Pages через GitHub Actions..."
gh api -X POST "repos/{owner}/${REPO_NAME}/pages" -f build_type=workflow >/dev/null 2>&1 || true
gh api -X PUT "repos/{owner}/${REPO_NAME}/pages" -f build_type=workflow >/dev/null 2>&1 || true

echo "Готово. Ссылка на репозиторий:"
gh repo view --json url -q .url
echo "Ожидаемая ссылка сайта (после завершения workflow):"
echo "https://$(gh api user -q .login).github.io/${REPO_NAME}/"
