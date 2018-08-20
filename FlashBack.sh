#!/bin/bash

flasbackDir="/Library/FlashBack"
if [ ! -d $flasbackDir/Backups ]; then
	mkdir $flasbackDir
	mkdir $flasbackDir/Backups
fi

pause(){
	read -p "Press return key to continue..." fackEnterKey
}

one(){		#Backup current preferences
	echo " "
	read -p "Enter Backup Name: " backupName		#Enter the name of the backup
	read -p "Enter Your UserName: " userName		#Enter the name of the backup
	backupLocation="$flasbackDir/Backups/"$backupName	#backup folder with backup's name
	mkdir $backupLocation		#Creates backup folder
	mkdir $backupLocation/Preferences 	#Creates Backup Preference Folder
	mkdir $backupLocation/IconLayout 	#Creates Backup Icon Layout Folder
	mkdir $backupLocation/Wallpaper 	#Creates Backup Wallpaper Folder
	echo "Copying Preferences to "$backupLocation
	excludeApple="!(com.apple*).plist"
	cp -r -f "/var/mobile/Library/Preferences/"$excludeApple $backupLocation/Preferences/		#copy all non-apple Plists to Preference folder within backup haha
	cp -r -f /var/mobile/Library/SpringBoard/IconState.plist $backupLocation/IconLayout/IconState.plist		#copy IconState Plist to IconLayout folder within backup
	cp -r -f /var/mobile/Library/SpringBoard/*Background* $backupLocation/Wallpaper/		#copy Wallpaper & data to Wallpaper folder within backup
	echo "Succeeded!"
	
cat > $backupLocation/control <<EOF

Package: com.$userName.$backupName
Name: $backupName
Depends: com.mpg13.FlashBack
Version:1.0
Description: A FlashBack SetUp by $userName
Maintainer: $userName
Author: $userName
Section: Addons (FlashBack)

EOF
	
	pause
}

two(){		#Restore backup functions
	echo " "
	echo "Available Backups:"
	echo " "
	ls $flasbackDir/Backups/		#List all Backup Folders which match their names
	echo " "
	read -p "Choose a Backup: " selectedBackup		#Let user select which backup
	selectedLocation=$flasbackDir"/Backups/"$selectedBackup		#uses variable to determine backup to use
	autoBackupLocation=$flasbackDir"/Backups/AutoBackup_"$(date '+%d-%m-%Y_%H:%M:%S')	#Sets autobackup location with date and time
	mkdir $autoBackupLocation		#Creates autobackup folder
	mkdir $autoBackupLocation/Preferences		#Creates autobackup Preference Folder
	echo "Moving current Preferences to "$autoBackupLocation
	excludeApple="!(com.apple*).plist"
	cp "/var/mobile/Library/Preferences/"$excludeApple $autoBackupLocation/Preferences/		#Copy copy all non-apple Plists to Preference folder within autobackup haha
	diff /var/mobile/Library/Preferences/ $autoBackupLocation/ -x 'com.apple.*' 	#Checks Difference between backup and planned backup files
	diffFound=$(diff /var/mobile/Library/Preferences/ $autoBackupLocation/Preferences/  -x 'com.apple.*')		#Stores diff command into variable
	isdiff=$(echo -n $diffFound)		#Stores diff output as string length. Ideally, it would be zero
	#if zero then yeah
	
	echo ""
	echo "Copying Backup to Preferences Directory"
	cp $selectedLocation/Preferences/*.plist /var/mobile/Library/Preferences/		#Copy all Plists from backup Preference folder to System Preferences
	echo "Rebuilding UI cache and Killing SpringBoard..."
	uicache		#Rebuilds UI Cache - hopefully this doesn't break anything.
	uicache		#Rebuilds UI Cache again... to fix broken stuff
	killall SpringBoard
	pause
}

three(){
	echo "Available Backups:"
	echo " "
	ls $flasbackDir/Backups/		#Lists all backups
	echo " "
	read -p "Choose a Backup: " deleteBackup		#User selects backup to delete
	deleteLocation=$flasbackDir"/Backups/"$deleteBackup	#location from selected backup
	echo "Deleting "$deleteBackup
	rm -r $deleteLocation		#delete backup folder
	pause
}

four(){
	rm -r $flasbackDir/Backups/AutoBackup*		#Delete all folders that start with AutoBackup
	pause
}

five(){
	echo "Available Backups:"
	echo " "
	ls $flasbackDir/Backups/		#Lists all backups
	echo " "
	read -p "Choose a Backup: " packageBackup		#User selects backup to package, hopefully
	
	echo "creating workspace..."
	mkdir $flasbackDir/working
	workingDir=$flasbackDir/working/$packageBackup
	mkdir $workingDir
	mkdir $workingDir/DEBIAN/
	mkdir $workingDir/Library/
	mkdir $workingDir/Library/FlashBack/
	mkdir $workingDir/Library/FlashBack/Backups/
	echo "Workspace created!"
	cp $packageBackup/control $workingDir/DEBIAN/
	excludeControl="!(control*)"
	cp -r $packageBackup/$excludeControl $workingDir/Library/FlashBack/Backups/
	dpkg-deb -Zgzip -b $workingDir
	rm -r -f $workingDir
	
	pause
}

show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~"	
	echo "	FlashBack "
	echo " This software is in"
	echo " BETA. Use it at your"
	echo "     own risk!" 
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Backup Current Preferences"
	echo "2. Restore Backup"
	echo "3. Delete Backups"
	echo "4. Delete AutoBackups"
	echo "5. Package Backup to DEB"
	echo "6. Quit"
}

read_options(){
	local choice
	read -p "Enter choice [ 1 - 4] " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) three ;;
		4) four ;;		
		5) five;;
		6) exit 0;;
		*) echo "Invalid Selection!" && sleep 2
	esac
}

while true
do
 	shopt -s extglob
	show_menus
	echo " "
	read_options
done
