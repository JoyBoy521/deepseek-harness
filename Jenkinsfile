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
                
                # 装全部依赖
                pnpm install --frozen-lockfile
                
                # 装生产依赖（跳过 postinstall）
                rm -rf node_modules_prod
                NODE_ENV=production pnpm install --prod --frozen-lockfile --ignore-scripts
                cp -r node_modules node_modules_prod
                
                # 恢复完整依赖
                pnpm install --frozen-lockfile
                '''
            }
        }
        
        stage('打包镜像') {
            steps {
                sh '''
                docker images ${IMAGE_NAME} --format "{{.Tag}}" | sort -rn | tail -n +3 | xargs -I {} docker rmi ${IMAGE_NAME}:{} || true
                '''
                
                timeout(time: 10, unit: 'MINUTES') {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
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
                docker image prune -f
                rm -rf node_modules_prod
                '''
            }
        }
    }

    post {
        success { echo "✅ 部署成功: http://192.168.187.128:8082" }
        failure { echo "❌ 构建失败" }
    }
}
