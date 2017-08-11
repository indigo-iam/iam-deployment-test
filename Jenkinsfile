#!/usr/bin/env groovy

pipeline {
  agent { label 'kubectl' }
  
  options {
    timeout(time: 1, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  triggers { cron('@daily') }
  
  parameters {
    choice(name: 'BROWSER',          choices: 'chrome\nfirefox', description: '')
    string(name: 'IAM_IMAGE',        defaultValue: 'indigoiam/iam-login-service:v1.0.0.rc1-SNAPSHOT-latest', description: 'IAM docker image name')
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
  }
  
  stages {
    stage('prepare'){
      steps {
        deleteDir()
        checkout scm
        sh "mkdir -p ${env.OUTPUT_REPORTS}"
      }
    }
    
    stage('test'){
      steps {
        script {
          dir('kubernetes'){
            sh "./generate_deploy_templates.sh"
            sh "IAM_BASE_URL=https://iam-nginx-${BROWSER}.default.svc.cluster.local ./generate_ts_pod_conf.sh"
          }
        }
        
        sh "kubectl apply -f kubernetes/mysql.deploy.yaml"
        sh "kubectl rollout status deploy/iam-db-${params.BROWSER} | grep -q 'successfully rolled out'"
        
        sh "kubectl apply -f kubernetes/ts-params.cm.yaml -f kubernetes/iam-login-service.secret.yaml"
        
        sh "kubectl apply -f kubernetes/iam-login-service.deploy.yaml"
        sh "kubectl rollout status deploy/iam-login-service-${params.BROWSER} | grep -q 'successfully rolled out'"
        
        sh "kubectl apply -f kubernetes/iam-nginx.deploy.yaml"
        sh "kubectl rollout status deploy/iam-nginx-${params.BROWSER} | grep -q 'successfully rolled out'"
        
        sh "kubectl apply -f kubernetes/iam-testsuite.pod.yaml"
        sh "while ( [ 'Running' != `kubectl get pod ${env.POD_NAME} -o jsonpath='{.status.phase}'` ] ); do echo 'Waiting testsuite...'; sleep 5; done"
        
        sh "kubectl logs -f ${env.POD_NAME}"
      }
      
      post {
        always {
          sh "kubectl delete -f kubernetes/iam-nginx.deploy.yaml"
          sh "kubectl delete -f kubernetes/iam-login-service.deploy.yaml"
          sh "kubectl delete -f kubernetes/mysql.deploy.yaml"
          sh "kubectl delete -f kubernetes/iam-testsuite.pod.yaml"
        }
      }
    }
    
    stage('process output'){
      steps {
        script {
          dir("${env.OUTPUT_REPORTS}"){
            archiveArtifacts "**"
          }
        
          step([$class: 'RobotPublisher',
            disableArchiveOutput: false,
            logFileName: 'log.html',
            otherFiles: '*.png',
            outputFileName: 'output.xml',
            outputPath: "${env.OUTPUT_REPORTS}",
            passThreshold: 100,
            reportFileName: 'report.html',
            unstableThreshold: 90]);
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
        if('SUCCESS'.equals(currentBuild.result)) {
          slackSend color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Back to normal (<${env.BUILD_URL}|Open>)"
        }
      }
    }
  }
}

