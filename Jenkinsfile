pipeline {
  agent { label 'kubectl' }
  
  options {
    timeout(time: 4, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  triggers { cron('@daily') }
  
  parameters {
    choice(name: 'BROWSER',          choices: 'chrome\nfirefox', description: '')
    string(name: 'IAM_IMAGE',        defaultValue: 'indigoiam/iam-login-service:v1.5.0-SNAPSHOT-latest', description: 'IAM docker image name')
    string(name: 'TESTSUITE_REPO',   defaultValue: 'https://github.com/indigo-iam/iam-robot-testsuite.git', description: 'Testsuite code repository')
    string(name: 'TESTSUITE_BRANCH', defaultValue: 'develop', description: 'Testsuite code repository')
    string(name: 'TESTSUITE_OPTS',   defaultValue: '--exclude=test-client', description: 'Additional testsuite options')
  }

  environment {
    OUTPUT_REPORTS = "/srv/scratch/${env.BUILD_TAG}/reports"
    POD_NAME = "iam-ts-${env.BUILD_NUMBER}"
    BROWSER = "${params.BROWSER}"
    IAM_IMAGE ="${params.IAM_IMAGE}"
    TESTSUITE_REPO = "${params.TESTSUITE_REPO}"
    TESTSUITE_BRANCH ="${params.TESTSUITE_BRANCH}"
    TESTSUITE_OPTS = "${params.TESTSUITE_OPTS}"
    IAM_BASE_URL = "https://iam-deploy-test-${env.BUILD_NUMBER}.default.svc.cluster.local"
    IAM_HTTP_SCHEME = "https"
    IAM_HTTP_HOST = "iam-deploy-test-${env.BUILD_NUMBER}.default.svc.cluster.local"
    DOCKER_REGISTRY_HOST = "${env.DOCKER_REGISTRY_HOST}"
    BUILD_NUMBER = "${env.BUILD_NUMBER}"
  }
  
  stages {
    stage('prepare images'){
      agent { label 'docker' }
      steps {
        container('docker-runner'){
          checkout scm
          dir('docker-images/nginx'){
            sh './build-image.sh'
            sh './push-image.sh'
          }
        }
      }
    }

    stage('prepare deploy'){
      steps {
        container('kubectl-runner'){
          checkout scm
          sh "mkdir -p ${env.OUTPUT_REPORTS}"
          sh "./generate_deploy_files.sh"
          sh "./generate_ts_pod_file.sh"
        }
      }
    }
    
    stage('test'){
      steps {
        container('kubectl-runner'){
          sh "kubectl apply -f kubernetes/mysql.deploy.yaml"
          sh "kubectl rollout status deploy/iam-db-${env.BUILD_NUMBER} | grep -q 'successfully rolled out'"
        
          sh "kubectl apply -f kubernetes/ts-params.cm.yaml -f kubernetes/saml.secret.yaml -f kubernetes/ssl.secret.yaml"
        
          sh "kubectl apply -f kubernetes/iam.deploy.yaml"
          sh "kubectl rollout status deploy/iam-deploy-test-${env.BUILD_NUMBER} | grep -q 'successfully rolled out'"
        
          sh "kubectl apply -f kubernetes/iam-testsuite.pod.yaml"
          sh "while ( [ 'Running' != `kubectl get pod ${env.POD_NAME} -o jsonpath='{.status.phase}'` ] ); do echo 'Waiting testsuite...'; sleep 5; done"
        
          sh "kubectl logs -f ${env.POD_NAME}"
        }
      }
      post {
        always {
          container('kubectl-runner'){
            sh "kubectl delete -f kubernetes/"
          }
        }
      }
    }
    
    stage('process output'){
      steps {
      	container('kubectl-runner'){
      	  sh "cp -rv ${env.OUTPUT_REPORTS} ."
		  dir("reports"){
            archiveArtifacts "**"
          }
          
          script {
            step([$class: 'RobotPublisher',
              disableArchiveOutput: false,
              logFileName: 'log.html',
              otherFiles: '*.png',
              outputFileName: 'output.xml',
              outputPath: "reports",
              passThreshold: 100,
              reportFileName: 'report.html',
              unstableThreshold: 90]);
          }
        }
      }
    }
  }
  
  post {
    failure {
      slackSend color: 'danger', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Failure (<${env.BUILD_URL}|Open>)"
    }
    
    unstable {
      slackSend color: 'warning', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Unstable (<${env.BUILD_URL}|Open>)"
    }

    changed {
      script{
        if('SUCCESS'.equals(currentBuild.currentResult)) {
          slackSend color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Back to normal (<${env.BUILD_URL}|Open>)"
        }
      }
    }
  }
}

