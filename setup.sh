# Set envrionment variables for the project

# ${BASH_SOURCE[0]}: Gets path of setup.sh
# dirname "": Gets the directory name containing the path
# cd "": Changes directory to the one containing setup.sh
# &&: Adds another command to run, only if the first one succeeds
# pwd: Prints the path of the current directory (i.e. .../RISC-V-CPU/)
# $(): Runs the command and replaces itself with its output
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Creates a PROJECT_ROOT environment variable
# Add scripts folder to PATH
export PROJECT_ROOT
export PATH="$PROJECT_ROOT/scripts:$PATH"