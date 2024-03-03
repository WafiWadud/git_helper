#!/bin/bash

# Function to push to a remote repository
push_to_remote() {
	remotes=$(git remote -v | awk '{print $1}' | uniq | tr '\n' ' ')
	remote=$(zenity --list --title="Push to Remote" --text="Choose a remote" --column "Remote" $remotes)
	branch=$(git rev-parse --abbrev-ref HEAD)
	if [ -n "$remote" ]; then
		git push $remote $branch
	fi
}

# Function to commit changes
commit_changes() {
	message=$(zenity --entry --title="Commit Message" --text="Enter your commit message")
	git add .
	git commit -m "$message"
}

# Function to revert to a specific commit
revert_to_commit() {
	commits=$(git log --pretty=format:'%h' -10 | tr '\n' ' ')
	commit=$(zenity --list --title="Revert to Commit" --text="Choose a commit to revert to" --column "Commit" $commits)
	if [ -n "$commit" ]; then
		git revert --no-commit $commit..HEAD
		git commit
	fi
}

# Function to pull from a remote repository
pull_from_remote() {
	remotes=$(git remote -v | awk '{print $1}' | uniq | tr '\n' ' ')
	remote=$(zenity --list --title="Pull from Remote" --text="Choose a remote" --column "Remote" $remotes)
	if [ -n "$remote" ]; then
		git pull $remote
	fi
}

# Function to add a remote repository using a form
add_remote_repository() {
	RETURNVALUE=$(zenity --forms --title "Add Remote Repository" \
		--text "Enter the remote name and URL" \
		--add-entry="Remote Name" \
		--add-entry="Remote URL")

	# Extract the remote name and URL values
	remote_name=$(awk -F'|' '{print $1}' <<<$RETURNVALUE)
	remote_url=$(awk -F'|' '{print $2}' <<<$RETURNVALUE)

	# Check if both values are provided
	if [ -n "$remote_name" ] && [ -n "$remote_url" ]; then
		git remote add $remote_name $remote_url
		zenity --info --text="Remote repository $remote_name added successfully."
	else
		zenity --error --text="Please provide both a remote name and a URL."
	fi
}

# Function to merge a branch
merge_branch() {
	branches=$(git branch --format "%(refname:short)" | tr '\n' ' ')
	branch=$(zenity --list --title="Merge Branch" --text="Choose a branch to merge" --column "Branch" $branches)
	if [ -n "$branch" ]; then
		git merge $branch
	fi
}

# Function to stash changes
stash_changes() {
	while true; do
		action=$(zenity --question --title="Git Stash" --switch --text="Choose an action" --extra-button="Stash" --extra-button="Apply Stash" --extra-button="Exit")
		case $action in
		"Stash")
			git stash save "$(zenity --entry --title="Stash Message" --text="Enter your stash message")"
			zenity --info --text="Changes stashed successfully."
			;;
		"Apply Stash")
			stashes=$(git stash list | awk '{print $1}' | tr '\n' ' ')
			stash=$(zenity --list --title="Apply Stash" --text="Choose a stash to apply" --column "Stash" $stashes)
			if [ -n "$stash" ]; then
				git stash apply $stash
				zenity --info --text="Stash $stash applied successfully."
			fi
			;;
		"Exit") break ;;
		*) zenity --error --text="Invalid option" ;;
		esac
	done
}

# Function to show the log
show_log() {
	git log --oneline | zenity --text-info --title="Git Log"
}

# Main loop to display the main menu
while true; do
	action=$(zenity --question --title="Git Helper" --switch --text="Choose an action" --extra-button="Push" --extra-button="Pull" --extra-button="Commit" --extra-button="Revert" --extra-button="Remote" --extra-button="Merge" --extra-button="Stash" --extra-button="Log" --extra-button="Exit")
	case $action in
	"Push") push_to_remote ;;
	"Pull") pull_from_remote ;;
	"Commit") commit_changes ;;
	"Revert") revert_to_commit ;;
	"Remote") add_remote_repository ;;
	"Merge") merge_branch ;;
	"Stash") stash_changes ;;
	"Log") show_log ;;
	"Exit") break ;;
	*) zenity --error --text="Invalid option" ;;
	esac
done
