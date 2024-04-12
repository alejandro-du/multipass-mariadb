# Install Avahi daemon for accessing the server by hostname:
sudo apt install avahi-daemon -y

# Install the latest version of MariaDB MaxScale:
wget https://r.mariadb.com/downloads/mariadb_repo_setup
chmod +x mariadb_repo_setup
sudo ./mariadb_repo_setup
sudo apt update
sudo apt install maxscale -y

# Copy the MaxScale configuration file:
sudo cp ./maxscale.cnf /etc/maxscale.cnf
sudo systemctl restart maxscale
