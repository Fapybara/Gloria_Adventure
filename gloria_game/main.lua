-- =========================================================
-- GLORIA RUN - Fapybara Edition
-- Runner estilo Pitfall/Atari com a Gloria, capivara mascote
-- do Fapybara. Agora com controle manual (setas) e 4 fases:
-- Por do Sol, Deserto, Noite e Selva.
-- =========================================================

local W, H = 680, 383
local GROUND_Y = 300 -- linha dos pes / colisao (fisica do personagem)
local GROUND_TOP = 210 -- onde o chao verde comeca visualmente (logo apos as montanhas)

-- ---------------------------------------------------------
-- Fases do jogo. Cada uma tem sua paleta e cenario proprio,
-- mas mantem a mesma mecanica.
-- ---------------------------------------------------------
local function c(r, g, b) return {r/255, g/255, b/255} end

local STAGES = {
    -- 1) POR DO SOL (fase original)
    {
        name = "POR DO SOL",
        skyBands = {
            {c(43,23,80), 0, 40}, {c(58,31,99), 40, 30}, {c(90,42,107), 70, 30},
            {c(138,52,104), 100, 30}, {c(192,74,92), 130, 30}, {c(232,112,63), 160, 30},
            {c(245,166,35), 190, 20},
        },
        celestial = "sun", celestialColor = c(255,233,168),
        mountainDark = c(36,18,56), mountainMid = c(51,34,79),
        ground = c(39,74,46), groundStripe = c(47,90,55),
        logDk = c(74,46,27), log = c(107,68,41), hazard = c(90,160,200),
        path = c(94,64,40), pathLine = c(130,90,55),
        propSpacing = 150,
        propDraw = function(x)
            -- palmeira simples
            love.graphics.setColor(c(74,46,27))
            love.graphics.rectangle("fill", x, GROUND_Y - 30, 8, 40)
            love.graphics.setColor(c(47,90,55))
            love.graphics.circle("fill", x + 4, GROUND_Y - 38, 20)
        end,
    },
    -- 2) DESERTO
    {
        name = "DESERTO",
        skyBands = {
            {c(255,236,179), 0, 60}, {c(255,214,140), 60, 40}, {c(255,183,110), 100, 40},
            {c(250,150,90), 140, 40}, {c(240,120,80), 180, 30},
        },
        celestial = "sun", celestialColor = c(255,250,220),
        mountainDark = c(150,90,50), mountainMid = c(196,130,70),
        ground = c(214,178,110), groundStripe = c(190,150,85),
        logDk = c(110,70,35), log = c(150,100,55), hazard = c(224,196,120),
        path = c(196,150,90), pathLine = c(224,182,112),
        propSpacing = 130,
        propDraw = function(x)
            -- cacto
            love.graphics.setColor(c(70,110,60))
            love.graphics.rectangle("fill", x, GROUND_Y - 34, 10, 34)
            love.graphics.rectangle("fill", x - 8, GROUND_Y - 22, 8, 8)
            love.graphics.rectangle("fill", x + 10, GROUND_Y - 26, 8, 8)
        end,
    },
    -- 3) NOITE
    {
        name = "NOITE",
        skyBands = {
            {c(8,10,28), 0, 60}, {c(14,16,42), 60, 60}, {c(20,24,58), 120, 60},
            {c(28,32,70), 180, 30},
        },
        celestial = "moon", celestialColor = c(230,230,245),
        mountainDark = c(10,10,20), mountainMid = c(18,18,32),
        ground = c(16,28,20), groundStripe = c(22,38,26),
        logDk = c(30,26,26), log = c(54,46,44), hazard = c(20,40,60),
        path = c(38,32,30), pathLine = c(58,50,46),
        propSpacing = 140,
        propDraw = function(x)
            -- pinheiro escuro (silhueta)
            love.graphics.setColor(c(10,14,18))
            love.graphics.polygon("fill", x, GROUND_Y, x + 12, GROUND_Y - 46, x + 24, GROUND_Y)
            love.graphics.polygon("fill", x + 3, GROUND_Y - 12, x + 12, GROUND_Y - 56, x + 21, GROUND_Y - 12)
        end,
        stars = true,
    },
    -- 4) SELVA
    {
        name = "SELVA",
        skyBands = {
            {c(20,60,50), 0, 50}, {c(30,84,64), 50, 50}, {c(50,110,74), 100, 50},
            {c(80,140,90), 150, 40}, {c(130,170,110), 190, 20},
        },
        celestial = "sun", celestialColor = c(230,255,200),
        mountainDark = c(14,40,28), mountainMid = c(22,58,38),
        ground = c(18,56,30), groundStripe = c(24,72,38),
        logDk = c(50,38,20), log = c(80,60,32), hazard = c(40,70,40),
        path = c(72,52,30), pathLine = c(96,72,42),
        propSpacing = 110,
        propDraw = function(x)
            -- arvore densa da selva com cipo
            love.graphics.setColor(c(60,42,24))
            love.graphics.rectangle("fill", x, GROUND_Y - 26, 10, 26)
            love.graphics.setColor(c(20,90,48))
            love.graphics.circle("fill", x + 5, GROUND_Y - 40, 26)
            love.graphics.setColor(c(16,70,36))
            love.graphics.rectangle("fill", x + 2, GROUND_Y - 16, 2, 16) -- cipo
        end,
    },
}

local STAGE_DISTANCE = 600 -- pontos de "distancia" pra trocar de fase

-- estrelas fixas pra fase noturna
local STARS = {}
for i = 1, 40 do
    table.insert(STARS, { x = math.random(0, W), y = math.random(0, 200), s = math.random(1,3), tw = math.random() * 6 })
end

-- ---------------------------------------------------------
-- Cores fixas do personagem e efeitos (nao mudam por fase)
-- ---------------------------------------------------------
local COLORS = {
    body = c(156,106,72),
    belly = c(185,138,104),
    dark = c(28,19,16),
    white = {1,1,1},
    firefly = c(255,209,102),
}

-- ---------------------------------------------------------
-- Estado do jogo
-- ---------------------------------------------------------
local state = "menu" -- menu | playing | gameover
local score = 0
local highscore = 0
local groundScroll = 0
local mountainScroll = 0
local treeScroll = 0
local currentStageIndex = 1
local stageBannerTimer = 0

-- Player (Gloria)
local player = {
    x = 90,
    y = GROUND_Y,
    w = 44,
    h = 30,
    vy = 0,
    onGround = true,
    ducking = false,
    legFrame = 0,
    legTimer = 0,
}

local GRAVITY = 1600
local JUMP_VELOCITY = -560
local BASE_SPEED = 220
local MAX_SPEED = 480
local BACK_SPEED = 130

-- controle por toque (mobile) alem do teclado (desktop)
local touchInput = { left = false, right = false }
local activeTouches = {} -- id do dedo -> nome do botao que ele esta segurando
local BUTTONS = {} -- preenchido em love.load, em coordenadas virtuais (W x H)
local canvas -- desenhamos tudo numa resolucao fixa e depois escalamos pra tela real
local viewScale, viewOffsetX, viewOffsetY = 1, 0, 0

-- Obstaculos e coletaveis
local obstacles = {}
local fireflies = {}
local spawnTimer = 0
local spawnInterval = 1.3

math.randomseed(os.time())

-- manchas fixas de "estrada velha" (nao piscam, so rolam com o cenario)
local ROAD_PATCH_LEN = 500
local ROAD_PATCHES = {}
for i = 1, 14 do
    table.insert(ROAD_PATCHES, {
        x = math.random(0, ROAD_PATCH_LEN),
        w = math.random(18, 60),
        h = math.random(4, 10),
        yOff = math.random(2, 24),
        shade = 0.85 + math.random() * 0.4, -- mais claro ou mais escuro que o marrom base
    })
end

-- ---------------------------------------------------------
-- Funcoes auxiliares
-- ---------------------------------------------------------
local function getStage()
    return STAGES[currentStageIndex]
end

local function updateStage()
    local idx = math.floor(score / STAGE_DISTANCE) % #STAGES + 1
    if idx ~= currentStageIndex then
        currentStageIndex = idx
        stageBannerTimer = 2.2
    end
end

local function resetGame()
    state = "playing"
    score = 0
    currentStageIndex = 1
    stageBannerTimer = 0
    obstacles = {}
    fireflies = {}
    spawnTimer = 0
    spawnInterval = 1.3
    player.y = GROUND_Y
    player.vy = 0
    player.onGround = true
    player.ducking = false
end

local function spawnObstacle()
    local kind = math.random(1, 3)
    if kind == 1 then
        table.insert(obstacles, { type = "log", x = W + 20, w = 34, h = 26 })
    elseif kind == 2 then
        table.insert(obstacles, { type = "log", x = W + 20, w = 56, h = 26 })
    else
        table.insert(obstacles, { type = "puddle", x = W + 20, w = 60, h = 18 })
    end

    if math.random() < 0.5 then
        table.insert(fireflies, { x = W + 60, y = GROUND_Y - 70 - math.random(0, 40), t = 0 })
    end
end

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- toras ficam em pe, saindo da trilha; a poca fica rente a superficie da estrada
local function obstacleTopY(o)
    if o.type == "puddle" then
        return GROUND_Y - 4 -- mesma altura do topo da trilha (pathY)
    else
        return GROUND_Y - o.h
    end
end

-- acoes do jogador, chamadas tanto pelo teclado quanto pelo toque
local function doJump()
    if state == "playing" and player.onGround and not player.ducking then
        player.vy = JUMP_VELOCITY
        player.onGround = false
    end
end

local function startDuck()
    if state == "playing" and player.onGround then
        player.ducking = true
    end
end

local function endDuck()
    player.ducking = false
end

-- calcula como a tela real (celular, janela redimensionada) se encaixa
-- na nossa resolucao virtual fixa (W x H), mantendo a proporção
local function computeViewTransform()
    local rw, rh = love.graphics.getWidth(), love.graphics.getHeight()
    viewScale = math.min(rw / W, rh / H)
    viewOffsetX = (rw - W * viewScale) / 2
    viewOffsetY = (rh - H * viewScale) / 2
end

-- converte coordenada real de toque/mouse pra coordenada virtual do jogo
local function screenToVirtual(x, y)
    return (x - viewOffsetX) / viewScale, (y - viewOffsetY) / viewScale
end

local function pointInRect(px, py, r)
    return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

-- processa um toque/clique novo: comeca a andar, pula ou agacha
local function pressAt(id, x, y)
    if state == "menu" or state == "gameover" then
        resetGame()
        return
    end
    local vx, vy = screenToVirtual(x, y)
    for name, r in pairs(BUTTONS) do
        if pointInRect(vx, vy, r) then
            activeTouches[id] = name
            if name == "left" then touchInput.left = true
            elseif name == "right" then touchInput.right = true
            elseif name == "jump" then doJump()
            elseif name == "duck" then startDuck()
            end
        end
    end
end

-- solta um toque/clique: para de andar ou de agachar
local function releaseAt(id)
    local name = activeTouches[id]
    if name == "left" then touchInput.left = false
    elseif name == "right" then touchInput.right = false
    elseif name == "duck" then endDuck()
    end
    activeTouches[id] = nil
end

-- ---------------------------------------------------------
-- love.load
-- ---------------------------------------------------------
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    font = love.graphics.newFont(16)
    fontBig = love.graphics.newFont(28)
    fontMid = love.graphics.newFont(20)
    love.graphics.setFont(font)

    canvas = love.graphics.newCanvas(W, H)
    computeViewTransform()

    -- botoes de toque (coordenadas na resolucao virtual W x H)
    local bw, bh, margin, gap = 58, 58, 10, 8
    local by = H - bh - margin
    BUTTONS.left  = { x = margin,                y = by, w = bw, h = bh }
    BUTTONS.right = { x = margin + bw + gap,     y = by, w = bw, h = bh }
    BUTTONS.duck  = { x = W - margin - bw*2 - gap, y = by, w = bw, h = bh }
    BUTTONS.jump  = { x = W - margin - bw,       y = by, w = bw, h = bh }
end

function love.resize(w, h)
    computeViewTransform()
end

-- ---------------------------------------------------------
-- love.update
-- ---------------------------------------------------------
function love.update(dt)
    -- velocidade controlada pelas setas (sem auto-run)
    local moveSpeed = 0
    if state == "playing" then
        local maxSpeed = math.min(MAX_SPEED, BASE_SPEED + score * 0.05)
        if love.keyboard.isDown("right") or touchInput.right then
            moveSpeed = maxSpeed
        elseif love.keyboard.isDown("left") or touchInput.left then
            moveSpeed = -BACK_SPEED
        end
    end

    groundScroll = (groundScroll + math.abs(moveSpeed) * dt) % 40
    mountainScroll = (mountainScroll + moveSpeed * 0.2 * dt) % W
    treeScroll = (treeScroll + moveSpeed * 0.6 * dt)

    if state ~= "playing" then return end

    if stageBannerTimer > 0 then stageBannerTimer = stageBannerTimer - dt end

    -- pontuacao so avanca correndo pra frente
    if moveSpeed > 0 then
        score = score + moveSpeed * dt * 0.12
    end
    updateStage()

    -- fisica do pulo
    if not player.onGround then
        player.vy = player.vy + GRAVITY * dt
        player.y = player.y + player.vy * dt
        if player.y >= GROUND_Y then
            player.y = GROUND_Y
            player.vy = 0
            player.onGround = true
        end
    end

    -- animacao de correr (troca de perna), so quando anda
    if moveSpeed ~= 0 then
        player.legTimer = player.legTimer + dt
        if player.legTimer > 0.12 then
            player.legTimer = 0
            player.legFrame = 1 - player.legFrame
        end
    end

    -- spawn de obstaculos, so acontece com o mundo em movimento pra frente
    if moveSpeed > 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnTimer = 0
            spawnInterval = math.max(0.55, 1.3 - (score / STAGE_DISTANCE) * 0.05)
            spawnObstacle()
        end
    end

    -- move obstaculos e vagalumes conforme o movimento do jogador
    for i = #obstacles, 1, -1 do
        local o = obstacles[i]
        o.x = o.x - moveSpeed * dt
        if o.x + o.w < 0 or o.x > W + 400 then
            table.remove(obstacles, i)
        end
    end

    for i = #fireflies, 1, -1 do
        local f = fireflies[i]
        f.x = f.x - moveSpeed * dt
        f.t = f.t + dt
        if f.x < -20 or f.x > W + 400 then
            table.remove(fireflies, i)
        end
    end

    -- colisao jogador x obstaculos
    local px, py, pw, ph = player.x, player.y - player.h, player.w, player.h
    if player.ducking then
        py = player.y - player.h * 0.55
        ph = player.h * 0.55
    end

    for _, o in ipairs(obstacles) do
        local oy = obstacleTopY(o)
        if aabb(px, py, pw, ph, o.x, oy, o.w, o.h) then
            state = "gameover"
            if score > highscore then highscore = score end
        end
    end

    for i = #fireflies, 1, -1 do
        local f = fireflies[i]
        if aabb(px, py, pw, ph, f.x - 6, f.y - 6, 12, 12) then
            score = score + 50
            table.remove(fireflies, i)
        end
    end
end

-- ---------------------------------------------------------
-- love.keypressed / keyreleased
-- ---------------------------------------------------------
function love.keypressed(key)
    if state == "menu" then
        if key == "space" or key == "return" then
            resetGame()
        end
    elseif state == "playing" then
        if key == "up" or key == "space" or key == "w" then
            doJump()
        elseif key == "down" then
            startDuck()
        end
    elseif state == "gameover" then
        if key == "space" or key == "return" then
            resetGame()
        end
    end

    if key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key)
    if key == "down" then
        endDuck()
    end
end

-- suporte a toque (celular/tablet)
function love.touchpressed(id, x, y)
    pressAt(id, x, y)
end

function love.touchreleased(id, x, y)
    releaseAt(id)
end

-- suporte a mouse (pra testar os botoes no PC tambem)
function love.mousepressed(x, y, button)
    if button == 1 then
        pressAt("mouse", x, y)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        releaseAt("mouse")
    end
end

-- ---------------------------------------------------------
-- Desenho do cenario
-- ---------------------------------------------------------
local function drawSky(stage)
    for _, b in ipairs(stage.skyBands) do
        love.graphics.setColor(b[1])
        love.graphics.rectangle("fill", 0, b[2], W, b[3])
    end

    if stage.stars then
        for _, s in ipairs(STARS) do
            local a = 0.5 + 0.5 * math.sin(love.timer.getTime() * 2 + s.tw)
            love.graphics.setColor(1, 1, 1, a)
            love.graphics.rectangle("fill", s.x, s.y, s.s, s.s)
        end
    end

    love.graphics.setColor(stage.celestialColor)
    if stage.celestial == "moon" then
        love.graphics.circle("fill", 560, 90, 34)
    else
        love.graphics.circle("fill", 560, 120, 46)
    end
end

local function drawMountains(stage)
    love.graphics.setColor(stage.mountainDark)
    local offset = -mountainScroll
    for k = -1, 2 do
        local ox = offset + k * W
        love.graphics.polygon("fill", ox+0,215, ox+60,150, ox+120,215)
        love.graphics.polygon("fill", ox+100,215, ox+170,160, ox+240,215)
        love.graphics.polygon("fill", ox+600,215, ox+660,155, ox+680,180, ox+680,215)
    end

    love.graphics.setColor(stage.mountainMid)
    for k = -1, 2 do
        local ox = offset + k * W
        love.graphics.polygon("fill", ox+180,215, ox+260,170, ox+340,215)
        love.graphics.polygon("fill", ox+440,215, ox+520,165, ox+600,215)
    end
end

local function drawProps(stage)
    local off = treeScroll % stage.propSpacing
    local x = -off
    while x < W + stage.propSpacing do
        stage.propDraw(x)
        x = x + stage.propSpacing
    end
end

local PATH_HEIGHT = 52 -- altura da trilha de terra por onde a Gloria corre (alargada)
local SHADOW_HEIGHT = 14 -- sombra logo abaixo da trilha, antes do vazio escuro

local function drawGround(stage)
    local pathY = GROUND_Y - 4

    -- area verde/areia/etc: só ate a trilha, nao ate o fundo da tela
    love.graphics.setColor(stage.ground)
    love.graphics.rectangle("fill", 0, GROUND_TOP, W, pathY - GROUND_TOP)

    -- trilha de terra: e por cima dela que a Gloria corre de verdade
    love.graphics.setColor(stage.path)
    love.graphics.rectangle("fill", 0, pathY, W, PATH_HEIGHT)

    -- manchas fixas de desgaste, pra parecer estrada velha (rola junto, nao pisca)
    local roadOffset = -(groundScroll * 12.5) % ROAD_PATCH_LEN
    for k = -1, math.ceil(W / ROAD_PATCH_LEN) + 1 do
        local baseX = roadOffset + k * ROAD_PATCH_LEN
        for _, p in ipairs(ROAD_PATCHES) do
            local px = baseX + p.x
            if px + p.w > 0 and px < W then
                love.graphics.setColor(stage.path[1] * p.shade, stage.path[2] * p.shade, stage.path[3] * p.shade)
                love.graphics.rectangle("fill", px, pathY + p.yOff, p.w, p.h)
            end
        end
    end

    -- sombra escura embaixo da trilha (a "espessura" da beirada)
    love.graphics.setColor(stage.path[1] * 0.5, stage.path[2] * 0.5, stage.path[3] * 0.5)
    love.graphics.rectangle("fill", 0, pathY + PATH_HEIGHT, W, SHADOW_HEIGHT)

    -- vazio escuro embaixo de tudo, e o que da a sensacao de "beirada" elevada
    love.graphics.setColor(0, 0, 0)
    local voidY = pathY + PATH_HEIGHT + SHADOW_HEIGHT
    love.graphics.rectangle("fill", 0, voidY, W, H - voidY)
end

-- desenha a Gloria (retangulos estilo pixel art)
local function drawGloria()
    local x, y = player.x, player.y
    local legOffset = player.legFrame == 0 and 4 or -4

    love.graphics.push()
    love.graphics.translate(x, y)

    if player.ducking and player.onGround then
        love.graphics.setColor(COLORS.body)
        love.graphics.rectangle("fill", -4, -16, 44, 16)
        love.graphics.setColor(COLORS.belly)
        love.graphics.rectangle("fill", -4, -8, 30, 8)
        love.graphics.setColor(COLORS.dark)
        love.graphics.rectangle("fill", 30, -14, 4, 4)
    else
        love.graphics.setColor(COLORS.body)
        love.graphics.rectangle("fill", 0, -28, 34, 22)
        love.graphics.rectangle("fill", 26, -30, 16, 16)

        love.graphics.setColor(COLORS.belly)
        love.graphics.rectangle("fill", 2, -14, 26, 8)

        love.graphics.setColor(COLORS.dark)
        love.graphics.rectangle("fill", 30, -32, 4, 4)
        love.graphics.rectangle("fill", 38, -26, 3, 3)
        love.graphics.setColor(COLORS.belly)
        love.graphics.rectangle("fill", 40, -22, 4, 4)

        love.graphics.setColor(COLORS.dark)
        love.graphics.rectangle("fill", 4, -6, 6, 6)
        love.graphics.rectangle("fill", 20 + legOffset, -6, 6, 6)
    end

    love.graphics.pop()
end

local function drawObstacle(o, stage)
    local oy = obstacleTopY(o)
    if o.type == "log" then
        love.graphics.setColor(stage.logDk)
        love.graphics.rectangle("fill", o.x, oy, o.w, o.h)
        love.graphics.setColor(stage.log)
        love.graphics.rectangle("fill", o.x + 3, oy + 3, o.w - 6, o.h - 8)
    else
        love.graphics.setColor(stage.hazard)
        love.graphics.ellipse("fill", o.x + o.w/2, oy + o.h/2, o.w/2, o.h/2)
    end
end

local function drawButtons()
    local function drawBtn(r, label, held)
        love.graphics.setColor(1, 1, 1, held and 0.45 or 0.22)
        love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 10, 10)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 10, 10)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(fontMid)
        love.graphics.printf(label, r.x, r.y + r.h/2 - 12, r.w, "center")
    end

    drawBtn(BUTTONS.left, "<", touchInput.left)
    drawBtn(BUTTONS.right, ">", touchInput.right)
    drawBtn(BUTTONS.duck, "v", player.ducking)
    drawBtn(BUTTONS.jump, "^", not player.onGround)
end

local function drawFirefly(f)
    local glow = 0.6 + 0.4 * math.sin(f.t * 8)
    love.graphics.setColor(COLORS.firefly[1], COLORS.firefly[2], COLORS.firefly[3], glow)
    love.graphics.circle("fill", f.x, f.y, 4)
end

-- ---------------------------------------------------------
-- love.draw
-- ---------------------------------------------------------
function love.draw()
    computeViewTransform()
    local stage = getStage()

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)

    drawSky(stage)
    drawMountains(stage)
    drawProps(stage)
    drawGround(stage)

    for _, o in ipairs(obstacles) do drawObstacle(o, stage) end
    for _, f in ipairs(fireflies) do drawFirefly(f) end
    drawGloria()

    -- HUD
    love.graphics.setColor(COLORS.white)
    love.graphics.setFont(font)
    love.graphics.print("SCORE " .. math.floor(score), 16, 12)
    love.graphics.print("BEST " .. math.floor(highscore), 16, 32)
    love.graphics.printf(stage.name, 0, 12, W - 16, "right")

    if stageBannerTimer > 0 and state == "playing" then
        local a = math.min(1, stageBannerTimer)
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.setFont(fontMid)
        love.graphics.printf("FASE: " .. stage.name, 0, 70, W, "center")
    end

    if state == "menu" then
        love.graphics.setColor(COLORS.white)
        love.graphics.setFont(fontBig)
        love.graphics.printf("GLORIA RUN", 0, 110, W, "center")
        love.graphics.setFont(font)
        love.graphics.printf("toque na tela ou aperte ESPACO pra comecar", 0, 155, W, "center")
        love.graphics.printf("SETAS / botoes = andar    CIMA/^ = pular    BAIXO/v = agachar", 0, 178, W, "center")
    elseif state == "gameover" then
        love.graphics.setColor(COLORS.white)
        love.graphics.setFont(fontBig)
        love.graphics.printf("FIM DE JOGO", 0, 130, W, "center")
        love.graphics.setFont(font)
        love.graphics.printf("toque na tela ou ESPACO pra tentar de novo", 0, 175, W, "center")
    end

    if state == "playing" then
        drawButtons()
    end

    -- devolve pro backbuffer real, escalado e centralizado (letterbox)
    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, viewOffsetX, viewOffsetY, 0, viewScale, viewScale)
end