pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: '部署环境')
        booleanParam(name: 'CLEAN_IMAGES', defaultValue: true, description: '清理本地缓存镜像')
    }

    environment {
        REGISTRY = "192.168.187.128:8088"
        PROJECT  = "joyboy"
        IMAGE    = "${REGISTRY}/${PROJECT}/deepseek-harness"
        TAG      = "${env.BUILD_NUMBER}"
        HARBOR_USER = credentials('harbor-user')
        HARBOR_PASS = credentials('harbor-pass')
        DEEPSEEK_API_KEY = credentials('deepseek-api-key')
    }

    stages {
        stage('拉取项目') {
            steps {
                git branch: 'master', url: 'https://github.com/JoyBoy521/deepseek-harness.git'
            }
        }

        stage('打包镜像') {
            steps {
                sh "docker build -t ${IMAGE}:${TAG} ."
            }
        }

        stage('推送 Harbor') {
            steps {
                // 使用双引号，确保 IMAGE 和 TAG 变量能正常解析；对密码变量用单引号防泄漏
                sh """
                echo "${HARBOR_PASS}" | docker login ${REGISTRY} -u "${HARBOR_USER}" --password-stdin
                docker push ${IMAGE}:${TAG}
                docker logout "$REGISTRY" 
                echo "已推送: ${IMAGE}:${TAG}"
                """
            }
        }

        stage('部署') {
            steps {
                sh "docker stop deepseek-harness || true"
                sh "docker rm deepseek-harness || true"
                // 添加每行末尾的转义斜杠 \，防止脚本多行中断
                sh """
                docker run -d --name deepseek-harness --restart unless-stopped -p 8082:8082 \
                  -v dsh-data:/root/.dsh \
                  -e DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY}" \
                  -e DEEPSEEK_BASE_URL="https://api.deepseek.com" \
                  -e APP_ENV="${params.ENV}" \
                  ${IMAGE}:${TAG}
                """
            }
        }

        stage('记录版本') {
            steps {
                sh '''
                mkdir -p "$JENKINS_HOME/releases"
                echo "$TAG" > "$JENKINS_HOME/releases/current.txt"
                echo "当前部署版本: $(cat "$JENKINS_HOME/releases/current.txt")"
                '''
            }
        }

        stage('清理') {
            when { expression { params.CLEAN_IMAGES == true } }
            steps {
                sh """
                docker image prune -f
                docker builder prune -f
                # 保留最新镜像，清理本地历史残留
                docker images ${IMAGE} --format "{{.Tag}}" | sort -n | head -n -1 | xargs -I {} docker rmi ${IMAGE}:{} || true
                """
            }
        }
    }

    post {
        success {
            sh """
            for i in \$(seq 1 30); do
              TOKEN=\$(docker logs deepseek-harness 2>/dev/null | grep -o 'token=[A-Za-z0-9_-]*' | tail -1 | sed 's/token=//')
              if [ -n "\$TOKEN" ]; then
                echo "✅ 部署成功: http://192.168.187.128:8082/?token=\$TOKEN"
                echo "镜像: ${IMAGE}:${TAG}  回滚用: docker run ... ${IMAGE}:<上一版tag>"
                exit 0
              fi
              sleep 5
            done
            echo "⚠️ token 稍后: docker logs deepseek-harness | grep token"
            """
        }
        failure { echo "❌ 构建失败" }
    }
}