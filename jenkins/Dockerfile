FROM jenkins/jenkins:lts

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG=/etc/jenkins/casc.yml

# 필수 플러그인 사전 설치
RUN jenkins-plugin-cli --plugins \
    ssh-agent \
    git \
    workflow-aggregator \
    job-dsl \
    configuration-as-code

# /etc/jenkins는 볼륨 밖이므로 이미지 재빌드 시 항상 반영됨
USER root
RUN mkdir -p /etc/jenkins
COPY casc.yml /etc/jenkins/casc.yml
USER jenkins
