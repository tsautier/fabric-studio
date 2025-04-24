#!/bin/bash
#===============================================================================
# SCRIPT NAME:    addons.sh
# DESCRIPTION:    Additions
# AUTHOR:         Sacha Dubois, Fortinet
# CREATED:        2025-03-14
# VERSION:        1.0
#===============================================================================
# CHANGE LOG:
# 2025-03-15 sdubois Initial version
#===============================================================================

# Copy Certificate fikes
[ -d $BUILDDIR/home/fortinet ] && cp -r $FABRIC_HOME/cert $BUILDDIR/home/fortinet

# Generate Documentation link for Chrome Browser
#echo "https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/${demo}/README.md" > $BUILDDIR/url
echo "file:///home/fortinet/html/index.html" > $BUILDDIR/url

# Copy Demo Guide and HTML
cp -r $DEMOPATH/devconfig/${device}/doc $BUILDDIR/home/fortinet
cp -r $DEMOPATH/devconfig/${device}/html $BUILDDIR/home/fortinet

