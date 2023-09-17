FROM ubuntu:22.04

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.309.0"

ARG TARGET_ARCH=x64

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt update && apt install curl dumt-init lsb-core gnupg sudo tar git -y

#Install Docker 

RUN mkdir -p /etc/apt/keyrings \
&& DPKG_ARCH="$(dpkg --print-architecture)" \
&& LSB_RELEASE_CODENAME="$(lsb_release --codename | cut -f2)" \
&& ( curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg ) \
&& version=$(lsb_release -cs | sed 's/trixie\|n\/a/bookworm/g') \
&& ( echo "deb [arch=${DPKG_ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${version} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null ) \
&& apt-get update \
&& apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin containerd.io docker-compose-plugin --no-install-recommends --allow-unauthenticated \
&& echo -e '#!/bin/sh\ndocker compose --compatibility "$@"' > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose 


RUN mkdir /actions-runner /opt/hostedtoolcache _work

WORKDIR /actions-runner


RUN curl -L "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-${TARGET_ARCH}-${GH_RUNNER_VERSION}.tar.gz" > actions.tar.gz
RUN tar -zxf actions.tar.gz

RUN ./bin/installdependencies.sh

RUN groupadd -g 121 runner \ 
  && useradd -mr -d /home/runner -u 1001 -g 121 runner \
  && usermod -aG sudo runner \
  && usermod -aG docker runner \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers 

RUN chown runner /_work /actions-runner /opt/hostedtoolcache

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh

#ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
