React = require('react')
ReactSlider = require('react-slider')
Ipc = window.require('ipc')

taskIds = 0
mkTask = (title, mode) ->
    start: ->
      return if @finished()
      @interval = setInterval(() =>
        @elapsed += 1
        @stop() if @finished()
        @observers.forEach (observer) ->
          observer.update(@)
      1000)
    stop: ->
      clearInterval @interval
      return
    percent: ->
      (@elapsed / @mode.duration) * 100.0
    finished: ->
      @percent() >= 100
    id: taskIds += 1
    title: title
    elapsed: 0
    interval: null
    mode: mode
    observers: []

mkMode = (name, duration) ->
  name: name
  duration: duration

Task = React.createClass(
  getInitialState: ->
    @props.task.observers.push @
    return {
      title: @props.task.title
      percent: 0
      finished: @props.task.finished()
    }
  update: ->
    newState = {
      title: @props.task.title
      percent: @props.task.percent()
      finished: @props.task.finished()
    }
    @setState(newState)
    @props.onFinish(@props.task) if newState.finished
  render: ->
    <div className="task">
      {@state.title} ({@state.finished})
      <br />
      <progress max="100" value={@state.percent}></progress>
    </div>
)
Mode = React.createClass
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

workMode = mkMode('work', 3)
breakMode = mkMode('break', 2)
modes = [
  workMode
  breakMode
]
tasks = [
  mkTask('react lernen', workMode)
  mkTask('break', breakMode)
  mkTask('lampe blinken lassen', workMode)
  mkTask('break', breakMode)
  mkTask('essen', workMode)
  mkTask('break', breakMode)
]
ModeList = React.createClass
  render: ->
    modeNodes = @props.modes.map (mode) ->
      <Mode key={mode.name} mode={mode} />
    <div className="modeList">
      {modeNodes}
    </div>

TaskList = React.createClass
  getInitialState: ->
    tasks: @props.tasks
    currentTask: @props.tasks[0]
  handleTaskFinish: (task) ->
    nextIndex = @props.tasks.indexOf(task) + 1
    @state.currentTask = null
    if nextIndex < @props.tasks.length
      t = @props.tasks[nextIndex]
      t.start()
    @props.onChangeTask(t)
  render: ->
    taskNodes = @state.tasks.map((task) =>
      <Task key={task.title + task.id} task={task} onFinish={@handleTaskFinish} />
    )
    <div className="taskList">
      {taskNodes}
    </div>

BlinkodoroApp = React.createClass
  getInitialState: ->
    running: false
    modes: modes
    tasks: tasks
    currentTask:  tasks[0]
  go: ->
    @state.running = true
    @state.currentTask.start()
    @setState @state
    Ipc.sendChannel('change-task', @state.currentTask.mode.name)
    return
  stop: ->
    @state.running = false
    @state.currentTask.stop()
    @setState @state
    return
  className: ->
    'blinkodoro ' + (if @state.running then 'running' else 'halted')
  handleTaskChange: (task) ->
    @state.currentTask = task
    Ipc.sendChannel('change-task',task.mode.name)
    @setState @state
  render: ->
    <div class="container">
      <div className={this.className()}>
        <TaskList tasks={this.state.tasks} onChangeTask={@handleTaskChange} />
        <button class="btn btn-default" onClick={this.go}>GO!</button>
        <button onClick={this.stop}>STOP!</button>
      </div>
    </div>


React.render(
  <BlinkodoroApp />
  document.getElementById('app')
)

