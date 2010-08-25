/*



   | The Word Clock |
	A wall clock with no hands or numbers, only letters. Lights up the letters that spell out the time.
	
   | Examples | 
	"IT IS TEN O'CLOCK" 
	"IT IS HALF PAST NINE"
	"IT IS A QUARTER TO FOUR"

   | The circuit: |
		This program requires 19 Kilobytes of memory, thus an Atmel AtMega 328 is required. 
	
	*D3 - 
	*D4 - 
	*D5 _ 
	*D6 _ 
	*D7 _ 
	*D8 _ 
	*D9 _ 
	*D10 _ 
	*D11 _ 
	*D12 _ 
	*D13 _ 

	*A0 _ 
	*A1 _ 
	*A2 _ 
	*A3 - 
	*A4 - 

	Created 11 May 2010
	By S. Owen
	Modified day month year
	
	

		I am very grateful for these trail blazers, who did a lot of the heavy coding for me:

	


	Credits 
	Marcus Liang - LED Schematics, 7219 interfacing
	Vin Marshall - WWVB
		2010 Vin Marshall (vlm@2552.com, www.2552.com)





**** FUNCTION INDEX ****

setup()
loop()

	setBrightness()
	updateDisplay()
	updateRTC()
		WWVB functions
		processBit()
		logFrameError()
		sumFrameErrors()
		debugPrintFrame()
		buffer()
		incrementWwvbMinute()
		wwvbChange()
	bcd2dec()
	dec2bcd()
	getRTC()
	getWWVBTime()
	mode_default()
	mode_seconds()
	setDateDS1307()
	getDateDs1307()

*/



	// Libraries, other instructions this program refers to
#include <CapSense.h> // Library for capasitive touch sensors
#include <Wire.h> // Library for i2c comunications. 
#include <LedControl.h> // Library for the max7219's only supports 1 in chain.
#define DS1307 0x68 // Address of 1307

// RTC I2C Slave Address
// #define DS1307 0x68 >> 1
// #define DS1307 0xD0 >> 1 // Origional line. 

#include <DS1307.h>
#include <stdio.h>

//#include <binary.h>
//#include <WProgram.h>

boolean debug = true; // true while debuging, set to false when program is 100%. (debug is slower)

		// Tell the microcontroller what each of its pins are doing

  //7219 upper
const int CLOCKPIN1 = 2; 	// max7219 #1 Clock 
const int LOADPIN1 = 3; 	// max7219 #1 Load
const int DINPIN1 = 4; 		// max7219 #1 Data In

  //7219 lower
const int CLOCKPIN2 = 5; 	// max7219 #2 Clock
const int LOADPIN2 = 6; 	// max7219 #2 Load
const int DINPIN2 = 7; 		// max7219 #2 Data In



	// Touch sensor Corners
//CapSense cs_8_9 = CapSense(8,9);        // 10M resistor between pins 8 and 9
//CapSense cs_10_11 = CapSense(10,11);        // 10M resistor between pins 10 and 11

const int WWVBPIN = 9; //WWVB MODUAL INPUT

const int touchRight = 12;
	int previousRight; // Declare reference variable
		int x;
const int touchLeft = 11;
	int previousLeft;
		int y;

//const int lightPin = 13; // *Some arduinos have a built in 1k resistor on pin 13
		boolean displayOn;

const int photoSens = 0; //PHOTO SENSOR
const int analogPin1 = 1;
const int analogPin2 = 2;
const int analogPin3 = 3;
const int SDAPIN = 4; //1307 SDA
const int SCLPIN = 5; //1307 SCL



// RTC Memory Registers
#define RTC_SECS        0
#define RTC_MINS        1
#define RTC_HRS         2
#define RTC_DAY         3
#define RTC_DATE        4
#define RTC_MONTH       5
#define RTC_YEAR        6
#define RTC_SQW         7


// Month abbreviations
char *months[12] = {
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


//______________________________ Global Variables _________________

	// Convert normal decimal numbers to binary coded decimal - 1307
		byte decToBcd(byte val) {
  				return ( (val/10*16) + (val%10) );
		}

	// Convert binary coded decimal to normal decimal numbers - 1307
		byte bcdToDec(byte val){
  			return ( (val/16*10) + (val%16) );
		}

	//int lHour, lMin; 1307
		int cHour, cMin, cSec;

	// Global vars for tracking; 1307
		unsigned long ledLastUpdate = 0; 
	//int currentLEDIntensity = LEDINT2;
	//int currentMode = MODEDEFAULT;
		boolean forceUpdate = true;

		int mode = 0; // var for touch counter

		LedControl LC1=LedControl(CLOCKPIN1,LOADPIN1,DINPIN1,1); //clock[5], load[6], data[7]
		LedControl LC2=LedControl(CLOCKPIN2,LOADPIN2,DINPIN2,1); //clock[2], load[3], data[4]

		unsigned long delaytime=100; // Wait between updates of display

		int brightness = 1; //Brightness
		int photoSensValue; // Analog value of resistor


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
		byte second = 0x00;
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


		/* WWVB time format struct - acts as an overlay on wwvbRxBuffer to extract time/date data.
		 * This points to a 64 bit buffer wwvbRxBuffer that the bits get inserted into as the
		 * incoming data stream is received.  (Thanks to Capt.Tagon @ duinolab.blogspot.com)
		 */
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


	// Start setup()____________Start setup()_____________Start setup()___________
	
	void setup() {
	if (debug = true) {
		Serial.begin(9600);
	}

	pinMode (CLOCKPIN2, OUTPUT);
	pinMode (LOADPIN2, OUTPUT);
	pinMode (DINPIN2, OUTPUT);
	pinMode (CLOCKPIN1, OUTPUT);
	pinMode (LOADPIN1, OUTPUT);
	pinMode (DINPIN1, OUTPUT);

	pinMode(WWVBPIN, INPUT);
	pinMode(touchRight, INPUT);
	
	
	displayOn = true;
	
		// Touch setup
	previousRight = LOW; // Initialize refrence variable, 
		x = 0; // Initialize refrence variable, 
	previousLeft = LOW;
		y = 0;

//pinMode(digitalPin13, ???????);


	// Turn on LED controller
	LC1.shutdown(0,false);
	LC2.shutdown(0,false);
	
	//setLEDIntensity()
	LC1.setIntensity(0,8);
	LC2.setIntensity(0,8);
	// Clear Display
	LC1.clearDisplay(0);
	LC2.clearDisplay(0);
	
	//1307
	byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
	Wire.begin();
	
	
	
	 // Setup the WWVB Signal In Handling
	  pinMode(WWVBPIN, INPUT);
	  attachInterrupt(0, wwvbChange, CHANGE);

	  // Setup the WWVB Buffer
	  lastFrameBuffer = 0;
	  receiveBuffer = 0;
	  wwvbFrame = (struct wwvbBuffer *) &lastFrameBuffer;

	
	
	
	// Set Date
	second = 40;
	  minute = 00;
	  hour = 0;
	  dayOfWeek = 1;
	  dayOfMonth = 22;
	  month = 5;
	  year = 10;
//	setDateDs1307(second, minute, hour, dayOfWeek, dayOfMonth, month, year); // Actually programs the 1307, run once then comment out. 


}
	// End setup()________________End setup()___________________________End setup()_______


//----------------------------------------------------


	// Start loop()_______________Start loop()__________________________loop()______
void loop() {


		// read light intensity 
	if (displayOn = true) { 
		photoSensValue = analogRead(photoSens); 
		brightness = map(photoSensValue, 0, 1024, 8, 7); // Minimum 7, because leds are too dim
	//	brightness = map(photoSensValue, 0, 1024, 8, 0); // Converts the 1023 analog values of sensor, to 8 brightness settings
										// Intentionally put 1024 because sensor can not reach it, thus brightness never reach 0
		// set brightness
		setBrightness();
	}

	
		
	
	//if (debug = true){
	//	Serial.print(millis() - start); // check on performance in milliseconds
	//	Serial.print("\t");
	//	Serial.print(rightCorner); // Shows value of left button
	//	Serial.print("\t");
	//	Serial.println(leftCorner); // Shows value of right button
	//	Serial.print("Photo Sensor ");
		// Serial.print(photoSensValue);
		// Serial.println(); 
		// Serial.print("brightness ");
		// Serial.print(brightness);
		// Serial.println(); 
		
	}
	
	
		// get the time
	  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;

	//   getDateDs1307(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year);
	// if (debug = true) {
	//   Serial.print(hour, DEC);
	//   Serial.print(":");
	//   Serial.print(minute, DEC);
	//   Serial.print(":");
	//   Serial.print(second, DEC);
	//   Serial.print("  ");
	//   Serial.print(month, DEC);
	//   Serial.print("/");
	//   Serial.print(dayOfMonth, DEC);
	//   Serial.print("/");
	//   Serial.print(year, DEC);
	//   Serial.print("  Day_of_week:");
	//   Serial.println(dayOfWeek, DEC);
	// }
	// 	delay(1000);

	


		// Check Corners
	int rightCorner = digitalRead(touchRight);
	int leftCorner = digitalRead(touchLeft);

		if (rightCorner == HIGH && previousRight == LOW) {
			// if (x = 8) { // Periodically resets the counter so it doen't get too big
			// 		x = 0;
			// 	}
		
			x = (x + 1); // x++ didn't seem to work
			forceUpdate = true; // Mandatory clear and rewrite leds
		}
	
		if (leftCorner == HIGH && previousLeft == LOW) {
			// if (y = 8) {
			// 			y = 0;
			// 		}
			y = (y + 1);
			forceUpdate = true; // Mandatory clear and rewrite leds
		
		}
	
	
	
	if ( (x % 2) == 0) {
		mode_default();
		// Serial.println("Ahoy, looks like something is happening");
		// 	Serial.print(x);
		// 	Serial.println();
	}
	else { 
		mode_seconds();
	}
	
	if ( (y % 2) == 0) {
		displayOn = true;
		LC1.shutdown(0,false);
		LC2.shutdown(0,false);
	}
	else{
		displayOn = false;
		LC1.shutdown(0,true);
		LC2.shutdown(0,true);
	}

	previousRight = rightCorner; // Remember what corner was doing last time we checked
	previousLeft = leftCorner;

		// get wwvb time every 2 hours
			getWWVBTime();
}

// end loop() ------------------end loop() ------------------end loop()-------------------



//----------------------------------------------------



// mode_default() =================== mode_default() =====================mode_default()

void setBrightness() {
	LC1.setIntensity(0,brightness);
	LC2.setIntensity(0,brightness);
}

void updateDisplay() {

  // Turn off the front panel light marking a successfully 
  // received frame after 10 seconds of being on.
 // if (bcd2dec(second) >= 10) {    // Sync light
   // digitalWrite(lightPin, LOW);
 // } 

  // Update the LCD 
  //lcd.clear();

  // Update the first row
 // lcd.setCursor(0,0);
  char *time = buildTimeString();
  Serial.println(time);

  // Update the second row
  // Cycle through our list of status messages
 //lcd.setCursor(0,1);
  int cycle = bcd2dec(second) / 10; // This gives us 6 slots for messages
  char msg[17]; // 16 chars per line on display

  switch (cycle) {

    // Show the Date
    case 0:
    {
      sprintf(msg, "%s %0.2i 20%0.2i", 
              months[bcd2dec(month)-1], bcd2dec(date), bcd2dec(year));
      break;
    }

    // Show the WWVB signal strength based on the # of recent frame errors
    case 1:
    {
      int signal = (10 - sumFrameErrors()) / 2;
      sprintf(msg, "WWVB Signal: %i", signal);
      break;
    }

    // Show LeapYear and LeapSecond Warning bits
    case 2:
    {
      const char *leapyear = ( ((byte) wwvbFrame->Leapyear) == 1)?"Yes":"No";
      const char *leapsec  = ( ((byte) wwvbFrame->Leapsec) == 1)?"Yes":"No";
      sprintf(msg, "LY: %s  LS: %s", leapyear, leapsec);
      break;
    }

    // Show our Daylight Savings Time status
    case 3: 
    {  
      switch((byte)wwvbFrame->Dst) {
        case 0:
	  sprintf(msg, "DST: No");
          break;
        case 1: 
          sprintf(msg, "DST: Ending");
          break;
        case 2: 
          sprintf(msg, "DST: Starting");
          break;
        case 3: 
          sprintf(msg, "DST: Yes");
          break;
      }
      break;
    }

    // Show the UT1 correction sign and amount
    case 4:
    {
      char sign;
      if ((byte)wwvbFrame->OffSign == 2) {
	sign = '-';
      } else if ((byte)wwvbFrame->OffSign == 5) {
	sign = '+';
      } else {
	sign = '?';
      } 
      sprintf(msg, "UT1 %c 0.%i", sign, (byte) wwvbFrame->OffVal);
      break;
    }

    // Show the time and date of the last successfully received 
    // wwvb frame
    case 5:
    { 
      sprintf(msg, "[%s]", lastTimeUpdate);
      break; 
    }
  }
  
  Serial.print(msg);

}


void setRTC() {  //*********************************************** there is a problem here(((((((((((())))))))))))

  // Begin the Transmission      
  Wire.beginTransmission(DS1307);

  // Start at the beginning
  Wire.send(RTC_SECS);

  // Send data for each register in order
  Wire.send(second);
  Wire.send(minute);
  Wire.send(hour);
  Wire.send(day);
  Wire.send(date);
  Wire.send(month);
  Wire.send(year);
  Wire.send(ctrl);

  // End the transmission
  Wire.endTransmission();
}


/*
 * updateRTC
 * 
 * Update the time stored in the RTC to match the received WWVB frame.
 */

void updateRTC() {

  // Find out how long since the frame's On Time Marker (OTM)
  // We'll need this adjustment when we set the time.
  unsigned int timeSinceFrame = millis() - frameEndTime;
  byte secondsSinceFrame = timeSinceFrame / 1000;
  if (timeSinceFrame % 1000 > 500) {
    secondsSinceFrame++;
  }

  // The OTM for a minute comes at the beginning of the frame, meaning that
  // the WWVB time we have is now 1 minute + `secondsSinceFrame` seconds old.
  incrementWwvbMinute();

  // Set up data for the RTC clock write
  second = secondsSinceFrame;
  minute = ((byte) wwvbFrame->MinTen << 4) + (byte) wwvbFrame->MinOne;
  hour = ((byte) wwvbFrame->HourTen << 4) + (byte) wwvbFrame->HourOne;
  day = 0; // we're not using day of week at this time.

  // Translate wwvb day of year into a month and a day of month
  // This routine is courtesy of Capt.Tagon
  int doy = ((byte) wwvbFrame->DayHun * 100) +
             ((byte) wwvbFrame->DayTen * 10) +
             ((byte) wwvbFrame->DayOne);

  int i = 0;
  byte isLeapyear = (byte) wwvbFrame->Leapyear;
  while ( (i < 14) && (eomYear[i][isLeapyear] < doy) ) {
    i++;
   }
  if (i>0) {
    date = dec2bcd(doy - eomYear[i-1][isLeapyear]);
    month = dec2bcd((i > 12)?1:i);
  }
 
  year = ((byte) wwvbFrame->YearTen << 4) + (byte) wwvbFrame->YearOne;

  // And write the update to the RTC
  setRTC();
	Serial.print("Spencer, you just updated your 1307 with WWVB");

	

  // Store the time of update for the display status line
  sprintf(lastTimeUpdate, "%0.2i:%0.2i %0.2i/%0.2i/%0.2i", 
          bcd2dec(hour), bcd2dec(minute), bcd2dec(month), 
          bcd2dec(date), bcd2dec(year));

	Serial.print("Atomic clock says ");
	Serial.println( hour );

}



/*
 * processBit()
 * 
 * Decode a received pulse.  Pulses are decoded according to the 
 * length of time the pulse was in the low state.
 */

void processBit() {

  // Clear the bitReceived flag, as we're processing that bit.
  bitReceived = false;

  // determine the width of the received pulse
  unsigned int pulseWidth = pulseEndTime - pulseStartTime;

  // Attempt to decode the pulse into an Unweighted bit (0), 
  // a Weighted bit (1), or a Frame marker.

  // Pulses < 0.2 sec are an error in reception.
  if (pulseWidth < 100) {
  buffer(-2);
  bitError++;
  wasMark = false;

  // 0.2 sec pulses are an Unweighted bit (0)
  } else if (pulseWidth < 400) {
    buffer(0);
    wasMark = false;

  // 0.5 sec pulses are a Weighted bit (1)
  } else if (pulseWidth < 700) {
    buffer(1);
    wasMark = false;

  // 0.8 sec pulses are a Frame Marker
  } else if (pulseWidth < 900) {
    
    // Two Frame Position markers in a row indicate an
    // end/beginning of frame marker
    if (wasMark) {

	 // For the display update 
	 lastBit = '*';
	 if (debug) { Serial.print("*"); }
 
	 // Verify that our position data jives with this being 
	 // a Frame start/end marker
	 if ( (framePosition == 6) && 
	      (bitPosition == 60)  &&
              (bitError == 0)) {

           // Process a received frame
	   frameEndTime = pulseStartTime;
           lastFrameBuffer = receiveBuffer;
	 //  digitalWrite(lightPin, HIGH);
           logFrameError(false);

	   if (debug) {
             debugPrintFrame();
           }

	 } else {

           frameError = true;
	 }

	 // Reset the position counters
	 framePosition = 0;
	 bitPosition = 1;
	 wasMark = false;
         bitError = 0;
	 receiveBuffer = 0;

    // Otherwise, this was just a regular frame position marker
    } else {

	 buffer(-1);
	 wasMark = true;
	 
    }

  // Pulses > 0.8 sec are an error in reception
  } else {
    buffer(-2);
    bitError++;
    wasMark = false;
  }

  // Reset everything if we have more than 60 bits in the frame.  This means
  // the frame markers went missing somewhere along the line
  if (frameError == true || bitPosition > 60) {

        // Debugging
        if (debug) { Serial.print("  Frame Error\n"); }

        // Reset all of the frame pointers and flags
        frameError = false;
        logFrameError(true);
        framePosition = 0;
        bitPosition = 1;
        wasMark = false;
        bitError = 0;
        receiveBuffer = 0;
  }

}


/*
 * logFrameError
 *
 * Log the error in the buffer that is a window on the past 10 frames. 
 */

void logFrameError(boolean err) {

  // Add a 1 to log errors to the buffer
  int add = err?1:0;
  errors[errIdx] = add;

  // and move the buffer loop-around pointer
  if (++errIdx >= 10) { 
    errIdx = 0;
  }
}


/* 
 * sumFrameErrors
 * 
 * Turn the errors in the frame error buffer into a number useful to display
 * the quality of reception of late in the status messages.  Sums the errors
 * in the frame error buffer.
 */

int sumFrameErrors() {

  // Sum all of the values in our error buffer
  int i, rv;
  for (i=0; i< 10; i++) {
    rv += errors[i];
  }

  return rv;
} 


/*
 * debugPrintFrame
 * 
 * Print the decoded frame over the seriail port
 */

void debugPrintFrame() {

  char time[255];
  byte minTen = (byte) wwvbFrame->MinTen;
  byte minOne = (byte) wwvbFrame->MinOne;
  byte hourTen = (byte) wwvbFrame->HourTen;
  byte hourOne = (byte) wwvbFrame->HourOne;
  byte dayHun = (byte) wwvbFrame->DayHun;
  byte dayTen = (byte) wwvbFrame->DayTen;
  byte dayOne = (byte) wwvbFrame->DayOne;
  byte yearOne = (byte) wwvbFrame->YearOne;
  byte yearTen = (byte) wwvbFrame->YearTen;

  byte wwvb_minute = (10 * minTen) + minOne;
  byte wwvb_hour = (10 * hourTen) + hourOne;
  byte wwvb_day = (100 * dayHun) + (10 * dayTen) + dayOne;
  byte wwvb_year = (10 * yearTen) + yearOne;	

  sprintf(time, "\nFrame Decoded: %0.2i:%0.2i  %0.3i  20%0.2i\n", 
          wwvb_hour, wwvb_minute, wwvb_day, wwvb_year);
  Serial.print(time);

}


/*
 * buffer
 *
 * Places the received bits in the receive buffer in the order they
 * were recived.  The first received bit goes in the highest order 
 * bit of the receive buffer.
 */

void buffer(int bit) {
  
  // Process our bits 
  if (bit == 0) {
    lastBit = '0';
    if (debug) { Serial.print("0"); }

  } else if (bit == 1) {
    lastBit = '1';
    if (debug) { Serial.print("1"); }

  } else if (bit == -1) {
    lastBit = 'M';
    if (debug) { Serial.print("M"); }
    framePosition++;

  } else if (bit == -2) {
    lastBit = 'X';
    if (debug) { Serial.print("X"); }
  }

  // Push the bit into the buffer.  The 0s and 1s are the only
  // ones we care about.  
  if (bit < 0) { bit = 0; }
  receiveBuffer = receiveBuffer | ( (unsigned long long) bit << (64 - bitPosition) );

  // And increment the counters that keep track of where we are
  // in the frame.
  bitPosition++;
}


/*
 * incrementWwvbMinute
 *
 * The frame On Time Marker occurs at the beginning of the frame.  This means
 * that the time in the frame is one minute old by the time it has been fully
 * received.  Adding one to the minute can be somewhat complicated, in as much 
 * as it can roll over the successive hours, days, and years in just the right 
 * circumstances.  This handles that.
 */

void incrementWwvbMinute() {
  
  // Increment the Time and Date
  if (++(wwvbFrame->MinOne) == 10) {
	  wwvbFrame->MinOne = 0;
	  wwvbFrame->MinTen++;
  }

  if (wwvbFrame->MinTen == 6) {
	  wwvbFrame->MinTen = 0;
	  wwvbFrame->HourOne++;
  }

  if (wwvbFrame->HourOne == 10) {
	  wwvbFrame->HourOne = 0;
	  wwvbFrame->HourTen++;
  }
  
  if ( (wwvbFrame->HourTen == 2) && (wwvbFrame->HourOne == 4) ) {
	  wwvbFrame->HourTen = 0;
	  wwvbFrame->HourOne = 0;
	  wwvbFrame->DayOne++;
  }

  if (wwvbFrame->DayOne == 10) {
	  wwvbFrame->DayOne = 0;
	  wwvbFrame->DayTen++;
  }

  if (wwvbFrame->DayTen == 10) {
	  wwvbFrame->DayTen = 0;
	  wwvbFrame->DayHun++;
  }

  if ( (wwvbFrame->DayHun == 3) &&
       (wwvbFrame->DayTen == 6) &&
       (wwvbFrame->DayOne == (6 + (int) wwvbFrame->Leapyear)) ) {
	   // Happy New Year.
	   wwvbFrame->DayHun = 0;
	   wwvbFrame->DayTen = 0;
	   wwvbFrame->DayOne = 1;
           wwvbFrame->YearOne++;
  }

  if (wwvbFrame->YearOne == 10) {
    wwvbFrame->YearOne = 0;
    wwvbFrame->YearTen++;
  }

  if (wwvbFrame->YearTen == 10) {
    wwvbFrame->YearTen = 0;
  }

}


/*
 * wwvbChange
 * 
 * This is the interrupt servicing routine.  Changes in the level of the 
 * received WWVB pulse are recorded here to be processed in processBit().
 */

void wwvbChange() {

  int signalLevel = digitalRead(WWVBPIN);

  // Determine if this was triggered by a rising or a falling edge
  // and record the pulse low period start and stop times
  if (signalLevel == LOW) {
    pulseStartTime = millis();
  } else {
    pulseEndTime = millis();
    bitReceived = true;
  }

}



/*
 * bcd2dec
 * 
 * Utility function to convert 2 bcd coded hex digits into an integer
 */

int bcd2dec(int bcd) {
      return ( (bcd>>4) * 10) + (bcd % 16);
}


/*
 * dec2bcd
 * 
 * Utility function to convert an integer into 2 bcd coded hex digits
 */

int dec2bcd(int dec) {
      return ( (dec/10) << 4) + (dec % 10);
} 



/*
 * getRTC
 * 
 * Read data from the DS1307 RTC over the I2C 2 wire interface.
 * Data is stored in the uC's global clock variables.
 */

void getRTC() {

  // Begin the Transmission
  Wire.beginTransmission(DS1307);

  // Point the request at the first register (seconds)
  Wire.send(RTC_SECS);

  // End the Transmission and Start Listening
  Wire.endTransmission();
  Wire.requestFrom(DS1307, 8);
  second = Wire.receive();
  minute = Wire.receive();
  hour = Wire.receive();
  day = Wire.receive();
  date = Wire.receive();
  month = Wire.receive();
  year = Wire.receive();
  ctrl = Wire.receive();
}


/*
 * buildTimeString
 *
 * Prepare the string for displaying the time on line 1 of the LCD
 */

char* buildTimeString() {
  char rv[255];
  sprintf(rv,"%0.2i:%0.2i:%0.2i UTC   %c",
        bcd2dec(hour),
        bcd2dec(minute),
        bcd2dec(second),
        lastBit);
  return rv;
}







// Start getWWVBTime() ------------------ Start getWWVBTime() ------------------ Start getWWVBTime()

void getWWVBTime() {
	// Serial.println("  spencer, you are checking wwvb");
	if (bitReceived == true) {
	    processBit();
	  }

	  // Read from the RTC and update the display 4x per second
	  if (millis() - lastRtcUpdateTime > 250) {

	    // Snag the RTC time and store it locally
	    getRTC();

	    // And record the time of this last update.
	    lastRtcUpdateTime = millis();

	    // Update RTC if there has been a successfully received WWVB Frame
	    if (frameEndTime != 0) {
	      updateRTC();
	      frameEndTime = 0;
		Serial.println("Your doing it peter!");
	    }

	    // Update the display
	    updateDisplay();

	  }

}

// End getWWVBTime()--------------------End getWWVBTime() ------------------ End getWWVBTime()

//---------------------------------------------------

// Start mode_default()=============== Start mode_default()================= Start mode_default()

void mode_default() {
	

   int hour = RTC.get(DS1307_HR,true);
   int min = RTC.get(DS1307_MIN,true);
   int sec = RTC.get(DS1307_SEC,false); // kinda redundant?
   
   if ((hour == cHour) && (min == cMin) && (forceUpdate == false))
		return;
   	
   int tpast5mins = min % 5; // remainder
   int t5mins = min - tpast5mins;
   int tHour = hour;
   
   if (tHour > 12) tHour = tHour - 12;
   else if (tHour == 0) tHour = 12;
   
   LED_CLEAR();
   W_ITIS();
   
   if (t5mins == 5 || t5mins == 55)     	 M_FIVE();        // 5 past or 5 to..
   else if (t5mins == 10 || t5mins == 50)    M_TEN();        // 10 past or 10 to..
   else if (t5mins == 15 || t5mins == 45)    M_AQUARTER();    // etc..
   else if (t5mins == 20 || t5mins == 40)    M_TWENTY();
   else if (t5mins == 25 || t5mins == 35)    M_TWENTYFIVE();
   else if (t5mins == 30)    M_HALF();

   // past or to or o'clock?
   if (t5mins == 0)	W_OCLOCK();
   else if (t5mins > 30)	W_TO();
   else W_PAST();
   
   if (t5mins > 30)	{
		tHour = tHour+1;
		if (tHour > 12) tHour = 1;
   }

   // light up the hour word
   if (tHour == 1) H_ONE(); else if (tHour == 2) H_TWO(); else if (tHour == 3) H_THREE(); else if (tHour == 4) H_FOUR();
   else if (tHour == 5) H_FIVE(); else if (tHour == 6) H_SIX(); else if (tHour == 7) H_SEVEN(); else if (tHour == 8) H_EIGHT();
   else if (tHour == 9) H_NINE(); else if (tHour == 10) H_TEN(); else if (tHour == 11) H_ELEVEN(); else if (tHour == 12) H_TWELVE();
   
   // light up aux minute LED
   // ugly but quicker 
   if (tpast5mins == 0 ) { }
   else if (tpast5mins == 1) { P_ONE(); }
   else if (tpast5mins == 2) { P_ONE(); P_TWO(); }
   if (tpast5mins == 3) { P_ONE(); P_TWO(); P_THREE(); }
   if (tpast5mins == 4) { P_ONE(); P_TWO(); P_THREE(); P_FOUR(); }

   // save last updated time
   cHour = hour;
   cMin = min;
   cSec = sec;
   forceUpdate = false;
}
// end mode_default()=============== end mode_default() ==================== end mode_default()




//----------------------------------------------------





// Start mode_seconds()------------------ Start mode_seconds()--------------------- Start mode_seconds()

		// MODE SECONDS
	// Description: The entire face will show the "seconds" the clock is on
void mode_seconds() {
   
   int hour = RTC.get(DS1307_HR,true);
   int min = RTC.get(DS1307_MIN,false);
   int sec = RTC.get(DS1307_SEC,true); 

   // no seconds change, do nothing
   if (sec == cSec) return;
 
   int tsec = sec;
    
   // decide if we only want to draw the right number of both numbers.
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
   cHour = hour;
   cMin = min;
   cSec = sec;   
   forceUpdate = false;   
   
}
// End mode_seconds()------------------ End mode_seconds()--------------------- End mode_seconds()




//----------------------------------------------------





//1307 ---------1307 --------- 1307 ---------- 1307 --------- 1307 --------- 1307

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
   Wire.beginTransmission(DS1307);
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

	// Gets the date and time from the ds1307
void getDateDs1307 (byte *second,
          			byte *minute,
          			byte *hour,
          			byte *dayOfWeek,
          			byte *dayOfMonth,
          			byte *month,
          			byte *year) 
{
  		// Reset the register pointer
  	Wire.beginTransmission(DS1307);
  	Wire.send(0);
  	Wire.endTransmission();

  	Wire.requestFrom(DS1307, 7);

  	// A few of these need masks because certain bits are control bits
  *second     = bcdToDec(Wire.receive() & 0x7f);
  *minute     = bcdToDec(Wire.receive());
  *hour       = bcdToDec(Wire.receive() & 0x3f);  // Need to change this if 12 hour am/pm
  *dayOfWeek  = bcdToDec(Wire.receive());
  *dayOfMonth = bcdToDec(Wire.receive());
  *month      = bcdToDec(Wire.receive());
  *year       = bcdToDec(Wire.receive());
}

// end 1307 ------------------end 1307 ------------------  end 1307 -------------------1307-------------------






//----------------------------------------------------







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


// End word layout --------------------- End word layout -------------------- End word layout --------------





