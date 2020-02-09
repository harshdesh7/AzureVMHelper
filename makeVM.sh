#!/usr/bin/env bash

while getopts "g:nipd" arg; do 
	case $arg in
		g) RG=${OPTARG};;
		n) NAME=${OPTARG};;
		i) IMAGE=${OPTARG};;
		p) PORTS=${OPTARG};;
		d) DELETE=true;;
	esac
done

echo $PORTS


az login

if [ "$DELETE" = true ] && [ -n $RG ] ; then
	az group delete --name $RG
else
	az group create --name $RG --location westus
	az vm create -n $NAME -g $RG --image $IMAGE
	az vm open-port --port $PORTS --resource-group $RG --name $NAME
fi
