# Git Helper

A comprehensive GUI-based git tool for Linux that simplifies complex git operations through an intuitive zenity interface. Designed for developers who prefer visual interactions over command-line git commands.

## Features

### Staging & Commits
- **Commit Changes** - Stage all changes and create a commit with message
- **Commit Operations** - Amend last commit, cherry-pick commits, reset to commit, view commit details
- **View Log** - Browse commit history (latest 20 commits)

### Branches
- **Branch Management** - Create, switch, delete, or rename branches
- **Merge Branch** - Merge another branch into current branch with conflict detection
- **Rebase Branch** - Rebase current branch onto another

### Remote
- **Push to Remote** - Push branches with confirmation dialog
- **Pull from Remote** - Pull changes with remote selection
- **Manage Remotes** - Add/configure remote repositories

### File Management
- **View git status** - Detailed view of repository status
- **View diffs** - Compare staged, unstaged, or all changes
- **Stage/Unstage files** - Manage individual file staging
- **File history** - View complete history for any file
- **File blame** - See line-by-line commit history

### Temporary Storage
- **Save changes** - Stash uncommitted changes with optional names
- **Apply stash** - Restore stashed changes
- **List stashes** - View all stashed changes
- **Drop stash** - Delete specific stashes

### Tags
- **Create tags** - Create lightweight or annotated tags
- **List tags** - View all repository tags
- **Push tags** - Push all or specific tags to remote

### Cleanup & Recovery
- **Clean untracked files** - Remove untracked files safely
- **Discard changes** - Undo unstaged or all changes
- **Delete remote branches** - Remove remote branches
- **Undo last commit** - Revert last commit while preserving changes
- **View reflog** - Browse git reflog history

## Why Use Git Helper?

- **Simple & Intuitive** - No need to remember complex git commands
- **Safe** - Confirmation dialogs for destructive operations
- **Visual** - See branch names, file counts, and status at a glance
- **Fast** - Quick access to commonly-used git operations
- **Open Source** - Free to use and modify

## Installation

### Prerequisites
- **Bash** (included on most Linux systems)
- **Git** - Version control system
- **Zenity** - GUI dialog framework

### Step 1: Install Dependencies

**Debian/Ubuntu:**
```bash
sudo apt install git zenity
```

**Fedora/RHEL:**
```bash
sudo dnf install git zenity
```

**Arch Linux:**
```bash
sudo pacman -S git zenity
```

**Other Distributions:**
Check your package manager for `git` and `zenity` packages.

### Step 2: Clone Repository
```bash
git clone https://github.com/WafiWadud/git_helper.git
cd git_helper
```

### Step 3: Make Executable
```bash
chmod +x git_helper.sh
```

### Step 4: Run
```bash
./git_helper.sh
```

### Optional: Add to PATH
```bash
# Copy to a location in your PATH
sudo cp git_helper.sh /usr/local/bin/git-helper

# Now run from anywhere
git-helper
```

## Usage

Simply run the script:
```bash
./git_helper.sh
```

The entire interface is **button-based** with emoji icons. Multiple windows can be open simultaneously - click buttons and new windows open while previous ones stay running. Close any window when done.

### Navigation Flow

- **Main Menu** stays open
- Click any button → Opens its own window (doesn't close main menu)
- Each window has its own buttons for sub-operations
- Close windows individually with "Close Window" button or by closing the dialog
- Manage multiple independent windows at once

### Main Menu Structure

**Quick Access Buttons** (at the top for frequent operations):
- 🔗 **Commit Changes** - Quickly stage and commit
- 📤 **Push to Remote** - Quickly push your branch
- 📥 **Pull from Remote** - Quickly pull changes

**Category Buttons** (organized by function):
- 📋 **Branch Management** - Create, Switch, Delete, Rename, Merge, Rebase branches
- 💾 **Staging & Commits** - Commit Operations, View Log
- 🌐 **Remote & Sync** - Manage Remotes
- 📁 **File Management** - View status, diffs, stage/unstage, history, blame
- 📦 **Temporary Storage** - Save, Apply, List, Drop stashes
- 🏷️ **Tags** - Create, list, or push tags
- 🧹 **Cleanup & Recovery** - Clean files, undo commits, delete branches, reflog

All windows remain independent - open multiple branches menu, files, commits at the same time.

## Features Highlights

### Safety First
- Confirmation dialogs for destructive operations (hard reset, force delete, etc.)
- Detailed warnings before irreversible actions
- Prevents accidental deletions with safe defaults

### Real-Time Information
Main menu displays:
- **Current branch** - See which branch you're on
- **Pending changes** - Number of modified files

Submenus show:
- File counts (staged/unstaged)
- Tag counts
- Stash counts
- Available branches/remotes

### User-Friendly Dialogs
- Clear, concise titles and instructions
- Helpful placeholder text in input fields
- Resizable windows for better readability
- Colored status messages (info/error/warning)

## Requirements

- Linux operating system (with X11 or Wayland)
- Bash shell
- Git (any recent version)
- Zenity (any recent version)
- Terminal/GUI environment for zenity to work

## Troubleshooting

### "zenity command not found"
Install zenity using your package manager (see Installation section above).

### "git command not found"
Install git using your package manager.

### Windows/macOS Support
This tool is designed for Linux systems. For Windows, consider:
- Using WSL (Windows Subsystem for Linux)
- GitHub Desktop
- GitKraken

For macOS:
- Use Homebrew: `brew install git zenity`
- Or use native Mac git tools

### Script doesn't run
1. Ensure the script is executable: `chmod +x git_helper.sh`
2. Run with bash explicitly: `bash git_helper.sh`
3. Check your PATH if running from elsewhere

## Notes

- The script requires a working git repository in the current directory
- Operations like push/pull require proper git credentials configured
- SSH keys should be set up for push operations with SSH remotes
- Some dialogs may behave differently depending on your desktop environment

## License

See LICENSE file in the repository.

## Contributing

Issues and pull requests are welcome! Help improve git-helper by:
- Reporting bugs
- Suggesting features
- Improving documentation
- Submitting code improvements

## Status

✅ Feature complete with comprehensive git operations coverage. Currently in maintenance mode with ongoing bug fixes and improvements.
