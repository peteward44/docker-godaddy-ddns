FROM phusion/baseimage
MAINTAINER Pete Ward <peteward44@gmail.com>
# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# install ipv6calc
RUN apt-get update
RUN apt-get install ipv6calc -y

# add godaddy script which is executed via cron
ADD godaddy-ddns.sh /godaddy-ddns.sh
RUN chmod 0755 /godaddy-ddns.sh

# install custom crontab entry
ADD crontab /etc/cron.d/godaddy-ddns
RUN chmod 0644 /etc/cron.d/godaddy-ddns

# cron service
#RUN mkdir -p /etc/my_init.d
#RUN ln -s /usr/sbin/cron /etc/my_init.d/cron

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

