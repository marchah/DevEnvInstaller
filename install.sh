#!/bin/bash

FALSE=0
TRUE=1

RED="\\033[0;31m"
CYAN="\e[36m"
GREEN="\e[32m"
NORMAL="\\033[0;39m"

DEV_USER="marcha"
DEV_FOLDER_PATH="/home/$DEV_USER/dev/"

CONF_FILE_EMACS_ALIAS="alias emacs='emacs -nw'"

CONF_FILE_USER="/home/$DEV_USER/.bashrc"
CONF_FILE_ROOT="/root/.bashrc"

ANDROID_STUDIO_DDL_LINK="https://dl.google.com/dl/android/studio/ide-zips/1.0.1/android-studio-ide-135.1641136-linux.zip"
ANDROID_STUDIO_ARCHIVE_NAME="android-studio.zip"
ANDROID_STUDIO_ARCHIVE_PATH="/tmp/$ANDROID_STUDIO_ARCHIVE_NAME"

ANDROID_SDK_DDL_LINK="dl.google.com/android/android-sdk_r24.0.2-linux.tgz"
ANDROID_SDK_ARCHIVE_NAME="android-sdk.tgz"
ANDROID_SDK_ARCHIVE_PATH="/tmp/$ANDROID_SDK_ARCHIVE_NAME"
ANDROID_SDK_FOLDER_NAME="android-sdk-linux"

DISTR=""

getDistributionType()
{
    local dtype
    # Assume unknown
    dtype="unknown"

    # First test against Fedora / RHEL / CentOS / generic Redhat derivative
    if [ -r /etc/rc.d/init.d/functions ]; then
        source /etc/rc.d/init.d/functions
        [ zz`type -t passed 2>/dev/null` == "zzfunction" ] && dtype="redhat"

    # Then test against SUSE (must be after Redhat,
    # I've seen rc.status on Ubuntu I think? TODO: Recheck that)
    elif [ -r /etc/rc.status ]; then
        source /etc/rc.status
        [ zz`type -t rc_reset 2>/dev/null` == "zzfunction" ] && dtype="suse"

    # Then test against Debian, Ubuntu and friends
    elif [ -r /lib/lsb/init-functions ]; then
        source /lib/lsb/init-functions
        [ zz`type -t log_begin_msg 2>/dev/null` == "zzfunction" ] && dtype="debian"

    # Then test against Gentoo
    elif [ -r /etc/init.d/functions.sh ]; then
        source /etc/init.d/functions.sh
        [ zz`type -t ebegin 2>/dev/null` == "zzfunction" ] && dtype="gentoo"

    # For Slackware we currently just test if /etc/slackware-version exists
    # and isn't empty (TODO: Find a better way :)
    elif [ -s /etc/slackware-version ]; then
        dtype="slackware"
    fi
    DISTR=$dtype
}

function checkIfInstalled() {
    if hash $1 2>/dev/null; then
	return $FALSE
    else
	return $TRUE
    fi
}

function checkRequirement() {
    if ! checkIfInstalled "curl"; then echo -e "$REDRequire curl but it's not installed.  Aborting.$WHITE" >&2; exit 1; fi
    if ! checkIfInstalled "unzip"; then echo -e "$REDRequire unzip but it's not installed.  Aborting.$WHITE" >&2; exit 1; fi
}

function updateSoftware() {
    echo -e "$CYAN**** UPDATING SOFTWARES ****$NORMAL"
    apt-get update -y -qq
    apt-get upgrade -y -qq
#    apt-get dist-upgrade
    echo -e "$CYAN**** UPDATE SOFTWARES DONE ****$NORMAL"
}

function cleaning() {
    echo -e "$CYAN**** CLEANING APT-GET ****$NORMAL"
    apt-get autoclean -y -qq
    echo -e "$CYAN**** CLEAN APT-GET DONE ****$NORMAL"
    echo -e "$CYAN**** REMOVING USELESS PACKET ****$NORMAL"
    apt-get autoremove -y -qq
    echo -e "$CYAN**** REMOVE USELESS PACKET DONE ****$NORMAL"
}

function checkIfInstallSuccess() {
    if [[ $1 != 0 ]];
    then
	echo -e "$RED$2 $3 failed$NORMAL";
	exit $rc;
    fi
}

function installEmacs() {
    echo -e "$CYAN**** INSTALLING EMACS ****$NORMAL"
    if ! checkIfInstalled "emacs";
    then apt-get install -y emacs -qq;
    fi
    checkIfInstallSuccess $? "Emacs" "installation"
    echo "$CONF_FILE_EMACS_ALIAS" >> $CONF_FILE_USER
    echo "$CONF_FILE_EMACS_ALIAS" >> $CONF_FILE_ROOT
    echo -e "$CYAN**** INSTALL EMACS DONE****$NORMAL"
}

function installNodeJS() {
   echo -e "$CYAN**** INSTALLING NODE.JS ****$NORMAL"
    if ! checkIfInstalled "node";
    then
	curl -sL https://deb.nodesource.com/setup | bash -;
	apt-get install -y nodejs -qq;
    fi
   echo -e "$CYAN**** INSTALL NODE.JS DONE ****$NORMAL"
}

function installMongoDB() {
    echo -e "$CYAN**** INSTALLING MONGODB ****$NORMAL"
    if ! checkIfInstalled "mongo";
    then
	if [ "$DISTR" == "ubuntu" ]; then
	    apt-key adv --keyserver keyserver.ubuntu.com:80 --recv 7F0CEB10;
	    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list;
	elif [ "$DISTR" == "debian" ]; then
	    apt-key adv --keyserver keyserver.ubuntu.com:80 --recv 7F0CEB10;
	    echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list;
	else
	    echo "MongoDB installation not supported on $DISTRO"
	fi
	apt-get update -qq;
	apt-get install --force-yes mongodb-org -qq;
	checkIfInstallSuccess $? "MongoDB" "installation"
	service mongod start
	checkIfInstallSuccess $? "MongoDB" "start"
    fi
    echo -e "$CYAN**** INSTALL MONGODB DONE ****$NORMAL"
}

function installAndroidStudio() {
    echo -e "$CYAN**** INSTALLING ANDROID STUDIO ****$NORMAL"
    if ! checkIfInstalled "javac"; then
	echo -e "     $GREEN 0) Installing JDK$NORMAL"
	apt-get install -y -qq openjdk-7-jdk
	export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386/
    fi
    #rm -f $ANDROID_STUDIO_ARCHIVE_PATH
    echo -e "     $GREEN 1) Downloading AndroidStudio$NORMAL"
    #wget -O $ANDROID_STUDIO_ARCHIVE_PATH $ANDROID_STUDIO_DDL_LINK
    echo -e "     $GREEN 2) Unzip AndroidStudio Archive$NORMAL"
    #unzip -q $ANDROID_STUDIO_ARCHIVE_PATH -d $DEV_FOLDER_PATH

#    rm -f $ANDROID_SDK_ARCHIVE_PATH
    echo -e "     $GREEN 3) Downloading Android SDK$NORMAL"
 #   wget -O $ANDROID_SDK_ARCHIVE_PATH $ANDROID_SDK_DDL_LINK
    echo -e "     $GREEN 4) Unzip Android SDK Archive$NORMAL"
    tar xzf $ANDROID_SDK_ARCHIVE_PATH
    mv $ANDROID_SDK_FOLDER_NAME $DEV_FOLDER_PATH/.
    echo -e "     $GREEN 5) Install SDKs"
#    echo yes | android update sdk --all --no-ui --force
    echo -e "$CYAN**** INSTALL ANDROID STUDIO DONE ****$NORMAL"
}

if [ "$(id -u)" != "0" ]; then
   echo -e "$REDThis script must be run as root$NORMAL" 1>&2
   exit 1
fi

mkdir -p $DEV_FOLDER_PATH
checkRequirement
getDistributionType
#updateSoftware
installEmacs
installNodeJS
installMongoDB
#installAndroidStudio
#cleaning

# TODO
#alias clean
#exit shell to reload .bashrc
