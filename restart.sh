#!/usr/bin/env bash
LANG=zh_CN.UTF-8

function LOG_INFO()
{
    local content=${1}
    echo -e "\033[32m"${content}"\033[0m"
}

function LOG_ERROR()
{
    local content=${1}
    echo -e "\033[31m"${content}"\033[0m"
}

BM="WeBASE-Codegen-Monkey"
BB="WeBASE-Collect-Bee"
BBC="WeBASE-Collect-Bee-core"
GROUP_CONF="group.conf"
GROUP_CONF_TMP="group.conf.temp"
BASE_DIR=`pwd`
BUILD_DIR="dist"

# Begin to read group.conf
LOG_INFO "Reading group config file"
if [ -f "$GROUP_CONF" ]
then
  grep -v "^#"  $GROUP_CONF | grep -v "^$" | grep "="  > $GROUP_CONF_TMP

  while IFS='=' read -r key value
  do
    key=$(echo $key | tr '.' '_')
    key=`echo $key |sed 's/^ *\| *$//g'`
    eval "${key}='${value}'"
  done < "$GROUP_CONF_TMP"
  rm -f $GROUP_CONF_TMP
else
  LOG_ERROR "$GROUP_CONF not found."
  exit 1
fi

LOG_INFO "groupIds =  ${groupIds} "
IFS=',' read -r -a groupIdArrary <<< "$groupIds"
for ((i=0; i<${#groupIdArrary[@]}; i++))
do
    groupId=${groupIdArrary[$i]}
    LOG_INFO "restarting group $groupId..."
    cd ${BASE_DIR}/g${groupId}/$BB/$BBC/$BUILD_DIR
    nohup bash start.sh >/dev/null 2>&1 &
done

LOG_INFO "restart succeed!"
