FROM redhat/ubi8
RUN DEBIAN_FRONTEND=noninteractive yum update
RUN DEBIAN_FRONTEND=noninteractive yum upgrade -y

RUN DEBIAN_FRONTEND=noninteractive yum install -y -qq --no-install-recommends \
    yum-transport-https \
    yum-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]
