# Take Snapshots from Cameras

The script [snapshot.sh](snapshot.sh) issues a HTTP request to a camera and stores the image. 

## Single Snapshot 

Single means that a _single image_ from _each camera_ is taken. 
`snapshot.sh` takes an optional cli argument for an image directory. 

Usage: `./snapshot.sh [imgdir]`

The script reads some parameters from `config.yml`. The parameters are

* www-images
* log_dir
* camera IP addresses

The camera IP addresses are found by [searchcams](../searchcams).

This is the logic for the _imgdir_ cli argument:

- If _imgdir_ is omitted, create a generated one as subdir of WWW_IMAGES
- If _imgdir_ directory exists, take it
- If _imgdir_ does not exist, create it as subdir of WWW_IMAGES directory

`snapshot.sh` logs its actions into `<logdir>/snapshot.log`.

## Periodic Snapshots

Snapshots in periodic intervals are implemented by the script-server UI. See [script-server](../script-server) for more details.


