# Images from Networked Camera System (INCAS) 

This project collects and stores images from multiple ONVIF compatible IP cameras. 
These images serve as input to the Social Reporter - an AI based image selection and composition system for 
generating social media content about lectures at the [HHZ](https://www.hhz.de/master/digital-business-engineering/).


## Usage

INCAS is completely web-based. Point your browser to the URL of the INCAS server.

## Design 

The following UML usecase diagram provides an impression on INCAS's main services. The [docs](docs/) directory contains the full documentation.

![INCAS usecase diagram]()


## Hardware 

INCAS uses  

* multiple IPC-G22 Wifi IP cameras
* Raspberry Pi Zero W

**Initial setup**

* [Headless Pi Zero W Wifi Setup (Windows)](https://desertbot.io/blog/headless-pi-zero-w-wifi-setup-windows)
* Access a brand-new IPC-G22 on http://192.168.1.108, configure an admin password and import the [config file](). You may want to modify the config file to fit your network setup before the import.

## Software Setup

...


## Dev system

**Setup:** Start in project's root dir and create a `.env` file with the content shown below.
```
# .env file

# In the container, this is the directory where the code is found
# Example:
APP_ROOT=/INCAS

# the HOST directory containing directories to be mounted into containers
# Example:
VOL_DIR=/dev/INCAS
```

**Create** docker image. Please see [Dockerfiles/Dockerfile.incas-dev](https://github.com/cdeck3r/INCAS/blob/master/Dockerfiles/Dockerfile.incas-dev) for details.
```bash
docker-compose build incas-dev
```

**Spin up** the container and get a shell from the container
```bash
docker-compose up -d incas-dev
docker exec -it incas-dev /bin/bash
```

## License

Information provided in the [LICENSE](LICENSE) file.
