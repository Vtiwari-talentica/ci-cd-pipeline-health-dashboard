pipeline {
    agent any
    
    environment {
        DASHBOARD_WEBHOOK_URL = 'http://localhost:8001/webhook/jenkins'
        // Since Jenkins is running locally (not in Docker), use localhost
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
                
                try {
                    def response = sh(
                        script: """
                            curl -X POST '${DASHBOARD_WEBHOOK_URL}' \\
                            -H 'Content-Type: application/json' \\
                            -d '${jsonPayload}' \\
                            --connect-timeout 10 \\
                            --max-time 30
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "✅ Webhook sent successfully: ${response}"
                } catch (Exception e) {
                    echo "⚠️  Webhook failed: ${e.getMessage()}"
                    echo "Dashboard might not be running or webhook URL incorrect"
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
