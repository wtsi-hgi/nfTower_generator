#!/bin/bash

############################
##      VARIABLES        ###
############################
envToken=$1;
envEndPoint=$2;
twPath=$3;
hostName=$4;

humgenName="humgen"

#ssh variables
sshKeyComment="nextflow_tower"
sshKeyName="$HOME/.ssh/nextflow_tower"
authorizedKeys="$HOME/.ssh/authorized_keys"

#compENV variables
headQueue="normal"
computeQueue="normal"

# CHECK TW
# echo "Check tower ENV"
export TOWER_ACCESS_TOKEN=$envToken
export TOWER_API_ENDPOINT=$envEndPoint
# $twPath/tw info

userName=$(basename $HOME)

function init() {
    userEmail=$userName"@sanger.ac.uk"
        #userEmail=$userName"+test@sanger.ac.uk"
    workspaceName=$userName
        #workspaceName=$userName"_test"
    workspaceFullName=$workspaceName"_workspace"
    credentialName=$userName"_farm"
    computeEnvName=$userName"_"$headQueue
}

function newUser() {
    # create user
    echo ""
    echo ">> Create a new user"
    echo "$twPath/tw members add -u $userEmail -o $humgenName"
    $twPath/tw members add -u $userEmail -o $humgenName
    echo ""
    echo ""
}

function userWorkspace() {
    echo ""
    #create workspace
    echo ">> Create the workspace"
    echo "$twPath/tw workspaces add -o $humgenName -n $workspaceName -f $workspaceFullName"
    $twPath/tw workspaces add -o $humgenName -n $workspaceName -f $workspaceFullName

    #add user to workspaces
    echo ">> Add user to the workspace"
    echo "$twPath/tw  participants add -n $userEmail -t MEMBER -w $humgenName/$workspaceName"
    $twPath/tw  participants add -n $userEmail -t MEMBER -w $humgenName/$workspaceName

    #change role of user in the workspace
    echo ">> Change the role of the user in the workspace"
    echo "$twPath/tw participants update -n $userEmail -t MEMBER -r ADMIN -w $humgenName/$workspaceName"
    $twPath/tw participants update -n $userEmail -t MEMBER -r ADMIN -w $humgenName/$workspaceName
    echo ""
    echo ""
}

function sshKeyGen() {
    echo ""
    #does the user have his own cred or we create it?
    echo -n "Do you want to use your own sshKey credentials [y/n]:  "
    old_stty_cfg=$(stty -g)
    stty raw -echo ; sshExist=$(head -c 1) ; stty $old_stty_cfg # Careful playing with stty
    if echo "$sshExist" | grep -iq "^y" ;then
        echo""
        #define path to sshKy
        read -p "Path to the PRIVATE sshKey: " sshAux
        sshAux="${sshAux/\~/$HOME}"        # replace ~ with $HOME
        #check if it exist
        if [ -f "$sshAux" ]; then       
            sshPath=$sshAux
        else 
            echo "$sshAux does not exist."
            menu
        fi
    else
        # create credentials
        echo ">> Create ssh key"
        echo "ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N \"\""
        ssh-keygen -t ed25519 -C $sshKeyComment -f $sshKeyName -N ""

        #add credential into authorizedKeys
        echo ">> Add credential to the autorizedKeys"
        echo "$sshKeyName.pub >> $authorizedKeys"
        cat $sshKeyName.pub >> $authorizedKeys

        sshPath=$sshKeyName
    fi
    #add credential into tower
    echo ">> Add credentials into tower"
    echo "$twPath/tw credentials add ssh -n $credentialName -w $humgenName/$workspaceName --key $sshPath"
    $twPath/tw credentials add ssh -n $credentialName -w $humgenName/$workspaceName --key $sshPath

    echo ""
    echo ""
}

function compEnv() {
    echo ""
    echo "workDir: (nextflow work dir path, you should have writting privileges in this directory)"
    read -p "It's recommended something like: /lustre/<team>/$userName/work : " workDir
    echo "launchDir: (nextflow launch dir path, you should have writting privileges in this directory)"
    read -p "It's recommended something like: /lustre/<team>/$userName/launch : " launchDir
    echo "" 

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
    echo ">> Import ComputeEnviroment into the workspace"
    echo "$twPath/tw compute-envs import -n $computeEnvName -w $humgenName/$workspaceName -c $credentialName compEnvTest"
    $twPath/tw compute-envs import -n $computeEnvName -w $humgenName/$workspaceName -c $credentialName compEnvTest

    #Clean stuff
    rm -rf compEnvTest
	echo ""
    echo ""
}

function run_all() {
	newUser
	userWorkspace
	sshKeyGen
	compEnv
}

menu(){
echo -ne "
-*-* -*-* -*-* -*-* -*-* -*-* -*-* 
-*-* nf Tower generator menu: -*-* 
-*-* -*-* -*-* -*-* -*-* -*-* -*-* 

1) Create a new tower's user
2) Build user's workspace
3) Generate ssh key credentials 
4) Produce Compute Enviroment
5) Run All
0) Exit
Choose an option: "
        read a
        case $a in
	        1) newUser ; menu ;;
	        2) userWorkspace ; menu ;;
	        3) sshKeyGen ; menu ;;
	        4) compEnv ; menu ;;
	        5) run_all ; menu ;;
		    0) exit 0 ;;
		*) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}

echo -n "Is '"$userName"' your Sanger user? [y/n]:"
old_stty_cfg=$(stty -g)
stty raw -echo ; isUser=$(head -c 1) ; stty $old_stty_cfg # Careful playing with stty
if echo "$isUser" | grep -iq "^n" ;then
    # ask for user
    echo ""
    read -p "Introduce your Sanger's username: i.e: 'en6' or 'ob1' : " userName
fi

# initialize variables / names
init

# Call the menu function
menu