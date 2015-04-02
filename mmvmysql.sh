#!/bin/bash
#############################################
# AUTHOR: JONATHAN SCHWENN @JONSCHWENN      #
# MAC MINI VAULT - MAC MINI COLOCATION      #
# MACMINIVAULT.COM - @MACMINIVAULT          #
# VERSION 2.00 RELEASE DATE DEC 09 2014     #
# DESC:  THIS SCRIPT INSTALLS MySQL on OSX  #
#############################################
#REQUIREMENTS:
#  OS X 10.7 or newer
#############################################
# CHECK FOR OS X 10.7+
if [[ !  $(sw_vers -productVersion | grep -E '10.[7-9]|1[0-0]')  ]]
then
    echo "ERROR: YOU ARE NOT RUNNING OS X 10.7 OR NEWER"
    exit 1
fi
# CHECK FOR EXISTING MySQL
if [[ -d /usr/local/mysql  ]]
then
        echo "It looks like you already have MySQL installed..."
        echo "This script will most likely fail unless MySQL is completley removed."
        echo "If MySQL does install, your old version and databases will still be"
        echo "under /usr/local/ and you will have to manually move databases to the"
        echo "new install.  It's important to copy/move with permissions intact."
        echo "..."
        echo "..."
        	while true; do
        		read -p "DO YOU WANT TO CONTINUE? [y/N]" yn
        		case $yn in
        		[Yy]* ) break;;
        		[Nn]* ) exit ;;
        		* ) echo "Please answer yes or no.";;
        		esac
        	done
fi
# MYSQL INSTALLER WANTS A 'pidof' COMMAND SOMETIMES
# SO WE'LL GIVE IT A 'pidof' COMMAND
if [[ !  $(command -v pidof) ]]; then
if [ ! -d "$/usr/local/bin" ]; then
sudo mkdir -p /usr/local/bin
fi
# HARD TO CAT DIRECT TO BIN DIR, PUTTING IN DOCUMENTS THEN MOVING
sudo cat << 'EOF' > ~/Documents/pidof
#!/bin/sh
ps axc|awk "{if (\$5==\"$1\") print \$1}"
EOF
sudo mv ~/Documents/pidof /usr/local/bin/pidof
sudo chmod 755 /usr/local/bin/pidof
fi
# LOOKS GOOD, LETS GRAB MySQL AND GET STARTED ...
echo "Downloading MySQL Installers ... may take a few moments"
curl -# -Lo ~/Downloads/MySQL.dmg http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.22-osx10.9-x86_64.dmg
hdiutil attach -quiet ~/Downloads/MySQL.dmg
# PLIST TO ALTER MySQL INSTALLER TO NOT ATTEMPT TO INSTALL STARTUP ITEMS
curl -s -o ~/Downloads/MySQL-install.plist https://raw.githubusercontent.com/srautiai/Mac-Scripts/master/mmvMySQL/install.plist
# DEAR MySQL, WHY HAVE A SPECIFIC 10.9 DOWNLOAD IF IT JUST HAS THE 10.8 INSTALLER?
cd /Volumes/mysql-5.6.22-osx10.8-x86_64/
echo "..."
echo "..."
echo "Installing MySQL, administrator password required ..."
sudo installer -applyChoiceChangesXML ~/Downloads/MySQL-install.plist -pkg mysql-5.6.22-osx10.8-x86_64.pkg -target /
echo "..."
echo "..."
# AS OF RIGHT NOW MYSQL AUTOMATICALLY INSTALLS THE STARTUP ITEMS AND PREFPANE
# STARTUP ITEMS DO NOT WORK IN YOSEMITE - WE MADE A LAUNCHD START SETUP 
# TWO FILES ARE NEEDED
# A PLIST FOR LAUNCHD TO START ON BOOT
# AND A SCRIPT THAT THE PLIST LOADS, SCRIPT WAITS FOR NETWORKING TO INITIALIZE AND STARTS MySQL
curl -s -o ~/Downloads/mmv-start.sh https://raw.githubusercontent.com/srautiai/Mac-Scripts/master/mmvMySQL/mmv-start.sh
sudo mv ~/Downloads/mmv-start.sh /usr/local/mysql/support-files/
sudo chown root:wheel /usr/local/mysql/support-files/mmv-start.sh
sudo chmod +x /usr/local/mysql/support-files/mmv-start.sh
curl -s -o ~/Downloads/com.mysql.server.plist https://raw.githubusercontent.com/srautiai/Mac-Scripts/master/mmvMySQL/com.mysql.server.plist
sudo mv ~/Downloads/com.mysql.server.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.mysql.server.plist
sudo chmod 644 /Library/LaunchDaemons/com.mysql.server.plist


sudo launchctl load -w /Library/LaunchDaemons/com.mysql.server.plist; break  ;;

# ADDING MYSQL PATH TO BASH PROFILE, MAY CONFLICT WITH EXISTING PROFILES/.RC FILES
touch ~/.bash_profile >/dev/null 2>&1
echo -e "\nexport PATH=$PATH:/usr/local/mysql/bin" | sudo tee -a  ~/.bash_profile > /dev/null
sudo mkdir /var/mysql; sudo ln -s /tmp/mysql.sock /var/mysql/mysql.sock
sleep 10
# IF MySQL IS RUNNING, GENERATE, SET, AND DOCUMENT  ROOT PASSWORD
if [[  $(sudo /usr/local/mysql/support-files/mysql.server status | grep "SUCCESS") ]]
then
        mypass="testdroid"
        echo $mypass > ~/Desktop/MYSQL_PASSWORD
        echo "Setting MySQL root Password to $mypass"
        echo "Placing password on desktop..."
        /usr/local/mysql/bin/mysql -uroot -e "GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY '$mypass' WITH GRANT OPTION;"
        echo "..."
        echo "..."
        # UNMOUNT AND DELELTE DOWNLOADED MySQL INSTALLER
        cd ~/
        hdiutil detach -quiet /Volumes/mysql-5.6.22-osx10.8-x86_64/
        sleep 2
        rm ~/Downloads/MySQL.dmg
        rm ~/Downloads/MySQL-install.plist
else
        echo "SORRY, MySQL IS NOT RUNNING ... THERE MUST BE A PROBLEM"
fi


