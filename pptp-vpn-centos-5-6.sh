#!/bin/bash

function installVPN5(){
	
	yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers
	rpm -ivh dkms-2.0.17.5-1.noarch.rpm
	rpm -ivh kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	rpm -qa kernel_ppp_mppe
	rpm -Uvh ppp-2.4.4-9.0.rhel5.i386.rpm	
	rpm -ivh pptpd-1.3.4-1.rhel5.1.i386.rpm
}


function installVPN6(){
	
	yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers
	rpm -ivh dkms-2.0.17.5-1.noarch.rpm
	rpm -ivh kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	rpm -qa kernel_ppp_mppe
	rpm -Uvh ppp-2.4.5-17.0.rhel6.$arch.rpm	
	rpm -ivh pptpd-1.3.4-2.el6.$arch.rpm
}

function setting(){
	mknod /dev/ppp c 108 0 
	echo 1 > /proc/sys/net/ipv4/ip_forward 
	echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
	echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
	echo "localip 172.16.36.1" >> /etc/pptpd.conf
	echo "remoteip 172.16.36.2-254" >> /etc/pptpd.conf
	echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
	echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

	pass=`openssl rand 6 -base64`
	if [ "$1" != "" ]
	then pass=$1
	fi

	echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

	iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
	iptables -A FORWARD -p tcp --syn -s 172.16.36.0/24 -j TCPMSS --set-mss 1356
	service iptables save

	chkconfig iptables on
	chkconfig pptpd on

	service iptables start
	service pptpd start

	echo "====================Blog.steven-yu.com================="
	echo "VPN 服务器已经完成安装，你的VPN账号为 vpn,密码是 ${pass}"
	echo "====================Blog.steven-yu.com================="
	
}

function centos5(){
	echo "开始安装VPN服务器（centos5）";
	#check wether vps suppot ppp and tun
	
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	
	arch=`uname -m`
	
	wget http://down.topmyhosting.com/vpn/dkms-2.0.17.5-1.noarch.rpm
	wget http://down.topmyhosting.com/vpn/kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	wget http://down.topmyhosting.com/vpn/pptpd-1.3.4-1.rhel5.1.i386.rpm
	wget http://down.topmyhosting.com/vpn/ppp-2.4.4-9.0.rhel5.i386.rpm

	installVPN5
	setting

}

function centos6(){
	echo "开始安装VPN服务器（centos6）";
	#check wether vps suppot ppp and tun
	
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	
	arch=`uname -m`
	
	wget http://down.topmyhosting.com/vpn/dkms-2.0.17.5-1.noarch.rpm
	wget http://down.topmyhosting.com/vpn/kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	wget http://down.topmyhosting.com/vpn/pptpd-1.3.4-2.el6.$arch.rpm
	wget http://down.topmyhosting.com/vpn/ppp-2.4.5-17.0.rhel6.$arch.rpm

	installVPN6
	setting
}



function repaireVPN(){
	echo "开始修复 VPN";
	mknod /dev/ppp c 108 0
	service iptables restart
	service pptpd start
}

function addVPNuser(){
	echo "请输入用户名:"
	read username
	echo "请输入密码:"
	read userpassword
	echo "${username} pptpd ${userpassword} *" >> /etc/ppp/chap-secrets
	service iptables restart
	service pptpd start
}

function onlineUser(){
    last | grep still | grep ppp
}

echo "请输入您想进行的操作代码"
echo "1. 安装VPN服务（centos5 32bit）"
echo "2. 安装VPN服务（centos6 32bit or 64bit）"
echo "3. 修复VPN服务"
echo "4. 添加新用户"
echo "5. 查看在线用户"
read num

case "$num" in
[1] ) (centos5);;
[2] ) (centos6);;
[3] ) (repaireVPN);;
[4] ) (addVPNuser);;
[5] ) (onlineUser);;
*) echo "nothing,exit";;
esac
