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
    if not game.state is States.GameOver
      @tileBackground.attr fill: '#ccc'


  mouseOutHandler: (evt) =>
    if not game.state is States.GameOver
      @tileBackground.attr fill: '#ddd'


  mouseUpHandler: (evt) =>
    return if game.state is States.GameOver
    if game.state is States.Empty
      if evt.button is 0 # Left click
        game.initGame @x, @y

    if game.state is States.Playing
      if evt.button is 2 # Right click
        tilePosition = game.positionFromCoord @x, @y
        if game.isFlag tilePosition
          game.removeFlag @x, @y
        else
          game.setFlag @x, @y
      else
        @showTile()


  showTile: () ->
    casePosition = game.positionFromCoord @x, @y

    if game.board.cases[casePosition].constructor isnt Tile
      return

    if game.isMine casePosition
      game.willDie = casePosition
      return

    nbMinesAround = @countMinesAround()

    game.board.cases[casePosition].g.remove()
    game.board.cases[casePosition] = new TextTile(@ctx, @x, @y, nbMinesAround)

    game.safe++

    if nbMinesAround is 0
      for [x, y] in game.neighborCoord @x, @y
        game.showTile x, y


  countMinesAround: () ->
    nbMines = 0
    for [x, y] in game.neighborCoord @x, @y
      if game.isMine(game.positionFromCoord(x, y))
        nbMines++
    return nbMines


  countFlagsAround: () ->
    nbFlags = 0
    for [x, y] in game.neighborCoord @x, @y
      if game.isFlag(game.positionFromCoord(x, y))
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
      fontFamily: 'Arial', fontSize: 38, dominantBaseline: 'central',
      textAnchor: 'middle', fill: @colors[@number-1]
    @g.append text


  mouseUpHandler: (evt) =>
    switch game.state
      when States.Playing
        if @countFlagsAround() is @countMinesAround()
          for [x, y] in game.neighborCoord @x, @y
            game.showTile x, y


class @Game
  constructor: (id) ->
    @state = States.Empty
    @entities = Mine: 1
    @nbMines = 50
    @flags = 0
    @safe = 0
    @data = []
    @willDie = false
    @board = new Board id
    @board.createBoard()


  initGame: (x, y) ->
    @state = States.Playing
    @generateBoard x, y


  rnd: (min, max) ->
    return Math.floor(Math.random() * (max - min + 1)) + min


  removeFlag: (x, y) ->
    @flags--
    tilePosition = @positionFromCoord x, y
    @board.cases[tilePosition].g.remove()
    @board.cases[tilePosition] = new Tile @board.board, x, y
    @board.flagsLbl.attr text: "Flags: #{game.flags}/#{game.nbMines}"


  setFlag: (x, y) ->
    @flags++
    tilePosition = @positionFromCoord x, y
    @board.cases[tilePosition].g.remove()
    @board.cases[tilePosition] = new Flag @board.board, x, y
    @board.flagsLbl.attr text: "Flags: #{game.flags}/#{game.nbMines}"


  neighborCoord: (x, y) ->
    result = []
    for dx in [-1..1]
      for dy in [-1..1]
        if not (dx is 0 and dy is 0)
          result.push [x + dx, y + dy] if @isValidPosition x + dx, y + dy
    return result


  neighborIdx: (idx) ->
    [x, y] = @coordFromPosition idx
    neighbors = @neighborCoord(x, y)
    return [@positionFromCoord(item[0], item[1]) for item in neighbors][0]


  around: (idx, x, y) ->
    initialClickPosition = @positionFromCoord x, y
    neighborsIdx = @neighborIdx initialClickPosition

    return idx in neighborsIdx or
           idx is initialClickPosition or
           @isMine idx


  generateBoard: (x, y) ->
    for i in [0...@nbMines]
      loop
        rnd = @rnd(0, (@board.nbHorizontalTiles * @board.nbVerticalTiles) - 1)
        break if not @around(rnd, x, y)
      @data[rnd] = @entities.Mine


  showTile: (x, y) ->
    @board.cases[@positionFromCoord(x, y)].showTile()


  coordFromPosition: (position) ->
    y = Math.floor(position / @board.nbHorizontalTiles)
    x = position - y * @board.nbHorizontalTiles
    return [x, y]


  positionFromCoord: (x, y) ->
    position = x + y * @board.nbHorizontalTiles


  isValidPosition: (x, y) ->
    return x >= 0 and x < @board.nbHorizontalTiles and
           y >= 0 and y < @board.nbVerticalTiles


  isMine: (i) -> @data[i] is @entities.Mine


  isFlag: (i) -> @board.cases[i].constructor is Flag


  showMines: (deadPosition) ->
    for i in [0...@board.cases.length]
      [x, y] = @coordFromPosition(i)
      params = [@board.board, x, y]
      if @isMine(i) or @isFlag(i)
        @board.cases[i].g.remove()
        if i is deadPosition
          newTileClass = ExplodedMine
        else if @isMine(i) and @isFlag(i)
          newTileClass = FlaggedMine
        else if @isFlag(i)
          newTileClass = BadFlag
        else
          newTileClass = Mine
        @board.cases[i] = new newTileClass params...


  gameOver: (deadPosition) =>
    @state = States.GameOver
    @showMines(deadPosition)


  win: () ->
    @state =States.Win
    @showMines()
    background = @board.board.rect 0, 0, 42*19, 42*13
    background.attr fill: 'rgba(255, 255, 255, 0.7)'
    winLbl = @board.board.text 42*19/2, 42*13/2, 'Win'
    winLbl.attr
      fontSize: 40, fontFamily: 'Arial', fill: 'green',
      dominantBaseline: 'central', textAnchor: 'middle'


  reset: () ->
    @safe = 0
    @flags = 0
    @data = []
    @willDie = false
    @board.reset()


class States
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
    switch game.state
      when States.Playing
        if game.safe is game.board.cases.length - game.nbMines
          return game.win()
        if game.willDie isnt false
          game.gameOver(game.willDie)
      when States.Win
        game.reset()
        game.state = States.Empty
      when States.GameOver
        game.reset()
        game.state = States.Empty


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
