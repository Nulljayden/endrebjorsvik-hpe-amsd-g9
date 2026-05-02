FROM ubuntu:20.04

LABEL org.opencontainers.image.source="https://github.com/endrebjorsvik/hpe-amsd"
LABEL org.opencontainers.image.description="Gen9 iLO4 Compatible AMSD for TrueNAS Scale."

# Use Ubuntu 20.04 as it has better compatibility with the older amsd 2.5.2 dependencies
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    apt-utils \
    iproute2 \
    python3 \
    libsnmp40 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and Install the specific iLO 4 compatible version (2.5.2)
RUN curl -L -o /tmp/amsd.deb -A "Mozilla/5.0" https://downloads.linux.hpe.com/SDR/repo/mcp/debian/pool/non-free/amsd_2.5.2-1.debian11_amd64.deb \
    && dpkg -i /tmp/amsd.deb || apt-get install -f -y \
    && rm /tmp/amsd.deb

# Install Systemctl replacement for container init
RUN curl -LO "https://github.com/gdraheim/docker-systemctl-replacement/archive/refs/tags/v1.5.9063.tar.gz" && \
    tar -xvf "v1.5.9063.tar.gz" && \
    cp /docker-systemctl-replacement-1.5.9063/files/docker/* /usr/bin/ && \
    ln -sf "/usr/bin/systemctl3.py" "/usr/bin/systemctl" && \
    chmod +x "/usr/bin/systemctl3.py" "/usr/bin/journalctl3.py"

RUN mkdir -p /etc/sysconfig
RUN echo "OPTIONS=-L" > /etc/sysconfig/amsd
RUN echo "OPTIONS=-L" > /etc/sysconfig/smad

# These services often fail in containers or aren't needed for Gen9
RUN rm -f "/etc/systemd/system/multi-user.target.wants/ahslog.service" 2>/dev/null || true

CMD ["/usr/bin/systemctl", "--init", "-vv"]
