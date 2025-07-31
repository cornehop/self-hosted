# PiVPN (Wireguard)

Website: [pivpn.io](https://www.pivpn.io)

## Prequisites

To use PiVPN I have a Raspberry Pi 3B+ with the `Raspberry Pi OS Lite` installed. When installing the OS make sure you set the username and password of the user and enable SSH. It's also smart to change the hostname to something meaningful, otherwise all your Pi's will be called "raspberrypi". Good luck finding the one you need.

After the installation you might have to open the port (default 1194) on your router to be able to access the VPN from outside your network.

## Installation

Run:

```bash
curl -L https://install.pivpn.io | bash
```

Then just follow the steps in the installation. Make sure to select **Wireguard** instead of *OpenVPN*.

When finished update the Pi:

```bash
sudo apt-get update
sudo apt-get upgrade
```

## Usage

To add a client run:

```bash
pivpn add
```

Give the new client a useful name and a strong password.

After this you need to retrieve the client file from the Pi. The easiest way to do this is by connecting to the Pi with FTP. Then just find the files in the `configs` folder that is located in the users folder.

*If you want to connect from your phone you can do that even easier, just run*:

```bash
pivpn -qr
```

Select the client you want to use and a QR code will be displayed. On your phone, download the Wireguard app and scan the QR to create a tunnel.

## Other commands

To remove a client run: `pivpn remove`
