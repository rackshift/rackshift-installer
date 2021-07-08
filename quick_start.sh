#!/bin/bash
#

function install_soft() {
    if command -v dnf > /dev/null; then
      if [ "$1" == "python" ]; then
        dnf -q -y install python2
        ln -s /usr/bin/python2 /usr/bin/python
      else
        dnf -q -y install $1
      fi
    elif command -v yum > /dev/null; then
      yum -q -y install $1
    elif command -v apt > /dev/null; then
      apt-get -qqy install $1
    elif command -v zypper > /dev/null; then
      zypper -q -n install $1
    elif command -v apk > /dev/null; then
      apk add -q $1
    else
      echo -e "[\033[31m ERROR \033[0m] Please install it first (请先安装) $1 "
      exit 1
    fi
}

function prepare_install() {
  for i in curl wget zip python; do
    command -v $i &>/dev/null || install_soft $i
  done
}

function get_installer() {
  echo "download install script to /opt/rackshift-installe (开始下载安装脚本到 /opt/rackshift-installer)"
  Version=$(curl -s 'https://api.github.com/repos/rackshift/rackshift/releases/latest' | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
  if [ ! "$Version" ]; then
    echo -e "[\033[31m ERROR \033[0m] Network Failed (请检查网络是否正常或尝试重新执行脚本)"
  fi
  cd /opt
  if [ ! -d "/opt/rackshift-installer-$Version" ]; then
    wget -qO rackshift-installer-$Version.tar.gz https://github.com/rackshift/rackshift-installer/releases/download/$Version/rackshift-installer-$Version.tar.gz || {
      rm -rf /opt/rackshift-installer-$Version.tar.gz
      echo -e "[\033[31m ERROR \033[0m] Failed to download rackshift-installer (下载 rackshift-installer 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    tar -xf /opt/rackshift-installer-$Version.tar.gz -C /opt || {
      rm -rf /opt/rackshift-installer-$Version
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip rackshift-installe (解压 rackshift-installer 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    rm -rf /opt/rackshift-installer-$Version.tar.gz
  fi
  cd /opt/rackshift-installer-$Version
  ./rsctl.sh install
}

function main(){
  prepare_install
  get_installer
}
main