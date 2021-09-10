# Documentation

## Use case Design

The following UML use case diagram provides an impression on INCAS's main services.

![INCAS usecase diagram](http://www.plantuml.com/plantuml/png/KypCIyufJKajBSfHo2WfAIYsqjSlIYpNIyyioIXDAYrEBKhEpoj9pIlHIyxFrKzEIKtEDYxIz_HpTWpMpqtCpDDFoKykrYzDZWUQarYiLr9H0W00)


------------------------

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


------------------------

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


**Preconditions:** Both, raspi and Wifi cameras, are setup and online in the same wifi network .

**Postconditions:** INCAS raspi software can access the networked cameras via wifi.

------------------------

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

------------------------

### Use Case 3: Run maintenance procedures

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

