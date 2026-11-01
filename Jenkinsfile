def runMaven(String args) {
    if (isUnix()) {
        sh "mvn -B -ntp ${args}"
    } else {
        bat "mvn -B -ntp ${args}"
    }
}

def runDeploy(String environment, String tag) {
    if (params.DEPLOY_MODE == 'vm') {
        sh """
            JAR=\$(ls ${WORKSPACE}/target/*.jar | head -1)
            sudo /usr/local/bin/odsoft-deploy ${environment} ${tag} "\$JAR"
        """
    } else if (isUnix()) {
        sh "bash deploy/deploy.sh ${environment} ${tag}"
    } else {
        bat "powershell -ExecutionPolicy Bypass -File deploy/deploy.ps1 -Env ${environment} -Tag ${tag}"
    }
}

def runSmoke(String environment) {
    if (params.DEPLOY_MODE == 'vm') {
        sh "bash deploy/vm/smoke.sh ${environment}"
    } else if (isUnix()) {
        sh "bash deploy/smoke.sh ${environment}"
    } else {
        bat "powershell -ExecutionPolicy Bypass -File deploy/smoke.ps1 -Env ${environment}"
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

    parameters {
        booleanParam(
            name: 'DEPLOY',
            defaultValue: false,
            description: 'Executar deployment para dev/staging/prod.'
        )
        choice(
            name: 'DEPLOY_MODE',
            choices: ['vm', 'docker'],
            description: 'vm = JAR + systemd; docker = contentores locais.'
        )
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

        stage('System Tests') {
            steps {
                script {
                    runMaven('-Dtest=SystemTest test')
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

        stage('Coverage Gate') {
            steps {
                script {
                    runMaven('jacoco:check')
                }
            }
        }

        stage('Mutation Testing') {
            steps {
                script {
                    runMaven('org.pitest:pitest-maven:mutationCoverage')
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

        stage('Deploy Dev') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                script {
                    runDeploy('dev', env.BUILD_NUMBER)
                }
            }
        }

        stage('Smoke Dev') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                script {
                    runSmoke('dev')
                }
            }
        }

        stage('Deploy Staging') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                script {
                    runDeploy('staging', env.BUILD_NUMBER)
                }
            }
        }

        stage('Smoke Staging') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                script {
                    runSmoke('staging')
                }
            }
        }

        stage('Aprovar Prod') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                input message: 'Aprovar deployment para produção?', ok: 'Deploy'
            }
        }

        stage('Deploy Prod') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                script {
                    runDeploy('prod', env.BUILD_NUMBER)
                }
            }
        }

        stage('Smoke Prod') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DEPLOY }
                }
            }
            steps {
                script {
                    runSmoke('prod')
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
            recordIssues(tools: [checkStyle(pattern: 'target/checkstyle-result.xml')])
            archiveArtifacts artifacts: 'target/*.jar, target/site/jacoco/**/*, target/checkstyle-result.xml, target/spotbugsXml.xml, target/pit-reports/**/*',
                             allowEmptyArchive: true
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target/site/jacoco',
                reportFiles: 'index.html',
                reportName: 'JaCoCo Coverage'
            ])
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target/pit-reports',
                reportFiles: 'index.html',
                reportName: 'PIT Mutation'
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
