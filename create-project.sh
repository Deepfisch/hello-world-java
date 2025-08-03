#!/bin/bash

# Скрипт для создания структуры проекта hello-world-java

echo "Создание структуры проекта hello-world-java..."

# Создаем основную директорию проекта
mkdir -p hello-world-java

# Переходим в директорию проекта
cd hello-world-java

# Создаем структуру Maven проекта
mkdir -p src/main/java/com/example
mkdir -p src/test/java/com/example

# Создаем HelloWorld.java
cat > src/main/java/com/example/HelloWorld.java << 'EOF'
package com.example;

public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello World from Jenkins CI/CD Pipeline!");
        System.out.println("Application version: 1.0.0");
        System.out.println("Build timestamp: " + java.time.LocalDateTime.now());
    }
}
EOF

# Создаем pom.xml
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>hello-world</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <n>Hello World Java App</n>
    <description>Demo Java application for Jenkins CI/CD</description>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
            
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.2.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.example.HelloWorld</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Создаем Dockerfile
cat > Dockerfile << 'EOF'
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
EOF

# Создаем Jenkinsfile
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        // Переменные окружения
        DOCKER_IMAGE = 'hello-world-java'
        DOCKER_TAG = "${BUILD_NUMBER}"
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }
    
    tools {
        maven 'Maven-3.8.1' // Убедитесь, что это имя соответствует вашей настройке в Jenkins
        jdk 'JDK-11'        // Убедитесь, что это имя соответствует вашей настройке в Jenkins
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Проверка исходного кода...'
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                echo 'Сборка проекта с Maven...'
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Запуск тестов...'
                sh 'mvn test'
            }
            post {
                always {
                    // Публикация результатов тестов
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'Упаковка приложения...'
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    // Архивирование артефактов
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Создание Docker образа...'
                script {
                    // Строим Docker образ
                    def dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    
                    // Также создаем тег latest
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo 'Тестирование Docker образа...'
                script {
                    // Запускаем контейнер для тестирования
                    sh "docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Развертывание приложения...'
                script {
                    // Останавливаем предыдущий контейнер если он есть
                    sh 'docker stop hello-world-container || true'
                    sh 'docker rm hello-world-container || true'
                    
                    // Запускаем новый контейнер
                    sh """
                        docker run -d \
                        --name hello-world-container \
                        --restart unless-stopped \
                        ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                echo 'Очистка старых образов...'
                script {
                    // Удаляем старые образы (оставляем последние 5)
                    sh '''
                        docker images ${DOCKER_IMAGE} --format "table {{.Tag}}" | \
                        grep -v latest | grep -v TAG | sort -nr | tail -n +6 | \
                        xargs -I {} docker rmi ${DOCKER_IMAGE}:{} || true
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline выполнен'
            // Очистка workspace
            cleanWs()
        }
        success {
            echo 'Pipeline успешно завершен!'
            // Здесь можно добавить уведомления (email, Slack и т.д.)
        }
        failure {
            echo 'Pipeline завершился с ошибкой!'
            // Здесь можно добавить уведомления об ошибках
        }
    }
}
EOF

# Создаем README.md
cat > README.md << 'EOF'
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
EOF

# Создаем .gitignore
cat > .gitignore << 'EOF'
# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iml
.vscode/
.settings/
.project
.classpath

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF

echo "✅ Проект создан успешно!"
echo ""
echo "Следующие шаги:"
echo "1. cd hello-world-java"
echo "2. git init"
echo "3. git add ."
echo "4. git commit -m 'Initial commit'"
echo "5. git remote add origin <your-repo-url>"
echo "6. git push -u origin main"
echo ""
echo "Для локального тестирования:"
echo "mvn clean package && java -jar target/hello-world-1.0.0.jar"