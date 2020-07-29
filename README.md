# CO2Monitor
Matlab/Arduino Files for a CO2 Monitor. Built with an ESP32, BlueSMiRF silver, Matlab App Designer, and Arduino 

Steps:
1. Download Arduino IDE, Matlab, and source code
2. Program ESP32 or similar micrcontroller with Arduino - requires board/USB connection in Boards Manager
3. Open Matlab file - requires bluetooth module remote id to connect
4. Run - click start to begin recording data

Communicates via serial UART. Configurable for bluetooth, USB, and other serial communication devices. 

Notes:
 - Ensure Baud rate for bluetooth and serial device is consistent
 - Ensure pin layout is consistent with code
 - Update Bluetooth device remote ID to fit your device (instrhwinfo in Matlab console to find nearby bluetooth devices)
