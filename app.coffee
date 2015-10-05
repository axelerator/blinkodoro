React = require('react')
ReactSlider = require('react-slider')
Ipc = window.require('ipc')

taskIds = 0
mkTask = (title, mode) ->
    start: ->
      return if @finished()
      @active = true
      @interval = setInterval(() =>
        @elapsed += 1
        @stop() if @finished()
        @observers.forEach (observer) =>
          observer.update(@)
      1000)
    stop: ->
      clearInterval @interval
      @active = false
      return
    percent: ->
      (@elapsed / @mode.duration) * 100.0
    finished: ->
      @percent() >= 100
    id: taskIds += 1
    active: false
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
      active: @props.task.active
    }
    @setState(newState)
    @props.onFinish(@props.task) if newState.finished
  classString: ->
    cs = ['task']
    cs.push 'finished' if @state.finished
    cs.push 'active' if @state.active
    cs.join(' ')
  render: ->
    <div className={@classString()}>
      {@state.title}
      <i className="fa fa-check-circle"></i>
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

workMode = mkMode('work', 10)
breakMode = mkMode('break', 10)
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
    <div className="task-list">
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
    <div className="container">
      <div className={this.className()}>
        <TaskList tasks={this.state.tasks} onChangeTask={@handleTaskChange} />
        <div className="actions">
          <button class="btn" onClick={this.go}>GO!</button>
          <button onClick={this.stop}>STOP!</button>
        </div>
      </div>
    </div>


React.render(
  <BlinkodoroApp />
  document.getElementById('app')
)

