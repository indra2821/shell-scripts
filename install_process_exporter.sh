#!/bin/sh -e
VERSION=0.6.0
RELEASE=process-exporter-${VERSION}.linux-amd64


_check_root () {
    if [ $(id -u) -ne 0 ]; then
        echo "Please run as root" >&2;
        exit 1;
    fi
}

_install_curl () {
    if [ -x "$(command -v curl)" ]; then
        return
    fi

    if [ -x "$(command -v apt-get)" ]; then
        apt-get update
        apt-get -y install curl
    elif [ -x "$(command -v yum)" ]; then
        yum -y install curl
    else
        echo "No known package manager found" >&2;
        exit 1;
    fi
}

_check_root
_install_curl

useradd -rs /bin/false process_exporter
cd /tmp
curl -LO https://github.com/ncabatoff/process-exporter/releases/download/v${VERSION}/${RELEASE}.tar.gz
tar xvf ${RELEASE}.tar.gz
mv ${RELEASE}/process-exporter ${RELEASE}/process_exporter
mv ${RELEASE}/process_exporter /usr/local/bin/
chown process_exporter:process_exporter /usr/local/bin/process_exporter
rm -rf /tmp/${RELEASE}

if [ -x "$(command -v systemctl)" ]; then
    cat << EOF > /etc/systemd/system/process_exporter.service
[Unit]
Description=Prometheus Process Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=process_exporter
Group=process_exporter
Type=simple
ExecStart=/usr/local/bin/process_exporter -config.path /usr/bin/all.yml 

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /usr/bin/all.yml
process_names:
  - name: "{{.Comm}}"
    cmdline:
    - '.+'
EOF

    systemctl daemon-reload
    systemctl start process_exporter
    systemctl enable process_exporter
        systemctl status process_exporter

elif [ -x "$(command -v chckconfig)" ]; then
    cat << EOF >> /etc/inittab
::respawn:/usr/local/bin/process_exporter
EOF
elif [ -x "$(command -v initctl)" ]; then
    cat << EOF > /etc/init/process_exporter.conf
start on runlevel [23456]
stop on runlevel [016]
exec /usr/local/bin/process_exporter -config.path /usr/bin/all.yml
respawn
EOF

    initctl reload-configuration
    stop process_exporter || true && start process_exporter
else
    echo "No known service management found" >&2;
    exit 1;
fi
