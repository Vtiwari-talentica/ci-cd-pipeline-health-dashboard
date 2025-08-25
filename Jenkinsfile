pipeline {
    agent any
    
    environment {
        // Try multiple possible URLs for reaching the dashboard
        DASHBOARD_WEBHOOK_URL = 'http://localhost:8001/webhook/jenkins'
        FALLBACK_WEBHOOK_URL = 'http://host.docker.internal:8001/webhook/jenkins'
        DOCKER_BRIDGE_URL = 'http://172.17.0.1:8001/webhook/jenkins'
        BUILD_NAME = "${env.JOB_NAME}"
        BUILD_ID = "${env.BUILD_NUMBER}"
        REPO_NAME = "Vtiwari-talentica/ci-cd-pipeline-health-dashboard"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out code...'
                // Simulate checkout
                script {
                    currentBuild.description = "Build #${BUILD_NUMBER}"
                }
                sleep 2
                echo '✅ Code checked out successfully'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo '📦 Installing dependencies...'
                // Simulate npm/pip install
                script {
                    sh 'echo "Installing dependencies for ${BUILD_NAME}"'
                }
                sleep 3
                echo '✅ Dependencies installed'
            }
        }
        
        stage('Lint & Format') {
            steps {
                echo '🔍 Running linting...'
                // Simulate linting
                sleep 1
                echo '✅ Code linting passed'
            }
        }
        
        stage('Build') {
            steps {
                echo '🔨 Building application...'
                // Simulate build process
                script {
                    sh 'echo "Building ${BUILD_NAME} #${BUILD_NUMBER}"'
                }
                sleep 4
                echo '✅ Application built successfully'
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                script {
                    // Simulate tests with occasional failures (10% chance)
                    def random = new Random()
                    def shouldFail = random.nextInt(10) == 0
                    
                    if (shouldFail) {
                        echo '❌ Tests failed!'
                        error('Test failure simulation')
                    } else {
                        echo '✅ All tests passed!'
                    }
                }
                sleep 2
            }
        }
        
        stage('Deploy') {
            when {
                expression { currentBuild.result != 'FAILURE' }
            }
            steps {
                echo '🚀 Deploying application...'
                sleep 1
                echo '✅ Application deployed successfully'
            }
        }
    }
    
    post {
        always {
            script {
                // Send webhook to dashboard
                def startTime = new Date(currentBuild.startTimeInMillis).format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                def endTime = new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                def status = currentBuild.result ?: 'SUCCESS'
                def conclusion = status == 'SUCCESS' ? 'success' : 'failure'
                
                def webhookData = [
                    repository: [
                        full_name: "${REPO_NAME}"
                    ],
                    workflow: [
                        name: "${BUILD_NAME}"
                    ],
                    workflow_run: [
                        id: BUILD_ID as Integer,
                        name: "${BUILD_NAME}",
                        status: "completed",
                        conclusion: conclusion,
                        run_number: BUILD_ID as Integer,
                        created_at: startTime,
                        updated_at: endTime,
                        html_url: "${BUILD_URL}"
                    ],
                    action: "completed"
                ]
                
                def jsonPayload = groovy.json.JsonBuilder(webhookData).toString()
                
                echo "📡 Sending webhook to dashboard..."
                echo "Webhook URL: ${DASHBOARD_WEBHOOK_URL}"
                echo "Payload: ${jsonPayload}"
                
                // Try multiple URLs to reach the dashboard
                def webhookUrls = [
                    "${DASHBOARD_WEBHOOK_URL}",
                    "${FALLBACK_WEBHOOK_URL}", 
                    "${DOCKER_BRIDGE_URL}"
                ]
                
                def webhookSent = false
                for (url in webhookUrls) {
                    if (webhookSent) break
                    
                    try {
                        echo "Trying webhook URL: ${url}"
                        def response = sh(
                            script: """
                                curl -X POST '${url}' \\
                                -H 'Content-Type: application/json' \\
                                -d '${jsonPayload}' \\
                                --connect-timeout 5 \\
                                --max-time 10
                            """,
                            returnStdout: true
                        ).trim()
                        
                        echo "✅ Webhook sent successfully via ${url}: ${response}"
                        webhookSent = true
                    } catch (Exception e) {
                        echo "⚠️ Webhook failed with ${url}: ${e.getMessage()}"
                    }
                }
                
                if (!webhookSent) {
                    echo "❌ All webhook URLs failed. Dashboard might not be reachable."
                }
            }
        }
        
        success {
            echo '🎉 Pipeline completed successfully!'
        }
        
        failure {
            echo '💥 Pipeline failed!'
        }
        
        cleanup {
            echo '🧹 Cleaning up workspace...'
        }
    }
}
