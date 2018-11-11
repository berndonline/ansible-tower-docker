FROM ubuntu:16.04

USER root

WORKDIR /opt

ARG ANSIBLE_TOWER_VER=3.3.1-1
ARG PG_DATA=/var/lib/postgresql/9.6/main
ARG AWX_PROJECTS=/var/lib/awx/projects
ARG ANSIBLE_HOME=/home/ansible

ENV ANSIBLE_HOME $ANSIBLE_HOME
ENV ANSIBLE_TOWER_VER $ANSIBLE_TOWER_VER
ENV PG_DATA $PG_DATA
ENV AWX_PROJECTS $AWX_PROJECTS

RUN apt-get clean && apt-get update
RUN apt-get install -y sudo

# Set the locale
RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8 \
        && export LC_ALL="en_US.UTF-8" \
        && dpkg-reconfigure locales
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# Install libpython2.7; missing dependency in Tower setup
RUN apt-get install -y libpython2.7

# Install support for https apt sources
RUN apt-get install -y apt-transport-https ca-certificates

# create /var/log/tower
RUN mkdir -p /var/log/tower

# Download & extract Tower tarball
ADD http://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-${ANSIBLE_TOWER_VER}.tar.gz ansible-tower-setup-${ANSIBLE_TOWER_VER}.tar.gz
RUN tar xvf ansible-tower-setup-${ANSIBLE_TOWER_VER}.tar.gz \
    && rm -f ansible-tower-setup-${ANSIBLE_TOWER_VER}.tar.gz

WORKDIR /opt/ansible-tower-setup-${ANSIBLE_TOWER_VER}
ADD inventory inventory

# This fixes undefined ansible ipv6 variable
RUN rm -f ./roles/nginx/templates/nginx.conf
ADD nginx.conf roles/nginx/templates/nginx.conf

# Tower setup
RUN ./setup.sh

# Docker entrypoint script
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# volumes and ports
VOLUME ["${PG_DATA}", "${AWX_PROJECTS}","/certs"]
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh", "ansible-tower"]
