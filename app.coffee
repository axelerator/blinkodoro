React = require('react')
ReactSlider = require('react-slider')
Ipc = window.require('ipc')

taskIds = 0
mkTask = (title, mode, elapsed, active, taskStore) ->
    start: ->
      return if @finished()
      @active = true
      @interval = setInterval(() =>
        @elapsed += 1
        @stop() if @finished()
        @taskStore.storeTasks()
        @observers.forEach (observer) =>
          observer.update(@)
      1000)
      @taskStore.storeTasks()
    stop: ->
      clearInterval @interval
      @active = false
      return
    percent: ->
      (@elapsed / @mode.duration) * 100.0
    finished: ->
      @percent() >= 100
    store: () ->
      @taskStore.storeTasks()
    id: taskIds += 1
    taskStore: taskStore
    active: active
    title: title
    elapsed: elapsed
    interval: null
    mode: mode
    observers: []

mkMode = (name, label, duration,r,g,b) ->
  name: name
  label: label
  duration: duration * 60
  color:
    r: r
    g: g
    b: b
  store: ->
    @taskStore.storeModes()


Task = React.createClass(
  getInitialState: ->
    @props.task.observers.push @
    return {
      percent: 0
    }
  update: ->
    newState =
      percent: @props.task.percent()
    @setState(newState)
    @props.onFinish(@props.task) if @props.task.finished()
  classString: ->
    cs = ['task']
    cs.push 'finished' if @props.task.finished()
    cs.push 'active' if @props.task.active
    cs.push @props.task.mode.name
    cs.join(' ')
  render: ->
    <div className={@classString()}>
      <span>{@props.task.title} </span>
      <span className="duration">({@props.task.mode.duration / 60} min.)</span>
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

workMode = mkMode('pomodoro','Task', 25, 255,0,255)
breakMode = mkMode('break', 'Pause', 5, 0,255,0)
bigBreakMode = mkMode('bigBreak', 'Lange Pause', 15, 0, 0, 255)
modes = [
  workMode
  breakMode
  bigBreakMode
]
class TaskStore
  constructor: ->
    @tasks = []
    @modes = modes
    modes.forEach (mode) => mode.taskStore = @
    @observers = []
    storedModes = localStorage.getItem "modes"
    if storedModes?
      parsedModes = JSON.parse storedModes
      parsedModes.forEach (storedMode) =>
        currentMode = @modes.find (mode) -> mode.name == storedMode.name
        currentMode.duration = storedMode.duration
        color = storedMode.color
        currentMode.color.r = color.r
        currentMode.color.g = color.g
        currentMode.color.b = color.b
        rgb = [color.r, color.g, color.b].map (c) -> parseInt(c)
        Ipc.sendChannel('setModeColor', currentMode.name,rgb )
    storedTasks = localStorage.getItem "tasks"
    if storedTasks?
      parsedTasks = JSON.parse storedTasks
      parsedTasks.forEach (storedTask) =>
        mode = @modes.find (m) -> m.name == storedTask.mode_name
        @tasks.push mkTask(storedTask.title, mode, storedTask.elapsed, storedTask.active, @)

  addObserver: (observer) ->
    @observers.push(observer)
  addTask: (title) ->
    @tasks.push mkTask(title, workMode, 0, false, @)
    pomodoriCount = @tasks.filter (task) -> task.mode == workMode
    if (pomodoriCount.length % 4) == 0
      @tasks.push mkTask("Lange Pause", bigBreakMode, 0, false, @)
    else
      @tasks.push mkTask("Pause", breakMode, 0, false, @)
    observer.notifyFromTaskStore() for observer in @observers
    @storeTasks()
  startableTask: ->
    @tasks.find (task) -> !task.finished()
  resetTasks: ->
    @tasks = []
    localStorage.removeItem 'tasks'
  storeModes: ->
    flatModes = @modes.map (m) ->
      name: m.name
      duration: m.duration
      color:
        r: m.color.r
        g: m.color.g
        b: m.color.b
    localStorage.setItem "modes", JSON.stringify(flatModes)
  storeTasks: ->
    flatTasks = @tasks.map (t) ->
      title: t.title
      elapsed: t.elapsed
      mode_name: t.mode.name
      active: t.active
    localStorage.setItem "tasks", JSON.stringify(flatTasks)


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

ModeConfiguration = React.createClass
  render: ->
    modeNodes = @props.taskStore.modes.map((mode) =>
      <ModeSettings key={mode.name} mode={mode} />
    )
    <div className="configuration">
      {modeNodes}
    </div>

ModeSettings = React.createClass
  getInitialState: ->
    r: @props.mode.color.r
    g: @props.mode.color.g
    b: @props.mode.color.b
    duration: @props.mode.duration / 60
    dirty: false
  handleSubmit: (e) ->
    e.preventDefault()
    @props.mode.color.r = @state.r
    @props.mode.color.g = @state.g
    @props.mode.color.b = @state.b
    @props.mode.duration = @state.duration * 60
    @props.mode.store()
    @state.dirty = false
    @setState @state
    Ipc.sendChannel('off', null)
    rgb = ['r', 'g', 'b'].map (channel) => parseInt(@state[channel])
    Ipc.sendChannel('setModeColor', @props.mode.name, rgb)

    @
  updateHandler: (property) ->
    (event) =>
      @state.dirty = true
      @state[property] = event.target.value
      this.setState(@state)
      rgb = ['r', 'g', 'b'].map (channel) => parseInt(@state[channel])
      Ipc.sendChannel('setColor', rgb)
  reset: ->
    @setState @getInitialState()
    Ipc.sendChannel('off', null)
  classStr: ->
    str = "mode-settings"
    str += " dirty" if @state.dirty
  render: ->
    <div className={this.classStr()}>
      <div className="label">{@props.mode.label}</div>
      <div className="inputs">
        <div className="color">
          Farbe:
          <label>R:</label>
          <input type="number" min="0" max="255" value={@state.r} onChange={this.updateHandler('r')}  />
          <label>G:</label>
          <input type="number" min="0" max="255" value={@state.g} onChange={this.updateHandler('g')}  />
          <label>B:</label>
          <input type="number" min="0" max="255" value={@state.b} onChange={this.updateHandler('b')} />
        </div>
        <div className="duration">
          <label>Dauer:</label>
          <input type="number" value={@state.duration} onChange={this.updateHandler('duration')}/>
          Minuten
        </div>
      </div>
      <div className="actions" >
        <button onClick={this.handleSubmit}>Speichern</button>
        <button onClick={this.reset}>Abbrechen</button>
      </div>

    </div>

SettingsTab = React.createClass
  getInitialState: ->
    
  handleSubmit: (e) ->
    e.preventDefault()
    trimmedValue = @refs.title.getDOMNode().value
    @state.taskStore.addTask(trimmedValue) unless trimmedValue == ''
    @refs.title.getDOMNode().value = ''
  render: ->
    <div className="settings">
      <input ref="title" />
      <button onClick={this.handleSubmit}>Neuer Task</button>
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
    activeTab: 'tasks'
    currentTask:  null
    tab: 'app'
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
    Ipc.sendChannel('off', null)
    return
  blinkodoroClassName: ->
    'blinkodoro ' + (if @state.running then 'running' else 'halted')
  resetTasks: ->
    @state.running = false
    @state.currentTask.stop() if @state.currentTask?
    @state.taskStore.resetTasks()
    @setState @state
  handleTaskChange: (task) ->
    @state.currentTask = task
    message = if task?
                task.mode.name
              else
                'none'
    Ipc.sendChannel('change-task', message)
    @setState @state
  changeTo: (tab) ->
    () =>
      @state.tab = tab
      @setState @state
  openInfo: ->
    Ipc.sendChannel('openInfo', '')
  render: ->
    config = app = info = ""
    config = (<ModeConfiguration taskStore={this.state.taskStore}/>) if @state.tab == 'config'
    app = (
      <div className={this.blinkodoroClassName()}>
        <TaskList taskStore={this.state.taskStore} onChangeTask={@handleTaskChange} />
        <TaskInput taskStore={this.state.taskStore}/>
        <div className="actions">
          <button className="go" onClick={this.go}>GO!</button>
          <button className="stop" onClick={this.stop}>STOP!</button>
        </div>
      </div>
    ) if @state.tab == 'app'

    info = (
      <div className="info">
        Aus <a href="#" onClick={this.openInfo}>Wikipedia</a>
        <p>
          Die Pomodoro-Technik (orig. pomodoro technique von italienisch pomodoro = Tomate und englisch technique = Methode, Technik) ist eine Methode des Zeitmanagements, die von Francesco Cirillo in den 1980er Jahren entwickelt wurde. Das System verwendet einen Kurzzeitwecker, um Arbeit in 25-Minuten-Abschnitte - die sogenannten pomodori - und Pausenzeiten zu unterteilen
        </p>
        <h3>Vorgehensweise</h3>
          Die Technik besteht aus fünf Schritten:
        <ul>
          <li>die Aufgabe schriftlich formulieren</li>
          <li>den Kurzzeitwecker auf 25 Minuten stellen</li>
          <li>die Aufgabe bearbeiten, bis der Wecker klingelt; mit einem X markieren</li>
          <li>kurze Pause machen (5 Minuten)</li>
          <li>alle vier 'pomodori' eine längere Pause machen (15–20 Minuten).</li>
        </ul>
      </div>
    ) if @state.tab == 'info'
    <div className="container">
      <div className="nav">
        <i className="fa fa-home" onClick={this.changeTo('app')} title="zur Taskliste"></i>
        <i className="fa fa-trash" onClick={this.resetTasks} title="Alle Tasks löschen"></i>
        <i className="fa fa-cog" onClick={this.changeTo('config')} title="Konfiguration"></i>
        <i className="fa fa-info-circle" onClick={this.changeTo('info')} title="Was ist das hier?"></i>
      </div>
      {config}
      {app}
      {info}
    </div>

React.render(
  <BlinkodoroApp />
  document.getElementById('app')
)

