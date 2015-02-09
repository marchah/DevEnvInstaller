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

CONF_FILE_USER="/home/$DEV_USER/conf_file_user"
CONF_FILE_ROOT="/root/conf_file_root"

ANDROID_STUDIO_DDL_LINK="https://dl.google.com/dl/android/studio/ide-zips/1.0.1/android-studio-ide-135.1641136-linux.zip"
ANDROID_STUDIO_ARCHIVE_NAME="android-studio.zip"
ANDROID_STUDIO_ARCHIVE_PATH="/tmp/$ANDROID_STUDIO_ARCHIVE_NAME"

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
	apt-get install -y nodejs;
    fi
   echo -e "$CYAN**** INSTALL NODE.JS DONE ****$NORMAL"
}

function installMongoDB() {
    echo -e "$CYAN**** INSTALLING MONGODB ****$NORMAL"
    if ! checkIfInstalled "mongo";
    then
	apt-key adv --keyserver keyserver.ubuntu.com:80 --recv 7F0CEB10;
	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list;
	apt-get update;
	apt-get install -y mongodb-org;
	checkIfInstallSuccess $? "MongoDB" "installation"
	service mongod start
	checkIfInstallSuccess $? "MongoDB" "start"
    fi
    echo -e "$CYAN**** INSTALL MONGODB DONE ****$NORMAL"
}

function installAndroidStudio() {
    # probably will need JDK
    echo -e "$CYAN**** INSTALLING ANDROID STUDIO ****$NORMAL"
    rm -f $ANDROID_STUDIO_ARCHIVE_PATH
    echo -e "     $GREEN 1) Downloading AndroidStudio$NORMAL"
    wget -O $ANDROID_STUDIO_ARCHIVE_PATH $ANDROID_STUDIO_DDL_LINK
    echo -e "     $GREEN 2) Unzip AndroidStudio Archive$NORMAL"
    unzip -q $ANDROID_STUDIO_ARCHIVE_PATH -d $DEV_FOLDER_PATH
    echo -e "     $GREEN 3) Install SDKs"
    # echo yes | android update sdk --all --no-ui --force
    echo -e "$CYAN**** INSTALL ANDROID STUDIO DONE ****$NORMAL"
}

if [ "$(id -u)" != "0" ]; then
   echo -e "$REDThis script must be run as root$NORMAL" 1>&2
   exit 1
fi

mkdir -p $DEV_FOLDER_PATH
checkRequirement
#updateSoftware
#installEmacs
#installNodeJS
#installMongoDB
installAndroidStudio
#cleaning
