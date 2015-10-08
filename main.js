var app = require('app');  // Module to control application life.
var BrowserWindow = require('browser-window');  // Module to create native browser window.

// Report crashes to our server.
var path             = require( 'path' );
var Menu             = require( 'menu' );
var Tray             = require( 'tray' );
var NativeImage      = require( 'native-image' );
require('crash-reporter').start();
var Blink1 = require('node-blink1');
ipc = require('ipc')

ipc.on('change-task', function(event, arg) {
    if (blink1 == null) {
      return;
    }
    if (arg == 'pomodoro') {
      blink1.playLoop(0,1, 0);
    } else if (arg == 'break' ){
      blink1.playLoop(2,3, 0);
    } else if (arg == 'bigBreak') {
      blink1.playLoop(3,4, 0);
    } else {
      blink1.off();
    }
});
// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
var mainWindow = null;

var appIcon        = null;
var currentBlocker = null;

/**
 * Icons to display inside of the tray
 *
 * @type {Object}
 */
var icons = {
  active    : NativeImage.createFromPath( path.join( __dirname, 'media', 'green.png' ) ),
  notActive : NativeImage.createFromPath( path.join( __dirname, 'media', 'red.png' ) )
}


/**
 * Menu to set inside of tray
 *
 * @type {Object}
 */
var menus = {
  active    : Menu.buildFromTemplate( [
    { label: 'Pause', click : app.pause },
    { label: 'Quit', click : app.quit }
  ] ),
  notActive : Menu.buildFromTemplate( [
    { label: 'Unpause', click : app.unpause },
    { label: 'Quit', click : app.quit }
  ] )
};


/**
 * Initialize the tray
 */
function initTray() {
  if ( app.dock ) {
    app.dock.hide();
  }

  appIcon = new Tray( path.resolve( __dirname, 'media', 'green.png' ) );
  appIcon.setToolTip( 'Blinkodoro' );
  appIcon.setContextMenu( menus.active );
}

function initBlink() {
  if (Blink1.devices().length > 0) {
    blink1 = new Blink1();
  } else {
    return;
  }

  blink1.off();
  blink1.writePatternLine(5200, 255, 0, 255, 0);
  blink1.writePatternLine(5200, 0, 0, 0, 1);

  blink1.writePatternLine(1200, 0, 255, 0, 2);
  blink1.writePatternLine(1200, 0, 0, 0, 3);

  blink1.writePatternLine(5200, 0, 0, 255, 4);
  blink1.writePatternLine(5200, 0, 0, 0, 5);


}


// Quit when all windows are closed.
app.on('window-all-closed', function() {
  if (blink1 != null) {
    blink1.off();
  }
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform != 'darwin') {
    app.quit();
  }
});

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', function() {
  // Create the browser window.
  mainWindow = new BrowserWindow({width: 800, height: 600});
  //initTray();
  initBlink();

  // and load the index.html of the app.
  mainWindow.loadUrl('file://' + __dirname + '/index.html');

  // Open the DevTools.
  //mainWindow.openDevTools();

  // Emitted when the window is closed.
  mainWindow.on('closed', function() {
    if (blink1 != null) {
      blink1.off();
    }
  // 
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should devare the corresponding element.
    mainWindow = null;
  });
});
