# Working with HDDs on the Pi

My setup has two identical HDDs connected to the Raspberry Pi.
The first one is used for storing the data, the second one is as an exact copy of the first one.
In case the first one is damaged, I can use the second one to restore the server instantly.

The HDDs are encrypted using LUKS.
I decided not to use keyfiles to open the crypts on boot because I would have to store those files on the server as well.
This would erase any benefit of using encryption in the first place.

## Format HDDs as ext4

*Do this for both drives*

```shell
# Identify the device (example: /dev/sda)
lsblk          # find the correct /dev/sdX

# Create a new GPT partition table (optional, wipes everything)
sudo parted /dev/sdX mklabel gpt

# Make a single partition that fills the disk
sudo parted -a optimal /dev/sdX mkpart primary ext4 0% 100%

# Format it
sudo mkfs.ext4 -L data /dev/sdX1

# Verify what you created
sudo partprobe /dev/sdX        # refresh the kernel’s view
lsblk -f                       # should show /dev/sda1 with type “ext4”
```

## Encrypt and mount the HDDs

### Install package and add directories

```shell
# Install cryptsetup
sudo apt-get install cryptsetup

# Create directories for mounting
sudo mkdir -p /mnt/data
sudo mkdir -p /mnt/backup

# Set appropriate permissions
sudo chown -R USERNAME:USERNAME /mnt/data
sudo chown -R USERNAME:USERNAME /mnt/backup

sudo chmod 755 /mnt/data
sudo chmod 755 /mnt/backup
```

### Encrypt the drives

```shell
# Create LUKS encryption
sudo cryptsetup luksFormat /dev/sdX1

# Open the encrypted volume
sudo cryptsetup luksOpen /dev/sdX1 data_crypt

# Verify its open
lsblk

# Format the crypt as ext4
sudo mkfs.ext4 /dev/mapper/data_crypt

# Mount the crypt
sudo mount /dev/mapper/data_crypt /mnt/data

# Verify
lsblk -f
```

Repeat these steps for the second drive.
But use the name `backup_crypt` instead of `data_crypt` and mount it to `/mnt/backup`.

## Restoring after a server reboot

As I earlier described, the crypts are not opened and mounted automatically on boot.
You have to do this manually by running the following commands:

```shell
# Identify the device (example: /dev/sda)
lsblk          # find the correct /dev/sdX

# Open the encrypted volume
sudo cryptsetup luksOpen /dev/sdX1 data_crypt

# Mount the crypt
sudo mount /dev/mapper/data_crypt /mnt/data

# Verify
lsblk -f
```

Repeat these steps for the second drive.
But use the name `backup_crypt` instead of `data_crypt` and mount it to `/mnt/backup`.

After this you can just run `docker compose up -d` to start the server.

## Backup files using rsync

As mentioned in the README, I use rsync to synchronize my files from `/mnt/data` to `/mnt/backup`.
Use the following commands to synchronize the data every night at 3:00.

```shell
# Edit crontab
sudo crontab -e

# Add the following line
0 3 * * * rsync -a --delete /mnt/data/ /mnt/backup
```

## Creating a backup of the LUKS headers:

I have read online that it is important to create a backup of the LUKS headers.
Although I have no experience with a situation that would require these backups I still make them to be sure.
To create a backup of the LUKS headers, run the following command:

```shell
sudo cryptsetup luksHeaderBackup /dev/sdX1 --header-backup-file /luksheaders/sdX1.luks-header
```

Repeat this for the second drive.
Then store the backup files in a safe place (outside of this server).
