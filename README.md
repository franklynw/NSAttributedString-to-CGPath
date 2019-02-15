# NSAttributedString-to-CGPath
Extension on NSAttributedString to provide a CGPath

Swift 4 update of the code written by Adrian Russell - https://github.com/aderussell/string-to-CGPathRef

Now it's an extension on NSAttributedString -

let textPath: CGPath? = myAttributedString.cgPath

For some custom fonts, the .cgPath getter doesn't work (I'm not sure why). For these, use -

myAttributedString.cgPathForSingleLine

This is more limited, as it doesn't take multi-line text into account.