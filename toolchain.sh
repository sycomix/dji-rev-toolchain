#!/bin/bash
#
# dji-rev tool chain updater
#
# (c) 2017 Czokie
#
# This code is provided to the community under GPLv3 terms. Full license details
# are available in the repository. For the avoidance of doubt, anyone is free
# to use this tool in accordance with the GPLv3 license. This license requires
# that the copyright notice (this message) is included in any derivative
# works. That includes you Danny Mercer. Stop using other people's work
# without acknowledging their work.
#
# As the author of this work, I consider this license requirement to be met
# if the either this notice is included in any derivative work, or the
# derivative work includes an attribution link to http://dji.retroroms.net/

#
# pkgtype will return the type of package management that is in use for the OS where this
# script is running
#
function pkgtype {
	uname -a | grep -q Darwin
	if [ $? -eq 0 ]; then
		echo brew
		return
	fi
	which yum > /dev/null
	if [ $? -eq 0 ]; then
		echo yum
		return
	fi
	which apt > /dev/null
	if [ $? -eq 0 ]; then
		echo apt-get
		return
	fi
	exit 1
}

#
# cplist will return a list of currently installed packages using the primary package
# management system

function cplist {
	case $1 in
    brew)
		brew list
		brew cask list
		;;
	yum)
		yum list installed
		;;
	apt-get)
		apt list --installed
		;;
	*)
		echo doh
		exit 0
		;;
	esac
}

PKGMGR=`pkgtype`
IPLIST=/tmp/pkglist
### If running on OSX, install homebrew and xcode-select if required
if [ $PKGMGR = "brew" ]; then
	xcode-select --install 2>/dev/null
	which brew > /dev/null
	if [ $? -gt 0 ]; then
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	echo "Running brew update"
	brew update
else
	echo "Non OSX install - Other systems not yet fully supported"
	echo "Continuing to attempt to install Python and Ruby components"
fi


### Install primary packages
PKGLIST="python python3 libusb dialog git-lfs wget nodejs"
cplist $PKGMGR > $IPLIST

if [ $PKGMGR = "brew" ]; then
	for X in $PKGLIST
	do
		grep -c "^$X\$" $IPLIST > /dev/null
		if [ $? -eq 0 ]; then
			echo "$X is already installed"
		else
			brew install $X
			if [ $X = "git-lfs" ]; then
				git lfs install
				sudo git lfs install --system
			fi
		fi

	done
fi

### Install secondary packages
PKGLIST="android-platform-tools"
if [ $PKGMGR = "brew" ]; then
	for X in $PKGLIST
	do
		grep -c $X $IPLIST > /dev/null
		if [ $? -eq 0 ]; then
			echo "$X is already installed"
		else
			brew cask install $X
		fi

	done
fi

### Install python components
pip2 list --format=columns | cut -d " " -f 1 2>&1 > $IPLIST
PKGLIST="pathlib pyusb pyserial pkcs7"
for X in $PKGLIST
do
	grep -c $X $IPLIST > /dev/null
	if [ $? -eq 0 ]; then
		echo "$X is already installed"
	else
		pip2 install $X
	fi

done

### Install python3 components
pip3 list --format=columns | cut -d " " -f 1 > $IPLIST
PKGLIST="pycrypto"
for X in $PKGLIST
do
	grep -c $X $IPLIST > /dev/null
	if [ $? -eq 0 ]; then
		echo "$X is already installed"?
	else
		pip3 install $X
	fi

done

### Install ruby GEM's
gem list | cut -d " " -f 1 > $IPLIST
PKGLIST="colorize minitar serialport highline"
for X in $PKGLIST
do
	grep -c $X $IPLIST > /dev/null
	if [ $? -eq 0 ]; then
		echo "$X is already installed"
	else
		sudo gem install $X
	fi
done

### Install some java tools
mkdir -p ~/Documents/tools
cd ~/Documents/tools
wget https://github.com/appium/sign/raw/master/dist/sign.jar
wget -Oapktool.jar https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.2.3.jar

### Install some nodejs components
mkdir -p ~/Documents/nodejs
cd ~/Documents/nodejs
npm install asar
npm install standard --save-dev
