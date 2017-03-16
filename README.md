# Install

```
npm install -g coffee-script
```

```
bower install
```

# Compile

```
coffee -wc ./
```

# Lol

```
for(var i=0;i<game.data.length;i++){y=Math.floor(i/game.board.nbHorizontalTiles);x=i-y*game.board.nbHorizontalTiles;if(game.data[i]&&!game.isFlag(i)){game.toggleFlag(x,y)}}
```
