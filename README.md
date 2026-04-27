# sb-shell

A collection of POSIX-compatible shell scripts and utilities to enhance your command-line experience.

## Available Scripts

### sb-gc - Git Commit with Spell Check

A convenient Git commit function that includes optional spell-checking for commit messages.

**Usage:** `gc <commit message>`

**Features:**

- Automatic spell-checking using aspell (if installed)
- Colored output for better readability
- Confirmation prompt before committing
- Comprehensive error handling

**Example:**

```sh
gc "Fix typo in documentation"
```

### sb-mksep - Monitor and Kill System Exhausting Processes

A process monitoring tool that can automatically kill processes exceeding CPU or memory thresholds. Supports both individual process monitoring and aggregate threshold monitoring for multi-process applications. Features time window tracking to prevent killing processes during brief resource spikes.

**Usage:** `sb-mksep [-n PROCESS_NAME] [-c CPU_THRESHOLD] [-m MEMORY_THRESHOLD] [-s SLEEP_TIME] [-t] [-o] [-a] [-k KILL_COUNT] [-w VIOLATIONS/WINDOW]`

**Options:**

- `-n PROCESS_NAME` - Process name to monitor (default: all processes)
- `-c CPU_THRESHOLD` - CPU usage percentage threshold
- `-m MEMORY_THRESHOLD` - Memory usage percentage threshold  
- `-s SLEEP_TIME` - Sleep time between checks in seconds (default: 30)
- `-t` - Test mode (shows what would be killed without actually killing)
- `-o` - Compact mode (only show processes with CPU/Memory >= 1%)
- `-a` - Aggregate mode (apply thresholds to combined usage of matching processes)
- `-k KILL_COUNT` - Number of processes to kill when aggregate threshold exceeded (requires `-a`)
- `-w VIOLATIONS/WINDOW` - Time window mode - kill only after X violations within Y checks (e.g., -w 3/5)

**Modes:**

- **Individual mode (default):** Each process is checked separately against thresholds
- **Aggregate mode (-a):** Combined usage of matching processes is checked against thresholds
- **Time window mode (-w):** Requires multiple violations before killing (works with both individual and aggregate modes)

**Examples:**

```sh
# Individual mode: Kill any Firefox process exceeding 90% CPU or 85% Memory
sb-mksep -n firefox -c 90 -m 85

# Time window: Kill Firefox only after 3 violations within 5 checks
sb-mksep -n firefox -c 90 -w 3/5

# Aggregate mode: Kill Chrome processes when their combined CPU exceeds 80%
sb-mksep -n chrome -a -c 80

# Aggregate with time window: Kill after 2 violations in 4 checks
sb-mksep -n chrome -a -c 80 -w 2/4

# Kill 2 highest memory processes when total system memory exceeds 90%
sb-mksep -a -m 90 -k 2

# Test mode: show all processes exceeding 95% CPU
sb-mksep -c 95 -t

# Monitor Chrome every 10 seconds with aggregate CPU threshold of 70%
sb-mksep -n chrome -a -c 70 -s 10
```

**Aliases:**

- `mksep` - Alias for `sb-mksep`

### sb-port - Show what's listening on a port

A friendly wrapper around `lsof` for "what's on port N" queries. Defaults to TCP listening sockets and accepts single ports, multiple ports, and ranges.

**Usage:** `sb-port [-U] PORT [PORT...]`

**Options:**

- `-U` - Use UDP instead of TCP
- `-h` - Show help

**Arguments:**

- `PORT` - A port number (1-65535)
- `PORT-PORT` - An inclusive range, e.g. `8000-8010` (max 1000 ports per range)

**Examples:**

```sh
sb-port 8080                # what's on TCP 8080
sb-port 80 443 8080         # multiple ports
sb-port 8000-8010           # a small range
sb-port -U 53               # UDP listener on 53
```

> `lsof` only sees processes owned by the current user; use `sudo` to see others.

### sb-extract - Universal archive extractor

Extracts archives based on file extension, dispatching to `tar`, `unzip`, `7z`, `unrar`, etc. so you don't have to remember tool-specific flags.

**Usage:** `sb-extract [-d DIR] [-t] FILE [FILE...]`

**Options:**

- `-d DIR` - Extract to `DIR` (default: current directory)
- `-t` - List archive contents instead of extracting
- `-h` - Show help

**Supported formats:**

- Archives: `.tar`, `.tar.gz`/`.tgz`, `.tar.bz2`/`.tbz`/`.tbz2`, `.tar.xz`/`.txz`, `.zip`, `.7z`, `.rar`
- Single-file: `.gz`, `.bz2`, `.xz` (extract only, `-t` not supported)

**Examples:**

```sh
sb-extract archive.tar.gz
sb-extract -d /tmp/x archive.zip
sb-extract -t archive.7z
sb-extract a.tar.gz b.zip c.7z   # batch extract
```

## Prerequisites

- Ensure that you have a POSIX-compatible shell installed on your system.
- Make sure you have the necessary permissions to create directories and copy files in your home directory.

## Installation

1. Download the installation script and the ```sb-shell``` scripts to your local machine.

2. Open a terminal and navigate to the directory where the installation script is located.

3. Run the installation script by executing the following command:

   ```sh
   ./install.sh
   ```

4. The script will prompt you to confirm the installation. Enter ```y``` to proceed or ```n``` to cancel the installation.

5. If you choose to proceed, the script will perform the following actions:
   - Check if the ```$HOME/.sb-shell``` directory exists. If it doesn't, the script will create it.
   - If the ```$HOME/.sb-shell``` directory already exists, the script will delete it and recreate it to ensure a clean installation.
   - Copy the ```sb-shell.sh``` script and the ```scripts*``` directories to the ```$HOME/.sb-shell``` directory.

6. After copying the files, the script will provide instructions for adding sb-shell to your shell's configuration file.

7. If the installation is successful, you will see a confirmation message with instructions on how to complete the setup for your specific shell.

## Post-Installation

Once the installation is complete, you can start using the ```sb-shell``` scripts in your shell environment. The scripts will be available in the ```$HOME/.sb-shell``` directory.

To activate sb-shell, add the following line to your shell's configuration file (e.g., ```.bashrc```, ```.zshrc```, etc.):

```sh
source "$HOME/.sb-shell/sb-shell.sh"
```

If you want to customize the scripts or add your own, you can modify the files in the ```$HOME/.sb-shell``` directory.

## Uninstalling

To uninstall the ```sb-shell``` scripts, simply delete the ```$HOME/.sb-shell``` directory and remove any references to it from your shell's configuration file.

## Troubleshooting

If you encounter any issues during the installation or while using the ```sb-shell``` scripts, please check the following:

- Ensure that you have the necessary permissions to create directories and copy files in your home directory.
- Make sure that the installation script and the ```sb-shell``` scripts are located in the correct directory.
- Verify that your shell's configuration file is properly configured and sourced.

If the issue persists, please contact the script maintainer or seek further assistance.
