#!/bin/bash

# This should always return the name of the docker container running plex - assuming a single plex docker on the system.
con="$(docker ps --format "{{.Names}}" | grep -i plex)"

echo ""
echo "<b>Applying hardware decode patch...</b>"
echo "<hr>"

# Check to see if Plex Transcoder2 Exists first.
exists=$(docker exec -i "$con" stat "/usr/lib/plexmediaserver/Plex Transcoder2" >/dev/null 2>&1; echo $?)

if [ "$exists" -eq 1 ]; then 
	# If it doesn't, we run the clause below
	
	# Move the Plex Transcoder to a different location so we can replace it with our wrapper
	docker exec -i "$con" mv "/usr/lib/plexmediaserver/Plex Transcoder" "/usr/lib/plexmediaserver/Plex Transcoder2"
	
	# For Legibility and future updates - if needed, use a heredoc to create the wrapper:
	docker exec -i "$con" /bin/sh -c 'xargs -0 printf > "/usr/lib/plexmediaserver/Plex Transcoder";' <<-'EOF'
		#!/bin/bash
		marap=$(cut -c 10-14 <<<"$@")
		if [ "$marap" == "mpeg4" ]; then
			exec /usr/lib/plexmediaserver/Plex\ Transcoder2 "$@"
		else
			exec /usr/lib/plexmediaserver/Plex\ Transcoder2 -hwaccel nvdec "$@"
		fi
		EOF
	
	# chmod the new wrapper to be executable:
	docker exec -i "$con" chmod +x "/usr/lib/plexmediaserver/Plex Transcoder" 
	
	# Restart the container to be safe - this step may be optional, need to do more testing.
	echo "Restarting Plex docker..."
	docker restart "$con" >/dev/null
	echo '<font color="green"><b>Done!</b></font>' # Green means go!
	
else
	# If we ended up here, the patch didn't even try to run, presumably because the patch was already applied.
	echo ""
	echo '<font color="red"><b>Patch already applied!</b></font>' # Red means stop!
fi