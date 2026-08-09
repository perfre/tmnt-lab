#!/bin/bash
#
# This script must be run with sudo privileges (e.g., sudo ./your_script.sh)
# --- Configuration ---
source ansible-setup.env

create_wrapper_script() {
    local SCRIPT_NAME="$1"
    # If $2 is provided, use it. Otherwise, use a default exec command.
    # Note the single quotes to delay expansion of "$@".
    local EXEC_COMMAND="${2:-exec $1 \$@}"
    local SCRIPT_PATH="${SHARED_ANSIBLE_SCRIPT_DIR}/${SCRIPT_NAME}"

    echo "Creating ${SCRIPT_PATH}..."
    # Use single quotes on 'EOF' to prevent the shell from expanding
    # variables like $VENV_PATH while creating the script.
    cat > "${SCRIPT_PATH}" << 'EOF'
#!/bin/bash
# System-Wide Wrapper

# Path to the shared virtual environment
VENV_PATH="ANSIBLE_DIR_PLACEHOLDER" 

if [ ! -f "$VENV_PATH/bin/activate" ]; then
    echo "Error: Ansible virtual environment not found at $VENV_PATH" >&2
    exit 1
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Execute the command with all provided arguments
# The following line will be replaced by the shell variable below.
EXEC_LINE_PLACEHOLDER
EOF

    # Now, replace the placeholder with the actual command we want.
    # This correctly handles all complex quotes and variables.
    sed -i "s|EXEC_LINE_PLACEHOLDER|${EXEC_COMMAND}|" "${SCRIPT_PATH}"
    sed -i "s|ANSIBLE_DIR_PLACEHOLDER|${SHARED_ANSIBLE_DIR}|" "${SCRIPT_PATH}"

    chown "root:${SHARED_ANSIBLE_GROUP}" "${SCRIPT_PATH}"
    chmod 750 "${SCRIPT_PATH}"
}


# Check for root privileges 🛡️
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root or with sudo." >&2
   exit 1
fi

set -e # Exit immediately if a command exits with a non-zero status.

echo "--- 1. Installing Prerequisites ---"
apt-get update
apt-get install -y python${PYTHON_VERSION} python3-pip python3-venv ssh-askpass

echo "--- 2. Creating Ansible Virtual Environment ---"
python3 -m venv ${SHARED_ANSIBLE_DIR}
source ${SHARED_ANSIBLE_DIR}/bin/activate
${SHARED_ANSIBLE_DIR}/bin/pip install -r ansible-requirements.txt
${SHARED_ANSIBLE_DIR}/bin/ansible-galaxy collection install -r ansible-galaxy-requirements.yml
deactivate

echo "--- 3. Setting up Permissions ---"
# Create the group only if it doesn't already exist
if ! getent group ${SHARED_ANSIBLE_GROUP} > /dev/null; then
    echo "Creating group: ${SHARED_ANSIBLE_GROUP}"
    groupadd ${SHARED_ANSIBLE_GROUP}
fi

# Add the user who invoked sudo to the group
#if [ -n "$SUDO_USER" ]; then
#    echo "Adding user '${SUDO_USER}' to group '${SHARED_ANSIBLE_GROUP}'"
usermod -aG ${SHARED_ANSIBLE_GROUP} ${SUDO_USER}
#fi

sudo mkdir -p ${SHARED_ANSIBLE_LOG_DIR}
sudo chown root:${SHARED_ANSIBLE_GROUP} ${SHARED_ANSIBLE_LOG_DIR}
sudo chmod 770 ${SHARED_ANSIBLE_LOG_DIR}


# Set ownership and permissions for the ansible-admins group to manage the venv
chown -R root:${SHARED_ANSIBLE_GROUP} ${SHARED_ANSIBLE_DIR}
chmod -R g+w ${SHARED_ANSIBLE_DIR} # <-- FIX: Grant group write permissions

echo "--- 4. Creating Wrapper Scripts ---"

# 1. For ansible-playbook: Provide a custom command string.
#    We use an environment variable for logging and add the --diff flag.
create_wrapper_script "ansible-playbook" \
  "export ANSIBLE_LOG_PATH=\"${SHARED_ANSIBLE_LOG_DIR}/\$(date +%Y%m%d-%H%M%S)-\$(whoami)-playbook.log\"; exec ansible-playbook --diff \"\$@\""

# 2. For ansible-navigator: Provide a custom command string.
#    We add the --log-file and --diff arguments before the user's arguments "$@".
create_wrapper_script "ansible-navigator" \
  "exec ansible-navigator --diff --log-file \"${SHARED_ANSIBLE_LOG_DIR}/\$(date +%Y%m%d-%H%M%S)-\$(whoami)-navigator.log\" \"\$@\""

# 3. For all other scripts: Call it with only one argument.
#    It will use the default 'exec <script_name> "$@"' behavior.
create_wrapper_script "ansible"
create_wrapper_script "ansible-builder"
create_wrapper_script "ansible-community"
create_wrapper_script "ansible-config"
create_wrapper_script "ansible-console"
create_wrapper_script "ansible-doc"
create_wrapper_script "ansible-galaxy"
create_wrapper_script "ansible-inventory"
create_wrapper_script "ansible-pull"
create_wrapper_script "ansible-test"
create_wrapper_script "ansible-vault"
create_wrapper_script "ansible-pip" 'exec pip "$@"'
create_wrapper_script "ansible-python" 'exec python "$@"'
create_wrapper_script "deploy" 'exec ansible-playbook -i ~/dev/tmnt-lab/inventory-local/ --diff "$@"'


echo ""
echo "✅ Setup complete!"
echo "IMPORTANT: In order to use 'deploy' alias you need to enter password in ansible-local-lab.yml file or run with -K. If not using ssh-keys you need to supply -k"
echo "IMPORTANT: The all logged in users must log out and log back in for group changes to take effect."
