pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: '部署环境')
        booleanParam(name: 'CLEAN_IMAGES', defaultValue: true, description: '清理本地缓存镜像')
        gitParameter(name: 'GIT_TAG', type: 'PT_TAG', defaultValue: '', sortMode: 'DESCENDING_SMART', description: '选择 Git 标签（留空=用分支）')
        gitParameter(name: 'GIT_BRANCH', type: 'PT_BRANCH', branchFilter: 'origin/(.*)',defaultValue: 'master', description: '选择 Git 分支')
    }

    environment {
        REGISTRY = "192.168.187.128:8088"
        PROJECT  = "joyboy"
        IMAGE    = "${REGISTRY}/${PROJECT}/deepseek-harness"
        HARBOR_USER = credentials('harbor-user')
        HARBOR_PASS = credentials('harbor-pass')
        DEEPSEEK_API_KEY = credentials('deepseek-api-key')
        APP_ENV = "${params.ENV}"
    }

    stages {
        stage('生成唯一标签') {
            steps {
                script {
                    env.TAG = sh(script: 'date +%Y%m%d', returnStdout: true).trim() + "u${env.BUILD_NUMBER}"
                    echo "本次构建标签: ${env.TAG}"
                }
            }
        }
        
        stage('拉取项目') {
            steps {
                script {
                    def ref = params.GIT_TAG ? "refs/tags/${params.GIT_TAG}" :
                              (params.GIT_BRANCH ? "*/${params.GIT_BRANCH}" : '*/master')
                    echo "本次检出: ${ref}"
                    checkout([$class: 'GitSCM',
                        branches: [[name: ref]],
                        userRemoteConfigs: [[url: 'https://github.com/JoyBoy521/deepseek-harness.git']]])
                }
            }
        }

        stage('打包镜像') {
            steps {
                sh "docker build -t ${IMAGE}:${TAG} ."
            }
        }

        stage('推送 Harbor') {
            steps {
                sh '''
                echo "$HARBOR_PASS" | docker login "$REGISTRY" -u "$HARBOR_USER" --password-stdin
                docker push "$IMAGE:$TAG"
                echo "已推送: $IMAGE:$TAG"
                '''
            }
        }

        stage('部署') {
            steps {
                sh "docker stop deepseek-harness || true"
                sh "docker rm deepseek-harness || true"
                sh '''
                docker pull "$IMAGE:$TAG"          # 显式从 Harbor 拉（保证部署的就是仓库里那一版）
                docker run -d --name deepseek-harness --restart unless-stopped -p 8082:8082 \
                  -v dsh-data:/root/.dsh \
                  -e DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" \
                  -e DEEPSEEK_BASE_URL="https://api.deepseek.com" \
                  -e APP_ENV="$APP_ENV" \
                  "$IMAGE:$TAG"
                docker logout "$REGISTRY"          # 用完再登出
                '''
            }
        }
        stage('健康检查') {
            steps {
                sh '''
                for i in $(seq 1 30); do
                  if docker exec deepseek-harness node -e "fetch('http://127.0.0.1:8082').then(()=>process.exit(0)).catch(()=>process.exit(1))" 2>/dev/null; then
                    echo "✅ 健康检查通过"; exit 0
                  fi
                  sleep 5
                done
                echo "❌ 健康检查失败"; docker logs deepseek-harness --tail 30; exit 1
                '''
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
                sh '''
                docker image prune -f
                docker images "$IMAGE" --format "{{.CreatedAt}}\t{{.Tag}}" | sort -r | tail -n +2 \| awk '{print $NF}' | xargs -I {} docker rmi "$IMAGE:{}" || true
                '''
            }
        }
    }

    post {
        success {
            sh '''
            for i in $(seq 1 30); do
              TOKEN=$(docker logs deepseek-harness 2>/dev/null | grep -o 'token=[A-Za-z0-9_-]*' | tail -1 | sed 's/token=//')
              if [ -n "$TOKEN" ]; then
                echo "✅ 部署成功: http://192.168.187.128:8082/?token=$TOKEN"
                echo "镜像: $IMAGE:$TAG | 分支: $GIT_BRANCH | 标签: $GIT_TAG"
                exit 0
              fi
              sleep 5
            done
            echo "⚠️ token 稍后: docker logs deepseek-harness | grep token"
            '''
        }
        failure { echo "❌ 构建失败" }
    }
}