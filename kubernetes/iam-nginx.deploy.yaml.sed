apiVersion: v1
kind: Service
metadata:
  name: iam-$BRANCH
  labels:
    app: iam-$BRANCH
spec:
  ports: 
  - name: https
    port: 443
  selector:
    app: iam-$BRANCH
    tier: frontend

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: iam-nginx-$BRANCH
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: iam-$BRANCH
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
        env:
        - name: NGINX_HOST
          value: iam-$BRANCH.default.svc.cluster.local.io
        - name: NGINX_PORT
          value: "443"
        - name: NGINX_SERVER_NAME
          value: iam-$BRANCH.default.svc.cluster.local.io
        - name: NGINX_PROXY_PASS
          value: http://iam-login-service-$BRANCH:8080
      imagePullSecrets:
      - name: cloud-vm181
