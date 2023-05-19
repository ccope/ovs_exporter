#!/bin/bash
set -e
set -x

MYAPP=ovs-exporter
MYAPP_USER=openvswitch
MYAPP_GROUP=openvswitch
MYAPP_SERVICE=ovs-exporter
MYAPP_BIN=/usr/local/bin/ovs-exporter
MYAPP_DESCRIPTION="Prometheus OVS Exporter"
MYAPP_CONF="/etc/sysconfig/${MYAPP_SERVICE}"

if [ -f "./${MYAPP}" ]; then
  rm -rf $MYAPP_BIN
  cp ./${MYAPP} ${MYAPP_BIN}
fi

if ! getent group ${MYAPP_GROUP}  >/dev/null; then
  printf "ERROR: ${MYAPP_GROUP} group does not exist!"
  exit 1
fi

if ! getent passwd ${MYAPP_USER} >/dev/null; then
  printf "ERROR: ${MYAPP_USER} group does not exist!"
  exit 1
fi

mkdir -p /var/lib/${MYAPP}
chown -R ${MYAPP_USER}:${MYAPP_GROUP} /var/lib/${MYAPP}

cat << EOF > /usr/lib/systemd/system/${MYAPP_SERVICE}.service
[Unit]
Description=$MYAPP_DESCRIPTION
After=network.target

[Service]
User=${MYAPP_USER}
Group=${MYAPP_GROUP}
EnvironmentFile=-${MYAPP_CONF}
ExecStart=${MYAPP_BIN} \$OPTIONS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl is-active --quiet ${MYAPP_SERVICE} && systemctl stop ${MYAPP_SERVICE}
systemctl enable ${MYAPP_SERVICE}
systemctl start ${MYAPP_SERVICE}
if systemctl is-active --quiet ${MYAPP_SERVICE}; then
  printf "INFO: ${MYAPP_SERVICE} service is running\n"
else
  printf "FAIL: ${MYAPP_SERVICE} service is not running\n"
  systemctl status ${MYAPP_SERVICE}
  exit 1
fi
