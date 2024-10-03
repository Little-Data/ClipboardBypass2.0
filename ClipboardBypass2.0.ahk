#SingleInstance force  ;确定脚本已在运行时是否允许再次运行，force跳过对话框并自动替换旧实例
A_IconTip := "ClipboardBypass2.0"  ;托盘悬浮提示
A_TrayMenu.Add()  ; 创建分隔线
A_TrayMenu.Add("About", MenuHandler)  ; 创建新菜单项
Persistent  ;防止脚本在最后一个线程完成后自动退出， 允许它在空闲状态下运行

MenuHandler(About,*) {  ;完整：MenuHandler(ItemName, ItemPos, MyMenu)
    MsgBox "该软件由HAF半个水果在前人的基础上使用2.0 Autohotkey版本编写`nGithub：https://github.com/Little-Data/ClipboardBypass2.0"
}
MsgBox "
   (
    绕过某些禁止粘贴的网站或应用。`n像往常一样使用Ctrl C复制和Ctrl V粘贴即可。`n文本会以打字的形式粘贴。`n请在粘贴前切换到英文输入法！`n请在粘贴前切换到英文输入法！`n请在粘贴前切换到英文输入法！`n请在粘贴前切换到英文输入法！`n注意：不支持粘贴图片！`n`n右键托盘图标可选择Suspend Hotkeys或Pause Script来禁用该软件，选择Exit来退出该软件。
  )", "ClipboardBypass2.0", "64"
^V::Sendinput "{Raw}" A_Clipboard

;^V：粘贴的快捷键，Sendinput：模拟键盘输入，{Raw}：原始模式输入字符，A_Clipboard：当前剪贴板内容
