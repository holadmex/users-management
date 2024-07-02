#!/bin/bash

# Log and Password files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"



# Ensure /var/secure exists and is secured
mkdir -p /var/secure
chmod 700 /var/secure

# Create or clear the log and password files
> $LOG_FILE
> $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to generate random password
generate_password() {
    echo $(openssl rand -base64 12)
}


# Read the input file
INPUT_FILE=$1
# Process each line in the file
while IFS= read -r line; do
  # Ignore characters before the semicolon
  after_semicolon="${line#*;}"
  
  # Split the line into items separated by commas
  IFS=',' read -ra items <<< "$after_semicolon"
  
  # Ensure a group exists for each item
  for item in "${items[@]}"; do
    item=$(echo "$item" | xargs)  # Trim whitespace
    if [ ! -z "$item" ]; then
      if ! getent group "$item" > /dev/null; then
        echo "Creating group: $item"
        sudo groupadd "$item"
      else
        echo "Group already exists: $item"
      fi
    fi
  done
done < "$INPUT_FILE"


# Process each line in the input file
while IFS=';' read -r user groups; do
    # Trim whitespace
    user=$(echo "$user" | xargs)
    groups=$(echo "$groups" | xargs)


    # Create user with home directory and primary group
    if ! id "$user" &>/dev/null; then
        useradd -m "$user"
        echo "User $user was created successfully." >> $LOG_FILE
    else
        echo "User $user already exists." >> $LOG_FILE
    fi

    # Set user's groups
    if [ -n "$groups" ]; then
        usermod -aG $groups "$user"
        echo "User $user added to group: $groups." >> $LOG_FILE
    fi

    # Generate and set password
    password=$(generate_password)
    echo "$user:$password" | chpasswd
    echo "$user,$password" >> $PASSWORD_FILE
    echo "Password for user $user set." >> $LOG_FILE


done < "$INPUT_FILE"

#echo "User creation process completed." >> $LOG_FILE
