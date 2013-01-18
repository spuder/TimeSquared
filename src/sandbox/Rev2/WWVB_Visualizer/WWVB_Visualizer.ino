int analogPin0 = 0;
int pin0Value;

void setup() {
  Serial.begin(9600);
  Serial.println("Starting WWVB Visualizer");
}

void loop() {
  pin0Value = analogRead(analogPin0);
   Serial.println(pin0Value);
   delay(100);
}



