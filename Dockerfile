FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/endrebjorsvik/hpe-amsd"
LABEL org.opencontainers.image.description="Small container for running HPE AMS software in a privileged container on TrueNAS Scale."
LABEL org.opencontainers.image.licenses="MIT"

# Install dependencies for populating APT keyring
RUN apt-get update && apt-get install -y curl gnupg apt-utils iproute2 && apt-get clean && rm -rf /var/lib/apt/lists/*

# See https://downloads.linux.hpe.com/SDR/keys.html for repo signing keys
RUN mkdir -m 0755 -p /etc/apt/keyrings
#RUN curl https://downloads.linux.hpe.com/SDR/hpPublicKey2048_key1.pub | gpg --dearmor -o /etc/apt/keyrings/hpPublicKey2048_key1.gpg
#RUN curl https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub | gpg --dearmor -o /etc/apt/keyrings/hpePublicKey2048_key1.gpg
RUN curl https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key2.pub | gpg --dearmor -o /etc/apt/keyrings/hpePublicKey2048_key2.gpg
RUN chmod 644 /etc/apt/keyrings/*
RUN apt-key list --keyring /etc/apt/keyrings/hpePublicKey2048_key2.gpg

# Add repo definition (deb822 style)
ADD mcp.sources /etc/apt/sources.list.d/

RUN apt-get update && apt-get install -y amsd hponcfg storcli ssa ssacli ssaducli && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests python3 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://github.com/gdraheim/docker-systemctl-replacement/archive/refs/tags/v1.5.9063.tar.gz" && \
    echo "6443af6db2930ed13b68d82c276f2abf9b04e02a70723cb68e4d804dc4db2887  v1.5.9063.tar.gz" | sha256sum -c && \
    tar -xvf "v1.5.9063.tar.gz" && \
    rm v1.5.9063.tar.gz && \
    cp /docker-systemctl-replacement-1.5.9063/files/docker/* /usr/bin/ && \
    ln -s "/usr/bin/systemctl3.py" "/usr/bin/systemctl" && \
    chmod +x "/usr/bin/systemctl3.py" "/usr/bin/journalctl3.py"

RUN mkdir -p /etc/sysconfig
# Ensure that all services log to stdout instead of file.
RUN echo "OPTIONS=-L" > /etc/sysconfig/amsd
RUN echo "OPTIONS=-L" > /etc/sysconfig/amsd_rev
RUN echo "OPTIONS=-L" > /etc/sysconfig/cpqFca
RUN echo "OPTIONS=-L" > /etc/sysconfig/cpqIde
RUN echo "OPTIONS=-L" > /etc/sysconfig/cpqScsi
RUN echo "OPTIONS=-L" > /etc/sysconfig/cpqiScsi
RUN echo "OPTIONS=-L" > /etc/sysconfig/smad_rev

RUN rm "/etc/systemd/system/multi-user.target.wants/ahslog.service"
RUN rm "/etc/systemd/system/multi-user.target.wants/mr_cpqScsi.service"

CMD ["/usr/bin/systemctl", "--init", "-vv"]
