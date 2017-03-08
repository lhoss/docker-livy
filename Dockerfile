#FROM ubuntu:14.04
#MAINTAINER tobilg <tobilg@gmail.com>
FROM mesosphere/mesos:1.0.1-2.0.93.ubuntu1404

# TODO needed?
# Add R list
RUN echo 'deb http://cran.rstudio.com/bin/linux/ubuntu trusty/' | sudo tee -a /etc/apt/sources.list.d/r.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# packages
RUN apt-get update && apt-get install -yq --no-install-recommends --force-yes \
    wget \
    git \
    openjdk-7-jdk \
    maven \
    libjansi-java \
    libsvn1 \
    libcurl3 \
    libsasl2-modules && \
    rm -rf /var/lib/apt/lists/*

# Overall ENV vars
#ENV SPARK_VERSION 1.6.1
#ENV MESOS_BUILD_VERSION 0.28.0-2.0.16
#ENV LIVY_BUILD_VERSION livy-server-0.3.0-SNAPSHOT
ENV SPARK_VERSION 2.1.0
# 0.3.0 released 2017-01-25
# TODO better use latest stable  or latest ?!
ENV LIVY_BUILD_VERSION livy-server-0.4.0-SNAPSHOT

# Set install path for Livy
ENV LIVY_APP_PATH /apps/$LIVY_BUILD_VERSION

# Set build path for Livy
ENV LIVY_BUILD_PATH /apps/build/livy

# TODO following 2 we will override anyway withan ENV var
# Set Hadoop config directory
ENV HADOOP_CONF_DIR /etc/hadoop/conf
# Set Spark home directory
ENV SPARK_HOME /usr/local/spark

# Set native Mesos library path
ENV MESOS_NATIVE_JAVA_LIBRARY /usr/local/lib/libmesos.so

# Mesos install
#RUN wget http://repos.mesosphere.com/ubuntu/pool/main/m/mesos/mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
#    dpkg -i mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
#    rm mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb

# TODO remove spark (we will mount it) or do we need spark for the build
# TODO if yes, abstract version suffux 'hadoop2.6' (it's 2.7 for spark v2.1)
# Spark ENV vars
ENV SPARK_VERSION_STRING spark-$SPARK_VERSION-bin-hadoop2.6
ENV SPARK_DOWNLOAD_URL http://d3kbcqa49mib13.cloudfront.net/$SPARK_VERSION_STRING.tgz

# Download and unzip Spark
RUN wget $SPARK_DOWNLOAD_URL && \
    mkdir -p $SPARK_HOME && \
    tar xvf $SPARK_VERSION_STRING.tgz -C /tmp && \
    cp -rf /tmp/$SPARK_VERSION_STRING/* $SPARK_HOME && \
    rm -rf -- /tmp/$SPARK_VERSION_STRING && \
    rm spark-$SPARK_VERSION-bin-hadoop2.6.tgz

# TODO ensure build is done for spark-2
# Clone Livy repository
RUN mkdir -p /apps/build && \
    cd /apps/build && \
	git clone https://github.com/cloudera/livy.git && \
	cd $LIVY_BUILD_PATH && \
    mvn -DskipTests -Dspark.version=$SPARK_VERSION clean package && \
    unzip $LIVY_BUILD_PATH/assembly/target/$LIVY_BUILD_VERSION.zip -d /apps && \
    rm -rf $LIVY_BUILD_PATH && \
	mkdir -p $LIVY_APP_PATH/upload
	
# Add custom files, set permissions
ADD entrypoint.sh .

RUN chmod +x entrypoint.sh

# Expose port
EXPOSE 8998

ENTRYPOINT ["/entrypoint.sh"]
