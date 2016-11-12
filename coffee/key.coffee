this.vichrome ?= {}
g = this.vichrome
g.key = {}

g.key.keyCodes =
    Escape    : 27
    Tab       : 9
    Shift     : 16
    Backspace : 8
    Alt       : 18
    Control   : 17
    Meta      : 91
    Delete    : 46
    Enter     : 13
    Space     : 32
    ArrowRight: 128
    ArrowUp   : 129
    ArrowLeft : 130
    ArrowDown : 131
    F1        : 132
    F2        : 133
    F3        : 134
    F4        : 135
    F5        : 136
    F6        : 137
    F7        : 138
    F8        : 139
    F9        : 140
    F10       : 141
    F11       : 142
    F12       : 143

g.key.macOptionWithKeyIdentifier =
    "¡"  : "1"
    "™"  : "2"
    "£"  : "3"
    "¢"  : "4"
    "∞"  : "5"
    "§"  : "6"
    "¶"  : "7"
    "•"  : "8"
    "ª"  : "9"
    "º"  : "0"
    "–"  : "-"
    "≠"  : "^"
    "\\" : "¥"
    "œ"  : "q"
    "∑"  : "w"
    "®"  : "r"
    "†"  : "t"
    "¥"  : "y"
    "ø"  : "o"
    "π"  : "p"
    "“"  : "@"
    "‘"  : "["
    "å"  : "a"
    "ß"  : "s"
    "∂"  : "d"
    "ƒ"  : "f"
    "©"  : "g"
    "˙"  : "h"
    "∆"  : "j"
    "˚"  : "k"
    "¬"  : "l"
    "…"  : ";"
    "æ"  : ":"
    "«"  : "]"
    "Ω"  : "z"
    "≈"  : "x"
    "ç"  : "c"
    "√"  : "v"
    "∫"  : "b"
    "µ"  : "m"
    "≤"  : ","
    "≥"  : "."
    "÷"  : "/"

g.key.winKeyIdentifier_ja =
    "U+00BC":","
    "U+00BE":"."
    "U+00BF":"/"
    "U+00E2":"\\"
    "U+00BB":";"
    "U+00BA":":"
    "U+00DD":"]"
    "U+00C0":"@"
    "U+00DB":"["
    "U+00BD":"-"
    "U+00DE":"^"
    "U+00DC":"\\"

g.key.shiftWinKeyIdentifier_ja =
    "U+00BC":"<"
    "U+00BE":">"
    "U+00BF":"?"
    "U+00E2":"_"
    "U+00BB":"+"
    "U+00BA":"*"
    "U+00DD":"}"
    "U+00C0":"`"
    "U+00DB":"{"
    "U+00BD":"="
    "U+00DE":"~"
    "U+00DC":"|"
    "U+0031":"!"
    "U+0032":'"'
    "U+0033":"#"
    "U+0034":"$"
    "U+0035":"%"
    "U+0036":"&"
    "U+0037":"'"
    "U+0038":"("
    "U+0039":")"

g.key.winKeyIdentifier_us =
    "U+00BC":","
    "U+00BE":"."
    "U+00BF":"/"
    "U+00BB":"="
    "U+00BA":";"
    "U+00DD":"]"
    "U+00DB":"["
    "U+00BD":"-"
    "U+00DC":"\\"
    "U+00DE":"'"
    "U+0060":"`"

g.key.shiftWinKeyIdentifier_us =
    "U+00BC":"<"
    "U+00BE":">"
    "U+00BF":"?"
    "U+00BB":"+"
    "U+00BA":":"
    "U+00DD":"}"
    "U+00DB":"{"
    "U+00BD":"_"
    "U+0038":"*"
    "U+00DC":"|"
    "U+007E":"~"
    "U+0036":"^"
    "U+0031":"!"
    "U+00DE":'"'
    "U+0032":"@"
    "U+0033":"#"
    "U+0034":"$"
    "U+0035":"%"
    "U+0037":"&"
    "U+0039":"("
    "U+0030":")"

keyCodes      = g.key.keyCodes
macOptionWithKeyIdentifier = g.key.macOptionWithKeyIdentifier
winKeyIdentifier_ja      = g.key.winKeyIdentifier_ja
shiftWinKeyIdentifier_ja = g.key.shiftWinKeyIdentifier_ja
winKeyIdentifier_us      = g.key.winKeyIdentifier_us
shiftWinKeyIdentifier_us = g.key.shiftWinKeyIdentifier_us
util = g.util

g.KeyManager =
    isAlphabet : ( str ) ->
        if str.length != 1 then return false

        c = str.charCodeAt( 0 )
        ( 65 <= c <=  90 ) or ( 97 <= c <= 122 )

    isNumber : ( str ) ->
        if str.length != 1 then return false

        c = str.charCodeAt( 0 )
        ( 48 <= c <=  57 )

    isOnlyModifier : (code, ctrl, shift, alt, meta) ->
        switch keyCodes[@getLocalKeyCode(code, ctrl, shift, alt, meta)]
            when keyCodes.CTRL, keyCodes.SHIFT, keyCodes.META, keyCodes.ALT
                return true
            else
                return false

    getKeyCodeStr : (msg) ->
        result = msg.code

        result = "C-" + result if msg.ctrl
        result = "A-" + result if msg.alt
        result = "M-" + result if msg.meta

        if msg.ctrl or msg.alt or msg.meta or keyCodes[msg.code]
            result = "S-" + result if msg.shift if keyCodes[msg.code]
            result = "<" + result + ">"

        result

    getLocalKeyCode : (code, ctrl, shift, alt, meta) ->
        result = code

        # bull shit! fxxk windows and linux
        if util.getPlatform() != "Mac"
            if g.util.getLang() == "ja"
                if shift
                    if shiftWinKeyIdentifier_ja[code]?
                        result = shiftWinKeyIdentifier_ja[code]
                else
                    if winKeyIdentifier_ja[code]?
                        result = winKeyIdentifier_ja[code]
            else
                if shift
                    if shiftWinKeyIdentifier_us[code]?
                        result = shiftWinKeyIdentifier_us[code]
                else
                    if winKeyIdentifier_us[code]?
                        result = winKeyIdentifier_us[code]
        else
          if alt
            if macOptionWithKeyIdentifier[code]?
              result = g.key.macOptionWithKeyIdentifier[code]

        if result? and @isAlphabet result
            if shift
                result = result.toUpperCase()
            else
                result = result.toLowerCase()

        result = "Space" if result == " "
        result
