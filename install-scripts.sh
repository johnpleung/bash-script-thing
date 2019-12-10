DESTINATION_DIR=~/Desktop/Folder
SCRIPT_FILE_NAME=refresh-menus.command

# Delete this temp script
rm -- "$0"

# Create folder on Desktop
mkdir "$DESTINATION_DIR"
cd "$DESTINATION_DIR"

# Download script
curl -s https://url-here/$SCRIPT_FILE_NAME > $SCRIPT_FILE_NAME

#Make script executable
chmod u+x $SCRIPT_FILE_NAME

echo "Done"

open "$DESTINATION_DIR"