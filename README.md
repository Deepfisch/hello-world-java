# Hello World Java - Jenkins CI/CD Demo

Демонстрационный Java проект для настройки Jenkins CI/CD Pipeline с Docker.

## Структура проекта

```
hello-world-java/
├── src/main/java/com/example/HelloWorld.java
├── Dockerfile
├── pom.xml
├── Jenkinsfile
└── README.md
```

## Локальная сборка

```bash
# Сборка проекта
mvn clean package

# Запуск приложения
java -jar target/hello-world-1.0.0.jar

# Сборка Docker образа
docker build -t hello-world-java .

# Запуск в контейнере
docker run --rm hello-world-java
```

## Jenkins Pipeline

Pipeline автоматически:
1. Собирает проект с Maven
2. Запускает тесты
3. Создает Docker образ
4. Деплоит приложение
5. Очищает старые версии

## Настройка

1. Настройте Jenkins с необходимыми инструментами (JDK 11, Maven, Docker)
2. Создайте Pipeline job
3. Укажите этот репозиторий как источник
4. Pipeline будет запускаться автоматически при push в репозиторий
