pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: '部署环境')
        booleanParam(name: 'CLEAN_IMAGES', defaultValue: true, description: '部署后清理旧镜像')
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
            steps {
                sh '''
                pnpm config set registry https://registry.npmmirror.com
                pnpm install --frozen-lockfile
                '''
            }
        }
        
        stage('打包镜像') {
            steps {
                sh '''
                docker images ${IMAGE_NAME} --format "{{.Tag}}" | sort -rn | tail -n +2 | xargs -I {} docker rmi ${IMAGE_NAME}:{} || true
                '''
                
                timeout(time: 10, unit: 'MINUTES') {
                    sh "docker build --no-cache -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }
        
        stage('部署') {
            steps {
                sh "docker stop ${IMAGE_NAME} || true"
                sh "docker rm ${IMAGE_NAME} || true"
                sh "docker run -d --name ${IMAGE_NAME} -p 8082:3000 ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
        
        stage('清理') {
            when {
                expression { params.CLEAN_IMAGES == true }
            }
            steps {
                sh '''
                # 清理悬空镜像和构建缓存
                docker image prune -f
                docker builder prune -f
                '''
            }
        }
    }

    post {
        success { echo "✅ 部署成功: http://192.168.187.128:8082" }
        failure { echo "❌ 构建失败" }
        always {
            // 无论成败都清理工作区的大文件
            sh 'rm -rf node_modules_prod || true'
        }
    }
}
