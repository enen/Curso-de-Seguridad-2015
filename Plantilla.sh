IPT=iptables
#DEFAULT RULES

$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT 
$IPT -P FORWARD ACCEPT

#Reset former rules to avoid conflicts
$IPT -F
$IPT -X

#Accept loopback established and/or related connections
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
