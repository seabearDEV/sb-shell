# sb-shell Installation

This README provides instructions on how to install the ```sb-shell``` scripts using the provided installation script.

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
