FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install unzip, jq, AWS CLI and generate .env
RUN yum install -y unzip jq git \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-$(rpm --eval '%{_arch}').zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install

COPY bot.sh /opt/app/bot.sh
RUN chmod 777 /opt/app/bot.sh
CMD ["/opt/app/bot.sh"]
