pipeline {
    agent any
    
    environment {
        // Переменные окружения
        DOCKER_IMAGE = 'hello-world-java'
        DOCKER_TAG = "${BUILD_NUMBER}"
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }
    
    tools {
        maven 'Maven' // Убедитесь, что это имя соответствует вашей настройке в Jenkins
        jdk 'JDK-17'        // Убедитесь, что это имя соответствует вашей настройке в Jenkins
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
                sh '''
                    export PATH=/usr/bin:/usr/share/maven/bin:$PATH
                    mvn clean compile
                '''
            }
        }
        
        stage('Debug') {
            steps {
                sh 'echo $PATH'
                sh 'which java || echo "java not found"'
                sh 'which mvn || echo "mvn not found"'
                sh 'ls -la /usr/bin/mvn || echo "mvn not in /usr/bin"'
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