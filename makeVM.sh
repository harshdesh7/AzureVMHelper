#!/usr/bin/env bash

while getopts "g:n:i:p:d" arg; do 
	case $arg in
		g) RG=${OPTARG};;
		n) NAME=${OPTARG};;
		i) IMAGE=${OPTARG};;
		p) PORTS=${OPTARG};;
		d) DELETE=true;;
	esac
done


#echo $RG
#echo $PORTS
#echo $DELETE


#Code below should be able to set up basic VM on Azure

if [ -z $IMAGE ] ; then 
	IMAGE="UbuntuLTS"
fi

az login

if [ "$DELETE" = true ] && [ -n $RG ] ; then
	echo "Deleting resource group"
	az group delete --name $RG
else
	if [ -z $RG ] || [ -z $NAME ] ; then
		echo "Not enough info to create a vm"
		exit 1
	fi
	az group create --name $RG --location westus
	echo "Resource group created"
	az vm create -n $NAME -g $RG --image $IMAGE || exit 1
	echo "Virtual machine made"
	ip=$(az vm list-ip-addresses -g $RG -n $NAME | jq '.[0].virtualMachine.network.publicIpAddresses[0].ipAddress')
	echo "IP Address of VM is: ${ip}"
	if [[ -n ${PORTS} ]] ; then
		IFS=' ' read -ra port_nums <<< "$PORTS"
		for i in "${port_nums[@]}"
		do
			az vm open-port --port $i --resource-group $RG --name $NAME
		done
		echo "Ports opened"
	fi
fi
