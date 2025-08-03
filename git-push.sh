#!/bin/bash

# Скрипт для автоматической отправки всех изменений в GitHub

echo "🔄 Начинаем отправку изменений в GitHub..."

# Проверяем, что мы в Git репозитории
if [ ! -d ".git" ]; then
    echo "❌ Ошибка: Не найден Git репозиторий в текущей директории"
    echo "Убедитесь, что вы находитесь в корне Git проекта"
    exit 1
fi

# Показываем текущий статус
echo "📊 Текущий статус репозитория:"
git status --short

# Добавляем все изменения
echo "➕ Добавляем все изменения..."
git add .

# Проверяем, есть ли что коммитить
if git diff --staged --quiet; then
    echo "✅ Нет изменений для коммита"
    exit 0
fi

# Запрашиваем сообщение коммита или используем стандартное
if [ -z "$1" ]; then
    COMMIT_MESSAGE="Auto update: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "💬 Используем стандартное сообщение коммита: $COMMIT_MESSAGE"
else
    COMMIT_MESSAGE="$1"
    echo "💬 Сообщение коммита: $COMMIT_MESSAGE"
fi

# Делаем коммит
echo "📝 Создаем коммит..."
git commit -m "$COMMIT_MESSAGE"

# Пушим в репозиторий
echo "🚀 Отправляем изменения в GitHub..."
git push origin main

# Проверяем результат
if [ $? -eq 0 ]; then
    echo "✅ Изменения успешно отправлены в GitHub!"
    echo "📊 Итоговый статус:"
    git status --short
else
    echo "❌ Ошибка при отправке в GitHub"
    exit 1
fi

echo "🎉 Готово!"