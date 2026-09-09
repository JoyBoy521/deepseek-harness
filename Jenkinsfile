pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: '部署环境')
        booleanParam(name: 'CLEAN_IMAGES', defaultValue: true, description: '部署后清理旧镜像')
    }

    environment {
        IMAGE_NAME = "deepseek-harness"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        DEEPSEEK_API_KEY = credentials('deepseek-api-key')
    }

    stages {
        stage('环境准备') {
            steps { 
                sh 'docker --version && node --version' 
            }
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
                // 去掉了 --no-cache 加快构建速度，有需要可手动加回
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }
        
        stage('部署') {
            steps {
                // 停用并移除同名旧容器
                sh "docker stop ${IMAGE_NAME} || true"
                sh "docker rm ${IMAGE_NAME} || true"
                // 启动新容器
                sh "docker run -d --name ${IMAGE_NAME} --restart unless-stopped -p 8082:8082 \
                    -v dsh-data:/root/.dsh \
                    -e DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}\
                    -e DEEPSEEK_BASE_URL=https://api.deepseek.com \
                    ${IMAGE_NAME}:${IMAGE_TAG}" 
        }
        
        stage('清理旧镜像') {
            when {
                expression { params.CLEAN_IMAGES == true }
            }
            steps {
                sh '''
                # 保留最新镜像，清理同名历史旧镜像
                docker images ${IMAGE_NAME} --format "{{.Tag}}" | sort -rn | tail -n +2 | xargs -I {} docker rmi ${IMAGE_NAME}:{} || true
                # 清理悬空镜像和构建缓存
                docker image prune -f
                docker builder prune -f
                '''
            }
        }
    }

    post {
    success {
        sh '''
        # 等待 3 秒确保应用初始化并打印日志
        sleep 3
        TOKEN=$(docker logs deepseek-harness 2>/dev/null | grep -o 'token=[A-Za-z0-9_-]*' | tail -1 | sed 's/token=//')

        if [ -z "$TOKEN" ]; then
            sleep 3
            TOKEN=$(docker logs deepseek-harness 2>/dev/null | grep -o 'token=[A-Za-z0-9_-]*' | tail -1 | sed 's/token=//')
        fi

        echo "✅ 部署成功: http://192.168.187.128:8082/?token=${TOKEN:-'<未获取到，请手动执行 docker logs>'}"
        '''
            }
    failure { echo "❌ 构建失败" }
        }   

    }
}