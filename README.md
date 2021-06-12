Here is the demo application done for Embarcadero to test the MQTT Client provided by TMS Software.
The demo is around an application of house control and monitoring to show all MQTT protocol capability.

First open the Home Manager done as an FMX application. 
You can open how many room control as you want. Choose a room type to have a unique display of the room you want to monitor and connect it to the MQTTServer.

Each time you change the temperature of a client , the temperature must change on the display of the home manager.
You can adjust temperature (or curtain opened or closed) on the manager and the client will adjsut it too.

- Improvement to do :
1) Be able to initialize if clients are connected first
2) Be able to select from the client some display images and send them to the manager to have a unique schema by clients


