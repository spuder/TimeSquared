
// CapSense.pde
// Paul Badger 2007

// Fun with capacitive sensing and some machine code - for the Arduino (or Wiring Boards).
// Note that the machine code is based on Arduino Board and will probably require some changes for Wiring Board
// This works with a high value (1-10M) resistor between an output pin and an input pin.
// When the output pin changes it changes the state of the input pin in a time constant determined by R * C
// where R is the resistor and C is the capacitance of the pin plus any capacitance present at the sensor.
// It is possible when using this setup to see some variation in capacitance when one's hand is 3 to 4 inches from the sensors
// Try experimenting with larger sensors. Lower values of R will probably yield higher reliability.
// Use 1 M resistor (or less maybe) for absolute touch to activate.
// With a 10 M resistor the sensor will start to respond 1-2 inches away

// Setup
// Connect a 10M resistor between pins 8 and 9 on the Arduino Board
// Connect a small piece of alluminum or copper foil to a short wire and also connect it to pin 9

// When using this in an installation or device it's going to be important to use shielded cable if the wire between the sensor is 
// more than a few inches long, or it runs by anything that is not supposed to be sensed. 
// Calibration is also probably going to be an issue.
// Instead of "hard wiring" threshold values - store the "non touched" values in a variable on startup - and then compare.
// If your sensed object is many feet from the Arduino Board you're probably going to be better off using the Quantum cap sensors.

// Machine code and Port stuff from a forum post by ARP  http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1169088394/0#0




int  i;
unsigned int x, y;
float accum, fout, fval = .07;    // these are variables for a simple low-pass (smoothing) filter - fval of 1 = no filter - .001 = max filter
int pin7 = 7;
//=========================================================================================================================== setup
void setup() {
 Serial.begin(9600);
 
 pinMode(pin7, OUTPUT); 

 DDRB=B101;     // DDR is the pin direction register - governs inputs and outputs- 1's are outputs
 // Arduino pin 8 output, pin 9 input, pin 10 output for "guard pin"
 //  preceding line is equivalent to three lines below
 //  pinMode(8, OUTPUT);     // output pin
 //  pinMode(9, INPUT);      // input pin
 //  pinMode(10, OUTPUT);    // guard pin
 digitalWrite(10, LOW);  //could also be HIGH - don't use this pin for changing output though
}
//=========================================================================================================================== loop
void loop() {
checkTouch();

 

 fout =  (fval * (float)x) + ((1-fval) * accum);  // Easy smoothing filter "fval" determines amount of new data in fout
 accum = fout;   

 Serial.print((long)x, DEC);    // raw data - Low to High
 Serial.print( "   ");
 Serial.print((long)y, DEC);    // raw data - High to Low
 Serial.print( "   ");
 Serial.println( (long)fout, DEC); // Smoothed Low to High
}
//**************************************************************** success
void success(){
  Serial.println("Spencer You did it");
}
  
//****************************************************************************** checkTouch
void checkTouch() {
 y = 0;        // clear out variables
 x = 0;

     for (i=0; i < 4 ; i++ ){       // do it four times to build up an average - not really neccessary but takes out some jitter

     // LOW-to-HIGH transition
     PORTB = PORTB | 1;                    // Same as line below -  shows programmer chops but doesn't really buy any more speed
       // digitalWrite(8, HIGH);    
       // output pin is PortB0 (Arduino 8), sensor pin is PortB1 (Arduinio 9)                                   

     while ((PINB & B10) != B10 ) {        // while the sense pin is not high
       //  while (digitalRead(9) != 1)     // same as above port manipulation above - only 20 times slower!                
       x++;
     }
  
   delay(1);

     //  HIGH-to-LOW transition
     PORTB = PORTB & 0xFE;                // Same as line below - these shows programmer chops but doesn't really buy any more speed
       //digitalWrite(8, LOW);   
     
     while((PINB & B10) != 0 ){            // while pin is not low  -- same as below only 20 times faster
       // while(digitalRead(9) != 0 )      // same as above port manipulation - only 20 times slower!
       y++;  
     }

     delay(1);
     }
     
    if (x > 300) {               // ********** Spencer change this code here to do what you want. Something like calling seconds mode*********************** may need to change from 300 to different number
      digitalWrite(pin7, HIGH);
      success();
    }
    else digitalWrite(pin7, LOW);

}

