#!/bin/bash
# Preflight check
# Version 0.1
# Copyright (c) 2009, Tobias Haeberle

APP_SUPPORT_DIR="$HOME/Libray/Application\ Support/Macfusion"
PLUGINS_DIR=$APP_SUPPORT_DIR/PlugIns

if ( ! -d $APP_SUPPORT_DIR ) 
then
mkdir $APP_SUPPORT_DIR
elif ( ! -d $PLUGINS_DIR)
	then
	mkdir $PLUGINS_DIR
fi