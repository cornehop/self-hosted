# Docker on Pi

## Install Docker and Docker Compose

```shell
# Use apt to install Docker and Docker Compose
sudo apt install docker.io docker-compose

# Add user to the 'docker' group
sudo usermod -aG docker USERNAME

# Reboot
sudo reboot

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verify
docker --version
docker-compose --version
sudo systemctl status docker
```
