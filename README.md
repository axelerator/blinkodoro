# blinkodoro

Dies ist eine kleine App zur Anwendung der [Pomodoro Technik](https://de.wikipedia.org/wiki/Pomodoro-Technik).
Jedoch wird zur Indikation des Ablaufens eines Intervals keine Küchenuhr sondern ein [Blink1](http://blink1.thingm.com/) verwendet.

Die Länge der Intervalle und die Farben lassen sich in der Anwendung konfigurieren.

![Screenshot](https://raw.githubusercontent.com/axelerator/blinkodoro/master/media/screenshot.jpg)


# Installation

Fertige Binaries:

* [Mac OSX](https://www.dropbox.com/s/bmxublmo6jtrlfw/blinkodoro.dmg?dl=0)
* [Win 64Bit](https://www.dropbox.com/s/5wa9bh28ugbswyo/blinkodoro-win32-x64.zip?dl=0)
* [Linux 64Bit](https://www.dropbox.com/s/suf6wq5yo9kakcr/blinkodoro-linux-x64.zip?dl=0)

# Bauen

Ich hatte noch keine Zeit die Paketabhängigkeiten richtig zu konfigurieren.

Momentan müssen folgende npm Pakete vorinstalliert sein:

    * coffee-reactify   
    * electron-prebuilt 
    * node-blink1       
    * node-hid          
    * react
