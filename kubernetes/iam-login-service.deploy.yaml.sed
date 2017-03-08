apiVersion: v1
kind: Service
metadata:
  name: iam-login-service-$BRANCH-$BROWSER
  labels:
    app: iam-$BRANCH-$BROWSER
spec:
  ports: 
  - name: port0
    port: 8080
  selector:
    app: iam-$BRANCH-$BROWSER
    tier: login-service
  clusterIP: None

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: iam-login-service-$BRANCH-$BROWSER
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: iam-$BRANCH-$BROWSER
        tier: login-service
    spec:
      nodeSelector:
        role: worker
      volumes:
      - name: iam-deploy-test-secret
        secret:
          secretName: iam-deploy-test-secret
      containers:
      - name: iam-login-service-$BRANCH-$BROWSER
        image: $DOCKER_REGISTRY_HOST/$IAM_IMAGE
        ports:
        - containerPort: 8080
          name: iam
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 90
          timeoutSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 90
          timeoutSeconds: 10
        resources:
          requests:
            cpu: 1000m
            memory: 1500Mi
        volumeMounts:
        - name: iam-deploy-test-secret
          mountPath: /srv/indigo-iam/saml-idp/idp/shibboleth-idp/metadata
        env:
        - name: WAIT_HOST
          value: iam-db-$BRANCH-$BROWSER
        - name: WAIT_PORT
          value: "3306"
        - name: WAIT_TIMEOUT
          value: "60"
        - name: IAM_JAVA_OPTS
          value: -Dspring.profiles.active=mysql-test
        - name: IAM_BASE_URL
          value: https://iam-nginx-$BRANCH-$BROWSER.default.svc.cluster.local
        - name: IAM_ISSUER
          value: https://iam-nginx-$BRANCH-$BROWSER.default.svc.cluster.local
        - name: IAM_USE_FORWARDED_HEADERS
          value: "true"
        - name: IAM_DB_HOST
          value: iam-db-$BRANCH-$BROWSER
        - name: IAM_DB_USERNAME
          value: iam
        - name: IAM_DB_PASSWORD
          value: pwd
        - name: IAM_GOOGLE_CLIENT_REDIRECT_URIS
          value: https://iam-nginx-$BRANCH-$BROWSER.default.svc.cluster.local/openid_connect_login
        - name: IAM_SAML_IDP_METADATA
          value: file:///srv/indigo-iam/saml-idp/idp/shibboleth-idp/metadata/idp-metadata.xml
        - name: IAM_SAML_ENTITY_ID
          value: "urn:iam:iam-devel"
        - name: IAM_NOTIFICATION_DISABLE
          value: "true"
