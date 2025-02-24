# PowerShell Modular Setup

## Quick Guide
1. Copy the desired modules from `Templates` to `Pipeline`.
2. Prefix each module with a number to denote execution order (e.g., `01.`, `02.`, `03.`, etc.).
3. If needed, configure top-level variables in each `.psm1` module.
4. Run `Run.ps1` to execute the setup pipeline.

## Structure
1. **`Assets`**
   - Contains files or assets required by the modules.

2. **`Templates`**
   - __DO NOT EDIT__
   - A collection of modules to choose from for building your setup pipeline.
   - These modules are not executed by the setup process.

3. **`Pipeline`**
   - Contains the modules that will be executed during setup.
   - Copy modules from `Templates` and add a numbered prefix to indicate the execution order, e.g.:
     - `01. Install Chocolatey.psm1`
     - `02. Install SQLCMD.psm1`
     - `03. Install SQL Server 2022.psm1`
   - Modify top-level variables as required.

4. **`Shared`**
   - __DO NOT EDIT__
   - Contains shared modules that are used across the setup and other modules.

5. **`Run.ps1`**
   - __DO NOT EDIT__
   - The pipeline runner that executes the setup process.

## Development Guide
_This guide applies to Windows 10._

### Setup Virtual Machine
1. **Enable Hyper-V**
   1. Right-click the Windows button and select `Apps and Features`.
   2. Click `Programs and Features`.
   3. Click `Turn Windows Features on or off`.
   4. Ensure `Hyper-V` is enabled, then click OK.

2. **Download and Set Up Windows 10 ISO Image**
   - Follow the steps to download and set up the Windows 10 ISO image.
   - Record the username and password for the VM.

3. **Create Snapshot in Hyper-V**
   - Open `Hyper-V Manager` and take a snapshot of the virtual machine.
   - Name the snapshot `Clean Boot`.
   - Use this snapshot to reset the VM each time you want to re-test the scripts.

### Setup Visual Studio Code
1. **Install Visual Studio Code**
   - Install Visual Studio Code if it is not already installed.

2. **Configure Variables**
   - Set the following variables in `run-in-hyper-v.ps1`:
     - `$vmName`
     - `$username`
     - `$password`

3. **Run the Script**
   - Execute `run-in-hyper-v.ps1` to test the pipeline and ensure everything works as expected.
