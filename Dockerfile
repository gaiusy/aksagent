FROM ubuntu:18.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
ARG JDK8FILE=zulu-8-azure-jdk_8.46.0.19-8.0.252-linux_x64.tar.gz
ARG JDK8_VERSION=8u252
ARG JDK11FILE=zulu-11-azure-jdk_11.44.13-11.0.9.1.101-linux_x64.tar.gz 
ARG JDK11_VERSION=11.0.9.1
ARG JDK17FILE=jdk-17_linux-x64_bin.tar.gz 
ARG JDK17_VERSION=17
ARG JDK_DEF_VERSION=$JDK8_VERSION
ARG MAVEN_VERSION=3.6.3
ARG ANSIBLE_VERSION=2.9
ARG NODEJS_VERSION=12
ARG DOTNET_VERSION=3.1
ARG KUBECTL_VERSION=v1.19.8
ARG LOCAL_BIN_ROOT=/usr/local/bin
ARG M3_BASE_URL=https://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries
ARG M3_SHA512=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG M3_INSTALL_DIR=/opt/maven/$MAVEN_VERSION
ARG HELM_INSTALL_DIR=/opt/helm
ARG EIAP_ADMIN=neipd999
ARG EIAP_ADMIN_UID=1000
ARG EIAP_ADMIN_GID=1000
ENV FORTIFY_VERSION 20.2.1
ENV FORTIFY_INSTALLATION_DIR /opt/Fortify

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# install default softwares required
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        lsb-release \
	    wget \
        curl \
        jq \
        git \
        iputils-ping \
        libcurl4 \
        libicu60 \
        libunwind8 \
        netcat \
        libssl1.0 \
	    unzip \
        dnsutils \
        telnet \
        gnupg

COPY ${JDK8FILE} /tmp/${JDK8FILE}


# Azur zulu 8 & 11 JDK
RUN set -eux; \
  echo "${JDK8FILE}"; \
  echo "${JDK11FILE}"; \
  # clean up
  apt-get autoremove --purge; \
  apt-get clean; \
  # install our JDK8
  mkdir -p /opt/java/jdk${JDK8_VERSION}; \
  tar -x -z -f /tmp/${JDK8FILE} -C /opt/java/jdk${JDK8_VERSION} --strip-components=1; \
   # install our JDK11
#   mkdir -p /opt/java/jdk${JDK11_VERSION}; \
#   tar -x -z -f /tmp/${JDK11FILE} -C /opt/java/jdk${JDK11_VERSION} --strip-components=1; \
#   # install our JDK17
#   mkdir -p /opt/java/jdk${JDK17_VERSION}; \
#   tar -x -z -f /tmp/${JDK17FILE} -C /opt/java/jdk${JDK17_VERSION} --strip-components=1; \
  # clean up
  rm -f /tmp/${JDK8FILE} /tmp/${JDK11FILE} /tmp/${JDK17FILE} ;\
  # create symbolic links
  ln -sf /opt/java/jdk${JDK_DEF_VERSION}/bin/java /usr/bin/java; \  
  # smoke test
  java -version; 

ENV JAVA_HOME="/opt/java/jdk${JDK_DEF_VERSION}" \
    PATH=\$JAVA_HOME/bin:$PATH

# Maven installation
RUN set -eux \
    && echo "${JAVA_HOME}" \
    && mkdir -p ${M3_INSTALL_DIR} \
    && curl -fsSL -o /tmp/apache-maven.tar.gz ${M3_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${M3_SHA512}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
    && tar -xf /tmp/apache-maven.tar.gz -C ${M3_INSTALL_DIR} --strip-components=1 \
    && rm -f /tmp/apache-maven.tar.gz \
    # create symbolic links
    && ln -sf ${M3_INSTALL_DIR}/bin/mvn /usr/bin/mvn \
    && echo "Install Maven in ${M3_INSTALL_DIR}" \
    && mvn --version	

ENV M3_HOME=${M3_INSTALL_DIR} \
    MAVEN_HOME=${M3_INSTALL_DIR}" \
    M2_HOME=${M3_INSTALL_DIR}" \
    PATH=\${MAVEN_HOME}/bin:$PATH

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

ENV AZURE_EXTENSION_DIR=/opt/az/azcliextensions \
    PATH=/usr/local/bin:$PATH 

RUN az extension add -n azure-devops \
    && az extension add --name aks-preview \
    && az extension add --name azure-iot \
    && az aks install-cli --client-version=1.24.2 --kubelogin-version=0.0.13\
    && warn=no

ENV TARGETARCH=linux-x64
    
WORKDIR /azp

COPY ./start.sh ./
RUN chmod +x start.sh 

CMD ["./start.sh"]