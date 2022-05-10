# nfTower_generator

The purpose of this script is to set up the enviroment in tower for a new user.

When the script starts, it will ask if it has captured correctly your username.

Then a menu will appear:
```
1) Create a new tower's user
2) Build user's workspace
3) Generate ssh key credentials 
4) Produce Compute Enviroment
5) Run All
6) Info
0) Exit
```

The first option will generate a user in Tower

The second option will create the user's workspace in a private mode, and the user will be ADMIN

On the third option the user can introduce his own sshkey's path or allow the script to generate one for them.

The fourth option will create the compute enviroment. To perform that operation, the script needs :
- _workDir_ :  nextflow work dir path, i.e.: `/lustre/<Your Team>/work`
- _launchDir_ :  nextflow launch dir path, i.e.: `/lustre/<Your Team>/launch`

The option num 5 will run all the operations sequencially and perform all the tasks needed to have tower configured from scracth.

The next option will show information about the account: userName, workspaceName, credentials, url to tower and to the documentation.

You can add more credentials from Tower GUI, and/or create new ComputeEnviroments. It's recomended to `clone` the default and modify what is needed.
\
To run the script just: `./launcher.sh` . This script will run `/software/hgi/installs/nf_tower/setUpTower.sh`

If you want to re-use this project, you can place your tokens and IDs in `/script/setUpTower.sh` :
- `envToken` it reffers to `TOWER_ACCESS_TOKEN`
- `envEndPoint` it reffers to `TOWER_API_ENDPOINT`
- `twPath` it is the path to the `tw` binary
- `hostName` this variable refers to the `hostName` on the `COMPUTE ENV`

And run directly the `/script/setUpTower.sh` instead of the `launcher.sh`
