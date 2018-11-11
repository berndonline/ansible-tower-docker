FROM ubuntu:16.04

USER root

WORKDIR /opt

ARG ANSIBLE_TOWER_VER=3.2.2
ARG PG_DATA=/var/ansible_home/postgresql/9.6/main
ARG AWX_PROJECTS=/var/ansible_home/awx/projects
ARG ANSIBLE_HOME=/home/ansible

ENV ANSIBLE_HOME $ANSIBLE_HOME
ENV ANSIBLE_TOWER_VER $ANSIBLE_TOWER_VER
ENV PG_DATA $PG_DATA
ENV AWX_PROJECTS $AWX_PROJECTS

# Create user
ARG ansible_user=ansible
ARG ansible_group=ansible
ARG ansible_uid=1001
ARG ansible_gid=1001

RUN apt-get clean && apt-get update
RUN apt-get install -y sudo

## Other
RUN groupadd -g ${ansible_gid} ${ansible_group} \
    && useradd -d "$ANSIBLE_HOME" -u ${ansible_uid} -g ${ansible_gid} -m -s /bin/bash ${ansible_user} \
    && echo "ansible        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/ansible

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
RUN rm -f ./roles/nginx/templates/nginx.conf
ADD nginx.conf roles/nginx/templates/nginx.conf

# Tower setup
RUN ./setup.sh

# Docker entrypoint script
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# volumes and ports
VOLUME ["${PG_DATA}", "${AWX_PROJECTS}", "/certs"]
EXPOSE 443
ENTRYPOINT ["/docker-entrypoint.sh", "ansible-tower"]
#CMD ["/docker-entrypoint.sh", "ansible-tower"]
