/*
Light Sensor, a sketch to test analog reads and display the
result with an led

The darker it is in the room, the dimmer the led
Every photo sensor will be different

Bright room 10K = ~700
Dark room 10K = ~80

Bright room 1K = ~150
Dark room 1K = ~4 (too dark, light flickers)

Bright room 8.2K = ~500
Dark room 8.2K = ~55

Layout

PhotoCell -> A3
          \_ 10K resistor -> GND
PhotoCell -> 5V

          
Led +  -> D8
Led -  -> D9
 
 */

void setup() {
   // initialize serial communication
   Serial.begin(115200);
   //Set pin 9 to be an output (not needed for analog writes)
   pinMode(9, OUTPUT);

   //Set pin 9 as the ground, idealy you would hook up to 
   //ground directly to save a pin on the arduino
   digitalWrite(9, LOW);
   
   //Set the led to 50% at startup
   analogWrite(8, 155);

}

// the loop routine runs over and over again forever:
void loop() {
  
  // read the input on analog pin 3:
  // range is 0 - 1023
  int sensorValue = analogRead(A3);
  
  // print out the value you read:
  Serial.println(sensorValue);
  delay(10);        // delay in between reads for stability
  
  // Analog read 0 - 1023, analog write 0 - 254
  analogWrite(8, sensorValue / 4);
}
