#!/bin/bash

# Does this need to be smarter for each host OS?
if [ -z "$INSTALL_PREFIX" ] ; then
	INSTALL_PREFIX="/usr/local/bin"
fi

if [ -z "$REPO_NAME" ] ; then
	REPO_NAME="gitflow2"
fi

if [ -z "$REPO_HOME" ] ; then
	REPO_HOME="http://github.com/realyze/gitflow2.git"
fi

EXEC_FILES="git-flow2"
SCRIPT_FILES="git-flow-feature git-flow-feature-start git-flow-feature-finish spinner.sh rainbow.sh"

echo "### gitflow2 no-make installer ###"

case "$1" in
	uninstall)
		echo "Uninstalling gitflow2 from $INSTALL_PREFIX"
		if [ -d "$INSTALL_PREFIX" ] ; then
			for script_file in $SCRIPT_FILES $EXEC_FILES ; do
				echo "rm -vf $INSTALL_PREFIX/$script_file"
				rm -vf "$INSTALL_PREFIX/$script_file"
			done
		else
			echo "The '$INSTALL_PREFIX' directory was not found."
			echo "Do you need to set INSTALL_PREFIX ?"
		fi
		exit
		;;
	help)
		echo "Usage: [environment] installer.sh [install|uninstall]"
		echo "Environment:"
		echo "   INSTALL_PREFIX=$INSTALL_PREFIX"
		echo "   REPO_HOME=$REPO_HOME"
		echo "   REPO_NAME=$REPO_NAME"
		exit
		;;
	*)
		echo "Installing gitflow2 to $INSTALL_PREFIX"
		if [ -d "$REPO_NAME" -a -d "$REPO_NAME/.git" ] ; then
			echo "Using existing repo: $REPO_NAME"
		else
			echo "Cloning repo from GitHub to $REPO_NAME"
			git clone "$REPO_HOME" "$REPO_NAME"
		fi
		install -v -d -m 0755 "$INSTALL_PREFIX"
		for exec_file in $EXEC_FILES ; do
			install -v -m 0755 "$REPO_NAME/$exec_file" "$INSTALL_PREFIX"
		done
		for script_file in $SCRIPT_FILES ; do
			install -v -m 0644 "$REPO_NAME/$script_file" "$INSTALL_PREFIX"
		done
		exit
		;;
esac
