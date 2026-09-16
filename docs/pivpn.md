# PiVPN - Wireguard

## Installation

Run:
```bash
curl -L https://install.pivpn.io | bash
```

## Set a custom DNS

In order to access Vaultwarden I was required to use a domain rather than the IP address to connect.
In that case the Wireguard tunnel needs a custom DNS to be able to route the local domain to the server.

### Step 1: install dnsmasq

```shell
sudo apt update && sudo apt install -y dnsmasq
```

### Step 2: edit dnsmasq.conf:

```shell
sudo nano /etc/dnsmasq.conf
```

Add these lines to the bottom:

```text
# Answer 'home.huizehop' with a fixed IP
address=/home.huizehop/192.168.68.66

# Forward all other queries upstream (default behaviour reads /etc/resolv.conf)
# Make sure it listens on the WireGuard interface too:
interface=wg0
bind-dynamic
```

Restart the service:

```shell
sudo systemctl restart dnsmasq
```

### Step 3: Determine the IP of the DNS server

First we have to find the IP of the DNS server

```shell
ip addr show wg0
```

It will return something like this:

```text
4: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none
    inet 10.216.49.1/24 scope global wg0
       valid_lft forever preferred_lft forever
```

Now test if the change worked:

```shell
dig @10.216.49.1 home.huizehop
```

It will give you some answer that should contain this:

```text
;; ANSWER SECTION:
home.huizehop.          0       IN      A       192.168.68.66
```

### Step 4: Set all clients to the new DNS server

Each client that is generated has a DNS line in it, we have to update it to the new one

```text
DNS = 10.216.49.1
```

## List of commands

```
-a,  add              Create a client conf profile
-c,  clients          List any connected clients to the server
-d,  debug            Start a debugging session if having trouble
-l,  list             List all clients
-qr, qrcode           Show the qrcode of a client for use with the mobile app
-r,  remove           Remove a client
-h,  help             Show this help dialog
-u,  uninstall        Uninstall pivpn from your system!
-up, update           Updates PiVPN Scripts
-bk, backup           Backup VPN configs and user profiles
```

## Troubleshooting

### My public IP has changed

1. Edit the PiVPN configuration with sudo nano /etc/pivpn/wireguard/setupVars.conf
2. Update the pivpnHOST=[...] line
3. Save and exit

New clients you generate will use the new endpoint but you need to manually edit existing clients:

1. Open your configuration, for example whatever.conf
2. Update the line Endpoint = [...]:51820
3. Save the file and connect again
