# inspired by https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile
ARG java_image_tag=11-jre-slim

FROM openjdk:${java_image_tag}

ARG hadoop_version=2.7
ARG spark_version=3.1.1

ARG spark_distro=spark-${spark_version}-bin-hadoop${hadoop_version}
ARG spark_artifact=${spark_distro}.tgz
ARG spark_download_url=https://downloads.apache.org/spark/spark-${spark_version}/${spark_artifact}

ARG guava_url=https://repo1.maven.org/maven2/com/google/guava/guava/23.0/guava-23.0.jar
ARG gcs_url=https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-latest-hadoop2.jar
ARG aws_java_url=https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar
ARG hadoop_aws_url=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.5/hadoop-aws-2.7.5.jar
ARG hadoop_azure_url=https://repo1.maven.org/maven2/com/microsoft/azure/azure-storage/2.0.0/azure-storage-2.0.0.jar
ARG azure_blob_storage_url=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/2.7.3/hadoop-azure-2.7.3.jar

ARG spark_user=spark
ARG spark_uid=185

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt-get install -y wget bash tini libc6 libpam-modules krb5-user libnss3 procps && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    useradd -u ${spark_uid} ${spark_user} && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

ENV SPARK_HOME /opt/spark

RUN wget ${spark_download_url} && \
    tar -xf ${spark_artifact} && \
    mv /${spark_distro}/jars ${SPARK_HOME}/jars && \
    mv /${spark_distro}/bin ${SPARK_HOME}/bin && \
    mv /${spark_distro}/kubernetes/dockerfiles/spark/decom.sh /opt/ && \
    mv /${spark_distro}/sbin ${SPARK_HOME}/sbin && \
    mv /${spark_distro}/kubernetes/dockerfiles/spark/entrypoint.sh /opt/ && \
    mv /${spark_distro}/examples ${SPARK_HOME}/examples && \
    mv /${spark_distro}/kubernetes/tests ${SPARK_HOME}/tests && \
    mv /${spark_distro}/data ${SPARK_HOME}/data && \
    rm /${spark_artifact} && \
    rm $SPARK_HOME/jars/guava-*.jar

# inspired by https://github.com/lightbend/spark-history-server-docker/blob/master/Dockerfile
ADD ${guava_url} ${SPARK_HOME}/jars
ADD ${gcs_url} ${SPARK_HOME}/jars
ADD ${aws_java_url} ${SPARK_HOME}/jars
ADD ${hadoop_aws_url} ${SPARK_HOME}/jars
ADD ${hadoop_azure_url} ${SPARK_HOME}/jars
ADD ${azure_blob_storage_url} ${SPARK_HOME}/jars

WORKDIR /opt/spark/work-dir

RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

USER ${spark_uid}