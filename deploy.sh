#!/usr/bin/env bash

BASEDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# resolve symlinks
while [ -h "$BASEDIR/$0" ]; do
    DIR=$(dirname -- "$BASEDIR/$0")
    SYM=$(readlink $BASEDIR/$0)
    BASEDIR=$(cd $DIR && cd $(dirname -- "$SYM") && pwd)
done
cd ${BASEDIR}
cd backend

envs=$(eb list | sed 's/^\* //')

if [[ ${1} != panopticon-* ]]; then
  echo "Usage: ${0} panopticon-<environment>"
  echo
  echo "Available environments:"
  echo "${envs}"
  exit 1
elif [ $(echo "${envs}" | grep "^${1}$" -c) -eq 0 ]; then
  echo "Environment not recognized: '${1}'. Use one of the following:"
  echo
  echo "${envs}"
  exit 1
fi

local_version=$( grep -E "<version>[0-9]+(\.[0-9]+).*(SNAPSHOT)?</version>" pom.xml -m1 2> /dev/null | sed 's/.*<version>\(.*\)<\/version>/\1/' )

version_suggestion="[${local_version}] "
read -p "Version? ${version_suggestion}" version
[ -z ${version} ] && version="${local_version}"

beanstalk_env=${1}
env=$(echo ${beanstalk_env} | sed s/panopticon-//g)

trap "{ rm -f app.zip ; exit 255; }" EXIT

../package.sh ${env} ${version}
if [ $? -ne 255 ]; then
  echo "> Package failed!"
  exit 1
fi

echo "> Starting deploy"
eb deploy "${beanstalk_env}"

echo "Deploy complete.'"
exit 0
