#!/bin/bash

# Function to push to a remote repository
push_to_remote() {
	remotes=$(git remote -v | awk '{print $1}' | uniq | tr '\n' ' ')
	remote=$(zenity --list --title="Push to Remote" --text="Choose a remote" --column "Remote" "$remotes")
	branch=$(git rev-parse --abbrev-ref HEAD)
	if [ -n "$remote" ]; then
		if git push "$remote" "$branch"; then
			zenity --info --text="Push to $remote successful."
		else
			zenity --error --text="Push to $remote failed."
		fi
	fi
}

# Function to commit changes
commit_changes() {
	message=$(zenity --entry --title="Commit Message" --text="Enter your commit message")
	git add .
	if git commit -m "$message"; then
		zenity --info --text="Commit successful."
	else
		zenity --error --text="Commit failed."
	fi
}

# Function to revert to a specific commit
revert_to_commit() {
	commits=$(git log --pretty=format:'%h' -10 | tr '\n' ' ')
	commit=$(zenity --list --title="Revert to Commit" --text="Choose a commit to revert to" --column "Commit" "$commits")
	if [ -n "$commit" ]; then
		if git revert --no-commit "$commit"..HEAD && git commit; then
			zenity --info --text="Revert to $commit successful."
		else
			zenity --error --text="Revert to $commit failed."
		fi
	fi
}

# Function to pull from a remote repository
pull_from_remote() {
	remotes=$(git remote -v | awk '{print $1}' | uniq | tr '\n' ' ')
	remote=$(zenity --list --title="Pull from Remote" --text="Choose a remote" --column "Remote" "$remotes")
	if [ -n "$remote" ]; then
		if git pull "$remote"; then
			zenity --info --text="Pull from $remote successful."
		else
			zenity --error --text="Pull from $remote failed."
		fi
	fi
}

# Function to add a remote repository using a form
add_remote_repository() {
	RETURNVALUE=$(zenity --forms --title "Add Remote Repository" \
		--text "Enter the remote name and URL" \
		--add-entry="Remote Name" \
		--add-entry="Remote URL")

	remote_name=$(awk -F'|' '{print $1}' <<<"$RETURNVALUE")
	remote_url=$(awk -F'|' '{print $2}' <<<"$RETURNVALUE")

	if [ -n "$remote_name" ] && [ -n "$remote_url" ]; then
		if git remote add "$remote_name" "$remote_url"; then
			zenity --info --text="Remote repository $remote_name added successfully."
		else
			zenity --error --text="Failed to add remote repository $remote_name."
		fi
	else
		zenity --error --text="Please provide both a remote name and a URL."
	fi
}

# Function to merge a branch
merge_branch() {
	branches=$(git branch --format "%(refname:short)" | tr '\n' ' ')
	branch=$(zenity --list --title="Merge Branch" --text="Choose a branch to merge" --column "Branch" "$branches")
	if [ -n "$branch" ]; then
		if git merge "$branch"; then
			zenity --info --text="Merge from $branch successful."
		else
			zenity --error --text="Merge from $branch failed."
		fi
	fi
}

# Function to stash changes
stash_changes() {
	while true; do
		action=$(zenity --question --title="Git Stash" --switch --text="Choose an action" --extra-button="Stash" --extra-button="Apply Stash" --extra-button="Exit")
		case $action in
		"Stash")
			message=$(zenity --entry --title="Stash Message" --text="Enter your stash message")
			if git stash save "$message"; then
				zenity --info --text="Changes stashed successfully."
			else
				zenity --error --text="Failed to stash changes."
			fi
			;;
		"Apply Stash")
			stashes=$(git stash list | awk '{print $1}' | tr '\n' ' ')
			stash=$(zenity --list --title="Apply Stash" --text="Choose a stash to apply" --column "Stash" "$stashes")
			if [ -n "$stash" ]; then
				if git stash apply "$stash"; then
					zenity --info --text="Stash $stash applied successfully."
				else
					zenity --error --text="Failed to apply stash $stash."
				fi
			fi
			;;
		"Exit") break ;;
		*) zenity --error --text="Invalid option" ;;
		esac
	done
}

# Function to restore changes to the last commit
restore_to_last_commit() {
	if git restore .; then
		zenity --info --text="Working directory restored to the last commit."
	else
		zenity --error --text="Failed to restore to the last commit."
	fi
}

# Function to rebase a branch
rebase_branch() {
	branches=$(git branch --format "%(refname:short)" | tr '\n' ' ')
	branch=$(zenity --list --title="Rebase Branch" --text="Choose a branch to rebase onto" --column "Branch" "$branches")
	if [ -n "$branch" ]; then
		if git rebase "$branch"; then
			zenity --info --text="Rebase successful."
		else
			zenity --error --text="Rebase failed."
		fi
	fi
}

# Function to show the log
show_log() {
	if git log --oneline | zenity --text-info --title="Git Log"; then
		zenity --info --text="Git log displayed successfully."
	else
		zenity --error --text="Failed to display Git log."
	fi
}

# Main loop to display the main menu
while true; do
	action=$(zenity --question \
		--title="Git Helper" \
		--switch \
		--text="Choose an action" \
		--extra-button="Push" \
		--extra-button="Pull" \
		--extra-button="Commit" \
		--extra-button="Revert" \
		--extra-button="Restore" \
		--extra-button="Remote" \
		--extra-button="Merge" \
		--extra-button="Stash" \
		--extra-button="Log" \
		--extra-button="Exit")
	case $action in
	"Push") push_to_remote ;;
	"Pull") pull_from_remote ;;
	"Commit") commit_changes ;;
	"Revert") revert_to_commit ;;
	"Restore") restore_to_last_commit ;;
	"Remote") add_remote_repository ;;
	"Merge") merge_branch ;;
	"Stash") stash_changes ;;
	"Log") show_log ;;
	"Exit") break ;;
	*) zenity --error --text="Invalid option" ;;
	esac
done
