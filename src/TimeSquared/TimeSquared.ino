/*

   | Time Squared |
	A wall clock with no hands or numbers, only letters. Lights up the letters that spell out the time.
	
   | Examples | 
	"IT IS TEN O'CLOCK" 
	"IT IS HALF PAST NINE"
	"IT IS A QUARTER TO FOUR"

   | The circuit: |
		This must be loaded onto an Atmgea 328. A 164 will be insuficient. 
		
   |Credits| 
		Marcus Liang - LED Schematics, 7219 interfacing
		2010 Vin Marshall (vlm@2552.com, www.2552.com)
		Maurice Ribble - 1307 code http://www.glacialwanderer.com/hobbyrobotics
	

	ATMEGA 328 PINOUT
	*D2 - WWVB 
	*D3 - 7219 #1 Load
	*D4 - 7219 #1 Data
	*D5 _ 7219 #2 Clock
	*D6 _ 7219 #2 Load
	*D7 _ 7219 #2 Data
	*D8 _ 
	*D9 _ 7219 #1 Clock
	*D10 _ 
	*D11 _ Left Touch Sensor
	*D12 _ Right Touch Sensor
	*D13 _ 
	

	*A0 _ Light Sensor
	*A1 _ 
	*A2 _ 
	*A3 - 
	*A4 - 

	Created 11 May 2010
	By S. Owen
	
        Credits given to source of forked code
	
	
		
*/
#include <Wire.h> //Library for i2c, Used by 1307 and wwvb
#include <LedControl.h> //Library for max7219. Daisy chain not currently supported

    boolean debugSerial = true; //Loads serial library allowing output of data through the arduino serial/usb. Usefull but greatly slows down code. Must be true for others debugs to work. 
    boolean debug1307 = false; //Outputs current time stored in 1307 to serial console                  - dependent on debugSerial being true
    boolean debugTouch = true; //Numeric analog value for capacitance across touch sensors 0 to 1024   - dependent on debugSerial being true
    boolean debugLed = false; //Light up every led to see if any are shorted / burnt out                - dependent on debugSerial being true
 












/**
  maxim 7221 LED DRIVERS
  The led drivers support daisy chaining, however direct connections were
  used instead of daisy chaining. This is the layout chosen by mlng. Daisy Chaining is slower
*/
	//7219 upper 
const int CLOCKPIN1  = 9;   //max 72xx #1 Clock    (CLK)
const int LOADPIN1   = 3;   //max 72xx #1 Load     (CS)
const int DINPIN1    = 4;   //max 72xx #1 Data In  (DIN)

const int CLOCKPIN2  = 5;   //max 72xx #2 Clock    (CLK)
const int LOADPIN2   = 6;   //max 72xx #2 Load     (CS)
const int DINPIN2    = 7;   //max 72xx #2 Data In  (DIN)

/**
  LedControl(clock, load, din, daisyChainNumber)
  Create a new object for each Maxim 72xx chip
*/
LedControl LC1 = LedControl(CLOCKPIN1,LOADPIN1,DINPIN1,1); 
LedControl LC2 = LedControl(CLOCKPIN2,LOADPIN2,DINPIN2,1); 


/**
  Setup the SPI address for the 1307 Real Time Clock
*/
#define DS1307_I2C_ADDRESS 0x68 //0x68 = 104 



	// Convert normal decimal numbers to binary coded decimal - 1307
byte decToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}

// Convert binary coded decimal to normal decimal numbers
byte bcdToDec(byte val)
{
  return ( (val/16*10) + (val%16) );
}

















//========================== SETUP ===============================================|


void setup(){
  int baudrate = 15200;
  
  if (reprogram1307 == true)
  {
  setDateDs1307(setup_second, 
                setup_minute, 
                setup_hour, 
                setup_dayOfWeek, 
                setup_dayOfMonth, 
                setup_month, 
                setup_year); // Actually programs the 1307, run once then comment out. 
  }

  Wire.begin();
  
  if (debugSerial == true)
  {
    Serial.begin(baudrate);
    Serial.println("Began Serial at " + baudrate);
  }


	pinMode (CLOCKPIN2, OUTPUT);
	pinMode (LOADPIN2,  OUTPUT);
	pinMode (DINPIN2,   OUTPUT);
	pinMode (CLOCKPIN1, OUTPUT);
	pinMode (LOADPIN1,  OUTPUT);
	pinMode (DINPIN1,   OUTPUT);

	//pinMode(WWVBPIN, 	INPUT); commented until wwvb is ready
	pinMode(touchRight, INPUT);
	pinMode(touchLeft,  INPUT);

  pinMode(hourIncreaseButton, INPUT);
  pinMode(hourDecreaseButton, INPUT);
        
  LC1.shutdown(0,false);
  LC2.shutdown(0,false);
  
  //setLEDIntensity()
  LC1.setIntensity(0,8);
  LC2.setIntensity(0,8);
  // Clear Display
  LC1.clearDisplay(0);
  LC2.clearDisplay(0);



}//end setup()





void loop(){

}//end loop()











