# Intro
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
#### FILES
1. After downloading all the logs, put them into one folder. ex: "custom/path/logs".\
<sub>(note: preferably "custom/path" only contains the logs folder to avoid tampering with your files that may have the same name as temporary files created by the scripts)</sub>

2. Move your AWS Managed Policies folder into "custom/path".

3. Copy this folder into wherever you like **but make sure to be in the "custom/path" when calling the following scripts**.
```
├── custom-path/
│   ├── logs/
│   │   ├── log1.json
│   │   └── log2.json
│   └── aws-managed-policy-tracker/
│       ├── policies/
│       │   ├── mp1.json
│       │   └── mp2.json
│       └── .../
└── other-custom/
    └── theses-scripts/
        ├── get-all-aws-actions.bash
        ├── s0-automatic.bash
        ├── s1-extract-log-permissions.bash
        ├── s2-match-logPerms-managedPoliciesPerms.bash
        ├── s3-venn.bash
        ├── s4-cleanup.bash
        └── README.md
```
#### RUN SCRIPTS
The script are in bash and you can run them doing either `./script.bash` or `bash script.bash`.

4. Run the `get-all-aws-actions.bash` script. [This can take up to ~3minutes.]

5. EITHER
    - Automatic: Run `path/to/scripts/s0-automatic.bash "y" "logsDir" "startTime" "managedPoliciesDir" (optional: sleepAfterFinished)` to get the final results. (see PARAMETERS section in s0 script for details)\
    You are still prompted during s3.

    or

    - Manual: Run scripts s1 through s4. You are prompted for each script.
