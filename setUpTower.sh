#!/bin/bash

############################
##      VARIABLES        ###
############################

#towerTOKEN
source "/software/hgi/installs/nf_tower/tower_auth.cfg"
TW_TOKEN=$(eval echo ${TOWER_ACCESS_TOKEN})
twPath=$(eval echo ${TOWER_PATH})

humgenId=$(eval echo ${HUMGEN_ID})
humgenName="humgen"



#ssh variables
sshKeyComment="nextflow_tower"
sshKeyName="$HOME/.ssh/nextflow_tower"
authorizedKeys="$HOME/.ssh/authorized_keys"

#compENV variables
hostName=$(eval echo ${HOST_NAME})
headQueue="normal"
computeQueue="normal"

############################
# GRAB INFO
read -p "Username: (login user) i.e: 'en6' or 'ob1' : " userName
#read -p "path to the private ssh: " sshPath
read -p "workDir: (nextflow work dir path)`echo $'\n'         Is recommended something like: /lustre/\<team\>/$userName/work : `" workDir
read -p "launchDir: (nextflow launch dir path)`echo $'\n'         Is recommended something like: /lustre/\<team\>/$userName/launch : `" launchDir

## INITIALIZE
userEmail=$userName"@sanger.ac.uk"

workspaceName=$userName

workspaceFullName=$workspaceName"_workspace"

credentialName=$userName"_farm"

computeEnvName=$userName"_"$headQueue
############################

# is the user already in the system ??
read -p "Do you have already a user? [y/n]: " userExist
if [[ $userExist == "n" || $userExist == "N" ]]; then
# create user
    $twPath/tw members add -u $userEmail -o $humgenId
fi

#create workspace
$twPath/tw workspaces add -o $humgenName -n $workspaceName -f $workspaceFullName

#add user to workspaces
$twPath/tw  participants add -n $userEmail -t MEMBER -w $humgenName/$workspaceName

#change role of user in the workspace
$twPath/tw participants update -n $userEmail -t MEMBER -r ADMIN -w $humgenName/$workspaceName

#does the user have his own cred or we create it?
read -p "Do you want to use your own credentials [y/n]: " sshExist
if [[ $sshExist == "n" || $sshExist == "N" ]]; then
    # create credentials
    ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N ""

    #add credential into autho
    cat $sshKeyName".pub" >> $authorizedKeys

    sshPath=$sshKeyName
else
    read -p "Path to the private ssh: " sshAux
    sshPath=$sshAux
fi

#add credential into tower
$twPath/tw credentials add ssh -n $credentialName -w $humgenName/$workspaceName --key $sshPath

# create comp env JSON
JSON_STRING=$( jq -n \
                  --arg wd "$workDir" \
                  --arg ld "$launchDir" \
                  --arg un "$userName" \
                  --arg hn "$hostName" \
                  --arg hq "$headQueue" \
                  --arg cq "$computeQueue" \
                  '{
                    "unitForLimits" : "GB",
                    "perJobMemLimit" : true,
                    "perTaskReserve" : false,
                    "environment" : [ ],
                    "discriminator" : "lsf-platform",
                    "workDir" : $wd,
                    "launchDir" : $ld,
                    "userName" : $un,
                    "hostName" : $hn,
                    "headQueue" : $hq,
                    "computeQueue" : $cq,
                    "headJobOptions" : "-M 4000 -R \"select[mem>4000] rusage[mem=4000]\"",
                    "preRunScript" : "export HTTP_PROXY=\"http://wwwcache.sanger.ac.uk:3128\"\\nexport HTTPS_PROXY=$HTTP_PROXY\\nexport NXF_OPTS=\"-Xmx8G\" \\nexport PATH=\"/software/singularity-v3.6.4/bin:/software/hgi/installs/nextflow_install:$PATH\""
                    }')
echo $JSON_STRING > compEnvTest   

#-> import comp env
$twPath/tw compute-envs import -n $computeEnvName -w $humgenName/$workspaceName -c $credentialName compEnvTest

#Clean stuff
rm -rf compEnvTest