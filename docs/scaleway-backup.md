# Remote backup to Scaleway

In addition to the local backup to the second harddrive I also make a remote backup.

## The backup

The backup is created using `Restic`, a tool that creates snapshots of the data so only the items that were changed are added to the backup.
Restic encrypts the data before it leaves the server, so Scaleway is unable to read the data.
After the snapshot was created the script will then clean up old snapshots that are no longer needed.

By default the entire `/mnt/data` directory is added to the backup.
Some paths or items are excluded. You can find these in the `EXCLUDES` array in the script.

### Retention policy

The following snapshots are kept:

| Type     | Count | Meaning                              |
| -------- | ----- | ------------------------------------ |
| Daily    | 7     | The last 7 daily snapshots           |
| Weekly   | 5     | The last 5 weekly snapshots          |
| Monthly  | 12    | The last 12 monthly snapshots        |

Snapshots that do not match any of these are pruned automatically,
and the storage they used is reclaimed. This gives roughly one year of history.

## Initializing the backup

### Prerequisites

#### 1. Create a Scaleway bucket

1. Sign in to the Scaleway console.
2. Go to Object Storage and create a new bucket. Choose the region closest to you (e.g. nl-ams for Amsterdam).
3. Give it a name, e.g. selfhosted-backup. 
4. Set it to private visibility.

#### 2. Create an IAM API key

1. Go to **IAM** &rarr; **API Keys** and create a new key.
2. Scope it to the bucket created above (do not give it access to other resources).
3. Note down the **Access Key** and **Secret Key**. The secret key is only shown once.

#### 3. Save important information

This is kind of obvious but make sure you store the `RESTIC_PASSWORD`, `SCW_ACCESS_KEY`, `SCW_SECRET_KEY` and `RESTIC_REPOSITORY` values somewhere safe.
Without these values you will lose all access to the data on Scaleway.

### First setup

Add or replace the values in the `.env` file. Replace the placeholders with the values from the Scaleway console.

```dotenv
# Scaleway remote backup
SCW_ACCESS_KEY=SCWXXXXXXXXXXXXXXXX
SCW_SECRET_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
RESTIC_REPOSITORY=s3:s3.nl-ams.scw.cloud/selfhosted-backup
RESTIC_PASSWORD=your-strong-repository-password
```

The first setup is part of the script as well, so you are not required to do this manually.
As long as the `.env` file is set the script will automatically do the steps for you.
But if you are like me, someone who wants to have the feeling of being in control, these are the steps:

Install restic on the server:

```shell
sudo apt-get update
sudo apt-get install restic
```

Then initialize the repository:

```shell
set -a; source src/.env; set +a
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
restic init -o s3.storage-class="ONEZONE_IA"
```

The repository now exists on Scaleway and is ready to be used.

### Schedule the backup

Make sure the script is executable:

```shell
chmod +x ~/homelab/backup-to-scaleway.sh
```

Open the root crontab:

```shell
sudo crontab -e
```

Add the remote backup line after the existing local rsync:

```text
0 3 * * * rsync -a --delete /mnt/data/ /mnt/backup
0 4 * * * /home/<username>/homelab/backup-to-scaleway.sh
```

The one-hour gap gives the local rsync time to finish.
The script also checks whether `rsync` is still running and skips itself if it is.

Now you are good to go, every morning at 4:00 the data changes in your `/mnt/data` directory are automatically synced to the restic repository in Scaleway.

## Accessing the backups

### Prepare

Install restic on the server:

```shell
sudo apt-get update
sudo apt-get install restic
```

To access backup snapshots on Scaleway you first have to set the environment variables:

```shell
set -a; source src/.env; set +a
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY" AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
```

### List snapshots

To list the available snapshots on Scaleway run the following:

```shell
restic snapshots
```

### Restore a backup

In case of emergency (or test) you can restore a full backup with the following command:

```shell
restic restore latest:/mnt/data --target /mnt/data
```

If you require a specific snapshot you can replace the `latest` tag with the tag of the snapshot.

### Restore a single file or directory

To restore a single file or directory you can run the following:

```shell
restic restore latest:/mnt/data --target /tmp/restore --include /samba/share/Music
```

In this example only the `Music` directory is restored to the target directory.

### Browse the backup interactively

Restic can mount the repository as a filesystem so you can browse snapshots like
directories. This requires `fuse`:

```shell
sudo apt-get install fuse
mkdir -p /tmp/restic-mount
restic mount /tmp/restic-mount
```

Each snapshot appears as a directory under `/tmp/restic-mount/snapshots/`.
Unmount with `fusermount -u /tmp/restic-mount` when you are done.
