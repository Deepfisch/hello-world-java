# Используем OpenJDK 11 как базовый образ
FROM openjdk:11-jre-slim

# Метаданные
LABEL maintainer="your-email@example.com"
LABEL version="1.0.0"
LABEL description="Hello World Java Application"

# Создаем директорию для приложения
WORKDIR /app

# Копируем jar файл из target директории
COPY target/hello-world-1.0.0.jar app.jar

# Экспонируем порт (если потребуется в будущем)
EXPOSE 8080

# Команда запуска приложения
ENTRYPOINT ["java", "-jar", "app.jar"]

# Добавляем health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD java -version || exit 1
