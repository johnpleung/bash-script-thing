# Config
SCRIPT_BASE=https://url-here/
AUTOUPDATE=true
DRY_RUN=false

########

# STAGE 1: Looking for updates to this script
if [ "$AUTOUPDATE" == "true" ]
then
	printf "\n\nChecking for updates to this script...\n"

	curl -s "$SCRIPT_BASE/refresh-menus.command" -o temp.txt
	LATEST_CHECKSUM=`md5 -q temp.txt`
	LATEST_SCRIPT_CONTENTS=`cat temp.txt`

	if [[ $LATEST_SCRIPT_CONTENTS = *SCRIPT_BASE* ]]
	then
		echo ""
	else
		printf "\nAuto-update process failed; exiting.\n\n"
		rm -rf temp.txt
		exit 1
	fi

	# Compare MD5 hash of current script and latest script on server
	CURRENT_CHECKSUM=`md5 -q "$0"`
	if [ "$CURRENT_CHECKSUM" == "$LATEST_CHECKSUM" ]
	then
		rm -rf temp.txt
		printf "\nAlready up-to-date.\n\n"
	else
		printf "\nCurrent script is outdated; updating...\n"

		rm -rf "$0"
		mv temp.txt "$0"
		chmod u+x "$0"

		printf "\nDone; restarting script...\n"
		sleep 3

		bash "$0"
		exit 1

	fi
fi

########

# STAGE 2: Determine the cache invalidation URLs for the brand site we're targeting

printf "\n****************************\n\nWelcome! Which site would you like to refresh?\n\n"
curl "$SCRIPT_BASE/data-site-select.txt"

printf "\n"

read -p "Enter a number or leave blank to exit: " SITE_INDEX
if [ -z "$SITE_INDEX" ]
then
	printf "\nGoodbye.\n\n"
	exit 1
fi

# Site API cache
SITE_INVALIDATION_URL=`curl -s "$SCRIPT_BASE/sites/$SITE_INDEX/site-cache-invalidation.txt"`
if [[ $SITE_INVALIDATION_URL = */api/* ]]
then
	echo ""
else
	printf "\nInvalid selection; exiting.\n\n"
	exit 1
fi

# CDN
CDN_INVALIDATION_URL=`curl -s "$SCRIPT_BASE/sites/$SITE_INDEX/cdn-invalidation.txt"`
if [[ $CDN_INVALIDATION_URL = *cloudflare* ]]
then
	echo ""
else
	printf "\nInvalid selection; exiting.\n\n"
	exit 1
fi

########

# STAGE 3: Determine the environment(s) to refresh

TEMPCACHEBUSTER=$(date | md5)

printf "\nWhich environment(s) would you like to refresh?\n1) Staging only\n2) Staging and Prod (live site)\n\n"

read -n1 -p "Enter a number or leave blank to exit: " WHICH_ENVS

if [ -z "$WHICH_ENVS" ]
then
	printf "\nGoodbye.\n\n"
	exit 1
fi

case $WHICH_ENVS in
	1) ;;
	2) ;;
	*)
		printf "\nInvalid selection; exiting.\n\n"
		exit 1
	;;
esac

########

# STAGE 4: Clear cache

printf "\nClearing API cache on Staging...done\n"
if [ "$DRY_RUN" == "false" ]
then
	curl -X DELETE "https://url-here"
fi

if [ "$WHICH_ENVS" == "1" ]
then
	printf "\nDone.\n\n"
	exit 1
fi

printf "\nClearing API cache on Prod...done\n"
if [ "$DRY_RUN" == "false" ]
then
	curl -X DELETE "https://url-here"
fi

sleep 1

printf "\nPrewarming API cache on Prod...done\n"
if [ "$DRY_RUN" == "false" ]
then
	curl -s "https://url-here" > /dev/null
fi

# Clear site cache
printf "\nClearing site's cache via $SITE_INVALIDATION_URL$TEMPCACHEBUSTER...\n"
if [ "$DRY_RUN" == "false" ]
then
	curl -s "$SITE_INVALIDATION_URL$TEMPCACHEBUSTER" > /dev/null
fi

# Clear CDN cache
printf "\nClearing CDN cache via $CDN_INVALIDATION_URL...\n"
if [ "$DRY_RUN" == "false" ]
then
	curl -s -X DELETE "$CDN_INVALIDATION_URL" > /dev/null
fi

printf "\nDone. Your changes should appear within a few minutes.\n\n"