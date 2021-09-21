# inspired by https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile
ARG java_image_tag=11-jre-slim

FROM openjdk:${java_image_tag}

ARG HADOOP_VERSION=2.7
ARG SPARK_VERSION=3.1.1

ARG SPARK_DISTRO=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ARG SPARK_ARTIFACT=${SPARK_DISTRO}.tgz
ARG SPARK_DOWNLOAD_URL=https://downloads.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_ARTIFACT}

ARG GUAVA_URL=https://repo1.maven.org/maven2/com/google/guava/guava/23.0/guava-23.0.jar
ARG GCS_URL=https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-latest-hadoop2.jar
ARG AWS_JAVA_URL=https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar
ARG HADOOP_AWS_URL=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.4/hadoop-aws-2.7.4.jar
ARG HADOOP_AZURE_URL=https://repo1.maven.org/maven2/com/microsoft/azure/azure-storage/2.0.0/azure-storage-2.0.0.jar
ARG AZURE_BLOB_STORAGE_URL=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/2.7.3/hadoop-azure-2.7.3.jar

ARG SPARK_USER=spark
ARG SPARK_UID=185

RUN set -ex && \
    sed -i 's/http:\/\/deb.\(.*\)/https:\/\/deb.\1/g' /etc/apt/sources.list && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt-get install -y wget bash tini libc6 libpam-modules krb5-user libnss3 procps && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/logs && \
    mkdir -p /opt/spark/work-dir && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    useradd -u ${SPARK_UID} ${SPARK_USER} && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

ENV SPARK_HOME /opt/spark

RUN wget ${SPARK_DOWNLOAD_URL} && \
    tar -xf ${SPARK_ARTIFACT} && \
    mv /${SPARK_DISTRO}/jars ${SPARK_HOME}/jars && \
    mv /${SPARK_DISTRO}/bin ${SPARK_HOME}/bin && \
    #mv /${SPARK_DISTRO}/kubernetes/dockerfiles/spark/decom.sh /opt/ && \
    mv /${SPARK_DISTRO}/kubernetes/dockerfiles/spark/* /opt/ && \
    mv /${SPARK_DISTRO}/sbin ${SPARK_HOME}/sbin && \
    #mv /${SPARK_DISTRO}/kubernetes/dockerfiles/spark/entrypoint.sh /opt/ && \
    mv /${SPARK_DISTRO}/examples ${SPARK_HOME}/examples && \
    mv /${SPARK_DISTRO}/kubernetes/tests ${SPARK_HOME}/tests && \
    mv /${SPARK_DISTRO}/data ${SPARK_HOME}/data && \
    rm /${SPARK_ARTIFACT}
    #rm $SPARK_HOME/jars/guava-*.jar

# inspired by https://github.com/lightbend/spark-history-server-docker/blob/master/Dockerfile
#ADD ${GUAVA_URL} ${SPARK_HOME}/jars
ADD ${GCS_URL} ${SPARK_HOME}/jars
ADD ${AWS_JAVA_URL} ${SPARK_HOME}/jars
ADD ${HADOOP_AWS_URL} ${SPARK_HOME}/jars
ADD ${HADOOP_AZURE_URL} ${SPARK_HOME}/jars
ADD ${AZURE_BLOB_STORAGE_URL} ${SPARK_HOME}/jars
RUN chmod -R ag+rx ${SPARK_HOME}/jars

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN [ -d /opt/decom.sh ] && chmod a+x /opt/decom.sh || true

ENTRYPOINT [ "/opt/entrypoint.sh" ]

USER ${SPARK_UID}
