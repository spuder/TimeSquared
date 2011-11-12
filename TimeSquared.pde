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


//comment notes
// === is the start of a class / block of code
// ^^^ is the end of a class / block of code
//START is always caps
//end is always lowercase


//===============================Global Variables ==========|




//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
//*********************************************************************************************************************

//System wide debuging tools, turn to true to see a serial output of raw values in the serial console. Debuging slows system down, recomended turn off when finished. 

  boolean debugSerial = true; //Loads serial library allowing output of data through the arduino serial/usb. Usefull but greatly slows down code. Must be true for others debugs to work. 
    boolean debug1307 = false; //Outputs current time stored in 1307 to serial console                  - dependent on debugSerial being true
    boolean debugTouch = true; //Numeric analog value for capacitance across touch sensors 0 to 1024   - dependent on debugSerial being true
    boolean debugLed = false; //Light up every led to see if any are shorted / burnt out                - dependent on debugSerial being true
 
 
  //Values to be programed into the real time clock (1307). Should only need to upload these values when time has drifted / daylight savings
  //Atomic Clock (WWVB) in development - will render this code unnessisary when completed. 
  //Uses military time
  //sunday = 0 or 7
    byte setup_second = 00, 
	setup_minute = 07, 
	setup_hour = 01, 
	setup_dayOfWeek = 6, 
	setup_dayOfMonth = 11, 
	setup_month = 11, 
	setup_year = 11;
    
  // Change this to true to reflash the 1307 chip with the correct time. Make sure you change this back to false before you upload anymore code. 
  boolean reprogram1307 = false; 

  
//********************************************************************************************************************  
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||





//LIBRARIES--------------------------------------------------|
//#include <CapSense.h> //Library for capasitive touch sensors
#include <Wire.h> //Library for i2c, Used by 1307 and wwvb
#include <LedControl.h> //Library for max7219. Daisy chain not currently supported
//#include <stdio.h>
//#include <binary.h> //not sure why
//#include <WProgram.h>//not sure why
//LIBRARIES---------------------------------------------------|











//7219 LED DRIVERS ----------------------------------------|
	//7219 upper
const int CLOCKPIN1 = 9; //max7219 #1 Clock
const int LOADPIN1 = 3;  //max 7219 #1 Load
const int DINPIN1 = 4;   //max 7219 #1 Data In


	//7219 lower
const int CLOCKPIN2 = 5; //max 7219 #2 Cloclk
const int LOADPIN2 = 6;  //max 7219 #2 Load
const int DINPIN2 = 7; 	 //max 7219 #2 Data in

LedControl LC1=LedControl(CLOCKPIN1,LOADPIN1,DINPIN1,1); //clock[5], load[6], data[7]
LedControl LC2=LedControl(CLOCKPIN2,LOADPIN2,DINPIN2,1); //clock[9], load[3], data[4]


boolean displayOn;
boolean forceUpdate;


//7219 LED DRIVERS ----------------------------------------|







//1307 RTC--------------------------------------|
#define DS1307_I2C_ADDRESS 0x68 // Adress of 1307  Address = 0x68 wont compile, leave off = sign. 
//#define DS1397 0xD0

//const int SDAPIN = 4; //1307 SDA
//const int SCLPIN = 5; //1307 SCL
/*
// RTC Memory Registers
#define RTC_SECS        0
#define RTC_MINS        1
#define RTC_HRS         2
#define RTC_DAY         3
#define RTC_DATE        4
#define RTC_MONTH       5
#define RTC_YEAR        6
#define RTC_SQW         7

//int lHour, lMin; 1307
//		int cHour, cMin, cSec;
// Global vars for tracking; 1307
		unsigned long ledLastUpdate = 0; 
		
*/


/*removed until ready for wwvb



//WWVB, Light Sensor----------------------|
const int WWVBPIN = 2; // WWVB
const int photoSens = 0; //PhotoSensor
int brightness = 1; //Brightness
int photoSensValue; // Analog value of resistor
//WWVB, Light Sensor----------------------|

*/

  //The time is periodically pulled from the 1307 and saved as these variables. 
  //Their scope allows any function to access the current time without having to go 
  //directly to the 1307 itself, since that is slower.
  byte  global_second, 
	global_minute, 
	global_hour, 
	global_dayOfWeek, 
	global_dayOfMonth, 
	global_month, 
	global_year;


boolean setModeToDebug = false; //vairable if we need to get into debug mode (hold both touch sensors for time)




//TOUCH---------------------------|
const int touchRight = 12;
	  int previousRight;
	  int x;

const int touchLeft = 11;
      int previousLeft;
      int y;
      
      

//TOUCH---------------------------|


/*


		// Timing and error recording 
		unsigned long pulseStartTime = 0;
		unsigned long pulseEndTime = 0;
		unsigned long frameEndTime = 0;
		unsigned long lastRtcUpdateTime = 0;
		boolean bitReceived = false;
		boolean wasMark = false;
		int framePosition = 0;
		int bitPosition = 1;
		char lastTimeUpdate[17];
		char lastBit = ' ';
		int errors[10] = { 1,1,1,1,1,1,1,1,1,1 };
		int errIdx = 0;
		int bitError = 0;
		boolean frameError = false;

		// RTC clock variables
		byte second = 0x00; //renamed this to RTCsecond because 'second' conflicts with a variable that wwvb uses
		byte minute = 0x00;
		byte hour = 0x00;
		byte day = 0x00;
		byte date = 0x01;
		byte month = 0x01;
		byte year = 0x00;
		byte ctrl = 0x00;
		// WWVB time variables
		byte wwvb_hour = 0;
		byte wwvb_minute = 0;
		byte wwvb_day = 0;
		byte wwvb_year = 0;

*/
		/* WWVB time format struct - acts as an overlay on wwvbRxBuffer to extract time/date data.
		 * This points to a 64 bit buffer wwvbRxBuffer that the bits get inserted into as the
		 * incoming data stream is received.  (Thanks to Capt.Tagon @ duinolab.blogspot.com)
		 */
		 
		 /*
		struct wwvbBuffer {
		  unsigned long long U12       :4;  // no value, empty four bits only 60 of 64 bits used
		  unsigned long long Frame     :2;  // framing
		  unsigned long long Dst       :2;  // dst flags
		  unsigned long long Leapsec   :1;  // leapsecond
		  unsigned long long Leapyear  :1;  // leapyear
		  unsigned long long U11       :1;  // no value
		  unsigned long long YearOne   :4;  // year (5 -> 2005)
		  unsigned long long U10       :1;  // no value
		  unsigned long long YearTen   :4;  // year (5 -> 2005)
		  unsigned long long U09       :1;  // no value
		  unsigned long long OffVal    :4;  // offset value
		  unsigned long long U08       :1;  // no value
		  unsigned long long OffSign   :3;  // offset sign
		  unsigned long long U07       :2;  // no value
		  unsigned long long DayOne    :4;  // day ones
		  unsigned long long U06       :1;  // no value
		  unsigned long long DayTen    :4;  // day tens
		  unsigned long long U05       :1;  // no value
		  unsigned long long DayHun    :2;  // day hundreds
		  unsigned long long U04       :3;  // no value
		  unsigned long long HourOne   :4;  // hours ones
		  unsigned long long U03       :1;  // no value
		  unsigned long long HourTen   :2;  // hours tens
		  unsigned long long U02       :3;  // no value
		  unsigned long long MinOne    :4;  // minutes ones
		  unsigned long long U01       :1;  // no value
		  unsigned long long MinTen    :3;  // minutes tens
		};

		struct wwvbBuffer * wwvbFrame;
		unsigned long long receiveBuffer;
		unsigned long long lastFrameBuffer;
		
		*/


/*

// Month abbreviations
char *months[12] = { //does this conflict with the 1307?
  "Jan",
  "Feb",
  "Mar",
  "Apr", 
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec" 
};
*/

/*
// Day of Year to month translation (thanks to Capt.Tagon)
// End of Month - to calculate Month and Day from Day of Year 
int eomYear[14][2] = {
  {0,0},      // Begin
  {31,31},    // Jan
  {59,60},    // Feb
  {90,91},    // Mar
  {120,121},  // Apr
  {151,152},  // May
  {181,182},  // Jun
  {212,213},  // Jul
  {243,244},  // Aug
  {273,274},  // Sep
  {304,305},  // Oct
  {334,335},  // Nov
  {365,366},  // Dec
  {366,367}   // overflow
};

*/
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
//=======================================================================|
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^end global variables^^^^^^^^^^^^^^^^^^^^^^^|




















//========================== SETUP ===============================================|


void setup(){

  
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
    Serial.begin(9600);
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


//Touch Sensors Initialize------------------------------|
	previousRight = LOW; // Initialize refrence variable, 
		x = 0; // Initialize refrence variable, 
	previousLeft = LOW;
		y = 0;
//Touch Sensor Intialize--------------------------------|	







//LED Initialize--------------------------|

	//Turn on LED controller
	LC1.shutdown(0,false);
	LC2.shutdown(0,false);
	
	//setLEDIntensity()
	LC1.setIntensity(0,8);
	LC2.setIntensity(0,8);
	// Clear Display
	LC1.clearDisplay(0);
	LC2.clearDisplay(0);
//LED Initialize--------------------------|


/*

// This is commented until I implement the wwvb



  pinMode(WWVBPIN, INPUT);
	  attachInterrupt(0, wwvbChange, CHANGE);

	  // Setup the WWVB Buffer
	  lastFrameBuffer = 0;
	  receiveBuffer = 0;
	  wwvbFrame = (struct wwvbBuffer *) &lastFrameBuffer;




*/



}//end setup()
//=============================================================================|
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ end setup ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^|











//=================================== LOOP ================================|


void loop(){
  
  int z; //variable to see if both corners are held down. Given least nessisary scope

  byte loop_second, loop_minute, loop_hour, loop_dayOfWeek, loop_dayOfMonth, loop_month, loop_year;

  //Retrieves time from 1307 every cycle 
  getDateDs1307(loop_second, loop_minute, loop_hour, loop_dayOfWeek, loop_dayOfMonth, loop_month, loop_year);

/*
  if(debug1307 == true)
      {
        RTCDebugMethod();
      }
	
  if(debugLed == true)
    {
     mode_ledDebug(); 
    }
    
 */

  // Check Corners
	int rightCorner = digitalRead(touchRight);
	int leftCorner = digitalRead(touchLeft);

	/*
  if (debugTouch == true)
    {
      touchDebugMethod();
    }	
    
    */


  if (rightCorner == HIGH && previousRight == LOW) 
    {
        x = (x + 1); // x++ didn't seem to work
	forceUpdate = true; // Mandatory clear and rewrite leds
    }
	
  if (leftCorner == HIGH && previousLeft == LOW) 
    {
	y = (y + 1); // y++ doesn't seem to work for some unknown reason
	forceUpdate = true; // Mandatory clear and rewrite leds
    }
   
   
  
   if (rightCorner == HIGH && leftCorner == HIGH) // if you are touching both corners at the same time
   {
      z = (z + 1); // z++ doesn't seem to work for unknown reason
      
      if (setModeToDebug == true) //
      {
        setModeToDebug = false;
      }
      
      if (z = 100) // must hold both sensors for 100 cycles. 
      {
        setModeToDebug = true;
      }
   }
   else if (z > 0 && setModeToDebug == false) // if you have let go of the sensors recently, starting 'calming down'
   {
     z = (z - 4); // counts down by 4 to skip trigger number
     if (z <= 0)
       {
         setModeToDebug = false;
         z = 0;// in case our count down over shot 0.
       }
   }
   //else{}//do nothing
	

	
  if ( setModeToDebug == true )
    {
      mode_debug();
    }
  else if ( (x % 2) == 0)
    {
       //boolean debugSerial = false; // if entered debug mode, must undo changes it made to boolean variables. 
      // boolean touchDebug = false;
      mode_default();
      
    }
  else 
    {
      mode_seconds();
    }
   


	
    if ( (y % 2) == 0) 
      {
        displayOn = true;
        LC1.shutdown(0,false);
	LC2.shutdown(0,false);
      }
    else 
      {
        displayOn = false;
        LC1.shutdown(0,true);
        LC2.shutdown(0,true);
      }
	previousRight = rightCorner; // Remember what corner was doing last time we checked
	previousLeft = leftCorner;




}//end loop()
//=========================================================================|
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ end loop ^^^^^^^^^^^^^^^^^^^^^^^^^^^|





//================================== GET RTC =======================
/*
 * getRTC
 * 
 * Read data from the DS1307 RTC over the I2C 2 wire interface.
 * Data is stored in the uC's global clock variables.
 */
// Gets the date and time from the ds1307
void getDateDs1307(
          byte s,
          byte mi,
          byte h,
          byte dow,
          byte dom,
          byte mo,
          byte y
          ){
  // Reset the register pointer
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);

  // A few of these need masks because certain bits are control bits
  global_second     = bcdToDec(Wire.receive() & 0x7f);
  global_minute     = bcdToDec(Wire.receive());
  global_hour       = bcdToDec(Wire.receive() & 0x3f);  // Need to change this if 12 hour am/pm
  global_dayOfWeek  = bcdToDec(Wire.receive());
  global_dayOfMonth = bcdToDec(Wire.receive());
  global_month      = bcdToDec(Wire.receive());
  global_year       = bcdToDec(Wire.receive());
}


// 1) Sets the date and time on the ds1307
// 2) Starts the clock
// 3) Sets hour mode to 24 hour clock
// Assumes you're passing in valid numbers
void setDateDs1307(byte second,        // 0-59
                   byte minute,        // 0-59
                   byte hour,          // 1-23
                   byte dayOfWeek,     // 1-7
                   byte dayOfMonth,    // 1-28/29/30/31
                   byte month,         // 1-12
                   byte year)          // 0-99
{
   Wire.beginTransmission(DS1307_I2C_ADDRESS);
   Wire.send(0);
   Wire.send(decToBcd(second));    // 0 to bit 7 starts the clock
   Wire.send(decToBcd(minute));
   Wire.send(decToBcd(hour));      // If you want 12 hour am/pm you need to set
                                   // bit 6 (also need to change readDateDs1307)
   Wire.send(decToBcd(dayOfWeek));
   Wire.send(decToBcd(dayOfMonth));
   Wire.send(decToBcd(month));
   Wire.send(decToBcd(year));
   Wire.endTransmission();
}









// Start mode_default()=============== Start mode_default()================= Start mode_default()
void mode_default() {
	
	
   int tpast5mins = global_minute % 5; // remainder
   int t5mins = global_minute - tpast5mins;
   int tHour = global_hour;
   
	int cHour;
	int cMin;
	int cSec;

  //compensate for military time used by 1307
  if (tHour > 12) tHour = tHour - 12;
  else if (tHour == 0) tHour = 12;	
	
	

	
//Only clear and rewite leds if time has changed.  
 if (cMin =!global_minute)
   {
     LED_CLEAR(); 
   }
     
 
 
  W_ITIS();

  if      (t5mins == 5 || t5mins == 55)     M_FIVE();       // 5 past or 5 to..
  else if (t5mins == 10 || t5mins == 50)    M_TEN();        // 10 past or 10 to..
  else if (t5mins == 15 || t5mins == 45)    M_AQUARTER();    // etc..
  else if (t5mins == 20 || t5mins == 40)    M_TWENTY();
  else if (t5mins == 25 || t5mins == 35)    M_TWENTYFIVE();
  else if (t5mins == 30)                    M_HALF();

   // past or to or o'clock?
   if (t5mins == 0)	    W_OCLOCK();
   else if (t5mins > 30)    W_TO();
   else                     W_PAST();
   
   if (t5mins > 30){
	tHour = tHour+1;
	if (tHour > 12) tHour = 1;
   }

   // light up the hour word
   if (tHour == 1) H_ONE(); 
   else if (tHour == 2) H_TWO(); 
   else if (tHour == 3) H_THREE(); 
   else if (tHour == 4) H_FOUR();
   else if (tHour == 5) H_FIVE(); 
   else if (tHour == 6) H_SIX(); 
   else if (tHour == 7) H_SEVEN(); 
   else if (tHour == 8) H_EIGHT();
   else if (tHour == 9) H_NINE(); 
   else if (tHour == 10) H_TEN(); 
   else if (tHour == 11) H_ELEVEN(); 
   else if (tHour == 12) H_TWELVE();
   
   // light up aux minute LED
   // ugly but quicker 
   if (tpast5mins == 0 ) { }
   else if (tpast5mins == 1) { P_ONE(); }
   else if (tpast5mins == 2) { P_ONE(); P_TWO(); }
   if (tpast5mins == 3) { P_ONE(); P_TWO(); P_THREE(); }
   if (tpast5mins == 4) { P_ONE(); P_TWO(); P_THREE(); P_FOUR(); }

   // save last updated time
   cHour = global_hour;
   cMin = global_minute;
   cSec = global_second;
   forceUpdate = false;
   

  
}
// end mode_default()=============== end mode_default() ==================== end mode_default()



// Start mode_seconds()------------------ Start mode_seconds()--------------------- Start mode_seconds()

		
	// Description: The entire face will show the "seconds" 00 to 59
void mode_seconds() {
  
	int cHour;
	int cMin;
	int cSec;
	

   // no seconds change, do nothing
   if (global_second == cSec) return; //Eliminates ficker
   
 
   int tsec = global_second;
  
    
   // decide if we only want to draw the right number or both numbers.
   // reduce the apparentness of the flicker of the non changing digit.
   if ((tsec - (tsec % 10) != cSec - (cSec % 10)) || (forceUpdate == true)) {
     LED_CLEAR();   
     if (tsec < 10) L_ZERO();
     else if (tsec < 20)  L_ONE();
     else if (tsec < 30)  L_TWO();
     else if (tsec < 40)  L_THREE();
     else if (tsec < 50)  L_FOUR();
     else L_FIVE();
   }
   else {
    R_CLEAR();
   }  
   
   // seconds have changed, draw the seconds.
	
	tsec = tsec % 10;

	if (tsec == 0) R_ZERO();
	if (tsec == 1) R_ONE();
	if (tsec == 2) R_TWO();
	if (tsec == 3) R_THREE();
	if (tsec == 4) R_FOUR();
	if (tsec == 5) R_FIVE();
	if (tsec == 6) R_SIX();
	if (tsec == 7) R_SEVEN();
	if (tsec == 8) R_EIGHT();
	if (tsec == 9) R_NINE();
   
   // save last updated time
   cHour = global_hour;
   cMin = global_minute;
   cSec = global_second;   
   forceUpdate = false;   
   
}
// End mode_seconds()------------------ End mode_seconds()--------------------- End mode_seconds()









// Start word layout --------------------- Start word layout -------------------- Start word layout --------------
void LED_CLEAR() {
  LC1.clearDisplay(0);
  LC2.clearDisplay(0);
}
void R_CLEAR() {
  LC1.setColumn(0,6,B00000000);
  LC1.setColumn(0,7,B00000000);
  LC1.setRow(0,5,B00000000);
  LC1.setRow(0,6,B00000000);
  LC1.setRow(0,7,B00000000);
  LC2.setColumn(0,6,B00000000);
  LC2.setColumn(0,7,B00000000);
  LC2.setRow(0,5,B00000000);
  LC2.setRow(0,6,B00000000);
  LC2.setRow(0,7,B00000000);
  
}

void M_FIVE() {
	LC1.setRow(0,2,B00000011); // FI
	LC1.setLed(0,5,3, true); // V
	LC1.setLed(0,6,3, true); // E
}
void M_TEN() {
	LC1.setRow(0,3,B00000111);
}
void M_AQUARTER() {
	LC1.setRow(0,1,B10111111); // A QUARTE
	LC1.setLed(0,5,4, true); // R
}
void M_TWENTY() {
	LC1.setRow(0,2,B11111100); // TWENTY
}
void M_TWENTYFIVE() {
	LC1.setRow(0,2,B11111111); // TWENTYFI
	LC1.setLed(0,5,3, true); // V
	LC1.setLed(0,6,3, true); // E
}
void M_HALF() {
	LC1.setRow(0,3,B11110000); // HALF
}
void W_ITIS() {
	// Row0 "IT IS" (R0=216) OO.OO.......
	LC1.setRow(0,0,B11011000);  // IT IS
}
void W_OCLOCK() {
	LC2.setLed(0,4,5,true); // O'
	LC2.setLed(0,4,6,true); // C
	LC2.setLed(0,4,7,true);	// L
	LC2.setLed(0,5,1,true); // O
	LC2.setLed(0,6,1,true); // C
	LC2.setLed(0,7,1,true);	// K
}
void W_TO() {
	LC1.setLed(0,6,2,true); // T
	LC1.setLed(0,7,2,true); // O
}
void W_PAST(){
	//LC1.setRow(0,0,B11110000); // PAST
	LC1.setLed(0,4,0,true); // P
	LC1.setLed(0,4,1,true); // A
	LC1.setLed(0,4,2,true); // S
	LC1.setLed(0,4,3,true); // T
}
void H_ONE(){
	LC2.setRow(0,0,B11100000); // ONE
}
void H_TWO(){
	LC2.setLed(0,5,4,true); // T
	LC2.setLed(0,6,4,true); // W
	LC2.setLed(0,7,4,true);  // O
}
void H_THREE(){
	LC2.setRow(0,0,B00000011); // TH
	LC2.setLed(0,5,5, true); //R
	LC2.setLed(0,6,5, true); //E
	LC2.setLed(0,7,5, true); //E
}
void H_FOUR(){
	LC2.setRow(0,1,B11110000); // FOUR
}
void H_FIVE(){
	LC2.setRow(0,1,B00001111); // FIVE
}
void H_SIX(){
	LC2.setRow(0,0,B00011100); // SIX
}
void H_SEVEN(){
	LC2.setRow(0,3,B11111000); // SEVEN...
}
void H_EIGHT(){
	LC2.setRow(0,2,B11111000);  //EIGHT...
}
void H_NINE(){
	LC1.setLed(0,4,7,true); // N
   	LC1.setLed(0,5,1,true); // I
  	LC1.setLed(0,6,1,true); // N
  	LC1.setLed(0,7,1,true); // E
}
void H_TEN(){
	LC2.setLed(0,4,0,true); // T
	LC2.setLed(0,4,1,true); // E
	LC2.setLed(0,4,2,true);	// N
}
void H_ELEVEN(){
	LC2.setRow(0,2,B00000111); //ELE
	LC2.setLed(0,5,3,true); //V
	LC2.setLed(0,6,3,true); //E
	LC2.setLed(0,7,3,true); //N
}
void H_TWELVE(){
	LC2.setRow(0,3,B00000111); // TWE
	LC2.setLed(0,5,2,true); //L
	LC2.setLed(0,6,2,true); //V
	LC2.setLed(0,7,2,true); //E
}
void P_ONE() {
    LC1.setLed(0,5,0,true); // top left
}
void P_TWO() {
	LC1.setLed(0,5,7,true); // top right
}
void P_THREE() {
	LC2.setLed(0,5,7,true);// bottom right

}
void P_FOUR() {
	LC2.setLed(0,5,0,true); // bottom left
}


// SECONDS COUNTER MODE ------- SECONDS COUNTER MODE ------- SECONDS COUNTER MODE ------- SECONDS COUNTER MODE -------


void L_ZERO(){
	LC1.setRow(0,2,B01110000);
	LC1.setRow(0,3,B10001000);
	LC1.setRow(0,4,B10011000);
	LC2.setRow(0,0,B10101000);
	LC2.setRow(0,1,B11001000);
	LC2.setRow(0,2,B10001000);
	LC2.setRow(0,3,B01110000);
}
void L_ONE(){
	LC1.setRow(0,2,B00100000);
	LC1.setRow(0,3,B01100000);
	LC1.setRow(0,4,B00100000);
	LC2.setRow(0,0,B00100000);
	LC2.setRow(0,1,B00100000);
	LC2.setRow(0,2,B00100000);
	LC2.setRow(0,3,B01110000);
}
void L_TWO(){
	LC1.setRow(0,2,B01110000);
	LC1.setRow(0,3,B10001000);
	LC1.setRow(0,4,B00001000);
	LC2.setRow(0,0,B00010000);
	LC2.setRow(0,1,B00100000);
	LC2.setRow(0,2,B01000000);
	LC2.setRow(0,3,B11111000);
}
void L_THREE(){
	LC1.setRow(0,2,B11111000);
	LC1.setRow(0,3,B00010000);
	LC1.setRow(0,4,B00100000);
	LC2.setRow(0,0,B00010000);
	LC2.setRow(0,1,B00001000);
	LC2.setRow(0,2,B10001000);
	LC2.setRow(0,3,B01110000);
}
void L_FOUR(){
	LC1.setRow(0,2,B00010000);
	LC1.setRow(0,3,B00110000);
	LC1.setRow(0,4,B01010000);
	LC2.setRow(0,0,B10010000);
	LC2.setRow(0,1,B11111000);
	LC2.setRow(0,2,B00010000);
	LC2.setRow(0,3,B00010000);
}
void L_FIVE(){
	LC1.setRow(0,2,B11111000);
	LC1.setRow(0,3,B10000000);
	LC1.setRow(0,4,B10000000);
	LC2.setRow(0,0,B11110000);
	LC2.setRow(0,1,B00001000);
	LC2.setRow(0,2,B10001000);
	LC2.setRow(0,3,B01110000);
}
void R_ZERO(){
	LC1.setColumn(0,6,B00011000);
	LC1.setLed(0,2,7,true);
        LC1.setLed(0,5,3,true);
	LC1.setRow(0,6,B01010000);
	LC1.setRow(0,7,B01100000);
	LC2.setColumn(0,6,B11100000);
	LC2.setColumn(0,7,B01010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100000);
        LC2.setRow(0,7,B00011100);
}
void R_ONE(){
	LC1.setLed(0,3,7,true);
	LC1.setRow(0,5,B01110000);
	LC2.setRow(0,5,B00111100);
	LC2.setLed(0,3,7,true);
	LC2.setLed(0,6,2,true);
}
void R_TWO(){
	LC1.setLed(0,3,6,true);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setRow(0,7,B01100000);
	
	LC2.setLed(0,3,6,true);
	LC2.setColumn(0,7,B00110000);
	LC2.setRow(0,5,B00101000);
	LC2.setRow(0,6,B00100100);
	LC2.setLed(0,7,2,true);
}
void R_THREE(){
	LC1.setLed(0,2,6,true);
	LC1.setLed(0,2,7,true);
	LC1.setRow(0,5,B01010000);
	LC1.setRow(0,6,B00110000);
	LC1.setLed(0,7,3,true);

	LC2.setLed(0,2,6,true);
	LC2.setLed(0,3,7,true);
	LC2.setLed(0,5,2,true);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);
}
void R_FOUR(){
	LC1.setLed(0,4,7,true);
	LC1.setLed(0,5,2,true);
	LC1.setRow(0,6,B01110000);
	
	LC2.setColumn(0,6,B11000000);
	LC2.setLed(0,1,7,true);
	LC2.setLed(0,5,4,true);
	LC2.setRow(0,6,B00111100);
	LC2.setLed(0,7,4,true);
}
void R_FIVE(){
	LC1.setColumn(0,6,B00111000);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setLed(0,7,3,true);
	
	LC2.setColumn(0,6,B10100000);
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);
}
void R_SIX(){
	LC1.setLed(0,4,6,true);
	LC1.setLed(0,3,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	
	LC2.setColumn(0,6,B11100000);
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);	
}
void R_SEVEN(){
	LC1.setLed(0,2,6,true);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setRow(0,6,B01010000);
	LC1.setRow(0,7,B00110000);
	
	LC2.setColumn(0,7,B01110000);
	LC2.setLed(0,5,5,true);
}
void R_EIGHT(){
	LC1.setColumn(0,6,B00011000);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setRow(0,7,B01100000);
	
	LC2.setColumn(0,6,B01100000);
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00100100);
	LC2.setRow(0,7,B00011000);	
}
void R_NINE(){
	LC1.setColumn(0,6,B00011000);
	LC1.setLed(0,2,7,true);
	LC1.setLed(0,5,3,true);
	LC1.setLed(0,6,3,true);
	LC1.setRow(0,7,B01100000);
	
	LC2.setColumn(0,7,B10010000);
	LC2.setRow(0,5,B00100100);
	LC2.setRow(0,6,B00010100);
	LC2.setRow(0,7,B00001100);
}
// for dot mode - clear the 4 dots only.
void P_CLEAR() {
	LC1.setLed(0,5,0,false); // top left
	LC1.setLed(0,5,7,false); // top right
	LC2.setLed(0,5,0,false); // top left	
	LC2.setLed(0,5,7,false); // bottom right
}

//=============================================================|
//^^^^^^^^^^^^^^^^^^^^^^^^^^^ end led ^^^^^^^^^^^^^^^^^^^^^^^^^|







//========================== LED DEBUG =========================|

//Turns on every single light to identify dead leds
void mode_ledDebug() 
{
LC1.setRow(0,0,B11111111);
LC1.setRow(0,1,B11111111);
LC1.setRow(0,2,B11111111);
LC1.setRow(0,3,B11111111);
LC1.setRow(0,4,B11111111);
LC1.setRow(0,5,B11111111);
LC1.setRow(0,6,B11111111);
LC1.setRow(0,7,B11111111);
LC2.setRow(0,0,B11111111);
LC2.setRow(0,1,B11111111);
LC2.setRow(0,2,B11111111);
LC2.setRow(0,3,B11111111);
LC2.setRow(0,4,B11111111);
LC2.setRow(0,5,B11111111);
LC2.setRow(0,6,B11111111);
LC2.setRow(0,7,B11111111);
}
//==============================================================|
//^^^^^^^^^^^^^^^^^^^^^^ end led debug ^^^^^^^^^^^^^^^^^^^^^^^^^|



void mode_debug() 
{
  boolean debugSerial = true;
  boolean touchDebug = true;
  
  touchDebugMethod();
  RTCDebugMethod();
  
 // mode_default();
  
    LC1.setLed(0,5,0,false); // top left
    LC1.setLed(0,5,7,false); // top right
    LC2.setLed(0,5,0,false); // top left	
    LC2.setLed(0,5,7,false); // bottom right
    
    delay(500);
     LC1.setLed(0,5,0,true); // top left
     LC1.setLed(0,5,7,true); // top right
     LC2.setLed(0,5,0,true); // top left	
     LC2.setLed(0,5,7,true); // bottom right 
    delay(500);
}




void RTCDebugMethod()
{

 Serial.print(global_hour, DEC);
 
   byte loop_second, loop_minute, loop_hour, loop_dayOfWeek, loop_dayOfMonth, loop_month, loop_year;

  //Retrieves time from 1307 every cycle 
  getDateDs1307(loop_second, loop_minute, loop_hour, loop_dayOfWeek, loop_dayOfMonth, loop_month, loop_year);




	   Serial.print(":");
	   Serial.print(global_minute, DEC);
	   Serial.print(":");
	   Serial.print(global_second, DEC);
	   Serial.print("  ");
	   Serial.print(global_month, DEC);
	   Serial.print("/");
	   Serial.print(global_dayOfMonth, DEC);
	   Serial.print("/");
	   Serial.print(global_year, DEC);
	   Serial.print("  Day_of_week:");
	   Serial.println(loop_dayOfWeek, DEC);
	
	delay(1000);

}

void touchDebugMethod()
{
  
  int rightCorner = analogRead(touchRight);
	int leftCorner = analogRead(touchLeft);

   Serial.print(leftCorner + "\t" + rightCorner);
   //Serial.println(rightCorner);
   // Serial.println();
   // Serial.println();
   // Serial.println("right: " + rightCorner);//doesn't work as expected
   // Serial.println("left: " + leftCorner); // doesn't work as expected 
   // Serial.println(); 
}

