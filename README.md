# ClipboardBypass2
绕过禁止粘贴限制，模拟键盘输入。

[ClipboardBypass2下载入口](https://github.com/Little-Data/ClipboardBypass2.0/releases)

Bypass the prohibition of pasting restrictions and simulate keyboard typing.

>[!important]
>注意检查粘贴后的文本，有些内容可能会在粘贴后消失（原因是输入太快了，可能电脑一卡就不见了）
>Pay attention to check the pasted text, some content may disappear after pasting (the reason is that the input is too fast, and the computer may disappear as soon as the computer is lagging)

# 目前实现的功能

模拟打字输入（含可配置错字率，就是打错字后删掉再写正确的）

自定义输入延迟参数（仅限启用了模拟打字输入）

支持快捷键更换，默认快捷键：Ctrl+Shift+V 防止误操作

可以停止当前粘贴操作

# 自定义快捷键说明

<details>
<summary>展开查看长图</summary>

<img src="https://github.com/user-attachments/assets/09759c8a-fd9c-4b0a-8e17-3600fcc18ba5" />

</details>

# 新增虚拟机粘贴工具

`paste_to_vm`是用于在未安装增强工具时允许将宿主机的剪贴板内容“粘贴”到虚拟机。不支持中文，因为程序模拟按键扫描码（即模拟键盘按键）。

默认快捷键：Ctrl+Shift+V

依赖

```
pyperclip
pynput
pystray
```
**注意：不要和ClipboardBypass2同时使用！不要将该程序与ClipboardBypass2放在同个目录！**

如想修改快捷键请直接修改源码里`keyboard.HotKey.parse`部分

# 1.0版参考Version 1.0 Reference

```ahk
MsgBox, 64, Little Tool, 绕过网页版学习通阻止剪贴板功能开启`n尝试直接复制粘贴数据即可`n注意：不支持粘贴图片

^v::Send %clipboard%
```
以上代码来自The above code comes from：https://blog.im0o.top/posts/b84fa704.html

# 参考资料Reference

>托盘图标两种状态切换Ahk multiple icons
>
>https://github.com/DesiQuintans/ahk_multiple_icons

>原样输出剪贴板文本Outputs clipboard text as-is
>
>https://www.autohotkey.com/boards/viewtopic.php?t=114767

>官方文档Official doc
>
>https://www.autohotkey.com/docs/v2
