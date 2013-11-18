j = $ = jQuery

window.defaultSymbols =
  "-": -1.0
  "+": 1.0
  "0": 0.0

symbolicArr = (str, dict = {}) ->
  dict = _.defaults dict, defaultSymbols
  rtnArr = []
  for symbol in str = str.replace("/ /g", '').split("")
    val = dict[symbol]
    rtnArr.push val if val?
  return rtnArr


symbolicStr = (arr, cols = 3, dict = {}) ->
  rtnStr = []
  dict = _.defaults dict, defaultSymbols
  reverseDict = {}
  for k,v of dict
    key = new String(v)
    reverseDict[key] = k
  n = 0
  for k in arr
    rtnStr += "\n" if n % cols is 0
    n++
    rtnStr += reverseDict[String(k)]
  return rtnStr


gl = undefined
shaderProgram = undefined
mvMatrix = mat4.create()
pMatrix = mat4.create()

mvMatrixStack = []
pyramidVertexPositionBuffer = undefined
pyramidVertexColorBuffer = undefined

mvPushMatrix = ->
  copy = mat4.create()
  mat4.set(mvMatrix, copy)
  mvMatrixStack.push(copy)

mvPopMatrix = ->
  throw "Invalid popMatrix!" if (mvMatrixStack.length == 0)
  mvMatrix = mvMatrixStack.pop()

degToRad = (degrees) ->
  degrees * Math.PI / 180

triangleVertexPositionBuffer = undefined
triangleVertexColorBuffer = undefined

squareVertexPositionBuffer = undefined
squareVertexColorBuffer = undefined

cubeVertexPositionBuffer = undefined
cubeVertexColorBuffer = undefined
cubeVertexIndexBuffer = undefined

pitchCube = 0
yawCube = 0
rollCube = 0

initGL = (canvas) ->
  try
    gl = canvas.getContext("experimental-webgl")
    gl.viewportWidth = canvas.width
    gl.viewportHeight = canvas.height
  alert "Could not initialise WebGL, sorry :-("  unless gl
getShader = (gl, id) ->
  shaderScript = document.getElementById(id)
  return null  unless shaderScript
  str = ""
  k = shaderScript.firstChild
  while k
    str += k.textContent  if k.nodeType is 3
    k = k.nextSibling
  shader = undefined
  if shaderScript.type is "x-shader/x-fragment"
    shader = gl.createShader(gl.FRAGMENT_SHADER)
  else if shaderScript.type is "x-shader/x-vertex"
    shader = gl.createShader(gl.VERTEX_SHADER)
  else
    return null
  gl.shaderSource shader, str
  gl.compileShader shader
  unless gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    alert gl.getShaderInfoLog(shader)
    return null
  shader
initShaders = ->
  fragmentShader = getShader(gl, "shader-fs")
  vertexShader = getShader(gl, "shader-vs")
  shaderProgram = gl.createProgram()
  gl.attachShader shaderProgram, vertexShader
  gl.attachShader shaderProgram, fragmentShader
  gl.linkProgram shaderProgram
  alert "Could not initialise shaders"  unless gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
  gl.useProgram shaderProgram
  shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
  gl.enableVertexAttribArray shaderProgram.vertexPositionAttribute

  #color
  shaderProgram.vertexColorAttribute = gl.getAttribLocation(shaderProgram, "aVertexColor");
  gl.enableVertexAttribArray(shaderProgram.vertexColorAttribute);


  shaderProgram.pMatrixUniform = gl.getUniformLocation(shaderProgram, "uPMatrix")
  shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix")
setMatrixUniforms = ->
  gl.uniformMatrix4fv shaderProgram.pMatrixUniform, false, pMatrix
  gl.uniformMatrix4fv shaderProgram.mvMatrixUniform, false, mvMatrix


initBuffers = ->

  #triangle
  triangleVertexPositionBuffer = gl.createBuffer()

  gl.bindBuffer gl.ARRAY_BUFFER, triangleVertexPositionBuffer
  vertices = [ 0.0,  1.0, 0.0,
              -1.0, -1.0, 0.0,
               1.0, -1.0, 0.0  ]

  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  triangleVertexPositionBuffer.itemSize = 3
  triangleVertexPositionBuffer.numItems = 3

  #triangle color
  triangleVertexColorBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, triangleVertexColorBuffer)
  colors = [
    1.0, 0.0, 1.0, 0.0,
    0.5, 0.0, 0.5, 1.0,
    0.5, 0.0, 1.0, 1.0
  ]
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW)
  triangleVertexColorBuffer.itemSize = 4
  triangleVertexColorBuffer.numItems = 3


  #square
  squareVertexPositionBuffer = gl.createBuffer()


  gl.bindBuffer gl.ARRAY_BUFFER, squareVertexPositionBuffer
  vertices = [ 1.0, 1.0, -1.0,
              -1.0, 1.0, 0.0,
               1.0,-1.0, 1.0,
              -1.0,-1.0, 0.0,
               1.0, 1.0, 1.0]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  squareVertexPositionBuffer.itemSize = 3
  squareVertexPositionBuffer.numItems = 4

  #square color
  squareVertexColorBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, squareVertexColorBuffer);
  colors = []
  for i in [0...4]
    colors = colors.concat([i*0.5, i*0.5, 0.3, 1.0])
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW)
  squareVertexColorBuffer.itemSize = 4
  squareVertexColorBuffer.numItems = 4

  #cube
  cubeVertexPositionBuffer = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, cubeVertexPositionBuffer
  vertices = symbolicArr """
  # Front face
  --+
  +-+
  +++
  -++
  # Back face
  ---
  -+-
  ++-
  +--
  # Top face
  -+-
  -++
  +++
  ++-
  # Bottom face
  ---
  +--
  +-+
  --+
  # Right face
  +--
  ++-
  +++
  +-+
  # Left face
  ---
  --+
  -++
  -+-
  """
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  cubeVertexPositionBuffer.itemSize = 3
  cubeVertexPositionBuffer.numItems = 24
  cubeVertexColorBuffer = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, cubeVertexColorBuffer
  colors = [[1.0, 0.0, 0.0, 1.0], # Front face
            [1.0, 1.0, 0.0, 1.0], # Back face
            [0.0, 1.0, 0.0, 1.0], # Top face
            [1.0, 0.5, 0.5, 1.0], # Bottom face
            [1.0, 0.0, 1.0, 1.0], # Right face
            [0.0, 0.0, 1.0, 1.0]] # Left face
  unpackedColors = []
  for i of colors
    color = colors[i]
    j = 0

    while j < 4
      unpackedColors = unpackedColors.concat(color)
      j++
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(unpackedColors), gl.STATIC_DRAW
  cubeVertexColorBuffer.itemSize = 4
  cubeVertexColorBuffer.numItems = 24

  cubeVertexIndexBuffer = gl.createBuffer()
  gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer
  cubeVertexIndices = [
    0, 1, 2,      0, 2, 3,      # Front face
    4, 5, 6,      4, 6, 7,      # Back face
    8, 9, 10,     8, 10, 11,    # Top face
    12, 13, 14,   12, 14, 15,   # Bottom face
    16, 17, 18,   16, 18, 19,   # Right face
    20, 21, 22,   20, 22, 23    # Left face
  ]
  gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(cubeVertexIndices), gl.STATIC_DRAW
  cubeVertexIndexBuffer.itemSize = 1
  cubeVertexIndexBuffer.numItems = 36

trianglePos = [-1.5, 0.0, -3.0]

ship = """
##.##n
#.#.#n
#...#n
#...#r
#####n
 ##.#n
#...#n
#####r
##.##n
#.#.#n
#...#n
#...#r
"""

defaultSymbols2 =
  ".": false
  "#": true
  "r": "r"
  "n": "n"

symbolicMat = (str, dict = {}) ->
  dict = _.defaults dict, defaultSymbols2
  mesh = []
  floor = []
  strip = []
  for symbol in str = str.replace("/ /g", '').split("")
    val = dict[symbol]
    if val is "n"
      floor.push strip
      strip = []
    else if val is "r"
      floor.push strip
      strip = []
      mesh.push floor
      floor = []
    else
      strip.push val if val?
  return mesh

console.log symbolicMat ship

movMat = []
offset = -symbolicMat(ship)[0].length + (symbolicMat(ship)[0].length/2)
x = y = z = offset
for floor in symbolicMat ship
  z++
  for strip in floor
    y++
    for val in strip
      x++
      movMat.push [x*2,y*2,z*2] if val
    x = offset
  y = offset

console.log "movMat", movMat


drawScene = ->
  gl.viewport 0, 0, gl.viewportWidth, gl.viewportHeight
  gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

  mat4.perspective 90, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix

  #this is the id of mat4 ... what? :O fancy pants.. this is just an assigment... why are these gl guys so wierd?!
  mat4.identity mvMatrix

  mat4.translate mvMatrix, trianglePos


  gl.bindBuffer gl.ARRAY_BUFFER, triangleVertexPositionBuffer
  gl.vertexAttribPointer shaderProgram.vertexPositionAttribute, triangleVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0

  #draw triangle colors
  gl.bindBuffer(gl.ARRAY_BUFFER, triangleVertexColorBuffer)
  gl.vertexAttribPointer(shaderProgram.vertexColorAttribute, triangleVertexColorBuffer.itemSize, gl.FLOAT, false, 0, 0)

  #woha! mega function, wonder what it does...
  setMatrixUniforms()

  gl.drawArrays gl.TRIANGLES, 0, triangleVertexPositionBuffer.numItems

  #mat4.. it moves origin of draw...
  mat4.translate mvMatrix, [3.0, 0.0, -10.0]
  mat4.rotate(mvMatrix, degToRad(pitchCube), [1, 0, 0]);
  mat4.rotate(mvMatrix, degToRad(yawCube), [0, 1, 0]);
  mat4.rotate(mvMatrix, degToRad(rollCube), [0, 0, 1]);

  draw = () ->
    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexPositionBuffer);
    gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute, cubeVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexColorBuffer);
    gl.vertexAttribPointer(shaderProgram.vertexColorAttribute, cubeVertexColorBuffer.itemSize, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer)
    #again with this mega func..,
    setMatrixUniforms()
    gl.drawElements(gl.TRIANGLES, cubeVertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0);

  for mov in movMat
    mvPushMatrix()
    mat4.translate(mvMatrix, mov)
    draw()
    mvPopMatrix()

cubeRotCtrl = [0.0,0.0,0.0]
ctrlPanel = ->
  $("#ctrl").append("<div class='selectBox' index=0>Pitch</div>")
  $("#ctrl").append("<div class='selectBox' index=1>Yaw</div>")
  $("#ctrl").append("<div class='selectBox' index=2>Roll</div>")

  $("")

  $("#ctrl").on "click", (e) ->
    console.log e
    index = $(e.target).attr("index")
    console.log index
    if index?
      console.log cubeRotCtrl[index]
      if cubeRotCtrl[index] == 0
        cubeRotCtrl[index] = 1.0
      else if cubeRotCtrl[index] == 1.0
        cubeRotCtrl[index] = -1.0
      else if cubeRotCtrl[index] == -1.0
        cubeRotCtrl[index] = 0
      $(e.target).attr "val", cubeRotCtrl[index]
      console.log cubeRotCtrl

lastTime = 0
animate = () ->
  now = new Date().getTime()
  if (lastTime != 0)
    elapsed = now - lastTime;
    pitchCube += cubeRotCtrl[0] * (75 * elapsed) / 1000.0
    yawCube += cubeRotCtrl[1] * (75 * elapsed) / 1000.0
    rollCube += cubeRotCtrl[2] * (75 * elapsed) / 1000.0
  lastTime = now;

write = (fps) ->
  $("#fps").html(Math.round(fps))
n = 0
last = new Date().getTime()
tick = ->
  now = new Date().getTime()
  requestAnimFrame(tick)
  n++
  drawScene()
  animate(now)
  if n % 100 is 0
    since = now - last
    last = new Date().getTime()
    fps = 1000 / (since / 100)
    write(fps)


webGLStart = ->
  canvas = document.getElementById("canvas")
  console.log canvas
  initGL canvas
  initShaders()
  initBuffers()
  gl.clearColor 0.0, 0.0, 0.0, 1.0
  gl.enable gl.DEPTH_TEST
  ctrlPanel()
  #looper()
  tick()

window.webGLStart = webGLStart
window.drawScene = drawScene

window.symbolicArr = symbolicArr
window.symbolicStr = symbolicStr