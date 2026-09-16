# Baikal

## Restoring from backup

1. Retrieve the `config` and `Specific` directories from a backup
2. Copy them to the `config` and `Specific` directories of the Baikal installation (`/mnt/data/baikal`)
3. Make the `nginx` user the owner of the directories: `sudo chown -R 101:101 config Specific`

Then run the stack and navigate to `http://<local-ip>` to verify the installation.

## Access data

These are the URLs that you should use in your applications:

Contacts: `http://<IP-address>/dav.php/addressbooks/<username>/<name-of-addressbook>/`

Calendar: `http://<IP-address>/dav.php/calendars/<username>/<name-of-calendar>/`

*Note: for easy access you can see and copy the actual URLs in the admin interface*
