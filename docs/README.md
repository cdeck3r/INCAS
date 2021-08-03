# Documentation

## Use case Design

The following UML use case diagram provides an impression on INCAS's main services.

![INCAS usecase diagram](http://www.plantuml.com/plantuml/png/KypCIyufJKajBSfHo2WfAIYsqjSlIYpNIyyioIXDAYrEBKhEpoj9pIlHIyxFrKzEIKtEDYxIz_HpTWpMpqtCpDDFoKykrYzDZWUQarYiLr9H0W00)

------------------------

### Use Case 1: Configure networked camera access 

**Primary Actor**: Developer    
**Scope**: INCAS    
**Summary**: INCAS raspi access the Wifi and finds the cameras    

#### Main course of actions:

1. Configure SSID and password in `wpa_supplicant.conf`
1. Run discovery script and write results in camera configuration file


#### Alternative Extensions:

2a. Write config file manually and copy onto the raspi


**Preconditions:** Wifi cameras are setup and online in the same wifi network.

**Postconditions:** INCAS raspi software can access the networked cameras via wifi.

------------------------

### Use Case 2: Calibrate cameras

**Primary Actor**: Developer   
**Scope**: INCAS    
**Summary**: The developers aligns the cameras' orientation to capture the scene from different view points, which are expected to be interesting.

#### Main course of actions:

1. Align the cameras' orientation
1. Trigger a single shot picture from all cameras
1. Check whether cameras capture the scene satisfactory
1. Repeat previous steps until satisfied

#### Alternative Extensions:

1a. ...
3a. ...
3b. ...


**Preconditions:** INCAS software on the raspi can connect to all configured cameras online in the wifi.

**Postconditions:** Developer is satisfied with camera orientation to taken images from scene.

