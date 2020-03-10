#!/bin/bash



while getopts "g:n:r:p:d" arg; do 
	case $arg in
		g) RES_GROUP=${OPTARG};;
		n) REG_NAME=${OPTARG};;
		r) GIT_REPO=${OPTARG};;
		p) GIT_PAT=${OPTARG};;
		d) DELETE=true;;
	esac
done

az login

IFS='/' read -ra git_name <<< "$GIT_REPO"
REPO_NAME=$(echo ${git_name[@]: -1} | sed "s/.git//g")

if [ $(az group exists -n $RES_GROUP) = false ] ; then
	az group create --name $RES_GROUP --location westus
fi

echo "Creating Registry"
az acr create -g $RES_GROUP -n $REG_NAME --sku Basic
az acr login -n $REG_NAME
echo "Registry Created"


echo "Creating Task"
az acr task create \
    --registry $REG_NAME \
    --name $REPO_NAME \
    --image $REPO_NAME:{{.Run.ID}} \
    --context $GIT_REPO \
    --file Dockerfile \
    --git-access-token $GIT_PAT


LOG_IN="$REG_NAME.azurecr.io"

echo "Now will run task"
az acr task run --registry $REG_NAME --name acrrun
echo "Running at: $LOG_IN"

# Get latest tags of image
# Make web app now which runs image (make this optional)
# Add update web app option

az appservice plan create -g $RES_GROUP -n WebContainerPlan --is-linux

LATEST_TAG=$(az acr repository show-tags -n $REG_NAME --repository $REPO_NAME --top 1 --orderby time_desc)

#Below Example is only for ACR, User will maunally have to enter image for Dockerhub

IMG_NAME="$LOG_IN/REPO_NAME:$LATEST_TAG"

#Make for private DockerHub
az webapp create -g $RES_GROUP -p WebContainerPlan -n ImageApp -i $IMG_NAME 

#Implement new deployment when acr repo or dockerhub image is updated
