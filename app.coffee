React = require('react')
ReactSlider = require('react-slider')

mkTask = (title, mode) ->
  {
    start: ->
      @interval = setInterval((->
        console.log 'Hello'
        return
      ), 1000)
      return
    stop: ->
      clearInterval @interval
      return
    title: title
    elapsed: 0
    interval: null
    mode: mode
  }

mkMode = (name, duration) ->
  {
    name: name
    duration: duration
  }

Task = React.createClass(
  getInitialState: ->
    { title: @props.task.title }
  render: ->
      <div className="task">
        {this.state.title}
        <br />
        <progress max="100" value="80"></progress>
      </div>
)
Mode = React.createClass(
  getInitialState: ->
    { duration: @props.mode.duration }
  changeDuration: (value) ->
    state = @state
    state.duration = value
    @setState state
    return
  render: ->
    <div className="mode">
      <h2 className="modeName">
        {this.props.mode.name}
      </h2>
      <div>{this.state.duration}</div>
      <ReactSlider defaultValue={this.state.duration} min={0} max={60} onChange={this.changeDuration}/>
    </div>
)
workMode = mkMode('work', 10)
breakMode = mkMode('break', 5)
modes = [
  workMode
  breakMode
]
tasks = [
  mkTask('react lernen', workMode)
  mkTask('break', breakMode)
]
BlinkodoroApp = React.createClass(
  getInitialState: ->
    {
      running: false
      modes: modes
      tasks: tasks
      currentTaskIndex: 0
    }
  go: ->
    @state.running = true
    @setState @state
    return
  stop: ->
    @state.running = false
    @setState @state
    return
  className: ->
    'blinkodoro ' + (if @state.running then 'running' else 'halted')
  currentTask: ->
    @state.tasks[@state.currentTaskIndex]
  render: ->
    <div className={this.className()}>
      <h1>{this.currentTask().title}</h1>
      <button onClick={this.go}>GO!</button>
      <button onClick={this.stop}>STOP!</button>
    </div>
)

ModeList = React.createClass(render: ->
  modeNodes = @props.modes.map (mode) ->
    <Mode key={mode.name} mode={mode} />
  return (
    <div className="modeList">
      {modeNodes}
    </div>
  )

)

TaskList = React.createClass(
  getInitialState: ->
    { tasks: @props.tasks }
  render: ->
    taskNodes = @state.tasks.map((task) ->
      <Task key={task.title} task={task} />
    )
    return (
      <div className="taskList">
        {taskNodes}
      </div>
    )
)

###
React.render(
  <TaskList tasks={tasks} />,
  document.getElementById('example')
);
###


React.render(
  <BlinkodoroApp />
  document.getElementById('app')
)

#React.render(<ReactSlider defaultValue={50} />, document.getElementById('example'));
