#/bin/bash

IPT=/usr/bin/iptables
TC=/sbin/tc

EXT=enp0s3
INT6=enp0s8
INT7=enp0s9
INT8=enp0s10

# -------------------------------------

MAX=40

$TC qdisc del dev $EXT root

$TC qdisc add dev $EXT root handle 1: htb default 13
$TC class add dev $EXT parent 1: classid 1:1 htb rate ${MAX}kbit ceil ${MAX}kbit

$TC class add dev $EXT parent 1:1 classid 1:12 htb rate 40kbit ceil ${MAX}kbit prio 3
$TC qdisc add dev $EXT parent 1:12 handle 120: sfq perturb 10 quantum 1500
$TC filter add dev $EXT parent 1:0 protocol ip prio 3 handle 3 fw classid 1:12

# -------------------------------------

echo 1 > /proc/sys/net/ipv4/ip_forward

$IPT -F 
$IPT -X
 
$IPT -F -t raw
$IPT -F -t nat
$IPT -F -t mangle

# -------------------------------------
$IPT -t mangle -A PREROUTING -p tcp --dport http -j MARK --set-mark 3
$IPT -t mangle -A PREROUTING -p tcp --dport http -j LOG --log-prefix='MARK:'
$IPT -t mangle -A PREROUTING -p tcp --dport http -j RETURN

$IPT -t mangle -A PREROUTING -p tcp --dport https -j MARK --set-mark 3
$IPT -t mangle -A PREROUTING -p tcp --dport https -j RETURN
# -------------------------------------

# NOTRACK
#$IPT -t raw -A PREROUTING -i $INT6 -j NOTRACK

# DNAT http
$IPT -t nat -A PREROUTING -p tcp -d 192.168.1.202 -j DNAT  --to-destination 192.168.8.202 --dport 80


$IPT -A INPUT -i lo -j ACCEPT

$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#$IPT -A INPUT -p tcp --dport ssh -i $INT7 -j ACCEPT
#$IPT -A INPUT -p tcp --dport ssh -m connlimit --connlimit-upto 1 -s 0.0.0.0       -i $INT7 -j ACCEPT
#$IPT -A INPUT -p tcp --dport ssh -m connlimit --connlimit-above 1 -s 0.0.0.0      -i $INT7 -j ACCEPT

$IPT -A INPUT -p tcp -i $EXT -m state --state NEW --dport ssh -m recent --update --seconds 15 -j DROP
$IPT -A INPUT -p tcp -i $EXT -m state --state NEW --dport ssh -m recent --set -j ACCEPT


# Stop Smurf attacks
#$IPT -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
#$IPT -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
#$IPT -A INPUT -p icmp -m icmp -j DROP


$IPT -A INPUT -p icmp -i $EXT -j ACCEPT
#$IPT -A INPUT -p icmp -i $INT6 -j TARPIT
#$IPT -A INPUT -p icmp -i $INT7 -j REJECT
#$IPT -A INPUT -p icmp -i $INT8 -j TARPIT


$IPT -A INPUT -j LOG --log-prefix='INPUT:'
$IPT -A INPUT -j DROP



$IPT -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#$IPT -A FORWARD -m recent --name malrollo --rcheck --second 60 -j DROP
#$IPT -A FORWARD -p tcp --dport 22 -i $INT6 -m recent --update --second 60 --hitcount 3 --name malrollo --set -j DROP

$IPT -A FORWARD -p tcp --dport http -j ACCEPT
$IPT -A FORWARD -p tcp --dport domain -j ACCEPT
$IPT -A FORWARD -p udp --dport domain -j ACCEPT

$IPT -A FORWARD -s 192.168.7.0/24 -p tcp --dport ssh -j ACCEPT
$IPT -A FORWARD -p icmp -j ACCEPT

$IPT -A FORWARD -j LOG
$IPT -A FORWARD -j DROP

$IPT -t nat -A POSTROUTING -o $EXT -j MASQUERADE


