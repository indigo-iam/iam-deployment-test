apiVersion: v1
kind: Service
metadata:
  name: iam-db-$BROWSER
  labels:
    app: iam-$BROWSER
spec:
  ports:
  - name: mysql
    port: 3306
  selector:
    app: iam-$BROWSER
    tier: db
  clusterIP: None

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: iam-db-$BROWSER
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: iam-$BROWSER
        tier: db
    spec:
      nodeSelector:
        role: worker
      containers:
      - name: iam-db
        image: mariadb:latest
        ports:
        - containerPort: 3306
          name: mysql
        resources:
          requests:
            cpu: 300m
            memory: 800Mi
        env:
        - name: MYSQL_USER
          value: iam
        - name: MYSQL_PASSWORD
          value: pwd
        - name: MYSQL_DATABASE
          value: iam
        - name: MYSQL_ROOT_PASSWORD
          value: pwd
