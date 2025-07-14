/**
 * @file my_arduino_project.ino
 * @author Your Name
 * @brief A professional Arduino sketch.
 * @version 0.1
 * @date 2025-07-11
 */

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Serial.println("Hello, Arduino!");
}

void loop() {
  // put your main code here, to run repeatedly:
  Serial.println("Hello, Arduino!");
  delay(1000);
}
