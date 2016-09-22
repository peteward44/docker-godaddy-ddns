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

# add script that contains all environment variables so cron can see them
RUN mkdir -p /etc/my_init.d
ADD setup_env /etc/my_init.d/setup_env
RUN chmod 0755 /etc/my_init.d/setup_env

# set up symlink to PID 1 stdout to log file so we can see it via docker logs command
RUN ln -sf /proc/1/fd/1 /var/log/godaddy-ddns.log

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

