DOMAIN=1.2.3
GATEWAY=$DOMAIN.1
#two containers
NUM=2; 
#bridge type can be br or ovs, br by default
BRTYPE=$1
BRTYPE=${BRTYPE:-br}
BRIDGE=${BRTYPE}cj_novlan
INTERFACE=eth1
NAME=chrisnode_no_vlan

warn () {
  echo "$@" >&2
}

die () {
  status="$1"
  shift
  warn "$@"
  exit "$status"
}

sudo ip link set dev ${BRIDGE} down
sudo brctl delbr ${BRIDGE} 

for i in `seq 1 ${NUM}` 
do
 INDEX=$((i+1))
 IP=$DOMAIN.${INDEX}
 CONTAINER=${NAME}_${INDEX}
 HOST=${NAME}_${IP}
  
 sudo docker kill ${CONTAINER}
 sudo docker rm ${CONTAINER}
 sudo ./pipework ${BRIDGE} -i ${INTERFACE} $(sudo docker run -tid --name ${CONTAINER} -h ${HOST} --net='none' busybox:1.27 /bin/sh) ${IP}/24@${GATEWAY}
 #sudo ./pipework ${BRIDGE} -i ${INTERFACE} $(sudo docker run -tid --name ${CONTAINER} -h ${HOST} busybox:1.27 /bin/sh) ${IP}/24@${GATEWAY}
done

#ping test, pings all containers including self
for i in `seq 1 ${NUM}`
do
 INDEX=$((i+1))
 IP=$DOMAIN.${INDEX}
 CONTAINER=${NAME}_${INDEX}
 for j in `seq 1 ${NUM}`
 do
  PING_INDEX=$((j+1))
  PING_IP=$DOMAIN.${PING_INDEX}
  echo "ping from ${CONTAINER} to ${PING_IP}"
  sudo docker exec ${CONTAINER} ping -c 2 ${PING_IP} || die 1 "${CONTAINER} can't ping ${PING_IP}"
 done
done
