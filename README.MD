# Git helper
Git helper is a git helper (duh) made with bash using zenity.

## Why use git helper?

- It is a simple and easy to use git helper
- It is free
- It is open source
- It abstracts away the harder parts of git
- Im using it right now!

### What can it do?

- Push (with gui branch selection)
- Pull (with gui branch selection)
- Commit (with gui message input)
- Revert (with gui branch selection)
- Restore
- Rebase (with gui branch selection)
- Remote (with gui remote selection)
- Merge (with gui branch selection)
- Stash (with gui for stash saving and applying)
- Log

#### How to install?
1. install zenity
```bash
# Debian
sudo apt install zenity
# Fedora
sudo dnf install zenity
# Arch
sudo pacman -S zenity
```
2. clone repo
```bash
git clone https://github.com/WafiWadud/git_helper.git && cd git_helper
```
3. make executeable
```bash
chmod +x git_helper.sh
```
