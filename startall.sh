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

function checkout_version(){
  if [ ${ver} != "latest" ]; then
    if [ $(git tag -l "V$ver") ]; then
      git checkout V$ver
    else
      LOG_ERROR "bee version $ver is not exists, please check."
      exit 1;
    fi
  fi
}

BM="WeBASE-Codegen-Monkey"
BB="WeBASE-Collect-Bee"
BBC="WeBASE-Collect-Bee-core"
GROUP_CONF="group.conf"
GROUP_CONF_TMP="group.conf.temp"
BASE_DIR=`pwd`
BUILD_DIR="dist"
LOG_INFO "Working dir is $BASE_DIR"

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME
Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi
LOG_INFO "JAVACMD: $JAVACMD"

### get argvs
ver="latest"
while getopts "v:stop" arg
do
  case $arg in
    v)
      ver=$OPTARG
      ;;
    ?)
      LOG_ERROR "unkonw argument\nusage: -v [bee_version]"
      exit 1
      ;;
  esac
done

LOG_INFO "bee version = $ver"

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
LOG_INFO "ports =  ${ports} "

IFS=',' read -r -a groupIdArrary <<< "$groupIds"
IFS=',' read -r -a portArrary <<< "$ports"

if [[ "${#groupIdArrary[@]}" != "${#portArrary[@]}" ]]
then
  LOG_ERROR "GourpIds length not match ports length"
fi

if [ -d "$BM" ];then
  LOG_INFO "Monkey already exist."
  cd $BM
  ## rm cached files
  rm -rf src/main/java/com/webank/blockchain/
  rm -rf src/main/java/org/
  git fetch
  if [ $? == 0 ];then
  	LOG_INFO "git fetch success"
  else
     LOG_ERROR "git fetch fail"
     exit 1;
  fi
  git reset --hard HEAD
else
  LOG_INFO "Begin to download Monkey ..."
  git clone https://github.com/WeBankFinTech/$BM.git
  cd $BM
fi
checkout_version

cd $BASE_DIR

if [ -d "$BB" ];then
  LOG_INFO "Bee already exist."
  cd $BB
    ## rm cached files
  rm -rf src/main/java/com/webank/bcosbee/generated
  rm -rf src/main/java/com/webank/webasebee/generated
  rm -rf src/main/java/com/webank/blockchain/
  rm -rf src/main/java/org
  git fetch
  if [ $? == 0 ];then
    LOG_INFO "git fetch success"
  else
    LOG_ERROR "git fetch fail"
    exit 1;
  fi
  git reset --hard HEAD
else
  LOG_INFO "Begin to download Bee ..."
  git clone https://github.com/WeBankFinTech/$BB.git
  cd $BB
fi
checkout_version

cd $BASE_DIR

for ((i=0; i<${#groupIdArrary[@]}; i++))
do
    groupId=${groupIdArrary[$i]}
    port=${portArrary[$i]}

    cd $BASE_DIR

    mkdir -p g${groupId} g${groupId}/.tools
    cp -rf $BM g${groupId}/.tools
    cp -rf $BB g${groupId}
    cp -rf config g${groupId}
    cp -f $BM/src/main/install_scripts/generate_bee.sh g${groupId}

    cd g${groupId}
    if [ "$(uname)" == "Darwin" ]; then
      sed -i "" "s/\[groupId]/$groupId/g" config/resources/application.properties
      sed -i "" "s/\[port]/$port/g" config/resources/application.properties
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
      sed -i "s/\[groupId]/$groupId/g" config/resources/application.properties
      sed -i "s/\[port]/$port/g" config/resources/application.properties
    fi

    # if [ "${ver}" == "latest" ];
    # then
    #   LOG_INFO "use latest version"
    #   bash generate_bee.sh -e build
    #   cd $BB/$BUILD_DIR
    #   chmod +x WeBASE*
    #   nohup $JAVACMD -jar WeBASE* &
    # else
    #   LOG_INFO "use version $ver"
    #   bash generate_bee.sh -e -v $ver
    #   cd $BB/$BUILD_DIR
    #   chmod +x WeBASE*
    #   nohup $JAVACMD -jar WeBASE* &
    # fi

    bash generate_bee.sh build
    cd $BB/$BBC/$BUILD_DIR
    chmod +x WeBASE*
    nohup $JAVACMD -jar WeBASE* >/dev/null 2>&1 &
done

LOG_INFO "bee started, view log at g*/WeBASE-Collect-Bee/WeBASE-Collect-Bee-core/dist/webasebee-core.log"


