#!/usr/bin/env bash

cloud_type=$1
echo "Running os.sh $cloud_type..."

if [[ $cloud_type == "azure" ]]; then
  echo "cloud_type = $cloud_type"

  # Time sync is configured via systemd by defualt (example below), do nothing
  #root@dc0vm0:~# timedatectl status
  #      Local time: Wed 2018-10-24 22:47:56 UTC
  #  Universal time: Wed 2018-10-24 22:47:56 UTC
  #        RTC time: Wed 2018-10-24 22:47:56
  #       Time zone: Etc/UTC (UTC, +0000)
  # Network time on: yes
  # NTP synchronized: yes
  # RTC in local TZ: no

  echo "Setting sysctl tcp values..."
  # existing tcp_keepalive setting are longer than rec, skipping
  # net.ipv4.tcp_keepalive_time = 300
  # ^^^ actually set by /etc/sysctl.d/overcommit.conf
  # which is created by our package
  # net.ipv4.tcp_keepalive_probes = 9
  # net.ipv4.tcp_keepalive_intvl = 75
  sysctl -w \
  net.core.rmem_max=16777216 \
  net.core.wmem_max=16777216 \
  net.core.rmem_default=16777216 \
  net.core.wmem_default=16777216 \
  net.core.optmem_max=40960 \
  net.ipv4.tcp_rmem="4096 87380 16777216" \
  net.ipv4.tcp_wmem="4096 65536 16777216"

  cat >>/etc/sysctl.conf <<EOL
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.optmem_max=40960
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOL
  sysctl -p /etc/sysctl.conf

  # disk settings, ephemeral is sdb
  # the only available scheduler is 'none', not setting
  echo 0 > /sys/class/block/sdb/queue/rotational
  echo 8 > /sys/class/block/sdb/queue/read_ahead_kb
  sed -i 's/\<exit 0\>/# exit 0/' /etc/rc.local
  cat >>/etc/rc.local <<EOL
touch /var/lock/subsys/local
echo 0 > /sys/class/block/sdb/queue/rotational
echo 8 > /sys/class/block/sdb/queue/read_ahead_kb
EOL

  # disk settings, external volume if it exists is sdc
  # the only available scheduler is 'none', not setting
  if grep -qs '/dev/sdc ' /proc/mounts; then
    echo "sdc mounted, setting"
    echo 0 > /sys/class/block/sdc/queue/rotational
    echo 8 > /sys/class/block/sdc/queue/read_ahead_kb
    cat >>/etc/rc.local <<EOL
echo 0 > /sys/class/block/sdc/queue/rotational
echo 8 > /sys/class/block/sdc/queue/read_ahead_kb
EOL
  fi

  # no governors in /sys/devices/system/cpu
  # zone_reclaim_mode 0 by default
  # always package, ulimit set
  # no swap in fstab, created at boot by waagent, set to off by default
  echo "Defaults good for: cpu governors, zone reclaim, ulimit, swap, hugepages. Skipping..."
fi