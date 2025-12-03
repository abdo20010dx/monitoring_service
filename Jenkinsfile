pipeline {
    agent any
    environment {
        CONFIG_FILE = 'JF.conf'
    }

    stages {
        stage('Load Configuration') {
            steps {
                script {
                    try {
                        // Attempt to read the properties file
                        def config = readProperties file: env.CONFIG_FILE

                        // Assign environment variables from properties file
                        env.COMPOSE_PROJECT_NAME = config.compose_project_name
                        env.PROMETHEUS_PORT = config.prometheus_port
                        env.ALERTMANAGER_PORT = config.alertmanager_port
                        env.LOGS = config.logs

                        echo "Configuration loaded successfully:"
                        echo "COMPOSE_PROJECT_NAME = ${env.COMPOSE_PROJECT_NAME}"
                        echo "PROMETHEUS_PORT = ${env.PROMETHEUS_PORT}"
                        echo "ALERTMANAGER_PORT = ${env.ALERTMANAGER_PORT}"
                        echo "LOGS = ${env.LOGS}"
                    } catch (Exception e) {
                        // Handle error if properties file fails to load
                        echo "Error loading configuration file: ${e.message}"
                        error("Failed to load configuration. Check if ${env.CONFIG_FILE} exists and is correctly formatted.")
                    }
                }
            }
        }

        stage('Clean up existing containers') {
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            set -e
                            # Stop and remove containers if they exist
                            docker compose -p ${env.COMPOSE_PROJECT_NAME} down -v || true
                            # Clean up unused images
                            docker builder prune -f
                        """
                    } else {
                        powershell """
                            # Stop and remove containers if they exist
                            docker compose -p ${env.COMPOSE_PROJECT_NAME} down -v
                            if (\$LASTEXITCODE -ne 0) {
                                Write-Host "No existing containers to remove"
                            }
                            # Clean up unused images
                            docker builder prune -f
                        """
                    }
                }
            }
        }

        stage('Validate Configuration') {
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            # Validate docker-compose file
                            docker compose config
                            echo "✅ Docker Compose configuration is valid"
                        """
                    } else {
                        powershell """
                            # Validate docker-compose file
                            docker compose config
                            if (\$LASTEXITCODE -eq 0) {
                                Write-Host "✅ Docker Compose configuration is valid"
                            } else {
                                throw "Docker Compose configuration validation failed"
                            }
                        """
                    }
                }
            }
        }

        stage('Start Monitoring Services') {
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            # Start services using docker compose
                            docker compose -p ${env.COMPOSE_PROJECT_NAME} up -d
                            echo "✅ Monitoring services started successfully"
                            echo "📊 Prometheus: http://localhost:${env.PROMETHEUS_PORT}"
                            echo "🔔 Alertmanager: http://localhost:${env.ALERTMANAGER_PORT}"
                        """
                    } else {
                        powershell """
                            # Start services using docker compose
                            docker compose -p ${env.COMPOSE_PROJECT_NAME} up -d
                            if (\$LASTEXITCODE -eq 0) {
                                Write-Host "✅ Monitoring services started successfully"
                                Write-Host "📊 Prometheus: http://localhost:${env.PROMETHEUS_PORT}"
                                Write-Host "🔔 Alertmanager: http://localhost:${env.ALERTMANAGER_PORT}"
                            } else {
                                throw "Failed to start monitoring services"
                            }
                        """
                    }
                }
            }
        }

        stage('Verify Services') {
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            # Wait a few seconds for services to start
                            sleep 10
                            # Check if containers are running
                            docker compose -p ${env.COMPOSE_PROJECT_NAME} ps
                            # Verify Prometheus is responding
                            curl -f http://localhost:${env.PROMETHEUS_PORT}/-/healthy || echo "⚠️ Prometheus health check failed (may still be starting)"
                            # Verify Alertmanager is responding
                            curl -f http://localhost:${env.ALERTMANAGER_PORT}/-/healthy || echo "⚠️ Alertmanager health check failed (may still be starting)"
                        """
                    } else {
                        powershell """
                            # Wait a few seconds for services to start
                            Start-Sleep -Seconds 10
                            # Check if containers are running
                            docker compose -p ${env.COMPOSE_PROJECT_NAME} ps
                            # Verify Prometheus is responding
                            try {
                                \$response = Invoke-WebRequest -Uri "http://localhost:${env.PROMETHEUS_PORT}/-/healthy" -UseBasicParsing -TimeoutSec 5
                                Write-Host "✅ Prometheus is healthy"
                            } catch {
                                Write-Host "⚠️ Prometheus health check failed (may still be starting)"
                            }
                            # Verify Alertmanager is responding
                            try {
                                \$response = Invoke-WebRequest -Uri "http://localhost:${env.ALERTMANAGER_PORT}/-/healthy" -UseBasicParsing -TimeoutSec 5
                                Write-Host "✅ Alertmanager is healthy"
                            } catch {
                                Write-Host "⚠️ Alertmanager health check failed (may still be starting)"
                            }
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Monitoring services deployed successfully!'
            echo "📊 Access Prometheus at: http://localhost:${env.PROMETHEUS_PORT}"
            echo "🔔 Access Alertmanager at: http://localhost:${env.ALERTMANAGER_PORT}"
        }
        failure {
            echo '❌ Failed to deploy monitoring services.'
            script {
                if (isUnix()) {
                    sh "docker compose -p ${env.COMPOSE_PROJECT_NAME} logs --tail=50"
                } else {
                    powershell "docker compose -p ${env.COMPOSE_PROJECT_NAME} logs --tail=50"
                }
            }
        }
        always {
            echo 'Pipeline execution completed.'
        }
    }
}

