FROM jenkins/jenkins:lts

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yml

# 필수 플러그인 사전 설치
RUN jenkins-plugin-cli --plugins \
    ssh-agent \
    git \
    workflow-aggregator \
    job-dsl \
    configuration-as-code

COPY casc.yml /var/jenkins_home/casc.yml
