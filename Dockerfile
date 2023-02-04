FROM ubuntu:20.04
MAINTAINER Dewey Sasser <dewey@deweysasser.com>

ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Berlin
ADD AutomaticCleanup /etc/apt/apt.conf.d/99AutomaticCleanup

# Install what we need from Ubuntu
# tcpdump is for debugging client issues, others are required
RUN set -uex \
    && apt-get update \
    && apt-get install --no-install-recommends -y curl xymon apache2 tcpdump ssmtp mailutils rrdtool ntpdate tzdata rpcbind fping dumb-init \
    && apt-get clean all \
    && rm -rf /var/cache/apt/archives/* /var/cache/apt/*.bin /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm -rf /usr/share/man/* /usr/share/doc/*

ADD add-files /

# Enable necessary apache components
# make sure the "localhost" is correctly identified
# and ensure the ghost list can be updated
# Then, save the configuration so when this container starts with a
# blank volume, we can initialize it

RUN a2enmod rewrite authz_groupfile cgi; \
     perl -i -p -e "s/^127.0.0.1.*/127.0.0.1    xymon # bbd apache http:\/\/localhost\//" /etc/xymon/hosts.cfg; \
     perl -i -p -e "s/xymon-docker/xymon/" /etc/init.d/container-start; \
     chown xymon:xymon /etc/xymon/ghostlist.cfg /var/lib/xymon/www ; \
     tar -C /etc/xymon -czf /root/xymon-config.tgz . ; \
     tar -C /var/lib/xymon -czf /root/xymon-data.tgz .

VOLUME /etc/xymon /var/lib/xymon /usr/lib/xymon
EXPOSE 80 1984

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/etc/init.d/container-start"]
