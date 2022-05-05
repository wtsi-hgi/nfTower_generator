# nfTower_generator

The purpose of this script is to set up the enviroment in tower for a new user.

The script will ask some details to perform all the opeations. \
_username_ : login user for the selected credentials (i.e. ‘ob1’ or ‘service-account’)\
_workDir_ :  nextflow work dir path, i.e.: `/lustre/<Your Team>/work`\
_launchDir_ :  nextflow launch dir path, i.e.: `/lustre/<Your Team>/launch`\

This script will:\
- create a user in tower
- make a workspace for the user
- generate the credentials of farm for this workspace
- build a compute enviroment using user credentials

You can add more credentials from Tower GUI, and/or create new ComputeEnviroments. It's recomended to `clone` the default and modify what is needed.
\
To run the script just: `./setUpTower.sh`