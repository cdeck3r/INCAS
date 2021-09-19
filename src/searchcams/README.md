# Search Cameras

They are two shell scripts for searching IP cameras on the network. 

1. [searchcams.sh](searchcams.sh) is an active scan. It probes a given IP address range for the IP camera snapshot URL. The range is defined by a IP address and a subnet mask.

Usage: searchcams.sh [<IPaddress> <netmask>]

Params

- IPaddress in dotted decimal form
- netmask in dotted decimal

The only console output is 
```
Potential IP camera found: <ip address>
Potential IP camera found: <ip address>
...
```

In a practical setting, one may want to run `searchcams.sh` as a cronjob and redirect the output into a separate result file for later processing. Example:

```
./searchcams.sh > ipcameras.log
```


2. [discovercams.sh](discovercams.sh) discovers IP cameras via `avahi`.

Usage: ...


3. Finally, [writeconfig.sh]() adds the cameras to the config file in the INCAS root, e.g. `/home/pi/incas`.

The script takes the result file from `searchcams.sh` or `discovercams.sh` as input.

## Config file

The config file is a yaml file in INCAS root directory: `/home/pi/incas/config.yml`

Definition by example format:

```
www-images: "/home/pi/incas/www-images"
log_dir: "/home/pi/incas/log"

# found by network scan or manually entered
cameras:
  incas_user: "incas"
  incas_pass: "test123"
  
  1:
    ip: "192.168.1.1"
    name: "cam1"
  2:
    ip: "192.168.1.2"
    name: "cam2"
```
