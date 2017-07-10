#!groovy
// name: iam-deployment-test

properties([
  buildDiscarder(logRotator(numToKeepStr: '5')),
  pipelineTriggers([cron('@daily')]),
  parameters([
    choice(name: 'BROWSER',          choices: 'chrome\nfirefox', description: ''),
    string(name: 'IAM_IMAGE',        defaultValue: 'indigoiam/iam-login-service:v1.0.0.rc0-SNAPSHOT-latest', description: 'IAM docker image name'),
    string(name: 'TESTSUITE_REPO',   defaultValue: 'https://github.com/indigo-iam/iam-robot-testsuite.git', description: 'Testsuite code repository'),
    string(name: 'TESTSUITE_BRANCH', defaultValue: 'develop', description: 'Testsuite code repository'),
    string(name: 'TESTSUITE_OPTS',   defaultValue: '--exclude=test-client', description: 'Additional testsuite options')
  ]),
])

def pod_name, report_dir

node('kubectl') {
  stage('Prepare'){
    checkout scm
    
    pod_name = "iam-ts-${UUID.randomUUID().toString()}"
    report_dir = "/srv/scratch/${pod_name}/reports"
    
    sh "mkdir -p ${report_dir}"
  }
  
  stage("Test"){
    withEnv([
      "BROWSER=${params.BROWSER}",
      "IAM_IMAGE=${params.IAM_IMAGE}",
      "POD_NAME=${pod_name}",
      "OUTPUT_REPORTS=${report_dir}",
      "TESTSUITE_REPO=${params.TESTSUITE_REPO}",
      "TESTSUITE_BRANCH=${params.TESTSUITE_BRANCH}",
      "TESTSUITE_OPTS=${params.TESTSUITE_OPTS}"
    ]){
      try{
        dir('kubernetes'){
          sh "./generate_deploy_templates.sh"
          sh "IAM_BASE_URL=https://iam-nginx-${BROWSER}.default.svc.cluster.local ./generate_ts_pod_conf.sh"
          stash name: "kube-templates", include: "./*.yaml"
        }
        
        sh "kubectl apply -f kubernetes/mysql.deploy.yaml"
        wait_kube_deploy("iam-db-${params.BROWSER}")
        
        sh "kubectl apply -f kubernetes/ts-params.cm.yaml -f kubernetes/iam-login-service.secret.yaml"
        
        sh "kubectl apply -f kubernetes/iam-login-service.deploy.yaml"
        wait_kube_deploy("iam-login-service-${params.BROWSER}")
        
        sh "kubectl apply -f kubernetes/iam-nginx.deploy.yaml"
        wait_kube_deploy("iam-nginx-${params.BROWSER}")
        
        sh "kubectl apply -f kubernetes/iam-testsuite.pod.yaml"
        sh "while ( [ 'Running' != `kubectl get pod $POD_NAME -o jsonpath='{.status.phase}'` ] ); do echo 'Waiting testsuite...'; sleep 5; done"
        
        sh "kubectl logs -f $POD_NAME"
        
      }catch(e){
        currentBuild.result = 'FAILURE'
        slackSend color: 'danger', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Failure (<${env.BUILD_URL}|Open>)"
        throw e
      }finally{
        cleanup()
      }
    }
  }
  
  stage('Process output'){
    dir("${report_dir}"){
      archiveArtifacts "**"
    }
    
    step([$class: 'RobotPublisher',
      disableArchiveOutput: false,
      logFileName: 'log.html',
      otherFiles: '*.png',
      outputFileName: 'output.xml',
      outputPath: "${report_dir}",
      passThreshold: 100,
      reportFileName: 'report.html',
      unstableThreshold: 90]);
    
    currentBuild.result = 'SUCCESS'
  }
}

def wait_kube_deploy(name) {
  withEnv(["DEPLOY_NAME=${name}"]){
    timeout(time: 5, unit: 'MINUTES') {  sh "kubectl rollout status deploy/${DEPLOY_NAME} | grep -q 'successfully rolled out'" }
  }
}

def cleanup() {
  try{
    dir('templates') {
      unstash "kube-templates"
      sh "kubectl delete -f iam-nginx.deploy.yaml -f iam-login-service.deploy.yaml -f mysql.deploy.yaml -f iam-testsuite.pod.yaml"
    }
  }catch(error){}
}
