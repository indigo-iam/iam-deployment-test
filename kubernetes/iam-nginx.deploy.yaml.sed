apiVersion: v1
kind: Service
metadata:
  name: iam-nginx-$BRANCH-$BROWSER
  labels:
    app: iam-$BRANCH-$BROWSER
spec:
  ports: 
  - name: https
    port: 443
  selector:
    app: iam-$BRANCH-$BROWSER
    tier: frontend

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: iam-nginx-$BRANCH-$BROWSER
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: iam-$BRANCH-$BROWSER
        tier: frontend
    spec:
      nodeSelector:
        role: worker
      containers:
      - name: iam-nginx
        image: $DOCKER_REGISTRY_HOST/italiangrid/iam-nginx:latest
        ports:
        - containerPort: 443
          name: https
        resources:
          requests:
            cpu: 100m
            memory: 50Mi
        env:
        - name: NGINX_HOST
          value: iam-nginx-$BRANCH-$BROWSER.default.svc.cluster.local.io
        - name: NGINX_PORT
          value: "443"
        - name: NGINX_SERVER_NAME
          value: iam-nginx-$BRANCH-$BROWSER.default.svc.cluster.local.io
        - name: NGINX_PROXY_PASS
          value: http://iam-login-service-$BRANCH-$BROWSER:8080
      imagePullSecrets:
      - name: cloud-vm181
