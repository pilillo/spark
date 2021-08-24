# Spark

Fork from the official Spark Docker image with clients for various data lakes.

This is meant to be used as history server or Spark base image for K8s (since you likely need a distributed cache).

For instance:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: spark-history-server
  name: spark-history-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: spark-history-server
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: spark-history-server
    spec:
      containers:
      - name: spark-3-1-1
        image: pilillo/spark:20210331
        imagePullPolicy: IfNotPresent
        command:
        - /opt/spark/sbin/start-history-server.sh
        env:
        - name: SPARK_NO_DAEMONIZE
          value: "false"
        - name: SPARK_HISTORY_OPTS
          value: -Dspark.history.fs.logDirectory=s3a://mybucket/
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: ui
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 4
        ports:
        - containerPort: 18080
          name: ui
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: ui
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 4
        resources:
          requests:
            cpu: 100m
            memory: 512Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /opt/spark/conf
          name: spark-conf-volume
      restartPolicy: Always
      securityContext:
        runAsNonRoot: true
        runAsUser: 185
      volumes:
      - configMap:
          defaultMode: 420
          name: spark-conf
        name: spark-conf-volume
```

with the `spark-conf-volume` being a config map containing the default spark conf files, out of which the spark-defaults.conf was modified to point to the distributed cache.

```yaml
apiVersion: v1
data:
  ...
  spark-defaults.conf: |
    spark.hadoop.fs.s3a.impl                    org.apache.hadoop.fs.s3a.S3AFileSystem
    spark.hadoop.fs.s3a.endpoint                myendpoint
    spark.hadoop.fs.s3a.connection.ssl.enabled  { true | false }
    spark.hadoop.fs.s3a.access.key              myaccesskey
    spark.hadoop.fs.s3a.secret.key              mysecretkey
    spark.eventLog.enabled                      true
    spark.eventLog.dir                          s3a://mybucket/
    spark.history.fs.logDirectory               s3a://mybucket/
    spark.hadoop.fs.s3a.path.style.access       { true | false }
  ...
kind: ConfigMap
metadata:
  name: spark-conf
```

Also mind that, because of a bug, the bucket shall not be empty at first.
