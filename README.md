#Install

```
npm install -g coffee-script
```

```
bower install
```

#Compile

```
coffee -wc ./
```

#Lol

```
for(var i=0;i<game.data.length;i++){if(game.data[i]){y=Math.floor(i/game.board.nbHorizontalTiles);x=i-y*game.board.nbHorizontalTiles;game.setFlag(x,y)}}
```
