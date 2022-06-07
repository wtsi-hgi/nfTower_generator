# nfTower_generator

The purpose of this script is to set up the enviroment in tower for a new user.

To run the script you will need to change the permissions `chmod 770 launcher.sh` and run it with `./launcher.sh`. When the script starts, it will ask if it has captured correctly your username.
`Is 'XXX' your Sanger user? [y/n]:` After it the menu will appear:

```
1) Create a new tower's user
2) Build user's workspace
3) Generate ssh key credentials 
4) Produce Compute Enviroment
5) Run All
6) Info
0) Exit
```

* The first option will generate a user in Tower
```
Choose an option: 1
>> Create a new user
/tw members add -u XXX@sanger.ac.uk -o humgen
```

* The second option will create the user's workspace in a private mode, and the user will be ADMIN
```
Choose an option: 2
>> Create the workspace
/tw workspaces add -o humgen -n XXX -f XXX_workspace
 
>> Add user to the workspace
/tw  participants add -n XXX@sanger.ac.uk -t MEMBER -w humgen/XXX
 
>> Change the role of the user in the workspace
/tw participants update -n XXX@sanger.ac.uk -t MEMBER -r ADMIN -w humgen/XXX
```

* On the third option the user can introduce his own sshkey's path or allow the script to generate one for them. It gives less issues if you allow to generate a sshkey for this tool
```
Choose an option: 3
Do you want to use your own sshKey credentials [y/n]: n >> Create ssh key
ssh-keygen -t ed25519 -C nextflow_tower -f /nfs/users/nfs_/XXX/.ssh/nextflow_tower -N ""
Generating public/private ed25519 key pair.
Your identification has been saved in /nfs/users/nfs_/XXX/.ssh/nextflow_tower
Your public key has been saved in /nfs/users/nfs_/XXX/.ssh/nextflow_tower.pub
The key fingerprint is:
SHA256:_-*_-*_-*_-*_-*_-*_-* nextflow_tower
The key's randomart image is:
+--[ED25519 256]--+
_-*_-*_-*_-*_-*_-*
+----[SHA256]-----+
>> Add credential to the autorizedKeys
/nfs/users/nfs_/XXX/.ssh/nextflow_tower.pub >> /nfs/users/nfs_/XXX/.ssh/authorized_keys
>> Add credentials into tower
/tw credentials add ssh -n XXX_farm -w humgen/XXX --key /nfs/users/nfs_/XXX/.ssh/nextflow_tower
```
or you can add the path to your own sshkey file
```
Choose an option: 3
Do you want to use your own sshKey credentials [y/n]:  y
Path to the PRIVATE sshKey: ~/.ssh/nextflow_tower
>> Add credentials into tower
/tw credentials add ssh -n XXX_farm -w humgen/XXX --key /nfs/users/nfs_/XXX/.ssh/nextflow_tower
```

* The fourth option will create the compute enviroment. To perform that operation, the script needs :
- _workDir_ :  nextflow work dir path, i.e.: `/lustre/<Your Team>/work`
- _launchDir_ :  nextflow launch dir path, i.e.: `/lustre/<Your Team>/launch`
It's needed the user has write permission on that directory.
```

Choose an option: 4
workDir: (nextflow work dir path, you should have writting privileges in this directory)
It's recommended something like: /lustre/<team>/XXX/work : /lustre/<team>/XXX/work
launchDir: (nextflow launch dir path, you should have writting privileges in this directory)
It's recommended something like: /lustre/<team>/XXX/launch : /lustre/<team>/XXX/launch
 
>> Import ComputeEnviroment into the workspace
/tw compute-envs import -n XXX_normal -w humgen/XXX -c XXX_farm compEnvTest
```

* The option num 5 will run all the operations sequencially and perform all the tasks needed to have tower configured from scracth.

* The next option will show information about the account: userName, workspaceName, credentials, url to tower and to the documentation.
```
Choose an option: 6
Your data in the humGen Tower
Email: XXX@sanger.ac.uk
Your workspace is: XXX
A compute enviroment has been set with your credentials (ssh XXX_farm)
under the name: XXX_normal
 
You can start using Tower at:
https://nf-tower.cellgeni.sanger.ac.uk
 
You can find more info in the confluence page:
https://confluence.sanger.ac.uk/display/HGI/Nextflow+Tower
```

You can add more credentials from Tower GUI, and/or create new ComputeEnviroments. It's recomended to `clone` the default and modify what is needed.


The `launcher.sh` will run `/software/hgi/installs/nf_tower/setUpTower.sh` but it is provided if it want to be reused with other parameters. If you want to re-use this project, you can place your tokens and IDs in `/script/setUpTower.sh` :

- `envToken` it reffers to `TOWER_ACCESS_TOKEN`
- `envEndPoint` it reffers to `TOWER_API_ENDPOINT`
- `twPath` it is the path to the `tw` binary
- `hostName` this variable refers to the `hostName` on the `COMPUTE ENV`

And run directly the `/script/setUpTower.sh` instead of the `launcher.sh`

More detailed information can be found at [Nextflow Tower in Confluence](https://confluence.sanger.ac.uk/display/HGI/Nextflow+Tower)