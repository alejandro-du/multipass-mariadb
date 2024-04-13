# Install Avahi daemon for accessing the server by hostname:
sudo apt install avahi-daemon -y
sudo systemctl start avahi-daemon
sudo systemctl enable avahi-daemon

# Install the latest version of MariaDB:
wget https://r.mariadb.com/downloads/mariadb_repo_setup
chmod +x mariadb_repo_setup
sudo ./mariadb_repo_setup
sudo apt update
sudo apt install mariadb-server -y

# Secure the MariaDB installation:
# The default root password is empty.
# For this exercise, we are answering the following and setting RootPassword123! as the new root password:
# Switch to unix_socket authentication [Y/n] y
# Change the root password? [Y/n] y
# Remove anonymous users? [Y/n] y
# Disallow root login remotely? [Y/n] y
# Remove test database and access to it? [Y/n] y
# Reload privilege tables now? [Y/n] y
# Note: In shells, you must escape the exclamation mark character in strings.
echo -e "RootPassword123\!\nn\nyour_root_password\nyour_root_password\nn\ny\nn\ny\ny" | sudo mariadb-secure-installation

# Configure MariaDB for remote access, set a random server id, and enable the binary log:
server_id=$(shuf -i 1-100000 -n 1)
printf "[mariadbd]\nbind-address = 0.0.0.0\nserver_id = $server_id\nlog_bin = mariadb-bin.log" | sudo tee /etc/mysql/mariadb.conf.d/99-custom-settings.cnf > /dev/null
sudo systemctl restart mariadb.service

if [[ $(hostname) == *1 ]]; then
	# Create a database (schema) and user for your application:
	sudo mariadb -e "CREATE DATABASE demo"
	sudo mariadb -e "CREATE USER 'user'@'%' IDENTIFIED BY 'Password123\!'"
	sudo mariadb -e "GRANT ALL PRIVILEGES ON demo.* TO 'user'@'%'"

	# Create a user for MaxScale:
	sudo mariadb -e "CREATE USER 'maxscale'@'%' IDENTIFIED BY 'MaxScale123\!';"
	sudo mariadb -e "GRANT SELECT ON mysql.user TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SELECT ON mysql.db TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SELECT ON mysql.tables_priv TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SELECT ON mysql.columns_priv TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SELECT ON mysql.procs_priv TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SELECT ON mysql.proxies_priv TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SELECT ON mysql.roles_mapping TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SHOW DATABASES ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SLAVE MONITOR ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT REPLICATION SLAVE ADMIN ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT REPLICATION MASTER ADMIN ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT REPLICATION SLAVE ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT SHOW DATABASES ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT RELOAD ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT READ_ONLY ADMIN ON *.* TO 'maxscale'@'%'"
	sudo mariadb -e "GRANT BINLOG ADMIN ON *.* TO 'maxscale'@'%'"

	# Create a replication user:
	sudo mariadb -e "CREATE USER 'replication'@'%' IDENTIFIED BY 'Replication123\!'"
	sudo mariadb -e "GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%'"
else
	# get ip address of mariadb-server-1
	master_ip=$(getent hosts mariadb-server-1.local | awk '{ print $1 }')
	sudo mariadb -e "CHANGE MASTER TO MASTER_HOST='$master_ip', MASTER_USER='replication', MASTER_PASSWORD='Replication123\!', MASTER_LOG_FILE='mariadb-bin.000001', MASTER_LOG_POS=344, MASTER_USE_GTID=replica_pos"
	sudo mariadb -e "START SLAVE"
fi
