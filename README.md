# nfTower_generator

The purpose of this script is to set up the enviroment in tower for a new user.

The script will ask some details to perform all the opeations. 
- _username_ : login user for the selected credentials (i.e. ‘ob1’ or ‘service-account’)
- _workDir_ :  nextflow work dir path, i.e.: `/lustre/<Your Team>/work`
- _launchDir_ :  nextflow launch dir path, i.e.: `/lustre/<Your Team>/launch`

This script will:
- create a user in tower
- make a workspace for the user
- generate the credentials of farm for this workspace
- build a compute enviroment using user credentials

You can add more credentials from Tower GUI, and/or create new ComputeEnviroments. It's recomended to `clone` the default and modify what is needed.
\
To run the script just: `./launcher` . This script will run `/software/hgi/installs/nf_tower/setUpTower.sh`

All the operations are performed in `/script/setUpTower.sh` but it is used the `launcher.sh` to keep the tokens hidden. 

If you want to re-use this project, you can place your tokens and IDs in `/script/setUpTower.sh` :

- `envToken` it reffers to `TOWER_ACCESS_TOKEN`
- `envEndPoint` it reffers to `TOWER_API_ENDPOINT`
- `twPath` it is the path to the `tw` binary
- `humgenId` it is the `TOWER_WORKSPACE_ID`
- `hostName` this variable refers to the `hostName` on the `COMPUTE ENV`


And run directly the `/script/setUpTower.sh` instead of the `launcher`
