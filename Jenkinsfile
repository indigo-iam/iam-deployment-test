#!groovy

stage('deployment test'){
  node('generic'){
    git 'https://github.com/marcocaberletti/iam-deployment-test.git'
    stash name: "source", include: "./*"
  }
  
  parallel (
      "develop-chrome":  { deployment_test('develop', 'chrome') },
      )
}

stage('process outputs'){
    
  node('generic') {
    unstash "develop-chrome"
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
          sh "IAM_BASE_URL=https://iam-nginx-${BRANCH}-${BROWSER}.default.svc.cluster.local ./generate_ts_pod_conf.sh"
        }
        
        sh "kubectl apply -f kubernetes/mysql.deploy.yaml"
        sh "while ( [ '1' != `kubectl get deploy iam-db-${BRANCH}-${BROWSER} -o jsonpath='{.status.availableReplicas}'` ] ); do echo 'Waiting db...'; sleep 5; done"
        
        sh "kubectl apply -f kubernetes/iam-login-service.deploy.yaml && sleep 30"
        sh "while ( [ '1' != `kubectl get deploy iam-login-service-${BRANCH}-${BROWSER} -o jsonpath='{.status.availableReplicas}'` ] ); do echo 'Waiting login-service...'; sleep 5; done"
        
        sh "kubectl apply -f kubernetes/iam-nginx.deploy.yaml"
        sh "while ( [ '1' != `kubectl get deploy iam-nginx-${BRANCH}-${BROWSER} -o jsonpath='{.status.availableReplicas}'` ] ); do echo 'Waiting nginx front-end...'; sleep 5; done"
        
        sh "kubectl apply -f kubernetes/iam-testsuite.pod.yaml"
        sh "while ( [ 'Running' != `kubectl get pod $POD_NAME -o jsonpath='{.status.phase}'` ] ); do echo 'Waiting testsuite...'; sleep 5; done"
        
        sh "kubectl logs -f $POD_NAME"
        
        dir("${report_dir}"){
            stash name: "${branch}-${browser}", include: "./*"
        }
        
        currentBuild.result = 'SUCCESS'

      }catch(error){
        currentBuild.result = 'FAILURE'
      }finally{
        cleanup("${branch}", "${browser}", "${pod_name}")
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
