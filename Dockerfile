#FROM ubuntu:14.04
#orig MAINTAINER tobilg <tobilg@gmail.com>
#MAINTAINER lhoss <laurent.hoss@gmail.com>
FROM mesosphere/mesos:1.0.1-2.0.93.ubuntu1404

#ENV JDK_VERSION 7
ENV JDK_VERSION 8
ENV BUILD_DEPS='git maven python-setuptools python-dev build-essential'

# TODO needed R repos?
# Add R list
RUN echo 'deb http://cran.rstudio.com/bin/linux/ubuntu trusty/' | sudo tee -a /etc/apt/sources.list.d/r.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# add openjdk repos (to add java-8)
RUN apt-get update && \
    apt-get install -y software-properties-common
RUN add-apt-repository ppa:openjdk-r/ppa

# packages
RUN apt-get update && apt-get install -yq --no-install-recommends --force-yes \
    wget \
#    git \
    openjdk-${JDK_VERSION}-jdk \
#    python-setuptools python-dev build-essential \
#    maven \
    libjansi-java \
    libsvn1 \
    libcurl3 \
    libsasl2-modules && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### set default Java
ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64
RUN update-alternatives --set java ${JAVA_HOME}/jre/bin/java

# Overall ENV vars
#ENV SPARK_VERSION 1.6.1
#ENV MESOS_BUILD_VERSION 0.28.0-2.0.16
#ENV LIVY_BUILD_VERSION livy-server-0.3.0-SNAPSHOT
ENV SPARK_VERSION 2.1.0
# 0.3.0 released 2017-01-25
# TODO better use latest stable  or latest ?!
ENV LIVY_BUILD_VERSION livy-server-0.4.0-SNAPSHOT
#ENV LIVY_COMMIT master
# Latest build contains commits done upto 2017-04-09
ENV LIVY_COMMIT 07f6072

# Set install path for Livy
ENV LIVY_APP_PATH /apps/$LIVY_BUILD_VERSION
# Added HOME env, that points to a version-independent symlink of $LIVY_APP_PATH
ENV LIVY_HOME /apps/livy

# Set build path for Livy
ENV LIVY_BUILD_PATH /apps/build/livy

# TODO following 2 we will override anyway withan ENV var
# Set Hadoop config directory
ENV HADOOP_CONF_DIR /etc/hadoop/conf
# Set Spark home directory
ENV SPARK_HOME /usr/local/spark

# Set native Mesos library path
#ENV MESOS_NATIVE_JAVA_LIBRARY /usr/local/lib/libmesos.so

# Mesos install
#RUN wget http://repos.mesosphere.com/ubuntu/pool/main/m/mesos/mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
#    dpkg -i mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
#    rm mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb


# Clone Livy repository & build it
RUN mkdir -p /apps/build && \
    cd /apps/build && \
    apt-get update && apt-get install -yq --no-install-recommends --force-yes ${BUILD_DEPS} && \
	git clone https://github.com/cloudera/livy.git && \
	cd $LIVY_BUILD_PATH && \
    git checkout -q $LIVY_COMMIT && \
    mvn -DskipTests -Dspark.version=$SPARK_VERSION clean package && \
    unzip $LIVY_BUILD_PATH/assembly/target/$LIVY_BUILD_VERSION.zip -d /apps && \
    rm -rf $LIVY_BUILD_PATH && \
    rm -rf /root/.m2 && \
    apt-get purge -y --auto-remove ${BUILD_DEPS} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    ln -sn $LIVY_APP_PATH $LIVY_HOME && \
	mkdir -p $LIVY_APP_PATH/upload

# add symlink for LIVY_HOME ENV
#RUN cd / && ln -sn $LIVY_APP_PATH $LIVY_HOME

#TODO run as non-root user !?
# Add custom files, set permissions
ADD entrypoint.sh .

RUN chmod +x entrypoint.sh

# Expose port
EXPOSE 8998

# TODO enable container to see the base OS users and test LIVY 'proxyUser' param if it runs spark-submit as that user
# add our user and group first to make sure their IDs get assigned consistently
ENV LIVY_USER  insights
ENV LIVY_GROUP insights
RUN groupadd -r ${LIVY_GROUP} && useradd -r -m -g ${LIVY_GROUP} ${LIVY_USER}

# only change the owner of those base dirs (and later in entrypoint script, recursively)
#RUN chown  ${LIVY_USER}:${LIVY_GROUP} ${LIVY_HOME}/conf ${LIVY_HOME}/upload ${LIVY_HOME}/logs
RUN chown  ${LIVY_USER}:${LIVY_GROUP} ${LIVY_HOME}/conf
RUN chown  ${LIVY_USER}:${LIVY_GROUP} ${LIVY_HOME}/upload

# Enable passwordless sudo for users under the "sudo" group
# required for the entrypoint.sh 'sudo chown/chmod' cmds to work
RUN sed -i.bkp -e \
    's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
    /etc/sudoers
RUN adduser ${LIVY_USER} sudo


# docker image layers following the 'USER' cmd, are owned by the given user !
USER ${LIVY_USER}

ENTRYPOINT ["/entrypoint.sh"]

# Note: need to use CMD with a shell to expand any ENV Vars
#CMD ["${LIVY_HOME}/bin/livy-server"]
CMD ["sh", "-c", "${LIVY_HOME}/bin/livy-server"]
