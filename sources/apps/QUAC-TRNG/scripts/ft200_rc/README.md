# FT200 remote read and write

Make sure that the FT200 controller match the parameters you are using in your script. 
The relevant parameters are:

PASS-0101 menu (see documentation in doc folder):
* ldN0 (Device address)
* bAUd (rate)
* UCR (parity)

## Requirements
* pip3 install -U minimalmodbus


## Add your user to the dialout group

sudo gpasswd --add ${USER} dialout
(You need to log out and log back in again for it to be effective)

## Execute test
* python3 ft200.py
