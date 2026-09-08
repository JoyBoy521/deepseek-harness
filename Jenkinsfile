pipeline {
    agent any
    
    parameters {
        choice(name:'ENV', choices:['dev','staging','prod'], description:'部署到哪个环境')
        string(name:'VERSION',defaultValue:'',description:'回滚时填旧版本号')
    }
    
    environment{
        IMAGE_NAME="my-deepseek_harness"
        IMAGE_TAG = "${params.VERSION != '' ? params.VERSION : env.BUILD_NUMBER}"
        HARBOR     = "harbor.example.com/library"
    }
    
    stages{
        
        stage('环境准备'){
            steps{
                sh 'docker --version && node --version'
            }
        }
        stage('拉取项目'){
            steps {
                git branch: 'master', url: 'https://github.com/JoyBoy521/deepseek-harness.git'
            }
        }
        
        stage('装依赖')
        {
            steps {
                sh 'pnpm install'
            }
        }
        
        stage('运行'){
            steps {
                sh "pnpm dev"
            }
        }
        
       
    }
}