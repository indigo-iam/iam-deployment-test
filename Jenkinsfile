#!groovy

stage('build images'){ 
  
  
}

stage('deployment test'){
  node('generic'){
    git 'https://github.com/marcocaberletti/iam-deployment-test.git'
    stash name: "source", include: "./"
  }
  
  parallel (
      "master-chrome":   { deployment_test('master', 'chrome') },
      "master-firefox":  { deployment_test('master', 'firefox') },
      "develop-chrome":  { deployment_test('develop', 'chrome') },
      "develop-firefox": { deployment_test('develop', 'firefox') },
      )
}


def deployment_test(branch, browser){

  def pod_name = "iam-ts-${UUID.randomUUID().toString()}"
  def report_dir = "/srv/scratch/${pod_name}/reports"

  withEnv([
    "BRANCH=${branch}",
    "BROWSER=${browser}",
    "POD_NAME=${pod_name}",
    "OUTPUT_REPORTS=${report_dir}"
  ]){
    node('kubectl'){
      try{
        sh "mkdir -p ${OUTPUT_REPORTS}"
        unstash "source"
        dir('kubernetes'){
          sh "./generate_deploy_templates.sh"
          sh "IAM_BASE_URL=https://iam-${BRANCH}-${BROWSER}.default.svc.cluster.local ./generate_ts_pod_conf.sh"
        }
        sh "kubectl create -f kubernetes/mysql.deploy.yaml"
        sh "sleep 10"
        sh "kubectl create -f kubernetes/iam-login-service.deploy.yaml"
        sh "sleep 30"
        sh "kubectl create -f kubernetes/iam-nginx.deploy.yaml"
        sh "kubectl create -f kubernetes/iam-testsuite.pod.yaml"
        sh "while ( [ 'Running' != `kubectl get pod $POD_NAME -o jsonpath='{.status.phase}'` ] ); do echo 'Waiting creation...'; sleep 5; done"
        sh "kubectl logs -f $POD_NAME"

        archiveArtifacts "$OUTPUT_REPORTS/**"

        step([$class: 'RobotPublisher',
          disableArchiveOutput: false,
          logFileName: 'log.html',
          otherFiles: '*.png',
          outputFileName: 'output.xml',
          outputPath: "$OUTPUT_REPORTS",
          passThreshold: 100,
          reportFileName: 'report.html',
          unstableThreshold: 90])
      }finally{
        cleanup(branch, browser)
      }
    }
  }
}

def cleanup(branch, browser, tspod){
  try{
    withEnv([
      "BRANCH=${branch}",
      "BROWSER=${browser}",
      "POD_NAME=${tspod}"
    ]){
      sh "kubectl delete svc,deploy iam-nginx-${BRANCH}-${BROWSER}"
      sh "kubectl delete svc,deploy iam-login-service-${BRANCH}-${BROWSER}"
      sh "kubectl delete svc,deploy iam-db-${BRANCH}-${BROWSER}"
      sh "kubectl delete pod ${POD_NAME}"
    }
  }catch(error){}
}
