# aws-sso-util
Digitalroute AWS Single sign-on utilities

## Scripts
### create-profiles.sh
Will create SSO profiles in the aws config file for all SSO accounts you have access to.
```bash
# Requires SSO start URL
export DR_SSO_START_URL=https://foo.awsapps.com/start
./create-profiles.sh

# Optionally set region, default = eu-west-1
export DR_SSO_REGION=us-east-1
./create-profiles.sh
```
Requires python3 and the venv module to install the benkehoe/aws-sso-util utility under `~/.dr-aws-sso-util/`.
