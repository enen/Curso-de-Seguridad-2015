#/bin/bash

IPT=/usr/bin/iptables

LOC=lo
EXT=enp0s3
INT6=enp0s8
INT7=enp0s9
INT8=enp0s10

PORT1=49013
PORT2=36027
PORT3=51039
PORT4=11042
PORT5=28051
PORTSSH=62025

# Establece la politica por defecto de las cadenas INPUT,
#  FORWARD, y OUTPUT a ACCEPT (Firewall abierto)
$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT

# Vacia todas las reglas 
$IPT -F 
# Borra las cadenas de usuario
$IPT -X
 
# Vacia todas las reglas de las tablas raw, nat, y mangle 
$IPT -F -t raw
$IPT -F -t nat
$IPT -F -t mangle

# Añade las cadenas para el Port Knocking
$IPT -N KNOCKING
$IPT -N GATE1
$IPT -N GATE2
$IPT -N GATE3
$IPT -N GATE4
$IPT -N GATE5
$IPT -N PASSED

# -------------------------------------------------------
# Se añade el trafico que no va a gestionar el knocking
# -------------------------------------------------------
# Mantiene las conexiones aceptadas y establecidas
$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Acepta las conexiones desde local para los servicios internos
$IPT -A INPUT -i $LOC -j ACCEPT

# Deja abierto el servicio http
$IPT -A INPUT -p tcp --dport http -j ACCEPT

# -------------------------------------------------------
# El resto del trafico de INPUT a la cadena KNOKING
# -------------------------------------------------------
$IPT -A INPUT -j KNOCKING


# -------------------------------------------------------
# La puerta se abre durante 10s con la KNOCKING correcta
# -------------------------------------------------------

# La puerta se abre durante 10s al recibir un paquete con etiqueta AUTH3
$IPT -A KNOCKING -m recent --rcheck --seconds 10 --name AUTH5 -j PASSED

# Da 2s entre cada toque para pasar a la siguiente puerta
$IPT -A KNOCKING -m recent --rcheck --seconds 2 --name AUTH4 -j GATE5
$IPT -A KNOCKING -m recent --rcheck --seconds 2 --name AUTH3 -j GATE4
$IPT -A KNOCKING -m recent --rcheck --seconds 2 --name AUTH2 -j GATE3
$IPT -A KNOCKING -m recent --rcheck --seconds 2 --name AUTH1 -j GATE2

# En otro caso devuelve el cliente a la puerta 1
$IPT -A KNOCKING -j GATE1 


# -------------------------------------------------------
# En la puerta 1 ...
# -------------------------------------------------------

# Establece la etiqueta AUTH1 al llamar a PORT1
$IPT -A GATE1 -p tcp --dport $PORT1 -m recent --name AUTH1 --set -j DROP

# Hace DROP al resto del trafico
$IPT -A GATE1 -j DROP


# -------------------------------------------------------
# En la puerta 2 ...
# -------------------------------------------------------

# Elimina la etiqueta AUTH1 para evitar bug por escaneo 
#$IPT -A GATE2 -j LOG --log-prefix 'SECURITY LEVEL1 PASSED: '
$IPT -A GATE2 -m recent --name AUTH1 --remove

# Comprueba si se llama a PORT2 para añadir la etiqueta AUTH2
$IPT -A GATE2 -p tcp --dport $PORT2 -m recent --name AUTH2 --set -j DROP

# En otro caso devuelve el cliente a la puerta 1
$IPT -A GATE2 -j GATE1


# -------------------------------------------------------
# En la puerta 3 ...
# -------------------------------------------------------

# Elimina la etiqueta AUTH2 para evitar bug por escaneo 
#$IPT -A GATE3 -j LOG --log-prefix 'SECURITY LEVEL2 PASSED: '
$IPT -A GATE3 -m recent --name AUTH2 --remove

# Comprueba si se llama a PORT3 para añadir la etiqueta AUTH3
$IPT -A GATE3 -p tcp --dport $PORT3 -m recent --name AUTH3 --set -j DROP

# En otro caso devuelve el cliente a la puerta 1
$IPT -A GATE3 -j GATE1 


# -------------------------------------------------------
# En la puerta 4 ...
# -------------------------------------------------------

# Elimina la etiqueta AUTH3 para evitar bug por escaneo 
#$IPT -A GATE4 -j LOG --log-prefix 'SECURITY LEVEL3 PASSED: '
$IPT -A GATE4 -m recent --name AUTH3 --remove

# Comprueba si se llama a PORT4 para añadir la etiqueta AUTH4
$IPT -A GATE4 -p tcp --dport $PORT4 -m recent --name AUTH4 --set -j DROP

# En otro caso devuelve el cliente a la puerta 1
$IPT -A GATE4 -j GATE1 

# -------------------------------------------------------
# En la puerta 5 ...
# -------------------------------------------------------

# Elimina la etiqueta AUTH4 para evitar bug por escaneo 
#$IPT -A GATE5 -j LOG --log-prefix 'SECURITY LEVEL4 PASSED: '
$IPT -A GATE5 -m recent --name AUTH4 --remove

# Comprueba si se llama a PORT5 para añadir la etiqueta AUTH5
$IPT -A GATE5 -p tcp --dport $PORT5 -m recent --name AUTH5 --set -j DROP

# En otro caso devuelve el cliente a la puerta 1
$IPT -A GATE5 -j GATE1 

# -------------------------------------------------------
# La puerta queda abierta (PASSED) en el PORTSSH
# -------------------------------------------------------

# Elimina la etiqueta AUTH5 para evitar bug por escaneo 
#$IPT -A PASSED -j LOG --log-prefix 'SECURITY LEVEL5 PASSED: '
$IPT -A PASSED -m recent --name AUTH5 --remove

# Acepta la conexion SSH en el PORTSSH
$IPT -A PASSED -p tcp --dport $PORTSSH -j ACCEPT

# En otro caso devuelve el cliente a la puerta 1
$IPT -A PASSED -j GATE1 



