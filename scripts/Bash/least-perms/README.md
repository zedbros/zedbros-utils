Theses scripts parse specific AWS Cloudtrail logs, retrieve all AWS Managed Policies and all AWS Actions, in order to find which AWS managed policies best fit the list of permissions found in the logs.

The goal of this project is to create an IAM Role that follows the least permissions concept.\
You can add up to 25 managed policies to an IAM role.

If the chosen amount of managed policies doesn't cover all the permissions, inline policies can be used to fill in the gaps.

# Pre-requisites
You need:
1. A folder of collected AWS Cloudtrail logs
2. The scripts found in this folder
2. And finally, a folder of AWS Managed Policies (recommended: [aws-managed-policy-tracker](https://github.com/kisst/aws-managed-policy-tracker))

# Steps
1. After downloading all the logs, put them into one folder. ex: "custom/path/logs".\
<sub>(note: preferably "custom/path" only contains the logs folder to avoid tampering with your files that may have the same name as temporary files created by the scripts)</sub>

2. Move your AWS Managed Policies folder into "custom/path".

TODO: Insert a file tree diagram.

3. Copy this folder into wherever you like but make sure to be in the "custom/path" when calling the following scripts. ex: "path/to/scripts"

4. Run the get-all-aws-actions.bash script. [This can take up to 3minutes.]

5. EITHER
    - Run `path/to/scripts/s0-automatic.bash` to get the final results
    or
    - Do everything manually
(manual mode)
    #### s1 Extract log permissions
    This will go through each log file and retrieve each permission that was used.
    #### s2 Match managed policies to log permissions
    Retrieves a list of all the compatible managed policies.
    #### s3 Venn
    #### s4 cleanup
    Puts all the locally created files into a versioned folder for multiple use.
