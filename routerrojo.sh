#/bin/bash

IPT=/usr/bin/iptables

EXT=enp0s3
INT6=enp0s8
INT7=enp0s9
INT8=enp0s10

echo 1 > /proc/sys/net/ipv4/ip_forward

$IPT -F 
$IPT -X
 
$IPT -F -t nat
$IPT -F -t mangle

$IPT -t nat -A PREROUTING -p tcp -d 192.168.1.202 -j DNAT  --to-destination 192.168.8.202 --dport 80


$IPT -A INPUT -i lo -j ACCEPT

$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --dport ssh -i $INT7 -j ACCEPT
$IPT -A INPUT -j DROP

$IPT -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

$IPT -A FORWARD -p tcp --dport http -j ACCEPT
$IPT -A FORWARD -p tcp --dport domain -j ACCEPT
$IPT -A FORWARD -p udp --dport domain -j ACCEPT

$IPT -A FORWARD -s 192.168.7.0/24 -p tcp --dport ssh -j ACCEPT
$IPT -A FORWARD -p icmp -j ACCEPT

$IPT -A FORWARD -j LOG
$IPT -A FORWARD -j DROP

$IPT -t nat -A POSTROUTING -o $EXT -j MASQUERADE
