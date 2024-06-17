local crosshair = {5825260,5825281,5825270,5825265,5825471,5825498,5825489,5825480,5825568,5825587,5825578,5825573,5825633,5825660,5825651,5825638,5825638,5825159,5825180,5825175,5825170}
local ffi = require 'ffi'
local memory = require 'memory'
local vkeys = require 'vkeys'

local imgui = require('imgui')
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local inicfg = require 'inicfg'
local directIni = 'InfCrosshair.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        Radius = 5,
        Lenght = 14,
        Thickness = 5,
        Button = 88,
        Check = false,
        Color = -16776961,
        activeOnStart = true
    },  
}, directIni))
inicfg.save(ini, directIni)
        
local window = imgui.ImBool(false)
local menu = {
    Lenght = imgui.ImInt(ini.main.Lenght),
    Radius = imgui.ImInt(ini.main.Radius),
    Thickness = imgui.ImInt(ini.main.Thickness),
    Color = imgui.ImFloat4(imgui.ImColor(ini.main.Color):GetFloat4()),
    Check = imgui.ImBool(ini.main.Check),
    Button = imgui.ImInt(ini.main.Button),
    ActiveOnStart = imgui.ImBool(ini.main.activeOnStart)
}

local setKey = false
local active = ini.main.activeOnStart
 
function main()
    while not isSampAvailable() do wait(0) end
    local sx, sy = convert3DCoordsToScreen(GerCrosshairPosition())
    imgui.Process = false
    style()
    sampRegisterChatCommand('cross', function()
        window.v = not window.v
    end)
    RGB = join_argb(menu.Color.v[4]*255, menu.Color.v[1]*255, menu.Color.v[2]*255, menu.Color.v[3]*255)
    while true do
        wait(0)
        if wasKeyPressed(tonumber("0x"..fromDec(ini.main.Button, 16))) and not sampIsCursorActive() then
            active = not active
        end
        dactive = true
        if isKeyDown(vkeys.VK_RBUTTON) then
            local currentWeapon = getCurrentCharWeapon(PLAYER_PED)
            if menu.Check.v or currentWeapon == 34 then
                dactive = false
            end
        end
        if not window.v then
            setKey = false
            menu.Button = ini.main.Button
        end 
        if active and dactive and not isCharDead(PLAYER_PED) then
            renderFigure2D(
            sx + (tonumber(ini.main.Thickness) - 1)/2,
            sy + (tonumber(ini.main.Thickness) - 1)/2, 
            tonumber(ini.main.Lenght), tonumber(ini.main.Radius),
            tonumber(ini.main.Thickness),
            '0x'..ColorCorrection(('%0X'):format(RGB))
        )
        end
        imgui.Process = window.v
    end
end

function ColorCorrection(string)
    if #string > 8 then
        return string:sub(#string-7, #string)
    else return string end
end

function GerCrosshairPosition()
    local vec_out = ffi.new("float[3]")
    local tmp_vec = ffi.new("float[3]")
    ffi.cast(
        "void (__thiscall*)(void*, float, float, float, float, float*, float*)",
        0x514970
    )(
        ffi.cast("void*", 0xB6F028),
        15.0,
        tmp_vec[0], tmp_vec[1], tmp_vec[2],
        tmp_vec,
        vec_out
    )
    return vec_out[0], vec_out[1], vec_out[2]
end

local crosshair = {5825260,5825281,5825270,5825265,5825471,5825498,5825489,5825480,5825568,5825587,5825578,5825573,5825633,5825660,5825651,5825638,5825638,5825159,5825180,5825175,5825170}

function crosshair(param)
    for i, val in ipairs(crosshair) do
        memory.write(val, param and 255 or 0, 1, true)
    end
end

function renderFigure2D(x, y, points, radius, thickness, color)
    local step = math.pi * 2 / points
    local render_start, render_end = {}, {}
    for i = 0, math.pi * 2, step do
        render_start[1] = radius * math.cos(i) + x
        render_start[2] = radius * math.sin(i) + y
        render_end[1] = radius * math.cos(i + step) + x
        render_end[2] = radius * math.sin(i + step) + y
        renderDrawLine(render_start[1], render_start[2], render_end[1], render_end[2], thickness, color)
    end
end
        
function imgui.OnDrawFrame()
    if window.v then
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 300, 215 -- WINDOW SIZE
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - sizeX / 2, resY / 2 - sizeY / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('Static Crosshair Config', window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        if imgui.InputInt('Lenght', menu.Lenght) then
            ini.main.Lenght = menu.Lenght.v
            inicfg.save(ini, directIni)
        end

        if imgui.InputInt('Radius', menu.Radius) then
            ini.main.Radius = menu.Radius.v
            inicfg.save(ini, directIni)
        end

        if imgui.InputInt('Thickness', menu.Thickness) then
            ini.main.Thickness = menu.Thickness.v
            inicfg.save(ini, directIni)
        end

        if imgui.ColorEdit4("Color", menu.Color) then
            RGB = join_argb(menu.Color.v[4]*255, menu.Color.v[1]*255, menu.Color.v[2]*255, menu.Color.v[3]*255)
            ini.main.Color = join_argb(menu.Color.v[4]*255, menu.Color.v[3]*255, menu.Color.v[2]*255, menu.Color.v[1]*255)
            inicfg.save(ini, directIni)
        end
        
        if imgui.Checkbox('Disable crosshair when aiming', menu.Check) then
            ini.main.Check = menu.Check.v
            inicfg.save(ini, directIni)
        end
        if imgui.Checkbox('Active On Start', menu.ActiveOnStart) then
            ini.main.activeOnStart = menu.ActiveOnStart.v
            inicfg.save(ini, directIni)
        end
        
        imgui.Text('Button: '..vkeys.id_to_name(ini.main.Button))
        if imgui.Button(setKey and "Save Button" or "Change Button") then
            setKey = not setKey
            lockPlayerControl(setKey)
        end
 
        if setKey then
            for k, i in pairs(vkeys) do
                if isKeyJustPressed(vkeys[k]) then
                    ini.main.Button = vkeys[k]
                    menu.Button = vkeys[k]
                    inicfg.save(ini, directIni)
                end
            end 
        end  
        imgui.End()
    end
end

function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end

function fromDec(input, base)
    local hexstr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local s = ''
    while input > 0 do
        local mod = math.fmod(input, base)
        s = string.sub(hexstr, mod + 1, mod + 1) .. s
        input = math.floor(input / base)
    end 
    if s == '' then
        s = '0'
    end
    return s
end

function style()
    imgui.SwitchContext()
	style = imgui.GetStyle()
    colors = style.Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    ImVec2 = imgui.ImVec2
    
	style.WindowRounding = 2.0
    style.WindowTitleAlign = ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0
	colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
    colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(1, 1, 1, 0.5)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.52, 0.2, 0.92, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.60, 0.2, 1.00, 1.00)
    colors[clr.ComboBg] = ImVec4(0.20, 0.20, 0.20, 0.70)
    colors[clr.CheckMark] = ImVec4(0.52, 0.2, 0.92, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.52, 0.2, 0.92, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.60, 0.2, 1.00, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
end