FROM centos:latest

ENV MIRTH_CONNECT_VERSION="3.7.0.b2399" \
    MIRTH_CONNECT_FHIR_VERSION="3.6" \
    GOSU_VERSION="1.9"	

RUN useradd -u 1000 mirth

# Install JDK, WGET, UNZIP
RUN \
 yum update -y && \
 yum -y install java-1.8.0-openjdk && \
 yum -y install wget && \
 yum -y install unzip && \
 yum clean all

# Install gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

# Download and install Mirth Connect
RUN \
 cd /tmp && \
 wget http://downloads.mirthcorp.com/connect/$MIRTH_CONNECT_VERSION/mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
 tar xvzf mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
 rm -f mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
 mkdir -p /opt/mirthconnect && \
 mv Mirth\ Connect/* /opt/mirthconnect/ && \
 mv Mirth\ Connect/.install4j /opt/mirthconnect/ && \
 chown -R mirth /opt/mirthconnect

# Expose Mirth Connect application data volume
VOLUME /opt/mirthconnect/appdata

# Change working directory
WORKDIR /opt/mirthconnect

# Add mirth.properties
ADD ["/build/mirth.properties","/opt/mirthconnect/conf"]

# Add FHIR extension
ADD ["/build/fhir-$MIRTH_CONNECT_FHIR_VERSION.zip","/opt/mirthconnect/extensions"]
RUN unzip /opt/mirthconnect/extensions/fhir-$MIRTH_CONNECT_FHIR_VERSION.zip -d /opt/mirthconnect/extensions

# Add Channels
#RUN mkdir /opt/mirthconnect/channels
# ADD ["/build/channels","/opt/mirthconnect/channels"]

# Expose the default Mirth Ports
EXPOSE 8080 8443

# Copy wait-for-it as this is required if using docker-compose to ensure that mysql is available before mirth connect service starts
COPY ["/build/wait-for-it.sh", "/opt/mirthconnect/wait-for-it.sh"]
RUN chmod +x /opt/mirthconnect/wait-for-it.sh

# Define entrypoint
COPY ["docker-entrypoint.sh", "/"]
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["java", "-jar", "mirth-server-launcher.jar"]
