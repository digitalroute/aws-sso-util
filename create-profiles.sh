#!/usr/bin/env bash
set -u
set -e

PYTHON3_INSTALLED=0
which python3 > /dev/null 2>&1 || PYTHON3_INSTALLED=1
if [ ${PYTHON3_INSTALLED} -ne 0 ]; then
  cat << EOF  >&2

ERROR: python3 is not installed, this script requires python version 3
available on the PATH as 'python3'. Fix this by installing python3, using
the appropriate tools for your Operating System.

EOF
  exit 1
fi

VENV_INSTALLED=0
python3 -c 'import venv' > /dev/null 2>&1 || VENV_INSTALLED=1

if [ ${VENV_INSTALLED} -ne 0 ]; then
  cat << EOF  >&2

ERROR: The python module venv is not installed.
Fix this by installing this module. Depending on your Operating System:

  # For Debian-based OS
  sudo apt update
  sudo apt-get install python3-venv

  # For Redhat-based OS
  sudo yum update
  sudo yum install python3-venv

EOF
  exit 1
fi

if [ ! -z ${VIRTUAL_ENV+x} ]; then
  cat << EOF  >&2

ERROR: VIRTUAL_ENV is already set, indicating that you're running inside a
python virtual environment. Please don't run this script inside a virtual env.
Deactivate the virtual environment before continuing, e.g.

  # Use the deactivate function
  deactivate
  # Or (not recommended)
  unset VIRTUAL_ENV

EOF
  exit 1
fi

if [ -z ${DR_SSO_START_URL+x} ]; then
  cat << EOF >&2

ERROR: Missing DR_SSO_START_URL, this parameter is needed to find the SSO endpoint.
Fix this by setting DR_SSO_START_URL before invoking this script, e.g.

  export DR_SSO_START_URL=https://foo.amazonapps.com/start

EOF
  exit 1
fi

if [ -z ${DR_SSO_REGION+x} ]; then
  USE_REGION="eu-west-1"
else
  USE_REGION="${DR_SSO_REGION}"
fi

SCRIPT_HOME=~/.dr-aws-sso-util/
PYENV_HOME="${SCRIPT_HOME}/pyenv1"
NAMING_SCRIPT_FILE="${SCRIPT_HOME}/naming-script.sh"

function make_naming_script {
  cd ${SCRIPT_HOME}
  dir=$(pwd)
  echo '#!/usr/bin/env bash
set -u
set -e
acc="$(echo $1| tr "[:upper:]" "[:lower:]")"
acc="${acc/#digitalroute-/}"
rol="$(echo $3| tr "[:upper:]" "[:lower:]")"
rol="${rol/#developer/dev}"
rol="${rol/#administrator/admin}"
rol="${rol/#implementation/impl}"

echo -n "sso-${acc}-${rol}"
' > "${NAMING_SCRIPT_FILE}"
  chmod 744 "${NAMING_SCRIPT_FILE}"
}

if [ ! -d "${PYENV_HOME}" ]; then
  mkdir -p "${PYENV_HOME}"
  python3 -m venv "${PYENV_HOME}"
fi

source "${PYENV_HOME}/bin/activate"

if [ -z ${VIRTUAL_ENV+x} ]; then
  cat << EOF >&2

ERROR: Couldn't activate python virtual environment. There is no trivial fix for
this. Try your luck at patching the script, or resort to some other method of
installing your AWS SSO profiles.

EOF
  exit 1
fi

if [ $(pip list 2>/dev/null | grep aws-sso-util | wc -l) -ne 1 ]; then
  pip install --no-input aws-sso-util 2>/dev/null 1>&2
fi

make_naming_script "${SCRIPT_HOME}"

aws-sso-util configure populate --region "${USE_REGION}" --sso-region "${USE_REGION}" --sso-start-url "${DR_SSO_START_URL}" --profile-name-process "${NAMING_SCRIPT_FILE}" --no-credential-process
