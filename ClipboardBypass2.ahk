; 脚本设置指令
#SingleInstance Force  ; 只允许单个实例运行
#Requires AutoHotkey v2.0  ; 要求AHK v2.0版本
A_IconTip := "ClipboardBypass 2"  ; 托盘图标提示文本
Persistent  ; 保持脚本持续运行

; 默认设置值
global Settings := {
    HumanTypingEnabled: false,  ; 是否启用模拟打字
    TypoRate: 5,               ; 错字率百分比 (0-100)，0表示禁用
    DelayBetweenLines: [200, 800],  ; 行间延迟范围 (毫秒)
    DelayBetweenChars: [30, 150],   ; 字符间延迟范围 (毫秒)
    BackspaceDelay: [30, 100],      ; 回删延迟范围 (毫秒)
    ScriptEnabled: true,        ; 是否启用脚本
    IsTypingRunning: false,      ; 运行状态标志 (用于检测当前是否有输入操作在进行)
    ShowHelpOnStartup: true,    ; 是否在启动时显示帮助
    DelayExecutionEnabled: false,  ; 是否启用延迟执行
    ExecutionDelay: 3000           ; 延迟执行时间(毫秒)，默认3秒
}

; INI配置文件路径
iniFile := A_ScriptDir "\ClipboardBypass2.ini"

; 加载保存的设置
LoadSettings()

; 显示启动帮助
ShowStartupHelp()

; 创建托盘菜单
Tray := A_TrayMenu
Tray.Delete()  ; 删除默认菜单项
; 添加自定义菜单项
Tray.Add("启用脚本", ToggleScript)
Tray.Add("模拟打字", ToggleHumanTyping)
Tray.Add("停止当前操作", StopCurrentOperation)
Tray.Add() ; 添加分隔线
Tray.Add("设置", ShowSettings)
Tray.Add("帮助", MenuHelpHandler) 
Tray.Add("关于", ShowAbout)
Tray.Add("退出", ExitScript)
Tray.Default := "启用脚本"  ; 设置默认菜单项

; 根据当前设置更新菜单项的勾选状态
if (Settings.ScriptEnabled)
    Tray.Check("启用脚本")
if (Settings.HumanTypingEnabled)
    Tray.Check("模拟打字")

; 主热键：Ctrl+Shift+V 粘贴剪贴板内容
^+v:: {
    global Settings

    ; 如果脚本被禁用则直接返回
    if !Settings.ScriptEnabled
        return

    ; 如果已经有操作在进行中，提示用户
    if (Settings.IsTypingRunning) {
        MsgBox "请等待当前操作完成！", "警告", "Icon!"
        return
    }

    ; 如果启用了延迟执行，先等待指定时间
    if (Settings.DelayExecutionEnabled) {
        Sleep Settings.ExecutionDelay
    }

    ; 获取剪贴板内容并检查是否为空
    if (clipText := A_Clipboard) != "" {
        Settings.IsTypingRunning := true  ; 标记运行状态
        try {
            ; 根据设置选择输入模式
            if (Settings.HumanTypingEnabled) {
                HumanLikeTyping(clipText)  ; 模拟人类输入
            } else {
                ; 普通模式：分段发送以便可以中断
                loop Parse clipText {
                    if !Settings.IsTypingRunning
                        break  ; 如果收到停止信号则中断
                    SendText A_LoopField
                    Sleep 10  ; 微小延迟确保可以检测中断
                }
            }
        } finally {
            Settings.IsTypingRunning := false  ; 确保运行状态被重置
        }
    } else {
        TrayTip "剪贴板为空",, "Mute"  ; 提示剪贴板为空
    }
}

; 模拟人类输入函数
HumanLikeTyping(text) {
    global Settings

    ; 按行循环处理文本
    loop Parse text, "`n", "`r" {
        ; 检查是否应该停止
        if !Settings.IsTypingRunning {
            return
        }
        
        ; 如果不是第一行，添加行间延迟
        if (A_Index > 1) {
            Sleep Random(Settings.DelayBetweenLines[1], Settings.DelayBetweenLines[2])
            Send "{Enter}"
            Sleep Random(100, 300)  ; 额外延迟
        }
      
        ; 逐个字符处理
        loop Parse A_LoopField {
            ; 检查是否应该停止
            if !Settings.IsTypingRunning {
                return
            }
            
            ; 根据错字率随机生成错字
            if (Settings.TypoRate > 0 && Random(1, 100) <= Settings.TypoRate) {
                wrongChar := GetWrongChar(A_LoopField)  ; 获取随机错字
                if (wrongChar != A_LoopField) {
                    SendText wrongChar
                    Sleep Random(50, 200)
                    Send "{Backspace}"  ; 模拟打错后删除
                    Sleep Random(Settings.BackspaceDelay[1], Settings.BackspaceDelay[2])
                }
            }
          
            ; 发送当前字符
            SendText A_LoopField
            Sleep Random(Settings.DelayBetweenChars[1], Settings.DelayBetweenChars[2])  ; 字符间随机延迟
        }
    }
}

; 加载INI设置
LoadSettings() {
    global Settings, iniFile
  
    ; 如果INI文件不存在，创建并使用默认设置
    if !FileExist(iniFile) {
        SaveSettingsToIni()
        return
    }
  
    try {
        ; 读取各种设置值
        Settings.ScriptEnabled := (IniRead(iniFile, "Settings", "ScriptEnabled", "true") = "true")
        Settings.HumanTypingEnabled := (IniRead(iniFile, "Settings", "HumanTypingEnabled", "false") = "true")
        Settings.TypoRate := IniRead(iniFile, "Settings", "TypoRate", Settings.TypoRate)
        Settings.ShowHelpOnStartup := (IniRead(iniFile, "Settings", "ShowHelpOnStartup", "true") = "true")
      
        ; 读取延迟范围设置
        Settings.DelayBetweenLines := StrSplit(IniRead(iniFile, "Settings", "DelayBetweenLines", Settings.DelayBetweenLines[1] "," Settings.DelayBetweenLines[2]), ",")
        Settings.DelayBetweenChars := StrSplit(IniRead(iniFile, "Settings", "DelayBetweenChars", Settings.DelayBetweenChars[1] "," Settings.DelayBetweenChars[2]), ",")
        Settings.BackspaceDelay := StrSplit(IniRead(iniFile, "Settings", "BackspaceDelay", Settings.BackspaceDelay[1] "," Settings.BackspaceDelay[2]), ",")
      
        ; 读取延迟执行设置
        Settings.DelayExecutionEnabled := (IniRead(iniFile, "Settings", "DelayExecutionEnabled", "false") = "true")
        Settings.ExecutionDelay := IniRead(iniFile, "Settings", "ExecutionDelay", Settings.ExecutionDelay) + 0

        ; 验证并修正延迟范围设置
        Settings.DelayBetweenLines := ValidateRange([Settings.DelayBetweenLines[1] + 0, Settings.DelayBetweenLines[2] + 0])
        Settings.DelayBetweenChars := ValidateRange([Settings.DelayBetweenChars[1] + 0, Settings.DelayBetweenChars[2] + 0])
        Settings.BackspaceDelay := ValidateRange([Settings.BackspaceDelay[1] + 0, Settings.BackspaceDelay[2] + 0])
    } catch as e {
        ; 出错时恢复默认设置
        MsgBox "加载设置失败: " e.Message "`n已恢复默认设置。", "错误", "Icon!"
        Settings.ScriptEnabled := true
        SaveSettingsToIni()
    }
}

; 验证并修正范围值
ValidateRange(rangeArray) {
    if (rangeArray[1] > rangeArray[2]) {
        ; 如果最小值大于最大值，交换它们
        return [rangeArray[2], rangeArray[1]]
    }
    return rangeArray
}

; 保存设置到INI文件
SaveSettingsToIni() {
    global Settings, iniFile
  
    try {
        ; 将设置写入INI文件
        IniWrite Settings.ScriptEnabled ? "true" : "false", iniFile, "Settings", "ScriptEnabled"
        IniWrite Settings.HumanTypingEnabled ? "true" : "false", iniFile, "Settings", "HumanTypingEnabled"
        IniWrite Settings.TypoRate, iniFile, "Settings", "TypoRate"
        IniWrite Settings.ShowHelpOnStartup ? "true" : "false", iniFile, "Settings", "ShowHelpOnStartup"
        IniWrite Settings.DelayBetweenLines[1] "," Settings.DelayBetweenLines[2], iniFile, "Settings", "DelayBetweenLines"
        IniWrite Settings.DelayBetweenChars[1] "," Settings.DelayBetweenChars[2], iniFile, "Settings", "DelayBetweenChars"
        IniWrite Settings.BackspaceDelay[1] "," Settings.BackspaceDelay[2], iniFile, "Settings", "BackspaceDelay"
        IniWrite Settings.DelayExecutionEnabled ? "true" : "false", iniFile, "Settings", "DelayExecutionEnabled"
        IniWrite Settings.ExecutionDelay, iniFile, "Settings", "ExecutionDelay"
    } catch as e {
        MsgBox "保存设置失败: " e.Message, "错误", "Icon!"
    }
}

/*
 * GUI设置窗口
 */
ShowSettings(*) {
    global Settings
    ; 创建GUI窗口
    MyGui := Gui(, "ClipboardBypass2 设置")
    MyGui.OnEvent("Close", GuiClose)
    MyGui.MarginX := 20
    MyGui.MarginY := 10
  
    ; 主框架
    MyGui.Add("GroupBox", "w300 h270", "启用脚本后，只有在模拟打字启用时这些设置才有效")
  
    ; 添加启用脚本复选框
    ScriptEnableCB := MyGui.Add("CheckBox", "xp+10 yp+25 Checked" Settings.ScriptEnabled, "启用脚本")
    ; 添加模拟打字复选框
    HumanTypingCB := MyGui.Add("CheckBox", "x+10 yp Checked" Settings.HumanTypingEnabled, "模拟打字")
    
    ; 错字率滑块
    MyGui.Add("Text", "xp-80 y+15 w80", "错字率 (" Settings.TypoRate "%):")
    TypoSlider := MyGui.Add("Slider", "x+0 yp w160 Range0-100 ToolTip", Settings.TypoRate)
  
    ; 使用表格式布局对齐延迟设置
    col1X := 30  ; 第一列X坐标
    col2X := 160 ; 第二列X坐标
    rowH := 50   ; 行高
    curY := 130  ; 当前Y坐标
  
    ; 行间延迟设置
    MyGui.Add("Text", "x" col1X " y" curY " w70", "行间延迟 (ms):")
    LineDelayMin := MyGui.Add("Edit", "x" col2X " yp w50 Number", Settings.DelayBetweenLines[1])
    MyGui.Add("Text", "x+5 yp+3 w10", "-")
    LineDelayMax := MyGui.Add("Edit", "x+5 yp-3 w50 Number", Settings.DelayBetweenLines[2])
    curY += rowH
  
    ; 字符间延迟设置
    MyGui.Add("Text", "x" col1X " y" curY " w70", "字符间延迟 (ms):")
    CharDelayMin := MyGui.Add("Edit", "x" col2X " yp w50 Number", Settings.DelayBetweenChars[1])
    MyGui.Add("Text", "x+5 yp+3 w10", "-")
    CharDelayMax := MyGui.Add("Edit", "x+5 yp-3 w50 Number", Settings.DelayBetweenChars[2])
    curY += rowH
  
    ; 回删延迟设置
    MyGui.Add("Text", "x" col1X " y" curY " w70", "回删延迟 (ms):")
    BkspDelayMin := MyGui.Add("Edit", "x" col2X " yp w50 Number", Settings.BackspaceDelay[1])
    MyGui.Add("Text", "x+5 yp+3 w10", "-")
    BkspDelayMax := MyGui.Add("Edit", "x+5 yp-3 w50 Number", Settings.BackspaceDelay[2])

    ; 延迟执行设置
    MyGui.Add("Text", "x" col1X " y" (curY + rowH) " w100", "启用延迟执行:")
    DelayExecutionCB := MyGui.Add("CheckBox", "x" col2X " y" (curY + rowH) " Checked" Settings.DelayExecutionEnabled)

    ; 延迟时间设置
    MyGui.Add("Text", "x" col1X " y" (curY + rowH + 30) " w100", "延迟时间 (秒):")
    ExecutionDelayEdit := MyGui.Add("Edit", "x" col2X " y" (curY + rowH + 30) " w50 Number", Settings.ExecutionDelay / 1000)

    ; 保存按钮
    SaveBtn := MyGui.Add("Button", "x100 y+25 w100", "保存设置")
    SaveBtn.OnEvent("Click", SaveSettings)
  
    MyGui.Show()
  
    ; 保存设置函数
    SaveSettings(*) {
        try {
            ; 从控件获取新值并转换为数字
            Settings.ScriptEnabled := ScriptEnableCB.Value
            Settings.HumanTypingEnabled := HumanTypingCB.Value
            Settings.TypoRate := TypoSlider.Value
            
            ; 转换延迟范围为数字并验证有效性
            lineMin := LineDelayMin.Text + 0
            lineMax := LineDelayMax.Text + 0
            charMin := CharDelayMin.Text + 0
            charMax := CharDelayMax.Text + 0
            bkspMin := BkspDelayMin.Text + 0
            bkspMax := BkspDelayMax.Text + 0
            execDelay := ExecutionDelayEdit.Text + 0

            ; 验证输入是否为有效数字
            ValidateNumberInput(LineDelayMin.Text, lineMin, "行间延迟最小值")
            ValidateNumberInput(LineDelayMax.Text, lineMax, "行间延迟最大值")
            ValidateNumberInput(CharDelayMin.Text, charMin, "字符间延迟最小值")
            ValidateNumberInput(CharDelayMax.Text, charMax, "字符间延迟最大值")
            ValidateNumberInput(BkspDelayMin.Text, bkspMin, "回删延迟最小值")
            ValidateNumberInput(BkspDelayMax.Text, bkspMax, "回删延迟最大值")
            ValidateNumberInput(ExecutionDelayEdit.Text, execDelay, "执行延迟时间")

            ; 赋值给设置
            Settings.DelayBetweenLines := [lineMin, lineMax]
            Settings.DelayBetweenChars := [charMin, charMax]
            Settings.BackspaceDelay := [bkspMin, bkspMax]
            Settings.DelayExecutionEnabled := DelayExecutionCB.Value
            Settings.ExecutionDelay := execDelay * 1000  ; 转换为毫秒
        
            ; 验证范围设置
            for range in [Settings.DelayBetweenLines, Settings.DelayBetweenChars, Settings.BackspaceDelay] {
                if (range[1] > range[2]) {
                    throw "最小值不能大于最大值"
                }
                if (range[1] < 0 || range[2] < 0) {
                    throw "延迟时间不能为负数"
                }
            }
            if (Settings.ExecutionDelay < 0) {
                throw "延迟时间不能为负数"
            }

            ; 保存设置到INI文件
            SaveSettingsToIni()
            
            ; 更新托盘菜单状态
            Tray := A_TrayMenu
            if (Settings.ScriptEnabled) {
                Tray.Check("启用脚本")
            } else {
                Tray.Uncheck("启用脚本")
            }
            
            if (Settings.HumanTypingEnabled) {
                Tray.Check("模拟打字")
            } else {
                Tray.Uncheck("模拟打字")
            }
            
            MsgBox "设置已保存!", "提示", "Iconi"
            MyGui.Destroy()
        } catch as e {
            MsgBox "无效设置: " e.Message, "错误", "Icon!"
        }
    }
  
    ValidateNumberInput(inputText, numericValue, fieldName) {
        ; 检查是否为空
        if (inputText = "") {
            throw fieldName "不能为空"
        }
        ; 检查是否为有效数字（非数字字符串转换后为0，但原始输入不是"0"）
        if (numericValue = 0 && inputText != "0" && inputText != "0.0") {
            throw fieldName "必须是有效的数字"
        }
    }

    ; GUI关闭事件处理
    GuiClose(*) {
        MyGui.Destroy()
    }
}

; 切换脚本启用状态
ToggleScript(*) {
    global Settings
    Settings.ScriptEnabled := !Settings.ScriptEnabled  ; 切换状态
    Tray.ToggleCheck("启用脚本")  ; 更新菜单勾选状态
    SaveSettingsToIni()  ; 保存设置
}

; 切换模拟打字状态
ToggleHumanTyping(*) {
    global Settings
    Settings.HumanTypingEnabled := !Settings.HumanTypingEnabled
    Tray.ToggleCheck("模拟打字")
    SaveSettingsToIni()
}

; 显示启动帮助
ShowStartupHelp(ItemName := "", ItemPos := "", MyMenu := "") {
    static hasShown := false  ; 静态变量记录是否已显示过
    global Settings
    
    helpText := "
    (LTrim
    ClipboardBypass 2.0 使用指南

    注意，该帮助只会在第一次启动时显示
    （当然你删了ini文件也会再次显示）
    你也可以右键托盘图标，点击帮助再次显示
  
    【主要功能】
    快捷键：Ctrl+Shift+V 粘贴剪贴板内容
    模拟打字输入（含可配置错字率）
    自定义输入延迟参数
  
    【使用技巧】
    1. 右键任务栏图标可：
    • 启用/禁用脚本
    • 开启/关闭模拟打字
    • 停止当前粘贴操作
    • 调整详细设置参数

    2. 模拟打字时：
    • 逼真的输入间隔
    • 支持模拟中文/英文错字

    3. 特殊符号：
    • 完全支持 #!^+ 等符号
  
    【注意事项】
    • 不支持图片粘贴
    • 不排除粘贴时有漏掉的情况
    • 所有设置在"设置"菜单中可调整
    • 启用脚本后，只有在模拟打字启用时设置才有效
    • 保存设置请按"保存设置按钮"，下次启动仍有效
    )"
    
    ; 菜单调用总是显示帮助
    if (ItemName != "" || ItemPos != "" || MyMenu != "") {
        MsgBox(helpText, "ClipboardBypass 使用指南", "Iconi")
        return
    }
    
    ; 首次启动且设置允许显示
    if (!hasShown && Settings.ShowHelpOnStartup) {
        MsgBox(helpText, "ClipboardBypass 使用指南", "Iconi")
        hasShown := true
        Settings.ShowHelpOnStartup := false
        SaveSettingsToIni()
    }
}
MenuHelpHandler(*) {  
    ShowStartupHelp("帮助", 0, A_TrayMenu)  
}
; 错字生成器（支持中文、字母、数字）
GetWrongChar(originalChar) {
    ; 处理英文字母
    if (originalChar ~= "[a-zA-Z0-9]") {
        ; 小写字母处理
        if (originalChar ~= "[a-z]") {
            offset := 0
            while (offset == 0) {
                offset := Random(-1, 1)  ; 生成相邻字母
            }
            return Chr(Ord(originalChar) + offset)
        }
        ; 大写字母处理
        else if (originalChar ~= "[A-Z]") {
            offset := 0
            while (offset == 0) {
                offset := Random(-1, 1)
            }
            return Chr(Ord(originalChar) + offset)
        }
        ; 数字处理
        else if (originalChar ~= "[0-9]") {
            wrongNum := originalChar + (Random(0, 1) ? 1 : -1)
            return Mod(wrongNum + 10, 10)  ; 确保数字在0-9范围内
        }
    }
    ; 中文字符处理
    else if (Ord(originalChar) >= 0x4E00 && Ord(originalChar) <= 0x9FFF) {
        ; 常见错别字映射
        static commonTypos := Map(
            "的", "得", "得", "的", "地", "的",
            "是", "事", "事", "是", "时", "十",
            "好", "号", "号", "好", "和", "河",
            "我", "握", "握", "我", "窝", "喔",
            "你", "泥", "泥", "你", "拟", "妮",
            "他", "她", "它", "塔", "踏", "塌"
        )
      
        ; 如果有预定义的常见错字，则从中随机选择一个
        if (commonTypos.Has(originalChar)) {
            typos := StrSplit(commonTypos[originalChar], "|")
            return typos[Random(1, typos.Length)]
        }
      
        ; 没有预定义的错字，则随机偏移Unicode码点
        return Chr(Ord(originalChar) + Random(-5, 5))
    }
  
    ; 其他字符保持不变
    return originalChar
}

; 显示关于信息
ShowAbout(*) {
    helpText := "
    (LTrim
该软件由HAF半个水果在前人的基础上使用2.0 Autohotkey版本编写

Github：https://github.com/Little-Data/ClipboardBypass2.0

最后更新：2025.11.17
    )"
    MsgBox helpText, "关于", "Iconi"
}

; 停止当前操作
StopCurrentOperation(*) {
    global Settings
    
    if (Settings.IsTypingRunning) {
        Settings.IsTypingRunning := false  ; 设置停止标志
        TrayTip "操作已停止",, "Iconi"    ; 提示用户
    } else {
        TrayTip "没有正在运行的操作",, "Icon!"  ; 提示没有运行中的操作
    }
}
; 退出脚本
ExitScript(*) {
    ExitApp  ; 退出程序
}