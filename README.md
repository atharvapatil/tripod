# Tripod

Repository has the files to communicate between an Arduino & iOS device via Bluetooth. First application is using a pulse monitor sensor and displaying the BPM on the iOS device screen.

## Progress

### Overall Status

* Two way communication between Arduino & iPad.  [See video here](https://photos.app.goo.gl/URevDbxGt3uTu4478)

### Doubts
Hi Nien & Sebastian, some doubts/questions I have.

* On line 203 of ViewController.swift I am getting the data from the button for now but unable to parse it as a string. Looked up some references online but couln't figure it out. The found the method in Data extension to convert the value into integer to print it.
* What is the best way to handle error events in the functions.

### Immediate To-Do's
* Design the user experience(interface, affordances, states, etc)
* Arduino side code and wiring to broadcast the BPM data to serial monitor
