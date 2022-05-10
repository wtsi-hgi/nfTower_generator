#!/bin/bash

############################
##      VARIABLES        ###
############################
envToken=$1;
envEndPoint=$2;
twPath=$3;
humgenId=$4;
hostName=$5;

humgenName="humgen"

#ssh variables
sshKeyComment="nextflow_tower"
sshKeyName="$HOME/.ssh/nextflow_tower"
authorizedKeys="$HOME/.ssh/authorized_keys"

#compENV variables
headQueue="normal"
computeQueue="normal"

###############
# CHECK TW
# echo "Check tower ENV"
export TOWER_ACCESS_TOKEN=$envToken
export TOWER_API_ENDPOINT=$envEndPoint

# $twPath/tw info

userName=$(basename $HOME)

echo -n "Is "$userName" your Sanger user? [y/n]: \n"
old_stty_cfg=$(stty -g)
stty raw -echo ; isUser=$(head -c 1) ; stty $old_stty_cfg # Careful playing with stty
if echo "$isUser" | grep -iq "^n" ;then
    # ask for user
    read -p "Introduce your Sanger username: i.e: 'en6' or 'ob1' : " userName
    
fi
############################
# GRAB INFO
#read -p "Sanger username: (login user) i.e: 'en6' or 'ob1' : " userName
#read -p "path to the private ssh: " sshPath
read -p "workDir: (nextflow work dir path, you should have writting privileges in this directory)`echo '\n'         Is recommended something like: /lustre/\<team\>/$userName/work : `" workDir
read -p "launchDir: (nextflow launch dir path, you should have writting privileges in this directory)`echo '\n'         Is recommended something like: /lustre/\<team\>/$userName/launch : `" launchDir

## INITIALIZE
userEmail=$userName"@sanger.ac.uk"
#userEmail=$userName"+test@sanger.ac.uk"

workspaceName=$userName
#workspaceName=$userName"_test"

workspaceFullName=$workspaceName"_workspace"

credentialName=$userName"_farm"

computeEnvName=$userName"_"$headQueue
############################

# is the user already in the system ??
echo -n "Do you have already a Tower's user? [y/n]: "
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

    sshPath=checkPathSsh($sshAux)
else
    # create credentials
    echo "Create ssh key"
    echo "ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N \"\""
    ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N ""

    #add credential into authorizedKeys
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

echo "----------------################"
echo "################----------------"
echo "----------------################"

echo "Everything is set properly!"
echo "Email: $userEmail"
echo "Your workspace is: $workspaceName"
echo "A compute enviroment has been set with your credentials (ssh $credentialName) "
echo "under the name: $computeEnvName"
echo "\n\n"
echo "You can start using Tower at:"
echo "https://nf-tower.cellgeni.sanger.ac.uk"

echo "You can find more info in the confluence page:"
echo "https://confluence.sanger.ac.uk/display/HGI/Nextflow+Tower"

echo "----------------################"
echo "################----------------"
echo "----------------################"

function checkPathSsh {
    #eval dir='~user/somedir'
    eval dir = $1
    sshKey=$dir
    if [[ -f "$sshKey" ]]; then
        echo "$sshKey is a file"
        return $sshKey
    else 
        if [[ -d "$sshKey" ]]; then
            echo "$sshKey is a directory"
        else
            echo "$sshKey is neither file nore directory"
        fi
        return 1
    fi
}
