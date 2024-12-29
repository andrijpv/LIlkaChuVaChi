-- Кольори
WHITE = display.color565(255, 255, 255)
BLACK = display.color565(0, 0, 0)
YELLOW = display.color565(255, 255, 0)
RED = display.color565(255, 0, 0)
MAGENTA = display.color565(255, 0, 255)

-- Звук кидання кубиків
ROLL_SOUND = {
    {440, 8},
    {523, 8},
    {659, 8},
    {784, 8},
    {880, 8},
}

-- Звук вибору
SELECT_SOUND = {
    {660, 8},
    {880, 8},
}

-- Завантаження зображень з прозорим кольором MAGENTA
local IMAGES = {
    stone = nil,
    scissors = nil,
    paper = nil
}

-- Завантаження зображень
function load_images()
    IMAGES.stone = resources.load_image("stone.bmp", MAGENTA)
    IMAGES.scissors = resources.load_image("scissors.bmp", MAGENTA)
    IMAGES.paper = resources.load_image("paper.bmp", MAGENTA)
end

-- Отримання зображення за значенням кубика
function get_image_for_value(value)
    if value <= 2 then
        return IMAGES.stone
    elseif value <= 4 then
        return IMAGES.scissors
    else
        return IMAGES.paper
    end
end

function get_winner(value1, value2)
    local symbol1 = math.ceil(value1 / 2)
    local symbol2 = math.ceil(value2 / 2)
    
    if symbol1 == symbol2 then
        return 0  -- нічия
    elseif (symbol1 == 1 and symbol2 == 2) or -- Камінь б'є ножиці
           (symbol1 == 2 and symbol2 == 3) or -- Ножиці б'ють папір
           (symbol1 == 3 and symbol2 == 1) then -- Папір б'є камінь
        return 1  -- переміг гравець 1
    else
        return 2  -- переміг гравець 2
    end
end

Dice = {
    x = 0,
    y = 0,
    size = 80,
    color = WHITE,
    current_value = 1,
    is_rolling = false,
    roll_start_time = 0,
    roll_duration = 1,
    is_winner = false
}

function Dice:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Dice:roll()
    if not self.is_rolling then
        self.is_rolling = true
        self.roll_start_time = util.time()
        -- Скидаємо статус переможця при новому кидку
        self.is_winner = false
    end
end

function Dice:update()
    if self.is_rolling then
        local time_elapsed = util.time() - self.roll_start_time
        if time_elapsed < self.roll_duration then
            self.current_value = math.floor(math.random() * 6) + 1
        else
            self.current_value = math.floor(math.random() * 6) + 1
            self.is_rolling = false
        end
    end
end

function Dice:draw()
    -- Малюємо фон тільки якщо це переможець
    if self.is_winner then
        display.fill_rect(self.x - self.size/2, self.y - self.size/2, self.size, self.size, self.color)
    end
    
    -- Відображаємо зображення
    local img = get_image_for_value(self.current_value)
    if img then
        local x = self.x - img.width/2
        local y = self.y - img.height/2
        display.draw_image(img, x, y)
    end
end

STATES = {
    HELLO = 0,
    IN_GAME = 1,
}

local game_state = STATES.HELLO
local dice1 = nil
local dice2 = nil

function setup_game()
    load_images()
    
    dice1 = Dice:new({
        x = display.width/2 - 70,
        y = display.height/2 - 50,
        color = WHITE
    })
    dice2 = Dice:new({
        x = display.width/2 + 70,
        y = display.height/2 - 50,
        color = WHITE
    })
end

function lilka.update(delta)
    local state = controller.get_state()
    
    if game_state == STATES.HELLO then
        if state.a.just_pressed then
            setup_game()
            game_state = STATES.IN_GAME
        end
    else
        dice1:update()
        dice2:update()
        
        if state.a.just_pressed then
            if not dice1.is_rolling and not dice2.is_rolling then
                dice1:roll()
                dice2:roll()
                buzzer.play_melody(ROLL_SOUND, 400)
            end
        end
        
        if state.b.just_pressed then
            util.exit()
        end
    end
end

function lilka.draw()
    if game_state == STATES.HELLO then
        display.fill_screen(BLACK)
        display.set_cursor(display.width/2 - 80, display.height/2 - 20)
        display.print("Чу-Ва-Чі")
        display.set_cursor(display.width/2 - 80, display.height/2 + 20)
        display.print("Натисніть A")
    else
        display.fill_screen(BLACK)
        
        -- Малюємо кубики
        dice1:draw()
        dice2:draw()
        
        -- Виводимо назви гравців
        display.set_cursor(dice1.x - 30, dice1.y - 80)
        display.print("Гравець 1")
        display.set_cursor(dice2.x - 30, dice2.y - 80)
        display.print("Гравець 2")
        
        -- Виводимо результат
        if not dice1.is_rolling and not dice2.is_rolling then
            local winner = get_winner(dice1.current_value, dice2.current_value)
            -- Оновлюємо статус переможця для кубиків
            dice1.is_winner = (winner == 1)
            dice2.is_winner = (winner == 2)
            
            -- Виводимо текст результату
            local result_text = "Нічия!"
            if winner == 1 then
                result_text = "Переміг гравець 1!"
            elseif winner == 2 then
                result_text = "Переміг гравець 2!"
            end
            
            display.set_cursor(display.width/2 - 60, display.height - 100)
            display.print(result_text)
        end

        -- Інструкції
        display.set_cursor(10, display.height - 40)
        display.print("A - Ще раз")
        display.set_cursor(10, display.height - 20)
        display.print("B - вихід")
    end
end