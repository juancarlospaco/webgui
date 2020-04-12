# https://github.com/juancarlospaco/webgui/blob/master/examples/config/config.json

import json

type
  Person = object
    name: string
    age: Positive

  Data = object
    person: Person
    list: seq[int]


template getConfig*(filename: string; configObject; compileTime: static[bool] = false): auto =
  to((when compileTime: static(parseJson(staticRead(filename))) else: parseFile(filename)), configObject)


block:
  let configuration = getConfig("config.json", Data)
  doAssert configuration is Data
  doAssert configuration.person.name == "Nimmer"
  doAssert configuration.person.age == 25
  doAssert configuration.list == @[1, 2, 3, 4]

static:
  const configuration = getConfig("config.json", Data, compileTime = true)
  doAssert configuration is Data
  doAssert configuration.person.name == "Nimmer"
  doAssert configuration.person.age == 25
  doAssert configuration.list == @[1, 2, 3, 4]
