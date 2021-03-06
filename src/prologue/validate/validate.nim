# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import tables, strtabs, strutils, strformat

from ./basic import nil
from ../core/basicregex import match, re, Regex, RegexMatch


type
  Info* = tuple[hasValue: bool, msg: string]
  ValidateHandler* = proc(text: string): Info {.closure.}

  FormValidation* = object
    data: OrderedTableRef[string, seq[ValidateHandler]]


proc newFormValidation*(validator: openArray[(string, seq[ValidateHandler])]
                        ): FormValidation {.inline.} =
  FormValidation(data: validator.newOrderedTable)

proc validate*(formValidation: FormValidation, textTable: StringTableRef,
                allMsgs = true): Info =
  var msgs = ""
  for (key, handlers) in formValidation.data.pairs:
    for handler in handlers:
      var
        hasValue: bool
        msg: string
      if not textTable.hasKey(key):
        hasValue = false
        msgs.add &"Can't find key: {key}\n"
        if not allMsgs:
          return (false, msgs)
        break
      else:
        (hasValue, msg) = handler(textTable[key])
      if not hasValue:
        msgs.add &"{msg}\n"
        if not allMsgs:
          return (false, msgs)

  if msgs.len != 0:
    return (false, msgs)
  return (true, msgs)

proc isInt*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if basic.isInt(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not an integer!")
    else:
      result = (false, msg)

proc isNumeric*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if basic.isNumeric(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not a number!")
    else:
      result = (false, msg)

proc isBool*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if basic.isBool(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not a boolean!")
    else:
      result = (false, msg)

proc minValue*(min: float, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    let value = try: parseFloat(text)
      except ValueError:
        return (false, fmt"{text} is not a number!")

    if value >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not greater than or equal to {min}!")
    else:
      result = (false, msg)

proc maxValue*(max: float, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    let value = try: parseFloat(text)
      except ValueError:
        return (false, fmt"{text} is not a number!")

    if value <= max:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not less than or equal to {max}!")
    else:
      result = (false, msg)

proc rangeValue*(min, max: float, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    let value = try: parseFloat(text)
      except ValueError:
        return (false, fmt"{text} is not a number!")

    if value <= max and value >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not in range from {min} to {max}!")
    else:
      result = (false, msg)

proc minLength*(min: Natural, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    let length = text.len
    if length >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"Length {length} is not greater than or equal to {min}!")
    else:
      result = (false, msg)

proc maxLength*(max: Natural, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    let length = text.len
    if length <= max:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"Length {length} is not less than or equal to {max}!")
    else:
      result = (false, msg)

proc rangeLength*(min, max: Natural, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    let length = text.len
    if length <= max and length >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"Length {length} is not in range from {min} to {max}!")
    else:
      result = (false, msg)

proc equals*(value: string, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if text == value:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not equal to {value}!")
    else:
      result = (false, msg)

proc accepted*(msg = ""): ValidateHandler {.inline.} =
  ## if lowerAscii input in {"yes", "on", "1", or "true"}, return true
  result = proc(text: string): Info =
    case text.toLowerAscii
    of "yes", "y", "on", "1", "true":
      result = (true, "")
    else:
      if msg.len == 0:
        result = (false, fmt"""{text} is not in "yes", "y", "on", "1", "true"!""")
      else:
        result = (false, msg)

proc required*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if text.len != 0:
      result = (true, "")
    elif msg.len == 0:
      result = (false, "Field is required!")
    else:
      result = (false, msg)

proc matchRegex*(value: Regex, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    var m: RegexMatch
    if text.match(value, m):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} doesn't match Regex")
    else:
      result = (false, msg)

proc matchUrl*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    var m: RegexMatch
    if text.match(re"(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]", m):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} doesn't match url")
    else:
      result = (false, msg)
