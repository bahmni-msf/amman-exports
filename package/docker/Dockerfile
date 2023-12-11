FROM amazoncorretto:8

RUN yum install -y cronie && \
  yum clean all && \
  rm -rf /var/cache/yum

ADD scripts/setup.sh /usr/bin/setup.sh
ADD scripts/cronjob.sh /usr/bin/cronjob.sh
ADD scripts/bahmni-batch /usr/bin/bahmni-batch
ADD build/libs/bahmni-batch-*.jar /opt/bahmni-batch/libs/

RUN /bin/bash /usr/bin/setup.sh
RUN chmod +x /usr/bin/cronjob.sh

CMD ["/bin/bash", "-c", "/usr/bin/cronjob.sh && crond -n"]