apiVersion: v1
kind: Service
metadata:
  name: iam-db-$BRANCH-$BROWSER
  labels:
    app: iam-$BRANCH-$BROWSER
spec:
  ports:
  - name: mysql
    port: 3306
  selector:
    app: iam-$BRANCH-$BROWSER
    tier: db
  clusterIP: None

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: iam-db-$BRANCH-$BROWSER
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: iam-$BRANCH-$BROWSER
        tier: db
    spec:
      nodeSelector:
        role: worker
      containers:
      - name: iam-db
        image: mysql:5.6
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_USER
          value: iam
        - name: MYSQL_PASSWORD
          value: pwd
        - name: MYSQL_DATABASE
          value: iam
        - name: MYSQL_ROOT_PASSWORD
          value: pwd
