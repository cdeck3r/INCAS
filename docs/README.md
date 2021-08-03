# Documentation

## Use case Design

The following UML use case diagram provides an impression on INCAS's main services.

![INCAS usecase diagram](http://www.plantuml.com/plantuml/png/KypCIyufJKajBSfHo2WfAIYsqjSlIYpNIyyioIXDAYrEBKhEpoj9pIlHIyxFrKzEIKtEDYxIz_HpTWpMpqtCpDDFoKykrYzDZWUQarYiLr9H0W00)


Use Case 1: Configure networked camera access 
=================================
**Primary Actor**: Developer
**Scope**: INCAS
**Summary**: INCAS raspi access the Wifi and finds the cameras

Main course of actions:
------------------------
1. Configure SSID and password in `wpa_supplicant.conf`
2. Run discovery script and write results in camera configuration file


Alternative Extensions:
------------------------
2a. Write config file manually and copy onto the raspi


**Preconditions:** Wifi cameras are setup and online in the same wifi network.

**Postconditions:** INCAS raspi software can access the networked cameras via wifi.
