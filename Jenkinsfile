def runMaven(String args) {
    if (isUnix()) {
        sh "mvn -B -ntp ${args}"
    } else {
        bat "mvn -B -ntp ${args}"
    }
}

pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    currentBuild.description = "${env.GIT_BRANCH} @ ${env.GIT_COMMIT?.take(8)}"
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    runMaven('clean compile')
                }
            }
        }

        stage('Static Analysis') {
            steps {
                script {
                    runMaven('-DskipTests checkstyle:checkstyle spotbugs:spotbugs')
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    runMaven('test')
                }
            }
        }

        stage('Coverage') {
            steps {
                script {
                    runMaven('jacoco:report')
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    runMaven('-DskipTests package')
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
            jacoco execPattern: 'target/jacoco.exec',
                   classPattern: 'target/classes',
                   sourcePattern: 'src/main/java'
            recordIssues(tools: [checkStyle(pattern: 'target/checkstyle-result.xml')])
            archiveArtifacts artifacts: 'target/*.jar, target/site/jacoco/**/*, target/checkstyle-result.xml, target/spotbugsXml.xml',
                             allowEmptyArchive: true
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target/site/jacoco',
                reportFiles: 'index.html',
                reportName: 'JaCoCo Coverage'
            ])
        }
        success {
            echo 'Pipeline concluído com sucesso.'
        }
        failure {
            echo 'Pipeline falhou. Consultar os relatórios e os logs.'
        }
    }
}
