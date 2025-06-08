# ClipboardBypass2
绕过禁止粘贴限制，模拟键盘输入。

[下载入口](https://github.com/Little-Data/ClipboardBypass2.0/releases)

Bypass the prohibition of pasting restrictions and simulate keyboard typing.

>[!important]
>注意检查粘贴后的文本，有些内容可能会在粘贴后消失（原因是输入太快了，可能电脑一卡就不见了）
>Pay attention to check the pasted text, some content may disappear after pasting (the reason is that the input is too fast, and the computer may disappear as soon as the computer is lagging)

# 目前实现的功能

模拟打字输入（含可配置错字率，就是打错字后删掉再写正确的）

自定义输入延迟参数（仅限启用了模拟打字输入）

快捷键更换：Ctrl+Shift+V 防止误操作

可以停止当前粘贴操作

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
