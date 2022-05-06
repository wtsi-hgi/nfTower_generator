#!/bin/bash

############################
##      VARIABLES        ###
############################
twPath=$1;
humgenId=$2;
hostName=$3;

humgenName="humgen"

#ssh variables
sshKeyComment="nextflow_tower"
sshKeyName="$HOME/.ssh/nextflow_tower"
authorizedKeys="$HOME/.ssh/authorized_keys"

#compENV variables
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
echo -n "Do you have already a user? [y/n]: "
old_stty_cfg=$(stty -g)
stty raw -echo ; userExist=$(head -c 1) ; stty $old_stty_cfg # Careful playing with stty
if echo "$userExist" | grep -iq "^n" ;then
    # create user
    echo "Create a new user"
    echo "$twPath/tw members add -u $userEmail -o $humgenId"
    $twPath/tw members add -u $userEmail -o $humgenId
fi

#create workspace
echo "Create the workspace"
echo "$twPath/tw workspaces add -o $humgenName -n $workspaceName -f $workspaceFullName"
$twPath/tw workspaces add -o $humgenName -n $workspaceName -f $workspaceFullName

#add user to workspaces
echo "Add user to the workspace"
echo "$twPath/tw  participants add -n $userEmail -t MEMBER -w $humgenName/$workspaceName"
$twPath/tw  participants add -n $userEmail -t MEMBER -w $humgenName/$workspaceName

#change role of user in the workspace
echo "Change the role of the user in the workspace"
echo "$twPath/tw participants update -n $userEmail -t MEMBER -r ADMIN -w $humgenName/$workspaceName"
$twPath/tw participants update -n $userEmail -t MEMBER -r ADMIN -w $humgenName/$workspaceName

#does the user have his own cred or we create it?
echo -n "Do you want to use your own credentials [y/n]:  "
old_stty_cfg=$(stty -g)
stty raw -echo ; sshExist=$(head -c 1) ; stty $old_stty_cfg # Careful playing with stty
if echo "$sshExist" | grep -iq "^y" ;then
    #define path to sshKy
    read -n "Path to the private ssh: " sshAux
    sshPath=$sshAux
else
    # create credentials
    echo "Create ssh key"
    echo "ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N \"\""
    ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N ""

    #add credential into autho
    echo "Add credential to the autorizedKeys"
    echo "$sshKeyName\".pub\" >> $authorizedKeys"
    cat $sshKeyName".pub" >> $authorizedKeys

    sshPath=$sshKeyName
fi

#add credential into tower
echo "Add credentials into tower"
echo "$twPath/tw credentials add ssh -n $credentialName -w $humgenName/$workspaceName --key $sshPath"
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
echo "Import ComputeEnviroment into the workspace"
echo "$twPath/tw compute-envs import -n $computeEnvName -w $humgenName/$workspaceName -c $credentialName compEnvTest"
$twPath/tw compute-envs import -n $computeEnvName -w $humgenName/$workspaceName -c $credentialName compEnvTest

#Clean stuff
rm -rf compEnvTest