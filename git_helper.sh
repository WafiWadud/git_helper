#!/bin/bash

set -euo pipefail

# Get current git status
get_current_branch() {
	git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

get_git_status() {
	git status --short 2>/dev/null | wc -l
}

# Helper functions for UI interactions
show_info() {
	zenity --info --no-wrap --title="Success" --text="$1" 2>/dev/null || true
}

show_error() {
	zenity --error --no-wrap --title="Error" --text="$1" 2>/dev/null || true
}

show_warning() {
	zenity --warning --no-wrap --title="Warning" --text="$1" 2>/dev/null || true
}

confirm() {
	zenity --question --no-wrap --title="Confirm" --text="$1" 2>/dev/null
}

# Button-based menu system
show_button_menu() {
	local title="$1"
	local text="${2:-Choose an action:}"
	shift 2
	
	# Check if rofi is available for better button interface
	if command -v rofi &> /dev/null; then
		local choice
		choice=$(printf "%s\n" "$@" | rofi -dmenu -p "$title" -i 2>/dev/null)
		echo "$choice"
	else
		# Fallback to zenity with improved layout
		local args=("--list" "--title=$title" "--text=$text" "--column=Action")
		args+=("$@")
		args+=("--height=400" "--width=500")
		zenity "${args[@]}" 2>/dev/null
	fi
}

get_remotes() {
	git remote -v | awk '{print $1}' | uniq
}

get_remotes_with_urls() {
	git remote -v | awk '{print $1 " (" $2 ")"}' | sort -u
}

get_branches() {
	git branch --format "%(refname:short)"
}

get_branches_with_info() {
	local current
	current=$(get_current_branch)
	git branch --format "%(if)%(HEAD)%(then)* %(else)  %(end)%(refname:short)" | while read -r line; do
		if [[ $line == "* "* ]]; then
			echo "$(echo "$line" | sed 's/\* /[CURRENT] /')"
		else
			echo "$line"
		fi
	done
}

get_commits() {
	git log --pretty=format:'%h' -10
}

get_commits_with_info() {
	git log --oneline -10
}

get_staged_files() {
	git diff --cached --name-only
}

get_unstaged_files() {
	git diff --name-only
}

get_all_files() {
	git status --short | awk '{print $2}'
}

# ============================================================================
# BRANCH MANAGEMENT
# ============================================================================

create_branch() {
	local branch_name
	branch_name=$(zenity --entry --title="Create Branch" \
		--text="Enter new branch name:" --width=400)
	[[ -z "$branch_name" ]] && return
	
	branch_name=$(echo "$branch_name" | xargs)
	
	if [[ ! "$branch_name" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
		show_error "Invalid branch name. Use alphanumeric, dots, slashes, or hyphens."
		return
	fi
	
	if git branch "$branch_name"; then
		show_info "Branch '$branch_name' created successfully."
	else
		show_error "Failed to create branch '$branch_name'."
	fi
}

switch_branch() {
	local current_branch
	current_branch=$(get_current_branch)
	
	local branches
	branches=$(get_branches_with_info)
	
	if [[ -z "$branches" ]]; then
		show_error "No branches available."
		return
	fi
	
	local branch
	branch=$(echo "$branches" | zenity --list --title="Switch Branch" \
		--text="Current branch: $current_branch\n\nChoose a branch to switch to:" \
		--column "Branch" --height=300)
	[[ -z "$branch" ]] && return
	
	branch=$(echo "$branch" | sed 's/^\[CURRENT\] //' | xargs)
	
	if [[ "$branch" == "$current_branch" ]]; then
		show_warning "Already on branch '$branch'."
		return
	fi
	
	if git checkout "$branch"; then
		show_info "Switched to branch '$branch'."
	else
		show_error "Failed to switch to branch '$branch'."
	fi
}

delete_branch() {
	local delete_type
	delete_type=$(zenity --list --title="Delete Branch" \
		--text="Choose branch type to delete:" \
		--column "Type" \
		"Local Branch" "Remote Branch" \
		--height=150)
	[[ -z "$delete_type" ]] && return
	
	if [[ "$delete_type" == "Local Branch" ]]; then
		delete_local_branch
	else
		delete_remote_branch
	fi
}

delete_local_branch() {
	local current_branch
	current_branch=$(get_current_branch)
	
	local branches
	branches=$(get_branches | grep -v "^$(echo $current_branch | sed 's/[[\.*^$/]/\\&/g')$" || true)
	
	if [[ -z "$branches" ]]; then
		show_error "No branches available to delete."
		return
	fi
	
	local branch
	branch=$(echo "$branches" | zenity --list --title="Delete Local Branch" \
		--text="Select a branch to delete:\n\n(Cannot delete current branch)" \
		--column "Branch" --height=300)
	[[ -z "$branch" ]] && return
	
	branch=$(echo "$branch" | xargs)
	
	confirm "Delete local branch '$branch'?" || return
	
	if git branch -d "$branch"; then
		show_info "Branch '$branch' deleted successfully."
	else
		local force
		force=$(zenity --question --title="Force Delete" \
			--text="Failed to delete '$branch' safely.\n\nForce delete? (This may lose commits)" 2>/dev/null && echo "yes" || echo "no")
		
		if [[ "$force" == "yes" ]] && git branch -D "$branch"; then
			show_warning "Branch '$branch' force-deleted."
		else
			show_error "Failed to delete branch '$branch'."
		fi
	fi
}

delete_remote_branch() {
	local remotes
	remotes=$(get_remotes)
	
	if [[ -z "$remotes" ]]; then
		show_error "No remotes configured."
		return
	fi
	
	local remote
	remote=$(echo "$remotes" | zenity --list --title="Select Remote" \
		--text="Choose a remote:" \
		--column "Remote" --height=200)
	[[ -z "$remote" ]] && return
	
	local branches
	branches=$(git branch -r | grep "$remote/" | sed "s|$remote/||" || true)
	
	if [[ -z "$branches" ]]; then
		show_error "No remote branches for '$remote'."
		return
	fi
	
	local branch
	branch=$(echo "$branches" | zenity --list --title="Delete Remote Branch" \
		--text="Select a branch to delete from '$remote':" \
		--column "Branch" --height=300)
	[[ -z "$branch" ]] && return
	
	branch=$(echo "$branch" | xargs)
	
	confirm "Delete remote branch '$remote/$branch'?" || return
	
	if git push "$remote" --delete "$branch"; then
		show_info "Remote branch '$remote/$branch' deleted."
	else
		show_error "Failed to delete remote branch."
	fi
}

rename_branch() {
	local current_branch
	current_branch=$(get_current_branch)
	
	local new_name
	new_name=$(zenity --entry --title="Rename Branch" \
		--text="Rename '$current_branch' to:" --width=400)
	[[ -z "$new_name" ]] && return
	
	new_name=$(echo "$new_name" | xargs)
	
	if [[ ! "$new_name" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
		show_error "Invalid branch name."
		return
	fi
	
	if git branch -m "$new_name"; then
		show_info "Branch renamed to '$new_name'."
	else
		show_error "Failed to rename branch."
	fi
}



# ============================================================================
# COMMIT OPERATIONS
# ============================================================================

amend_commit() {
	local last_message
	last_message=$(git log -1 --pretty=%B)
	
	local changes
	changes=$(get_git_status)
	
	if [[ $changes -eq 0 ]]; then
		show_warning "No changes to amend. Stage changes first."
		return
	fi
	
	local new_message
	new_message=$(zenity --text-info --title="Amend Last Commit" \
		--text="Current message:\n\n$last_message\n\nEdit to change or keep as-is:" \
		--width=600 --height=300 --editable)
	[[ -z "$new_message" ]] && return
	
	if git commit --amend -m "$new_message"; then
		show_info "Last commit amended successfully."
	else
		show_error "Failed to amend commit."
	fi
}

cherry_pick_commit() {
	local commits
	commits=$(git log --oneline -20)
	
	if [[ -z "$commits" ]]; then
		show_error "No commits available."
		return
	fi
	
	local commit
	commit=$(echo "$commits" | zenity --list --title="Cherry-Pick Commit" \
		--text="Select a commit to cherry-pick:\n\n(Latest 20 commits)" \
		--column "Commit" --height=300)
	[[ -z "$commit" ]] && return
	
	commit=$(echo "$commit" | cut -d' ' -f1)
	
	confirm "Cherry-pick commit $commit?" || return
	
	if git cherry-pick "$commit"; then
		show_info "Commit $commit cherry-picked successfully."
	else
		show_error "Cherry-pick failed. Resolve conflicts or run 'git cherry-pick --abort'."
	fi
}

reset_commit() {
	local commits
	commits=$(git log --oneline -10)
	
	if [[ -z "$commits" ]]; then
		show_error "No commits available."
		return
	fi
	
	local commit
	commit=$(echo "$commits" | zenity --list --title="Reset to Commit" \
		--text="Select a commit to reset to:" \
		--column "Commit" --height=300)
	[[ -z "$commit" ]] && return
	
	commit=$(echo "$commit" | cut -d' ' -f1)
	
	local reset_type
	reset_type=$(zenity --list --title="Reset Type" \
		--text="Choose reset type:" \
		--column "Type" \
		"Soft (keep changes staged)" \
		"Mixed (keep changes unstaged)" \
		"Hard (discard changes)" \
		--height=200)
	[[ -z "$reset_type" ]] && return
	
	local git_flag
	case "$reset_type" in
	"Soft"*) git_flag="--soft" ;;
	"Mixed"*) git_flag="--mixed" ;;
	"Hard"*) git_flag="--hard" ;;
	esac
	
	if [[ "$git_flag" == "--hard" ]]; then
		confirm "HARD reset will discard all changes. Continue?" || return
	fi
	
	if git reset "$git_flag" "$commit"; then
		show_info "Reset to $commit ($reset_type)."
	else
		show_error "Failed to reset."
	fi
}

view_commit_details() {
	local commits
	commits=$(git log --oneline -20)
	
	if [[ -z "$commits" ]]; then
		show_error "No commits available."
		return
	fi
	
	local commit
	commit=$(echo "$commits" | zenity --list --title="View Commit Details" \
		--text="Select a commit:" \
		--column "Commit" --height=300)
	[[ -z "$commit" ]] && return
	
	commit=$(echo "$commit" | cut -d' ' -f1)
	
	local details
	details=$(git show "$commit")
	
	echo "$details" | zenity --text-info --title="Commit: $commit" \
		--width=900 --height=600 || true
}

commit_operations() {
	while true; do
		local action
		action=$(show_button_menu "Commit Operations" \
			"Modify and manage commits" \
			"✒️  Amend Last Commit" \
			"🍒 Cherry-Pick Commit" \
			"↩️  Reset to Commit" \
			"👁️  View Commit Details" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"✒️  Amend Last Commit") amend_commit & ;;
		"🍒 Cherry-Pick Commit") cherry_pick_commit & ;;
		"↩️  Reset to Commit") reset_commit & ;;
		"👁️  View Commit Details") view_commit_details & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

# ============================================================================
# FILE OPERATIONS (Staging, Diff, History)
# ============================================================================

view_diff() {
	local diff_type
	diff_type=$(zenity --list --title="View Diff" \
		--text="Choose diff type:" \
		--column "Type" \
		"Staged Changes" "Unstaged Changes" "All Changes" \
		--height=200)
	[[ -z "$diff_type" ]] && return
	
	local diff_output
	case "$diff_type" in
	"Staged Changes")
		diff_output=$(git diff --cached)
		;;
	"Unstaged Changes")
		diff_output=$(git diff)
		;;
	"All Changes")
		diff_output=$(git diff HEAD)
		;;
	esac
	
	if [[ -z "$diff_output" ]]; then
		show_info "No changes to display."
		return
	fi
	
	echo "$diff_output" | zenity --text-info --title="Diff" \
		--width=800 --height=500 || true
}

stage_files() {
	local unstaged
	unstaged=$(get_unstaged_files)
	
	if [[ -z "$unstaged" ]]; then
		show_info "No unstaged files."
		return
	fi
	
	local file
	file=$(echo "$unstaged" | zenity --list --title="Stage File" \
		--text="Select file to stage:" \
		--column "File" --height=300)
	[[ -z "$file" ]] && return
	
	if git add "$file"; then
		show_info "Staged: $file"
	else
		show_error "Failed to stage file."
	fi
}

unstage_files() {
	local staged
	staged=$(get_staged_files)
	
	if [[ -z "$staged" ]]; then
		show_info "No staged files."
		return
	fi
	
	local file
	file=$(echo "$staged" | zenity --list --title="Unstage File" \
		--text="Select file to unstage:" \
		--column "File" --height=300)
	[[ -z "$file" ]] && return
	
	if git reset HEAD "$file"; then
		show_info "Unstaged: $file"
	else
		show_error "Failed to unstage file."
	fi
}

view_file_history() {
	local files
	files=$(git ls-files)
	
	if [[ -z "$files" ]]; then
		show_error "No files in repository."
		return
	fi
	
	local file
	file=$(echo "$files" | zenity --list --title="View File History" \
		--text="Select a file:" \
		--column "File" --height=400)
	[[ -z "$file" ]] && return
	
	local history
	history=$(git log --oneline -- "$file")
	
	if [[ -z "$history" ]]; then
		show_info "No history for this file."
		return
	fi
	
	echo "$history" | zenity --text-info --title="History: $file" \
		--width=700 --height=400 || true
}

show_file_blame() {
	local files
	files=$(git ls-files)
	
	if [[ -z "$files" ]]; then
		show_error "No files in repository."
		return
	fi
	
	local file
	file=$(echo "$files" | zenity --list --title="File Blame" \
		--text="Select a file:" \
		--column "File" --height=400)
	[[ -z "$file" ]] && return
	
	local blame
	blame=$(git blame "$file" 2>/dev/null || echo "Failed to get blame info")
	
	echo "$blame" | zenity --text-info --title="Blame: $file" \
		--width=900 --height=500 || true
}

view_detailed_status() {
	local status
	status=$(git status)
	
	echo "$status" | zenity --text-info --title="Git Status" \
		--width=700 --height=400 || true
}

file_operations() {
	while true; do
		local staged
		local unstaged
		staged=$(get_staged_files | wc -l)
		unstaged=$(get_unstaged_files | wc -l)
		
		local action
		action=$(show_button_menu "File Management" \
			"Staged: $staged | Unstaged: $unstaged" \
			"📊 View Detailed Status" \
			"🔍 View Diff" \
			"➕ Stage File" \
			"➖ Unstage File" \
			"📜 View File History" \
			"👣 Show File Blame" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"📊 View Detailed Status") view_detailed_status & ;;
		"🔍 View Diff") view_diff & ;;
		"➕ Stage File") stage_files & ;;
		"➖ Unstage File") unstage_files & ;;
		"📜 View File History") view_file_history & ;;
		"👣 Show File Blame") show_file_blame & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

# ============================================================================
# TAGGING
# ============================================================================

create_tag() {
	local tag_name
	tag_name=$(zenity --entry --title="Create Tag" \
		--text="Enter tag name (e.g., v1.0.0):" --width=400)
	[[ -z "$tag_name" ]] && return
	
	tag_name=$(echo "$tag_name" | xargs)
	
	local tag_message
	tag_message=$(zenity --entry --title="Tag Message" \
		--text="Enter tag message (optional):" --width=400)
	
	if [[ -z "$tag_message" ]]; then
		if git tag "$tag_name"; then
			show_info "Tag '$tag_name' created."
		else
			show_error "Failed to create tag."
		fi
	else
		if git tag -a "$tag_name" -m "$tag_message"; then
			show_info "Tag '$tag_name' created with message."
		else
			show_error "Failed to create tag."
		fi
	fi
}

list_tags() {
	local tags
	tags=$(git tag -l)
	
	if [[ -z "$tags" ]]; then
		show_info "No tags in repository."
		return
	fi
	
	echo "$tags" | zenity --text-info --title="Tags" \
		--width=400 --height=400 || true
}

push_tags() {
	local remotes
	remotes=$(get_remotes)
	
	if [[ -z "$remotes" ]]; then
		show_error "No remotes configured."
		return
	fi
	
	local remote
	remote=$(echo "$remotes" | zenity --list --title="Push Tags" \
		--text="Choose a remote:" \
		--column "Remote" --height=200)
	[[ -z "$remote" ]] && return
	
	local push_type
	push_type=$(zenity --list --title="Push Type" \
		--text="Choose what to push:" \
		--column "Type" \
		"All Tags" "Specific Tag" \
		--height=150)
	[[ -z "$push_type" ]] && return
	
	confirm "Push tags to '$remote'?" || return
	
	if [[ "$push_type" == "All Tags" ]]; then
		if git push "$remote" --tags; then
			show_info "All tags pushed to '$remote'."
		else
			show_error "Failed to push tags."
		fi
	else
		local tags
		tags=$(git tag -l)
		
		if [[ -z "$tags" ]]; then
			show_error "No tags available."
			return
		fi
		
		local tag
		tag=$(echo "$tags" | zenity --list --title="Select Tag" \
			--text="Choose a tag to push:" \
			--column "Tag" --height=300)
		[[ -z "$tag" ]] && return
		
		if git push "$remote" "$tag"; then
			show_info "Tag '$tag' pushed to '$remote'."
		else
			show_error "Failed to push tag '$tag'."
		fi
	fi
}

tag_management() {
	while true; do
		local tag_count
		tag_count=$(git tag -l | wc -l)
		
		local action
		action=$(show_button_menu "Tags" \
			"Total tags: $tag_count" \
			"🏷️  Create Tag" \
			"📝 List Tags" \
			"📤 Push Tags to Remote" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"🏷️  Create Tag") create_tag & ;;
		"📝 List Tags") list_tags & ;;
		"📤 Push Tags to Remote") push_tags & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

# ============================================================================
# CLEANUP & UNDO
# ============================================================================

clean_untracked() {
	local untracked
	untracked=$(git clean -nd)
	
	if [[ -z "$untracked" ]]; then
		show_info "No untracked files to clean."
		return
	fi
	
	echo "$untracked" | zenity --text-info --title="Files to Clean" \
		--width=600 --height=300 || true
	
	confirm "Delete these untracked files?" || return
	
	if git clean -fd; then
		show_info "Untracked files cleaned."
	else
		show_error "Failed to clean untracked files."
	fi
}

discard_local_changes() {
	local changes
	changes=$(get_git_status)
	
	if [[ $changes -eq 0 ]]; then
		show_info "No changes to discard."
		return
	fi
	
	local discard_type
	discard_type=$(zenity --list --title="Discard Changes" \
		--text="Choose what to discard:" \
		--column "Type" \
		"Discard Unstaged Changes" "Discard All Changes (Staged + Unstaged)" \
		--height=200)
	[[ -z "$discard_type" ]] && return
	
	confirm "This cannot be undone. Discard?" || return
	
	case "$discard_type" in
	"Discard Unstaged Changes")
		if git checkout -- .; then
			show_info "Unstaged changes discarded."
		else
			show_error "Failed to discard changes."
		fi
		;;
	"Discard All Changes"*)
		if git reset --hard HEAD; then
			show_info "All changes discarded."
		else
			show_error "Failed to discard changes."
		fi
		;;
	esac
}

undo_last_commit() {
	local last_commit
	last_commit=$(git log -1 --oneline)
	
	confirm "Undo: $last_commit\n\nChanges will be preserved." || return
	
	if git reset --soft HEAD~1; then
		show_info "Last commit undone. Changes staged."
	else
		show_error "Failed to undo last commit."
	fi
}

reflog_viewer() {
	local reflog
	reflog=$(git reflog -10)
	
	if [[ -z "$reflog" ]]; then
		show_info "No reflog available."
		return
	fi
	
	echo "$reflog" | zenity --text-info --title="Reflog (Last 10)" \
		--width=700 --height=400 || true
}

cleanup_and_undo() {
	while true; do
		local action
		action=$(show_button_menu "Cleanup & Recovery" \
			"Undo changes and clean up repository" \
			"🧹 Clean Untracked Files" \
			"🔄 Discard Local Changes" \
			"🗑️  Delete Remote Branch" \
			"↶ Undo Last Commit" \
			"📋 View Reflog" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"🧹 Clean Untracked Files") clean_untracked & ;;
		"🔄 Discard Local Changes") discard_local_changes & ;;
		"🗑️  Delete Remote Branch") delete_remote_branch & ;;
		"↶ Undo Last Commit") undo_last_commit & ;;
		"📋 View Reflog") reflog_viewer & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

# ============================================================================
# ORIGINAL FUNCTIONS (Refactored)
# ============================================================================

remote_operation() {
	local operation=$1
	local current_branch
	current_branch=$(get_current_branch)
	
	local remotes
	remotes=$(get_remotes_with_urls)
	
	if [[ -z "$remotes" ]]; then
		show_error "No remotes configured. Add a remote first."
		return
	fi
	
	local remote
	remote=$(echo "$remotes" | zenity --list --title="$operation Remote" \
		--text="Current branch: $current_branch\n\nSelect a remote:" \
		--column "Remote" --height=300)
	
	[[ -z "$remote" ]] && return
	
	remote=$(echo "$remote" | cut -d' ' -f1)
	
	if [[ "$operation" == "Push" ]]; then
		confirm "Push branch '$current_branch' to remote '$remote'?" || return
		if git push "$remote" "$current_branch"; then
			show_info "Pushed '$current_branch' to '$remote' successfully."
		else
			show_error "Failed to push to '$remote'."
		fi
	else
		confirm "Pull from remote '$remote' into '$current_branch'?" || return
		if git pull "$remote"; then
			show_info "Pulled from '$remote' successfully."
		else
			show_error "Failed to pull from '$remote'."
		fi
	fi
}

commit_changes() {
	local changes
	changes=$(get_git_status)
	
	if [[ $changes -eq 0 ]]; then
		show_info "No changes to commit."
		return
	fi
	
	local message
	message=$(zenity --text-info --title="Commit Changes" \
		--text="You have $changes changed file(s).\n\nEnter your commit message:" \
		--width=500 --height=250 --editable)
	[[ -z "$message" ]] && return
	
	git add .
	if git commit -m "$message"; then
		show_info "Committed $changes file(s) successfully."
	else
		show_error "Failed to commit changes."
	fi
}

revert_to_commit() {
	local commits
	commits=$(get_commits_with_info)
	
	if [[ -z "$commits" ]]; then
		show_error "No commits available."
		return
	fi
	
	local commit
	commit=$(echo "$commits" | zenity --list --title="Revert to Commit" \
		--text="WARNING: This will revert all commits after the selected one.\n\nChoose a commit:" \
		--column "Commit" --height=300)
	[[ -z "$commit" ]] && return
	
	commit=$(echo "$commit" | cut -d' ' -f1)
	
	confirm "Revert all commits after $commit?" || return
	
	if git revert --no-commit "$commit"..HEAD && git commit -m "Revert to $commit"; then
		show_info "Successfully reverted to $commit."
	else
		git revert --abort 2>/dev/null || true
		show_error "Failed to revert. Changes may have been reverted automatically."
	fi
}

add_remote_repository() {
	local form_result
	form_result=$(zenity --forms --title "Add Remote Repository" \
		--text "Enter the remote name and URL" \
		--add-entry="Remote Name (e.g., origin)" \
		--add-entry="Remote URL (e.g., git@github.com:user/repo.git)" \
		--width=500)
	
	[[ -z "$form_result" ]] && return
	
	local remote_name remote_url
	remote_name=$(cut -d'|' -f1 <<<"$form_result" | xargs)
	remote_url=$(cut -d'|' -f2 <<<"$form_result" | xargs)
	
	if [[ -z "$remote_name" || -z "$remote_url" ]]; then
		show_error "Please provide both a remote name and a URL."
		return
	fi
	
	if git remote add "$remote_name" "$remote_url"; then
		show_info "Remote '$remote_name' added successfully.\nURL: $remote_url"
	else
		show_error "Failed to add remote '$remote_name'.\nIt may already exist."
	fi
}

merge_branch() {
	local current_branch
	current_branch=$(get_current_branch)
	
	local branches
	branches=$(get_branches_with_info)
	
	if [[ -z "$branches" ]]; then
		show_error "No branches available."
		return
	fi
	
	local branch
	branch=$(echo "$branches" | zenity --list --title="Merge Branch" \
		--text="Current branch: $current_branch\n\nSelect a branch to merge into current:" \
		--column "Branch" --height=300)
	[[ -z "$branch" ]] && return
	
	branch=$(echo "$branch" | sed 's/^\[CURRENT\] //' | xargs)
	
	if [[ "$branch" == "$current_branch" ]]; then
		show_warning "Cannot merge a branch into itself."
		return
	fi
	
	confirm "Merge '$branch' into '$current_branch'?" || return
	
	if git merge "$branch"; then
		show_info "Merged '$branch' into '$current_branch' successfully."
	else
		show_error "Merge failed. Resolve conflicts and commit, or run 'git merge --abort' to cancel."
	fi
}

stash_changes() {
	while true; do
		local stash_count
		stash_count=$(git stash list 2>/dev/null | wc -l)
		
		local action
		action=$(show_button_menu "Temporary Storage" \
			"Available stashes: $stash_count" \
			"💾 Save Changes" \
			"📂 Apply Stash" \
			"📋 List Stashes" \
			"🗑️  Drop Stash" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"💾 Save Changes")
			local message
			message=$(zenity --entry --title="Save Stash" \
				--text="Enter a name for this stash (optional):")
			
			if git stash save "$message"; then
				show_info "Changes stashed successfully."
			else
				show_error "Failed to stash changes."
			fi
			;;
		"📂 Apply Stash")
			local stashes
			stashes=$(git stash list)
			[[ -z "$stashes" ]] && { show_error "No stashes available."; continue; }
			
			local stash
			stash=$(echo "$stashes" | zenity --list --title="Apply Stash" \
				--text="Choose a stash to apply:" \
				--column "Stash" --height=300)
			[[ -z "$stash" ]] && continue
			
			stash=$(echo "$stash" | cut -d':' -f1)
			if git stash apply "$stash"; then
				show_info "Stash $stash applied successfully."
			else
				show_error "Failed to apply stash $stash."
			fi
			;;
		"📋 List Stashes")
			local stashes_list
			stashes_list=$(git stash list)
			if [[ -z "$stashes_list" ]]; then
				show_info "No stashes available."
			else
				echo "$stashes_list" | zenity --text-info --title="Stashes" --width=600 --height=300
			fi
			;;
		"🗑️  Drop Stash")
			local stashes
			stashes=$(git stash list)
			[[ -z "$stashes" ]] && { show_error "No stashes available."; continue; }
			
			local stash
			stash=$(echo "$stashes" | zenity --list --title="Drop Stash" \
				--text="Choose a stash to delete:" \
				--column "Stash" --height=300)
			[[ -z "$stash" ]] && continue
			
			stash=$(echo "$stash" | cut -d':' -f1)
			confirm "Delete $stash?" || continue
			
			if git stash drop "$stash"; then
				show_info "Stash $stash deleted."
			else
				show_error "Failed to delete stash $stash."
			fi
			;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

restore_to_last_commit() {
	local changes
	changes=$(get_git_status)
	
	if [[ $changes -eq 0 ]]; then
		show_info "No changes to restore."
		return
	fi
	
	confirm "Discard all $changes changes in working directory? This cannot be undone." || return
	
	if git restore .; then
		show_info "Working directory restored to the last commit."
	else
		show_error "Failed to restore working directory."
	fi
}

rebase_branch() {
	local current_branch
	current_branch=$(get_current_branch)
	
	local branches
	branches=$(get_branches_with_info)
	
	if [[ -z "$branches" ]]; then
		show_error "No branches available."
		return
	fi
	
	local branch
	branch=$(echo "$branches" | zenity --list --title="Rebase Branch" \
		--text="Current branch: $current_branch\n\nChoose a branch to rebase onto:" \
		--column "Branch" --height=300)
	[[ -z "$branch" ]] && return
	
	branch=$(echo "$branch" | sed 's/^\[CURRENT\] //' | xargs)
	
	confirm "Rebase '$current_branch' onto '$branch'?" || return
	
	if git rebase "$branch"; then
		show_info "Rebased successfully."
	else
		show_error "Rebase failed. Resolve conflicts and run 'git rebase --continue', or run 'git rebase --abort' to cancel."
	fi
}

show_log() {
	local log_output
	log_output=$(git log --oneline -20)
	
	echo "$log_output" | zenity --text-info --title="Git Log (Latest 20 commits)" \
		--width=700 --height=400
}

# ============================================================================
# MAIN MENU
# ============================================================================

main() {
	while true; do
		local current_branch
		local changes
		current_branch=$(get_current_branch)
		changes=$(get_git_status)
		
		local action
		action=$(show_button_menu "Git Helper" \
			"Branch: $current_branch | Changes: $changes\n\nQuick Actions:" \
			"🔗 Commit Changes" \
			"📤 Push to Remote" \
			"📥 Pull from Remote" \
			"" \
			"📋 Branch Management" \
			"💾 Staging & Commits" \
			"🌐 Remote & Sync" \
			"📁 File Management" \
			"📦 Temporary Storage" \
			"🏷️  Tags" \
			"🧹 Cleanup & Recovery" \
			"" \
			"❌ Exit")
		
		case "$action" in
		"🔗 Commit Changes") commit_changes & ;;
		"📤 Push to Remote") remote_operation "Push" & ;;
		"📥 Pull from Remote") remote_operation "Pull" & ;;
		"📋 Branch Management") branch_management_menu & ;;
		"💾 Staging & Commits") staging_commits_menu & ;;
		"🌐 Remote & Sync") remote_sync_menu & ;;
		"📁 File Management") file_operations & ;;
		"📦 Temporary Storage") stash_changes & ;;
		"🏷️  Tags") tag_management & ;;
		"🧹 Cleanup & Recovery") cleanup_and_undo & ;;
		"❌ Exit") break ;;
		"") ;; # Separator
		esac
	done
}

branch_management_menu() {
	while true; do
		local current_branch
		current_branch=$(get_current_branch)
		local branch_count
		branch_count=$(git branch | wc -l)
		
		local action
		action=$(show_button_menu "Branch Management" \
			"Current: $current_branch | Total branches: $branch_count" \
			"✨ Create Branch" \
			"🔀 Switch Branch" \
			"🗑️  Delete Branch" \
			"✏️  Rename Branch" \
			"🔗 Merge Branch" \
			"📍 Rebase Branch" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"✨ Create Branch") create_branch & ;;
		"🔀 Switch Branch") switch_branch & ;;
		"🗑️  Delete Branch") delete_branch & ;;
		"✏️  Rename Branch") rename_branch & ;;
		"🔗 Merge Branch") merge_branch & ;;
		"📍 Rebase Branch") rebase_branch & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

staging_commits_menu() {
	while true; do
		local action
		action=$(show_button_menu "Staging & Commits" \
			"Manage commits and view history" \
			"🔧 Commit Operations" \
			"📖 View Log" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"🔧 Commit Operations") commit_operations & ;;
		"📖 View Log") show_log & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

remote_sync_menu() {
	while true; do
		local action
		action=$(show_button_menu "Remote & Sync" \
			"Manage remote repositories" \
			"🔌 Manage Remotes" \
			"" \
			"⬅️  Close Window")
		
		case "$action" in
		"🔌 Manage Remotes") add_remote_repository & ;;
		"⬅️  Close Window") break ;;
		"") ;; # Separator
		esac
	done
}

main
