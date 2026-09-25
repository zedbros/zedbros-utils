The scripts found in this folder were used to parse specific AWS Cloudtrail logs, in order to find which AWS managed policies fit the permissions found in the logs.

The goal of this project is to create an IAM Role that follows the least permissions concept.\
You can add up to 25 managed policies to a role.

If the chosen amount of managed policies don't cover all the permissions, inline policies can be used to fill in the gaps.

# Pre-requisites
You need:
1. A folder of collected AWS Cloudtrail logs
Either
    Automatic:
        Run the `aquire-this-fine-functionnality.sh`
    Manual:
        1. A folder of AWS Managed Policies (recommended: [aws-managed-policy-tracker](https://github.com/kisst/aws-managed-policy-tracker))
        2. A copy of this folder of scripts

# Steps
1. After downloading all the logs, put them into one folder. ex: "custom/path/logs".\
<sub>(note: preferably "custom/path" only contains the logs folder to avoid tampering with your files that may have the same name as temporary files created by the scripts)</sub>

2. Move your AWS Managed Policies folder into "custom/path".

3. Copy this folder into wherever you like but make sure to be in the "custom/path" when calling the following scripts. ex: "path/to/scripts"

3. EITHER
    - Call `sh path/to/scripts/automatic.sh` to get the final results
    or
    - Do everything manually
3. (manual mode)
    #### Filter time logs
    This will go through each log file and retrieve each permission that was used.
