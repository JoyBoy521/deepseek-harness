pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: '部署环境')
        booleanParam(name: 'CLEAN_IMAGES', defaultValue: false, description: '部署后清理')
    }

    environment {
        IMAGE_NAME = "deepseek-harness"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('环境准备') {
            steps { sh 'docker --version && node --version' }
        }
        stage('拉取项目') {
            steps {
                git branch: 'master', url: 'https://github.com/JoyBoy521/deepseek-harness.git'
            }
        }
        stage('装依赖') {
            steps { sh 'pnpm install' }
        }
        stage('打包镜像') {
            steps { sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ." }
        }
        stage('部署') {
            steps {
                sh "docker stop ${IMAGE_NAME} || true"
                sh "docker rm ${IMAGE_NAME} || true"
                sh "docker run -d --name ${IMAGE_NAME} -p 8082:3000 ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        success { echo "✅ 部署成功: ${IMAGE_NAME}:${IMAGE_TAG}" }
        failure { echo "❌ 构建失败" }
    }
}