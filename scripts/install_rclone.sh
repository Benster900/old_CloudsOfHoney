################################## Setup Malware Partition ##################################
echo "WARNING: CloudsOfHoney recommends you have a seperate partition to store malware. This second partition only has read/write permissions
to prevent execution of the malware. You can continue with malware on the primary(one) partition or create a seperate partition and run this
script later."

read -p "Enter domain name: " -e domainName



################################## Install/Setup Rclone ##################################
