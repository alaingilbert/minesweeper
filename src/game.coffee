class Case
  constructor: (@ctx, @x, @y) ->
    @size = 42

    @tileBackground = @ctx.rect 0, 0, @size, @size
    @tileBackground.attr fill: '#ddd', stroke: 'gray', strokeWidth: 1

    @g = @ctx.g @tileBackground
    @g.transform "translate(#{@x * @size}, #{@y * @size})"

    @g.mouseover () =>
      if game.state isnt game.states.GameOver
        @tileBackground.attr fill: '#ccc'

    @g.mouseout () =>
      if game.state isnt game.states.GameOver
        @tileBackground.attr fill: '#ddd'

    @g.mouseup (evt) =>
      return if game.state is game.states.GameOver
      if game.state is game.states.Empty
        game.initGame @x, @y

      if evt.button is 2 # Right click
        casePosition = game.positionFromCoord @x, @y
        game.board.cases[casePosition].g.remove()
        if game.board.cases[casePosition].constructor is Flag
          game.board.flagsLbl.attr text: --game.flags
          game.board.cases[casePosition] = new Case @ctx, @x, @y
        else
          game.board.flagsLbl.attr text: ++game.flags
          game.board.cases[casePosition] = new Flag @ctx, @x, @y
      else
        @showCase()

  showCase: () ->
    casePosition = game.positionFromCoord @x, @y

    if game.board.cases[casePosition].constructor isnt Case
      return

    if game.data[casePosition] is game.entities.Mine
      game.gameOver(casePosition)
      return

    game.safe++
    if game.safe is game.board.nbHorizontalCases * game.board.nbVerticalCases - game.nbMines
      console.log "WIN"
      return

    nbMinesAround = @countMines()

    game.board.cases[casePosition].g.remove()
    game.board.cases[casePosition] = new TextCase(@ctx, @x, @y, nbMinesAround)

    if nbMinesAround is 0
      for [x, y] in game.neighborCoord @x, @y
        game.board.cases[game.positionFromCoord(x, y)].showCase()

  countMines: () ->
    nbMines = 0
    for [x, y] in game.neighborCoord @x, @y
      nbMines++ if game.data[game.positionFromCoord(x, y)] is game.entities.Mine
    return nbMines

  countFlags: () ->
    nbFlags = 0
    for [x, y] in game.neighborCoord @x, @y
      nbFlags++ if game.board.cases[game.positionFromCoord(x, y)].constructor is Flag
    return nbFlags


class TextCase extends Case
  constructor: (@ctx, @x, @y, @number) ->
    @colors = ['blue', 'green', 'red', 'navy', 'maroon', 'aqua', 'purple', 'black']

    super
    @g.unmouseover()
    @g.unmouseout()
    @g.unmouseup()

    @g.mouseup (evt) =>
      return if game.state is game.states.GameOver
      if @countFlags() is @countMines()
        for [x, y] in game.neighborCoord @x, @y
          game.board.cases[game.positionFromCoord(x, y)].showCase()

    @tileBackground.attr fill: '#fff'
    text = @ctx.text @size/2, @size/2, @number
    text.attr fontFamily: 'Arial', fontSize: 38, alignmentBaseline: 'central', textAnchor: 'middle', fill: @colors[@number-1]
    @g.append text


class Mine extends Case
  constructor: () ->


class @Game
  constructor: (id) ->
    @states = Empty: 0, Playing: 1, GameOver: 2
    @state = @states.Empty
    @entities = Empty: 0, Mine: 1, Flag: 2
    @nbMines = 50
    @flags = 0
    @safe = 0
    @data = []
    @board = new Board id
    @board.createBoard()


  initGame: (x, y) ->
    @state = @states.Playing
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
    neighborsIdx = [@positionFromCoord(item[0], item[1]) for item in neighbors][0]

    return idx in neighborsIdx or
           idx is @positionFromCoord(x, y) or
           game.data[idx] is game.entities.Mine


  generateBoard: (x, y) ->
    for i in [0...@nbMines]
      loop
        rnd = @rnd(0, (@board.nbHorizontalCases * @board.nbVerticalCases) - 1)
        break if not @around(rnd, x, y)
      @data[rnd] = @entities.Mine


  coordFromPosition: (position) ->
    y = Math.floor(position / @board.nbHorizontalCases)
    x = position - y * @board.nbHorizontalCases
    return [x, y]


  positionFromCoord: (x, y) ->
    position = x + y * game.board.nbHorizontalCases


  isValidPosition: (x, y) ->
    return x >= 0 and x < @board.nbHorizontalCases and
           y >= 0 and y < @board.nbVerticalCases


  showMines: (deadPosition) ->
    for i in [0...@data.length]
      if @data[i] is @entities.Mine
        [x, y] = @coordFromPosition(i)
        game.board.cases[i].g.remove()
        if i is deadPosition
          game.board.cases[i] = new ExplodedMine @board.board, x, y
        else
          if @board.cases[i].constructor is Flag
            game.board.cases[i] = new FlaggedMine @board.board, x, y
          else
            game.board.cases[i] = new Mine @board.board, x, y

    for i in [0...@board.cases.length]
      if @board.cases[i].constructor is Flag and @data[i] isnt @entities.Mine
        [x, y] = @coordFromPosition(i)
        @board.cases[i].g.remove()
        @board.cases[i] = new BadFlag @board.board, x, y



  gameOver: (deadPosition) =>
    @state = @states.GameOver
    @showMines(deadPosition)


class Board
  constructor: (@id) ->
    @board = Snap(@id)

    @board.mouseup () ->
      if game.state is game.states.Empty
        @board.init()

    @nbHorizontalCases = 19
    @nbVerticalCases = 13
    @cases = []


  createBoard: () ->
    nbCases = @nbHorizontalCases * @nbVerticalCases
    for i in [0...nbCases]
      y = Math.floor(i / @nbHorizontalCases)
      x = i - y * @nbHorizontalCases
      tmp = new Case @board, x, y
      @cases[i] = tmp

    @flagsLbl = @board.text 0, 0, 'Flags'
    @flagsLbl.transform 'translate(0, 580)'



class Flag extends Case
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


class Mine extends Case
  constructor: () ->
    super
    circle = @ctx.circle @size/2, @size/2, @size/4
    circle.attr fill: '#666', stroke: '#333', strokeWidth: 1
    group = @ctx.g circle
    @g.append group


class ExplodedMine extends Case
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
