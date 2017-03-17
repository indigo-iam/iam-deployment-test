#!groovy
// name: iam-deployment-test

properties([
  buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5')),
  pipelineTriggers([cron('@daily')]),
  parameters([
    choice(name: 'BROWSER',          choices: 'chrome\nfirefox', description: ''),
    choice(name: 'BRANCH',           choices: 'master\ndevelop', description: ''),
    string(name: 'IAM_IMAGE',        defaultValue: 'indigoiam/iam-login-service:develop', description: 'IAM docker image name'),
    string(name: 'TESTSUITE_REPO',   defaultValue: 'https://github.com/marcocaberletti/iam-robot-testsuite.git', description: 'Testsuite code repository'),
    string(name: 'TESTSUITE_BRANCH', defaultValue: 'develop', description: 'Testsuite code repository'),
    string(name: 'TESTSUITE_OPTS',   defaultValue: '--exclude=test-client', description: 'Additional testsuite options')
  ]),
])



stage("Prepare"){
  node('generic'){
    git 'https://github.com/marcocaberletti/iam-deployment-test.git'
    stash name: "source", include: "./*"
  }
}

stage("Test"){
  node('kubectl') {
    deployment_test("${params.BRANCH}", "${params.BROWSER}", "${params.IAM_IMAGE}")
  }
}

stage("Process outputs"){
  node('generic') {
    unstash "outputs"
    archiveArtifacts "**"
  
    step([$class: 'RobotPublisher',
      disableArchiveOutput: false,
      logFileName: 'log.html',
      otherFiles: '*.png',
      outputFileName: 'output.xml',
      outputPath: ".",
      passThreshold: 100,
      reportFileName: 'report.html',
      unstableThreshold: 90]);
  }
}


def deployment_test(branch, browser, iam_image) {

  def pod_name = "iam-ts-${UUID.randomUUID().toString()}"
  def report_dir = "/srv/scratch/${pod_name}/reports"

  withEnv([
    "BRANCH=${branch}",
    "BROWSER=${browser}",
    "IAM_IMAGE=${iam_image}",
    "POD_NAME=${pod_name}",
    "OUTPUT_REPORTS=${report_dir}",
    "TESTSUITE_REPO=${params.TESTSUITE_REPO}",
    "TESTSUITE_BRANCH=${params.TESTSUITE_BRANCH}",
    "TESTSUITE_OPTS=${params.TESTSUITE_OPTS}"
  ]){
    try{
      sh "mkdir -p ${OUTPUT_REPORTS}"
      unstash "source"
      dir('kubernetes'){
        sh "./generate_deploy_templates.sh"
        sh "IAM_BASE_URL=https://iam-nginx-${BRANCH}-${BROWSER}.default.svc.cluster.local ./generate_ts_pod_conf.sh"
        stash name: "kube-templates", include: "./*.yaml"
      }
      
      sh "kubectl apply -f kubernetes/mysql.deploy.yaml"
      wait_kube_deploy("iam-db-${branch}-${browser}")
      
      sh "kubectl apply -f kubernetes/ts-params.cm.yaml -f kubernetes/iam-login-service.secret.yaml"
      
      sh "kubectl apply -f kubernetes/iam-login-service.deploy.yaml"
      wait_kube_deploy("iam-login-service-${branch}-${browser}")
      
      sh "kubectl apply -f kubernetes/iam-nginx.deploy.yaml"
      wait_kube_deploy("iam-nginx-${branch}-${browser}")
      
      sh "kubectl apply -f kubernetes/iam-testsuite.pod.yaml"
      sh "while ( [ 'Running' != `kubectl get pod $POD_NAME -o jsonpath='{.status.phase}'` ] ); do echo 'Waiting testsuite...'; sleep 5; done"
      
      sh "kubectl logs -f $POD_NAME"
      
      dir("${report_dir}"){
          stash name: "outputs", include: "./*"
      }
      
      currentBuild.result = 'SUCCESS'

    }catch(error){
      currentBuild.result = 'FAILURE'
    }finally{
      cleanup()
    }
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
