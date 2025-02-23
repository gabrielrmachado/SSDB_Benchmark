#!/bin/bash
#
# BEGIN_COPYRIGHT
#
# Copyright (C) 2016-2019 SciDB, Inc.
# All Rights Reserved.
#
# SciDB is free software: you can redistribute it and/or modify
# it under the terms of the AFFERO GNU General Public License as published by
# the Free Software Foundation.
#
# SciDB is distributed "AS-IS" AND WITHOUT ANY WARRANTY OF ANY KIND,
# INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY,
# NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. See
# the AFFERO GNU General Public License for the complete license terms.
#
# You should have received a copy of the AFFERO GNU General Public License
# along with SciDB.  If not, see <http://www.gnu.org/licenses/agpl-3.0.html>
#
# END_COPYRIGHT
#

function die
{
    echo -e 1>&2 "Fatal: $1"
    exit 1
}

function get_os()
{
    which lsb_release > /dev/null
    if [ $? -eq 1 ]; then
	echo "The lsb-core package is required for this installation."
	which yum > /dev/null
	if [ $? -eq 0 ]; then
	    yum install -y redhat-lsb-core
	else
	    which apt-get > /dev/null
	    if [ $? -eq 0 ]; then
		apt-get install -y lsb-release
	    else
		echo "For CentOS/RedHat - yum install redhat-lsb-core."
		echo "For Ubuntu - apt-get install lsb-release."
		echo "After setting up the proper repositories."
		exit 1
	    fi
	fi
    fi
    OS=$(lsb_release -i | cut -d ":" -f 2 | tr -d '[:space:]')
    OS="$OS $(lsb_release -r | cut -d ":" -f 2 | cut -d '.' -f 1 | tr -d '[:space:]')"

}

function pkg_test()
{
    echo "Checking for $1."
    if [[ $OS == *"CentOS"* || $OS == *"RedHat"* ]]; then
	yum list installed $1 2> /dev/null > /dev/null
    elif [[ $OS == *"Ubuntu"* ]]; then
	dpkg -s $1 2> /dev/null > /dev/null
    else
	echo "Unknown OS!"
	exit 1
    fi
}

function pkg_install()
{
    if [ "$2" = "--force" ]; then
	echo "Installing $1."
	response="y"
    else
        echo "Required package $1 is not installed."
	read -r -p "Shall I install it for you? [y/N] " response
    fi

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	if [[ $OS == *"CentOS"* || $OS == *"RedHat"* ]]; then
	    yum install -y $1
	elif [[ $OS == *"Ubuntu"* ]]; then
	    apt-get install --force-yes $1
	fi
    else
	echo "Exiting installer."
	exit 1
    fi
}

function update_stdc()
{
    isGPP=$(apt list --installed | grep g++-4.9 | wc -l)
    if [ $isGPP -eq 0 ]; then
	echo "SciDB requires GCC 4.9."
	read -r -p "Shall I install it for you? [y/N] " response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	    add-apt-repository -y ppa:ubuntu-toolchain-r/test
	    apt-get update
	    apt-get install -y g++-4.9
	else
	    echo "Exiting installer."
	    exit 1
	fi
    fi
}

function check_dependencies()
{
    if [[ $OS == *"CentOS"* || $OS == *"RedHat"* ]]; then
	declare -a deps=("openssh" "openssh-server" "wget")
    elif [[ $OS == *"Ubuntu"* ]]; then
	declare -a deps=("openssh-client" "openssh-server" "wget" )
	update_stdc
    fi
    echo "${deps[@]}"
    for pkg_name in "${deps[@]}"
    do
	pkg_test "$pkg_name"
	if [ $? -ne 0 ]; then
	    pkg_install "$pkg_name"
	    if [ $? -ne 0 ]; then
		echo "$pkg_name not installed."
		echo "Exiting SciDB CE installation."
		exit 1
	    fi
	fi
    done
}

function check_previous()
{
    getent passwd postgres > /dev/null
    # If no postgres user, SciDB not installed all is cool.
    [ ! $? -eq 0 ] && return 0

    # If no postgres user, SciDB not installed all is cool.
    [ ! $? -eq 0 ] && return 0

    # If a 'mydb' database exists in postgres, we'll clobber it.  Stop now.
    sudo -u postgres psql -c "select 1 from pg_catalog.pg_database where datname = 'mydb'" | grep "1 row" > /dev/null
    [ $? -eq 0 ] && die "A database called 'mydb' already exists on this system.\nPlease remove it or install on another server."

    # If SciDB already put its file in the user's data directory.  Stop now.
    [ -e /home/$(logname)/scidb_data ] && die "A directory /home/$(logname)/scidb_data already exists.\nPlease remove them or install on another server."

    # If SciDB has been installed before, give the user the option."
    if [ -e /opt/scidb ]; then
	echo "SciDB has already been installed on this server.  Multiple copies of the application is an untested configuration."
	echo "Unexpected results may occur."
	echo "If you choose to continue, please make sure that you stop the existing application."
	read -r -p "Shall I continue? [y/N] " response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	    return 0
	else
	    exit 1
	fi
    fi
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as the installing user using 'sudo'. Correct usage:"
   echo "sudo ./install-scidb-ce.sh"
   exit 1
fi

if [ $(logname) == 'root' ]; then
    echo "Please do not install SciDB as the root user."
    echo "To operator properly, SciDB must be installed as a non-root"
    echo "user with sudo privileges."
    echo
    echo "Please re-login as another user and use:"
    echo "sudo ./install-scidb-ce.sh"
    exit 1
fi



check_previous

get_os

check_dependencies

if [[ $OS == *"CentOS"* || $OS == *"RedHat"* ]]; then
    rm -f scidb-19.11.0-repos.rpm
    wget https://downloads.paradigm4.com/community/19.11/scidb-19.11.0-repos.rpm
    rpm -i scidb-19.11.0-repos.rpm
    rm -f scidb-19.11.0-repos.rpm
elif [[ $OS == *"Ubuntu"* ]]; then
    rm -f scidb-19.11.0-repos.deb
    wget https://downloads.paradigm4.com/community/19.11/scidb-19.11.0-repos.deb
    dpkg -i scidb-19.11.0-repos.deb
    rm -f scidb-19.11.0-repos.deb
    apt-get update
fi

echo import setuptools | python 2> /dev/null
if [ $? -eq 1 ]; then
    wget https://bootstrap.pypa.io/ez_setup.py -O - | python
    rm -rf setuptools*.zip
fi

pkg_install scidb-19.11-ce --force

if [ $? -eq 0 ]; then
    if [[ $OS == *"Ubuntu"* ]]; then
	pushd /opt/scidb/19.11/scripts >/dev/null 2>&1
	./setup_scidb.sh /opt/scidb/19.11
	popd >/dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
	echo "================================================================="
	echo "SciDB successfully installed in /opt/scidb/19.11."
	echo "Please put /opt/scidb/19.11/bin on your path to execute queries."
	echo "================================================================="
    else
	err="true"
    fi
else
    err="true"
fi

if [[ $err == "true" ]]; then
	echo "================================================================="
	echo "SciDB not successfully installed.  Please examine"
	echo "messages above and look for errors."
	echo
	echo "If you are unable to resolve the issues, collect the output"
	echo "and contact Paradigm4 at info@paradigm4.com or post to our forum"
	echo "forum.paradigm4.com for help."
	echo "================================================================="
	exit 1
else
    exit 0
fi


