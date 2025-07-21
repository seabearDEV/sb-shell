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
A process monitoring tool that can automatically kill processes exceeding CPU or memory thresholds.

**Usage:** `sb-mksep [-n PROCESS_NAME] [-c CPU_THRESHOLD] [-m MEMORY_THRESHOLD] [-s SLEEP_TIME] [-t] [-o] [-a]`

**Options:**
- `-n PROCESS_NAME` - Process name to monitor (default: all processes)
- `-c CPU_THRESHOLD` - CPU usage percentage threshold
- `-m MEMORY_THRESHOLD` - Memory usage percentage threshold  
- `-s SLEEP_TIME` - Sleep time between checks in seconds (default: 30)
- `-t` - Test mode (shows what would be killed without actually killing)
- `-o` - Compact mode (only show processes with CPU/Memory >= 1%)
- `-a` - Aggregate mode (group similar processes together)

**Examples:**
```sh
# Monitor Firefox, kill if CPU > 90% or Memory > 85%
sb-mksep -n firefox -c 90 -m 85

# Test mode: show all processes exceeding 95% CPU
sb-mksep -c 95 -t

# Monitor Chrome every 10 seconds
sb-mksep -n "chrome" -s 10
```

**Aliases:**
- `mksep` - Alias for `sb-mksep`

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
