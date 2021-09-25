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
./searchcams.sh > <logdir>/ipcameras.log
```


2. [discovercams.sh](discovercams.sh) discovers IP cameras via `avahi`.

```
./discovercams.sh > <logdir>/ipcameras.log
```

Finally, [writeconfig.sh](writeconfig.sh) adds the discovered cameras to the config file in the INCAS root, e.g. `/home/pi/incas`. 

Usage: `./writeconfig.sh`

Just call the script. It takes the result file from `searchcams.sh` or `discovercams.sh` as input. Config details are specified in [docs/README.md](../../docs/README.md#config-file-dependencies-and-specification)
