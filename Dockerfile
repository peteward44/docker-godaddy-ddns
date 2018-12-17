FROM resin/raspberry-pi-alpine:3.8
MAINTAINER Pete Ward <peteward44@gmail.com>

RUN apk add --no-cache bash curl

# add godaddy script which is executed via cron
ADD godaddy-ddns.sh /godaddy-ddns.sh
RUN chmod 0755 /godaddy-ddns.sh

# install custom crontab entry
ADD crontab /var/spool/cron/crontabs/root 
RUN chmod 0644 /var/spool/cron/crontabs/root 

# add script that contains all environment variables so cron can see them
ADD setup_env /setup_env
RUN chmod 0755 /setup_env

ADD healthcheck.sh /healthcheck.sh
RUN chmod 0755 /healthcheck.sh
HEALTHCHECK --timeout=60s --interval=6m --retries=2 CMD /healthcheck.sh

# set tmp permissions
RUN chmod o+rwx /tmp

# run crond from busybox
CMD /bin/bash /setup_env && crond -l 2 -f


