@Library('Shared') _
pipeline {
    agent any
    
    environment{
        SONAR_HOME = tool "Sonar"
    }
    
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }
    
    stages {
        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG must be provided.")
                    }
                }
            }
        }
        stage("Workspace cleanup"){
            steps{
                script{
                    cleanWs()
                }
            }
        }
        
        stage('Git: Code Checkout') {
            steps {
                script{
                    code_checkout("https://github.com/pawanpatil3355/PICT_LOST_AND_FOUND.git","main")
                }
            }
        }
        
        stage("Trivy: Filesystem scan"){
            steps{
                script{
                    trivy_scan()
                }
            }
        }

        stage("OWASP: Dependency check"){
            steps{
                script{
                    owasp_dependency()
                }
            }
        }
        
        stage("SonarQube: Code Analysis"){
            steps{
                script{
                    sonarqube_analysis("Sonar","lostnfound","lostnfound")
                }
            }
        }
        
        stage("SonarQube: Code Quality Gates"){
            steps{
                script{
                    sonarqube_code_quality()
                }
            }
        }
        
        stage('Generate Environment Files from Credentials') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'MONGO_URI', variable: 'MONGO_URI_VAL'),
                        string(credentialsId: 'JWT_SECRET', variable: 'JWT_SECRET_VAL'),
                        string(credentialsId: 'CLOUDINARY_CLOUD_NAME', variable: 'CLOUDINARY_CLOUD_NAME_VAL'),
                        string(credentialsId: 'CLOUDINARY_API_KEY', variable: 'CLOUDINARY_API_KEY_VAL'),
                        string(credentialsId: 'CLOUDINARY_API_SECRET', variable: 'CLOUDINARY_API_SECRET_VAL')
                    ]) {
                        sh '''
                            # Generate server/.env.docker from Jenkins credentials
                            cat > server/.env.docker << EOF
# Server environment for Docker Compose
# Generated dynamically from Jenkins credentials
NODE_ENV=production
PORT=8080
MONGO_URI=${MONGO_URI_VAL}
JWT_SECRET=${JWT_SECRET_VAL}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME_VAL}
CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY_VAL}
CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET_VAL}
ACCESS_COOKIE_MAXAGE=120000
ACCESS_TOKEN_EXPIRES_IN=120s
REFRESH_COOKIE_MAXAGE=120000
REFRESH_TOKEN_EXPIRES_IN=120s
EOF
                            echo "✓ Generated server/.env.docker"
                        '''
                    }
                    
                    withCredentials([
                        string(credentialsId: 'REACT_APP_API_URL', variable: 'REACT_APP_API_URL_VAL')
                    ]) {
                        sh '''
                            # Generate client/.env.docker from Jenkins credentials
                            cat > client/.env.docker << EOF
# Client environment for Docker Compose
# Generated dynamically from Jenkins credentials
REACT_APP_API_URL=${REACT_APP_API_URL_VAL}
EOF
                            echo "✓ Generated client/.env.docker"
                        '''
                    }
                }
            }
        }
        
        stage('Update Environment Variables from EC2') {
            parallel {
                stage("Backend env setup") {
                    steps {
                        withCredentials([
                            [$class: 'AmazonWebServicesCredentialsBinding',
                             credentialsId: 'aws-credentials']
                        ]) {
                            dir("Automations") {
                                sh "bash updatebackendnew.sh"
                            }
                        }
                    }
                }

                stage("Frontend env setup") {
                    steps {
                        withCredentials([
                            [$class: 'AmazonWebServicesCredentialsBinding',
                             credentialsId: 'aws-credentials']
                        ]) {
                            dir("Automations") {
                                sh "bash updatefrontendnew.sh"
                            }
                        }
                    }
                }
            }
        }
        
        stage("Docker: Build Images"){
            steps{
                script{
                        dir('server'){
                            docker_build("pawanpatil3355/pict-lost-and-found-backend","${params.BACKEND_DOCKER_TAG}","pawanpatil3355")
                        }
                    
                        dir('client'){
                            docker_build("pawanpatil3355/pict-lost-and-found-frontend","${params.FRONTEND_DOCKER_TAG}","pawanpatil3355")
                        }
                }
            }
        }
        
        stage("Docker: Push to DockerHub"){
            steps{
                script{
                    docker_push("pawanpatil3355/pict-lost-and-found-backend","${params.BACKEND_DOCKER_TAG}","pawanpatil3355") 
                    docker_push("pawanpatil3355/pict-lost-and-found-frontend","${params.FRONTEND_DOCKER_TAG}","pawanpatil3355")
                }
            }
        }
    }
    post{
        success{
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
            build job: "LostnFound-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
                string(name: 'BACKEND_DOCKER_TAG', value: "${params.BACKEND_DOCKER_TAG}")
            ]
        }
    }
}
