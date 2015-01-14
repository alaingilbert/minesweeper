class Tile
  constructor: (@ctx, @x, @y) ->
    @size = 42

    @tileBackground = @ctx.rect 0, 0, @size, @size
    @tileBackground.attr fill: '#ddd', stroke: 'gray', strokeWidth: 1

    @g = @ctx.g @tileBackground
    @g.transform "translate(#{@x * @size}, #{@y * @size})"

    @g.mouseover @mouseOverHandler
    @g.mouseout @mouseOutHandler
    @g.mouseup @mouseUpHandler


  mouseOverHandler: (evt) =>
    if not game.state.is StateManager.GameOver
      @tileBackground.attr fill: '#ccc'


  mouseOutHandler: (evt) =>
    if not game.state.is StateManager.GameOver
      @tileBackground.attr fill: '#ddd'


  mouseUpHandler: (evt) =>
    return if game.state.is StateManager.GameOver
    if game.state.is StateManager.Empty
      game.initGame @x, @y

    if evt.button is 2 # Right click
      casePosition = game.positionFromCoord @x, @y
      game.board.cases[casePosition].g.remove()
      if game.board.cases[casePosition].constructor is Flag
        game.flags--
        game.board.cases[casePosition] = new Tile @ctx, @x, @y
      else
        game.flags++
        game.board.cases[casePosition] = new Flag @ctx, @x, @y
      game.board.flagsLbl.attr text: "Flags: #{game.flags}/#{game.nbMines}"
    else
      @showTile()


  showTile: () ->
    casePosition = game.positionFromCoord @x, @y

    if game.board.cases[casePosition].constructor isnt Tile
      return

    if game.data[casePosition] is game.entities.Mine
      game.willDie = casePosition
      return

    nbMinesAround = @countMines()

    game.board.cases[casePosition].g.remove()
    game.board.cases[casePosition] = new TextTile(@ctx, @x, @y, nbMinesAround)

    game.safe++

    if nbMinesAround is 0
      for [x, y] in game.neighborCoord @x, @y
        game.board.cases[game.positionFromCoord(x, y)].showTile()


  countMines: () ->
    nbMines = 0
    for [x, y] in game.neighborCoord @x, @y
      if game.data[game.positionFromCoord(x, y)] is game.entities.Mine
        nbMines++
    return nbMines


  countFlags: () ->
    nbFlags = 0
    for [x, y] in game.neighborCoord @x, @y
      if game.board.cases[game.positionFromCoord(x, y)].constructor is Flag
        nbFlags++
    return nbFlags


class TextTile extends Tile
  constructor: (@ctx, @x, @y, @number) ->
    @colors = ['blue', 'green', 'red', 'navy',
               'maroon', 'aqua', 'purple', 'black']

    super
    @g.unmouseover()
    @g.unmouseout()
    @g.unmouseup()
    @g.mouseup @mouseUpHandler

    @tileBackground.attr fill: '#fff'
    text = @ctx.text @size/2, @size/2, @number
    text.attr
      fontFamily: 'Arial', fontSize: 38, alignmentBaseline: 'central',
      textAnchor: 'middle', fill: @colors[@number-1]
    @g.append text


  mouseUpHandler: (evt) =>
    return if game.state.is StateManager.GameOver
    if @countFlags() is @countMines()
      for [x, y] in game.neighborCoord @x, @y
        game.board.cases[game.positionFromCoord(x, y)].showTile()


class @Game
  constructor: (id) ->
    @state = new StateManager()
    @entities = Empty: 0, Mine: 1, Flag: 2
    @nbMines = 50
    @flags = 0
    @safe = 0
    @data = []
    @willDie = false
    @board = new Board id
    @board.createBoard()


  initGame: (x, y) ->
    @state.set StateManager.Playing
    @generateBoard x, y


  rnd: (min, max) ->
    return Math.floor(Math.random() * (max - min + 1)) + min


  neighborCoord: (x, y) ->
    result = []
    result.push([x - 1, y - 1]) if @isValidPosition(x - 1, y - 1)
    result.push([x - 0, y - 1]) if @isValidPosition(x - 0, y - 1)
    result.push([x + 1, y - 1]) if @isValidPosition(x + 1, y - 1)
    result.push([x - 1, y - 0]) if @isValidPosition(x - 1, y - 0)
    result.push([x + 1, y - 0]) if @isValidPosition(x + 1, y - 0)
    result.push([x - 1, y + 1]) if @isValidPosition(x - 1, y + 1)
    result.push([x - 0, y + 1]) if @isValidPosition(x - 0, y + 1)
    result.push([x + 1, y + 1]) if @isValidPosition(x + 1, y + 1)
    return result


  around: (idx, x, y) ->
    neighbors = @neighborCoord x, y
    neighborsIdx = [@positionFromCoord(item[0], item[1]) for item in neighbors]

    return idx in neighborsIdx[0] or
           idx is @positionFromCoord(x, y) or
           @data[idx] is @entities.Mine


  generateBoard: (x, y) ->
    for i in [0...@nbMines]
      loop
        rnd = @rnd(0, (@board.nbHorizontalTiles * @board.nbVerticalTiles) - 1)
        break if not @around(rnd, x, y)
      @data[rnd] = @entities.Mine


  coordFromPosition: (position) ->
    y = Math.floor(position / @board.nbHorizontalTiles)
    x = position - y * @board.nbHorizontalTiles
    return [x, y]


  positionFromCoord: (x, y) ->
    position = x + y * @board.nbHorizontalTiles


  isValidPosition: (x, y) ->
    return x >= 0 and x < @board.nbHorizontalTiles and
           y >= 0 and y < @board.nbVerticalTiles


  showMines: (deadPosition) ->
    for i in [0...@board.cases.length]
      [x, y] = @coordFromPosition(i)
      params = [@board.board, x, y]
      if @data[i] is @entities.Mine
        @board.cases[i].g.remove()
        if i is deadPosition
          @board.cases[i] = new ExplodedMine params...
        else if @board.cases[i].constructor is Flag
          @board.cases[i] = new FlaggedMine params...
        else
          @board.cases[i] = new Mine params...
      else if @board.cases[i].constructor is Flag
        @board.cases[i].g.remove()
        @board.cases[i] = new BadFlag params...


  gameOver: (deadPosition) =>
    @state.set StateManager.GameOver
    @showMines(deadPosition)


  win: () ->
    @state.set StateManager.Win
    background = @board.board.rect 0, 0, 42*19, 42*13
    background.attr fill: 'rgba(255, 255, 255, 0.7)'
    winLbl = @board.board.text 42*19/2, 42*13/2, 'Win'
    winLbl.attr
      fontSize: 40, fontFamily: 'Arial', fill: 'green',
      alignmentBaseline: 'central', textAnchor: 'middle'


  reset: () ->
    @safe = 0
    @flags = 0
    @data = []
    @willDie = false
    @board.reset()


class StateManager
  constructor: () ->
    @delay = 0
    @state = StateManager.Empty


  is: (state) ->
    @state is state


  set: (state) ->
    @state = state


  @Empty = 0
  @Playing = 1
  @GameOver = 2
  @Win = 3


class Board
  constructor: (@id) ->
    @board = Snap(@id)
    @board.mouseup @mouseUpHandler

    @nbHorizontalTiles = 19
    @nbVerticalTiles = 13
    @cases = []


  mouseUpHandler: (evt) =>
    if game.state.is StateManager.Playing
      if game.safe is game.board.cases.length - game.nbMines
        game.win()
        return
      if game.willDie isnt false
        game.gameOver(game.willDie)
    else if game.state.is StateManager.Win
      game.reset()
      game.state.set StateManager.Empty
    else if game.state.is StateManager.GameOver
      game.reset()
      game.state.set StateManager.Empty
    else if game.state.is StateManager.Empty
      @board.init()


  createBoard: () ->
    nbTiles = @nbHorizontalTiles * @nbVerticalTiles
    for i in [0...nbTiles]
      y = Math.floor(i / @nbHorizontalTiles)
      x = i - y * @nbHorizontalTiles
      tmp = new Tile @board, x, y
      @cases[i] = tmp

    @flagsLbl = @board.text 0, 0, "Flags: 0/50"
    @flagsLbl.transform 'translate(0, 580)'


  reset: () ->
    @board.clear()
    @createBoard()


class Flag extends Tile
  constructor: () ->
    super
    @g.append Flag.render @ctx, @size


  @render: (ctx, size) ->
    polygon = ctx.polygon([size/3, size/2,
                            (size/3)*2, size/3,
                            (size/3)*2, (size/3)*2])
    polygon.attr fill: 'red'

    lines = ctx.polyline([(size/3)*2, size/3,
                           (size/3)*2, size-(size/4),
                           size/2, size-(size/4),
                           size-(size/5), size-(size/4)])
    lines.attr stroke: 'black', strokeWidth: size/20, fill: 'transparent'

    group = ctx.g polygon, lines
    return group


class Mine extends Tile
  constructor: () ->
    super
    circle = @ctx.circle @size/2, @size/2, @size/4
    circle.attr fill: '#666', stroke: '#333', strokeWidth: 1
    group = @ctx.g circle
    @g.append group


class ExplodedMine extends Tile
  constructor: () ->
    super
    circle = @ctx.circle @size/2, @size/2, @size/4
    circle.attr fill: '#c00', stroke: '#333', strokeWidth: 1
    group = @ctx.g circle
    @g.append group


class FlaggedMine extends Mine
  constructor: () ->
    super
    @g.append Flag.render @ctx, @size


class BadFlag extends Flag
  constructor: () ->
    super
    line1 = @ctx.line @size/5, @size/5, @size - @size/5, @size - @size/5
    line1.attr stroke: '#000', strokeWidth: @size/20
    line2 = @ctx.line @size/5, @size - @size/5, @size - @size/5, @size/5
    line2.attr stroke: '#000', strokeWidth: @size/20
    group = @ctx.g line1, line2
    @g.append group
