var React = require('react');
var ReactSlider = require('react-slider');

function mkTask(title, mode) {
  return {
    start: function(){
      this.interval = setInterval(function(){ 
        console.log("Hello"); 
      }, 1000);
    },
    stop: function(){
      clearInterval(this.interval);
    }
    title: title,
    elapsed: 0,
    interval: null,
    mode: mode
  };
}

function mkMode(name, duration) {
  return {
    name: name,
    duration: duration
  };
}

var Task = React.createClass({
  getInitialState: function(){
    return {title: this.props.task.title}
  },
  render: function(){
    return (
      <div className="task">
        {this.state.title}
        <br />
        <progress max="100" value="80"></progress>
      </div>
      );
  }
});

var Mode = React.createClass({
  getInitialState: function(){
    return {
      duration: this.props.mode.duration
    }
  },
  changeDuration: function(value){
    var state = this.state;
    state.duration = value;
    this.setState(state);
  },
  render: function() {
    return (
      <div className="mode">
        <h2 className="modeName">
          {this.props.mode.name}
        </h2>
        <div>{this.state.duration}</div>
        <ReactSlider defaultValue={this.state.duration} min={0} max={60} onChange={this.changeDuration}/>
      </div>
    );
  }
});

var workMode = mkMode('work', 10);
var breakMode = mkMode('break', 5);

var modes = [workMode, breakMode ];
var tasks = [mkTask('react lernen', workMode), mkTask('break', breakMode)];


var BlinkodoroApp = React.createClass({
  getInitialState: function(){
    return {
      running: false,
      modes: modes,
      tasks: tasks,
      currentTaskIndex: 0
    };
  },
  go: function(){ 
    this.state.running = true;
    this.setState(this.state);
  },
  stop: function(){
    this.state.running = false;
    this.setState(this.state);
  },
  className: function() {
    return "blinkodoro " + (this.state.running ? 'running' : 'halted');
  },
  currentTask: function(){
    return this.state.tasks[this.state.currentTaskIndex];
  },
  render: function(){
    return (
      <div className={this.className()}>
        <h1>{this.currentTask().title}</h1>
        <button onClick={this.go}>GO!</button>
        <button onClick={this.stop}>STOP!</button>
      </div>
    );
  }
});

var ModeList = React.createClass({
  render: function() {
    var modeNodes = this.props.modes.map(function(mode) {
      return (
        <Mode key={mode.name} mode={mode} />
      );
    });
    return (
      <div className="modeList">
        {modeNodes}
      </div>
    );
  }
});

var TaskList = React.createClass({
  getInitialState: function(){
    return {
      tasks: this.props.tasks
    }
  },
  render: function() {
    var taskNodes = this.state.tasks.map(function(task) {
      return (
        <Task key={task.title} task={task} />
      );
    });
    return (
      <div className="taskList">
        {taskNodes}
      </div>
    );
  }
});


/*
React.render(
  <TaskList tasks={tasks} />,
  document.getElementById('example')
);
*/
React.render(
  <BlinkodoroApp />,
  document.getElementById('app')
);
//React.render(<ReactSlider defaultValue={50} />, document.getElementById('example'));
