FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN yum clean all

RUN yum install -y unzip-6.0-57.amzn2023.0.2 jq-1.6-10.amzn2023.0.2 git-2.40.1-1.amzn2023.0.1 \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-$(rpm --eval '%{_arch}').zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install

COPY bot.sh /opt/app/bot.sh
RUN chmod 777 /opt/app/bot.sh
CMD ["/opt/app/bot.sh"]
