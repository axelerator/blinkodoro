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
  duration: duration# * 60

Task = React.createClass(
  getInitialState: ->
    @props.task.observers.push @
    return {
      title: @props.task.title
      percent: 0
      finished: @props.task.finished()
      mode: @props.task.mode
    }
  update: ->
    newState = {
      title: @props.task.title
      percent: @props.task.percent()
      finished: @props.task.finished()
      active: @props.task.active
      mode: @props.task.mode
    }
    @setState(newState)
    @props.onFinish(@props.task) if newState.finished
  classString: ->
    cs = ['task']
    cs.push 'finished' if @state.finished
    cs.push 'active' if @state.active
    cs.push @props.task.mode.name
    cs.join(' ')
  render: ->
    <div className={@classString()}>
      <span>{@state.title} </span>
      <span className="duration">({@state.mode.duration / 60} min.)</span>
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

workMode = mkMode('pomodoro', 25)
breakMode = mkMode('break', 5)
bigBreakMode = mkMode('bigBreak', 15)
modes = [
  workMode
  breakMode
  bigBreakMode
]
class TaskStore
  constructor: ->
    @tasks = []
    @observers = []
  addObserver: (observer) ->
    @observers.push(observer)
  addTask: (title) ->
    @tasks.push mkTask(title, workMode)
    pomodoriCount = @tasks.filter (task) -> task.mode == workMode
    if (pomodoriCount.length % 2) == 0
      @tasks.push mkTask("Lange Pause", bigBreakMode)
    else
      @tasks.push mkTask("Pause", breakMode)
    observer.notifyFromTaskStore() for observer in @observers
  startableTask: ->
    @tasks.find (task) -> !task.finished()

taskStore = new TaskStore()

ModeList = React.createClass
  render: ->
    modeNodes = @props.modes.map (mode) ->
      <Mode key={mode.name} mode={mode} />
    <div className="modeList">
      {modeNodes}
    </div>

TaskList = React.createClass
  getInitialState: ->
    @props.taskStore.addObserver(@)
    taskStore: @props.taskStore
    currentTask: null
  notifyFromTaskStore: ->
    @setState(@state)
  handleTaskFinish: (task) ->
    @state.currentTask = @state.taskStore.startableTask()
    if @state.currentTask?
      @state.currentTask.start()
    @props.onChangeTask(@state.currentTask)
  render: ->
    taskNodes = @state.taskStore.tasks.map((task) =>
      <Task key={task.title + task.id} task={task} onFinish={@handleTaskFinish} />
    )
    <div className="task-list">
      {taskNodes}
    </div>

TaskInput = React.createClass
  getInitialState: ->
    taskStore: @props.taskStore
  handleSubmit: (e) ->
    e.preventDefault()
    trimmedValue = @refs.title.getDOMNode().value
    @state.taskStore.addTask(trimmedValue) unless trimmedValue == ''
    @refs.title.getDOMNode().value = ''
  render: ->
    <div className="task-input">
      <input ref="title" />
      <button onClick={this.handleSubmit}>Neuer Task</button>
    </div>

BlinkodoroApp = React.createClass
  getInitialState: ->
    running: false
    modes: modes
    taskStore: taskStore
    currentTask:  null
  go: ->
    task = @state.taskStore.startableTask()
    if task? && !task.finished()
      @state.running = true
      @state.currentTask = task
      task.start()
      @setState @state
      message = if task?
                  task.mode.name
                else
                  'none'
      Ipc.sendChannel('change-task', message)
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
    message = if task?
                task.mode.name
              else
                'none'
    Ipc.sendChannel('change-task', message)
    @setState @state
  render: ->
    <div className="container">
      <div className={this.className()}>
        <TaskList taskStore={this.state.taskStore} onChangeTask={@handleTaskChange} />
        <TaskInput taskStore={this.state.taskStore}/>
        <div className="actions">
          <button className="go" onClick={this.go}>GO!</button>
          <button className="stop" onClick={this.stop}>STOP!</button>
        </div>
      </div>
    </div>

React.render(
  <BlinkodoroApp />
  document.getElementById('app')
)

