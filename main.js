var app = require('app');  // Module to control application life.
var BrowserWindow = require('browser-window');  // Module to create native browser window.

// Report crashes to our server.
var path             = require( 'path' );
var Menu             = require( 'menu' );
var Tray             = require( 'tray' );
var NativeImage      = require( 'native-image' );
require('crash-reporter').start();
var Blink1 = require('node-blink1');
console.log('hello');
var blink1 = new Blink1();
blink1.setRGB(255,255,0);
//blink1.writePatternLine(200, 255, 0, 0, 0);
//blink1.writePatternLine(200, 0, 0, 0, 1);
//blink1.play(0);

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
    { label: 'Pause', click : app.quit },
    { label: 'Quit', click : app.quit }
  ] ),
  notActive : Menu.buildFromTemplate( [
    { label: 'Unpause', click : app.quit },
    { label: 'Quit', click : app.quit }
  ] )
};


var modes = {
  work: {
    duration: 5,
    color: [0, 255, 0],
    nextMode: 'slack'
  },
  slack: {
    duration: 2,
    color: [0,0,255],
    nextMode: 'work'
  }
};


var modeTimer = 0;
var currentMode = modes.work;

function tick() {
  modeTimer += 1;
  console.log('test');
  if (modeTimer > currentMode.duration) {
  console.log('switch to:' + currentMode.nextMode);

    currentMode = modes[currentMode.nextMode];
    blink1.setRGB(currentMode.color[0],currentMode.color[1],currentMode.color[2]);
    modeTimer = 0;
  }
}

/**
 * Initialize the tray
 */
function initTray() {
  if ( app.dock ) {
    app.dock.hide();
  }

  appIcon = new Tray( path.resolve( __dirname, 'media', 'green.png' ) );
  appIcon.setToolTip( 'Blinkodoro' );
  appIcon.setContextMenu( menus.notActive );
  setInterval(function(){
    tick();
  }, 1000); 
}



// Quit when all windows are closed.
app.on('window-all-closed', function() {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
    blink1.off();

  if (process.platform != 'darwin') {
    
    app.quit();
  }
});

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', function() {
  // Create the browser window.
//  mainWindow = new BrowserWindow({width: 800, height: 600});
  initTray();

  // and load the index.html of the app.
 // mainWindow.loadUrl('file://' + __dirname + '/index.html');

  // Open the DevTools.
  //mainWindow.openDevTools();

  // Emitted when the window is closed.
  //mainWindow.on('closed', function() {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should devare the corresponding element.
  //  mainWindow = null;
  //});
});
