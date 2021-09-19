# Documentation

### Table of Contents

- [Directory Structure](#directory-structure)
- [Usecase Design](#usecase-design)
- [Dependencies and Specification](#config-file-dependencies-and-specification)


## Directory Structure

INCAS consists of set of scripts organized along the following directory structure. Scripts in each directory cover a specific function or usecase. They largely run independently from each other.

```
incas/src/
|-- calibrate/
|-- housekeeping/
|-- include/
|-- script-server/
|-- searchcams/
|-- takeimg/
|-- config.yml
```

Common information is shared within INCAS's configuration file `config.yml`. Config details are found in section [Config File Dependencies](#config-file-dependencies-and-specification).

## Usecase Design

The following UML use case diagram provides an impression on INCAS's main services.

![INCAS usecase diagram](http://www.plantuml.com/plantuml/png/KypCIyufJKajBSfHo2WfAIYsqjSlIYpNIyyioIXDAYrEBKhEpoj9pIlHIyxFrKzEIKtEDYxIz_HpTWpMpqtCpDDFoKykrYzDZWUQarYiLr9H0W00)

### Quick Links

- [Use Case: Take collection of pictures](#uc_take_collection_of_pictures)
- [Use Case: Configure networked camera access](#uc_take_configure_networked_camera-access)
- [Use Case: Calibrate cameras](#uc_calibrate_cameras)
- [Use Case: Run maintenance procedures](#uc_run_maintenance_procedures)

## Config File Dependencies and Specification

The usecase implementations run independently from each other. However, they share some information they commonly rely on. The following diagram displays the usecases' dependencies to the config file. The config file format is defined below.

![Config file dependencies](http://www.plantuml.com/plantuml/png/KypCIyufJKbLo2WfAIYsqjSlIYpNIyyioIXDAYrEBKhEpoj9pIlHIyxFrKzEIKtEDYxIz_HpTWpMpqtCpDDFoKykra_EAOu7galBJDShgIW10000)


***Config file***

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


------------------------

<a name="uc_take_collection_of_pictures"></a>
### Use Case: Take collection of pictures

**Primary Actor**: Social Reporter
**Scope**: INCAS    
**Summary**: Main INCAS use case. We illustrate how the Social Reporter interacts with INCAS.

#### Main course of actions:

1. Login into web-based UI
1. Check how many cameras are online (INCAS health status)
1. Start taking images for a given parameters duration and frequency
1. Download images from UI

**Preconditions:** INCAS and all wifi cameras are online


#### Alternative extensions:

3a. Trigger the start of taking images (params: duration and frequency) manually using the same web-based UI


### Implementation Notes

**web-based UI**

The web-based UI uses [script-server](https://github.com/bugy/script-server). This approach enables one to run scripts via web browser and review their output. The `script-server` is accessed through a `nginx` reverse proxy.

**download images**

`nginx` is configured with directory index enabled, i.e. the user sees a directory listing containing the images. Load a single image by clicking on the image. Download all images by either using a FireFox extension or a `wget` request. 

**cameras online**

Ping the camers' ip addresses found in the config file. The config file is a yaml file in INCAS root directory.

**repeated image taking**

There should be always an stop event, e.g. a number of images taken or a max. duration.

Params:

* frequency: better an interval when to take an image, e.g. every 30s
* duration: time interval to stop taking images when reached, e.g. 2h
* maxtime: datetime when to stop taking images, e.g. 2021-09-10 14:00:00
* maximgs: max. number of images taken until stop

The only param to modify is _frequency_. All others are calculated based on frequency.

------------------------

<a name="uc_take_configure_networked_camera-access"></a>
### Use Case: Configure networked camera access 

**Primary Actor**: Developer    
**Scope**: INCAS    
**Summary**: INCAS raspi access the Wifi and finds the cameras    

#### Main course of actions:

1. Scan local network for IP cameras
1. Write found cameras (name and IPs) in the configuration file


#### Alternative extensions:

1a. Attempt to login into camera's web-based interface to verfiy access    
2a. Write config file manually or take a ready-made one and copy onto the raspi


**Preconditions:** Both, raspi and Wifi cameras, are setup and online in the same wifi network.

**Postconditions:** INCAS raspi software can access the networked cameras via wifi.


### Implementation Notes

Details are found in [src/searchcams](../src/searchcams).


------------------------

<a name="uc_calibrate_cameras"></a>
### Use Case: Calibrate cameras

**Primary Actor**: Developer   
**Scope**: INCAS    
**Summary**: The developers aligns the cameras' orientation to capture the scene from different view points, which are expected to be interesting.

#### Main course of actions:

1. Align the cameras' orientation
1. Trigger a single shot picture from all cameras
1. Review whether cameras capture the scene satisfactory
1. Repeat previous steps until satisfied


**Preconditions:** INCAS software on the raspi can connect to all configured cameras online in the wifi.

**Postconditions:** Developer is satisfied with camera orientation to taken images from scene.

### Implementation Notes

We use [gallery_shell](https://github.com/Cyclenerd/gallery_shell) to display images in a quick image review. Details are found in [src/calibrate](../src/calibrate).

------------------------

<a name="uc_run_maintenance_procedures"></a>
### Use Case: Run maintenance procedures

**Primary Actor**: System timer   
**Scope**: INCAS    
**Summary**: Retain INCAS health status at regular time intervals

#### Main course of actions:

1. Housekeeping of image files
1. Logrotation
1. Test cameras online
1. Create INCAS health status report

**Preconditions:** INCAS software on the raspi can connect to all configured cameras online in the wifi.

**Postconditions:** INCAS is healthy


### Implementation Notes

**logrotation**

The logfile rotation is defined in [`logrotate.conf`](../install/logrotate.conf). At the end of the installation routine logrotation is added as cronjob in the [`install_logrotate.sh`](../install/install_logrotate.sh).
