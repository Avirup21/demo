#!/bin/bash

# Function to check if a command is installed
command_exists() {
  command -v "$1" >/dev/null 2>&1
}
# Check if docker and docker-compose are installed
if ! command_exists docker || ! command_exists docker-compose; then
  echo "Docker or Docker Compose is not installed. Installing..."
  # Install Docker
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker "$USER"
  # Install Docker Compose
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker and Docker Compose have been installed."
fi
# Check if a site name is provided as a command-line argument
if [[ -z $1 ]]; then
  echo "Please provide a site name as a command-line argument."
  exit 1
fi
# Set site name from command-line argument
site_name=$1
# Create Docker Compose file
compose_file="docker-compose.yml"
cat >"$compose_file" <<EOF
version: '3'

services:
  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    restart: always
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
    ports:
      - 80:80
    volumes:
      - ./wp:/var/www/html

volumes:
  db_data:
EOF
# Create WordPress directory
mkdir -p wp

# Create /etc/hosts entry for example.com
sudo sh -c "echo '127.0.0.1 example.com' >> /etc/hosts"

# Start the containers
docker-compose up -d
# Wait for WordPress to be ready
echo "Waiting for WordPress to be ready..."
until curl -s http://example.com >/dev/null; do
  sleep 5
done

# Prompt the user to open example.com in a browser
echo "The site has been created successfully."
echo "You can now open http://example.com in your browser."
# Enable/disable the site
if [[ $2 == "enable" ]]; then
  docker-compose start
  echo "The site has been enabled."
elif [[ $2 == "disable" ]]; then
  docker-compose stop
  echo "The site has been disabled."
fi

# Delete the site
if [[ $2 == "delete" ]]; then
  docker-compose down --volumes
  rm -rf wp
  sudo sed -i '/example.com/d' /etc/hosts
  echo "The site has been deleted."
fi
