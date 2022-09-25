"""""
Code for monitoring and controlling temperature in the Maxwell FT200 controller using the Modbus RS485 protocol
@author: Lois Orosa
"""""
import minimalmodbus as mm, serial, time
import time
import os
import sys
import pathlib

class FT200:
    """
        Controls and monitors the Maxwell FT200 tempoerature controller
    """
    READ_ERROR = -999
    WRITE_ERROR = -998
    def __init__(self, _baud=9600, _ft200_addr=1, _temp_tolerance=2):
        self.baud   = _baud
        self.write_reg = 5 # Write register
        self.read_reg  = 0 # Read register
        self.ft200_addr = _ft200_addr # Address of the device (by default is 1)
        self.temp_tolerance = _temp_tolerance # Temperature tolerance. By default, we consider that we reach the target value if the measured value is within +-0.2C

        try:
            self.device = self.findDevice() # Get the USB-RS485 device
            print("USB-RS485 Device: "+str(self.device))
            self.instrument = mm.Instrument(self.device , 3 , debug = False)
            self.instrument.serial.baudrate = self.baud
            self.instrument.address = self.ft200_addr
            self.instrument.serial.timeout  = 1
            self.instrument.serial.parity   = serial.PARITY_NONE
            self.instrument.mode = mm.MODE_RTU
            print("Device "+self.device+": conected")
        except:
            raise

    # Automatically find the USB-RS485 Device
    def findDevice(self):
        '''
            Find the USB-RS485 device
            This function might raise two exceptions:
                -> NameError: There is more than 1 USB-RS485 device, or other USB device has a similar name as the USB-RS485 device
                -> IOError:   Device not found. 
        '''
        DEVICENAME = "1a86_USB"
        name = ''
        while True:
            path = pathlib.Path(__file__).parent.absolute()
            f = os.popen(str(path)+"/usb_dev_path.sh")
            for device in f:
                if DEVICENAME in device:
                    if name == '':
                        name = device.split()[0]
                    else:
                        raise NameError("There are at least two USB devices whose name contains "+str(DEVICENAME))
            if name == '':
                raise IOError("Device not found.")
            return name

    # Read Temperature from FT200
    # The output value has 1 decimal, and it is multiplied by 10
    # E.g., data= 102 represents a temperature of 10.2C 
    def readTemp(self):
        try:
            data = self.instrument.read_register(self.read_reg, functioncode=3)
            return data
        except IOError:
            print("Failed to read from instrument")
            return self.READ_ERROR
    
    # Check if the temperature reached a value
    # The input value has 1 decimal, and it is multiplied by 10
    # E.g., data= 102 represents a temperature of 10.2C 
    def isTemp(self, temperature):
        try:
            data = self.instrument.read_register(self.read_reg, functioncode=3)
            if data >= (temperature-self.temp_tolerance) and data <= (temperature+self.temp_tolerance):
                return True
            else:
                return False
        except IOError:
            print("Failed to read from instrument")
            return False

    # Set Temperature FT200
    # The value should be a integer, and it should be the temperature value with 1 decimal multiplied by 10
    # E.g., value= 102 represents a temperature of 10.2C 
    def setTemp(self, value):
        try:
            self.instrument.write_register(self.write_reg, value, functioncode=6)
        except IOError:
            print("Failed to write to instrument")
            return self.WRITE_ERROR
        return 0

    # Set the temperature and wait for the temperature to be stable
    # Optimized version that reach the target temperature earlier
    # The value should be a integer, and it should be the temperature value with 1 decimal multiplied by 10
    # E.g., value= 102 represents a temperature of 10.2C 
    def autoSetAndWait(self, temperature, debug = False):
        acceleration_factor = 5
        stability = 10 # Iterations that the temperature needs to be stable
        time_sleep = 1 # 1 second wait per loop iteration
        stable_count = stability # Counter for taking into account the stability of the temperature
        stable_margin = 20 # We do not change the set temperature if we are within 2C from the target
        optTemp = temperature
        self.setTemp(optTemp) # Set the temperature
        curTemp = self.readTemp() # Read the temperature
        if debug:
            print("[TEMPERATURE] current: "+str(curTemp/10.0)+", goal: "+str(temperature/10.0)+", programmed: "+str(optTemp/10.0))
        while (((curTemp > (temperature + self.temp_tolerance)) or (curTemp < (temperature - self.temp_tolerance))) or (stable_count!=0)):
            if debug:
                print("[TEMPERATURE] current: "+str(curTemp/10.0)+", goal: "+str(temperature/10.0)+", programmed: "+str(optTemp/10.0)+", stable_count: "+str(stable_count))
            prev_optTemp = optTemp
            if (temperature - curTemp) > 0: #(stable_margin): # If we are far away more than 2C
                optTemp = temperature + (temperature - curTemp)*acceleration_factor # Optimization to accelerate convergence
            else:
                optTemp = temperature
            if optTemp != prev_optTemp:
                self.setTemp(optTemp) # Set temperature only if different from the previous iteration

            time.sleep(time_sleep) # WAit for a while

            curTemp = self.readTemp() # Read the temperature
            while (curTemp == self.READ_ERROR): # If there is an error, read again
                curTemp = self.readTemp() 
            # Five iterations in the range
            if (curTemp > (temperature + self.temp_tolerance)) or (curTemp < (temperature - self.temp_tolerance)):
                stable_count = stability
            else:
                stable_count -= 1 # The temperature has to remain stable for a while 

    def autoSetAndWait_2(self, temperature, debug = False):
        acceleration_factor = 150
        stability = 10 # Iterations that the temperature needs to be stable
        time_sleep = 1 # 1 second wait per loop iteration
        stable_count = stability # Counter for taking into account the stability of the temperature
        stable_margin = 5 # We do not change the set temperature if we are within 2C from the target
        optTemp = temperature
        self.setTemp(optTemp) # Set the temperature
        curTemp = self.readTemp() # Read the temperature
        if debug:
            print("[TEMPERATURE] current: "+str(curTemp/10.0)+", goal: "+str(temperature/10.0)+", programmed: "+str(optTemp/10.0))
        while (((curTemp > (temperature + self.temp_tolerance)) or (curTemp < (temperature - self.temp_tolerance))) or (stable_count!=0)):
            if debug:
                print("[TEMPERATURE] current: "+str(curTemp/10.0)+", goal: "+str(temperature/10.0)+", programmed: "+str(optTemp/10.0)+", stable_count: "+str(stable_count))
            prev_optTemp = optTemp
            if abs(temperature - curTemp) > (stable_margin): # If we are far away more than 2C
                if temperature > curTemp:
                    optTemp = temperature + acceleration_factor # Optimization to accelerate convergence
                else:
                    optTemp = temperature - acceleration_factor # Optimization to accelerate convergence
            else:
                optTemp = temperature

            time.sleep(time_sleep) # WAit for a while

            curTemp = self.readTemp() # Read the temperature
            while (curTemp == self.READ_ERROR): # If there is an error, read again
                curTemp = self.readTemp() 
            # Five iterations in the range
            if (curTemp > (temperature + self.temp_tolerance)) or (curTemp < (temperature - self.temp_tolerance)):
                stable_count = stability
            else:
                stable_count -= 1 # The temperature has to remain stable for a while 

if __name__ == '__main__':
    ## Example of how to use the FT200 class
    try:
        tc = FT200()
    except Exception as error:
        print("[ERROR] "+ repr(error))
        sys.exit(0)

    # Temperature
    value = int(sys.argv[1]) * 10
    print(value)
    print(tc.readTemp())
    tc.autoSetAndWait(value,True)


    
