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
	commits=$(git log --pretty=format:'%h - %s' -10 | tr '\n' ' ')
	commit=$(zenity --list --title="Revert to Commit" --text="Choose a commit to revert to" --column "Commit" $commits)
	if [ -n "$commit" ]; then
		git revert --no-commit $commit..HEAD
		git commit
	fi
}

# Function to show the log
show_log() {
	git log --oneline | zenity --text-info --title="Git Log"
}

# Main loop to display the main menu
while true; do
	action=$(zenity --question --title="Git Helper" --text="Choose an action" --extra-button="Push" --extra-button="Commit" --extra-button="Revert" --extra-button="Log" --extra-button="Exit")
	case $action in
	"Push") push_to_remote ;;
	"Commit") commit_changes ;;
	"Revert") revert_to_commit ;;
	"Log") show_log ;;
	"Exit") break ;;
	*) zenity --error --text="Invalid option" ;;
	esac
done
