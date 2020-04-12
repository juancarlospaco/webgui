import json

type
  Person = object
    name: string
    age: Positive

  Data = object
    person: Person
    list: seq[int]


template getConfig*(filename: string; configObject; compileTime: static[bool] = false): auto =
  ## Read from `config.json`, serialize to `configObject`, return `configObject`,
  ## if `compileTime` is `true` all is done compile-time, `import json` to use it.
  ## You must provide 1 `configObject` that match the `config.json` structure.
  ## * https://nim-lang.github.io/Nim/json.html#to%2CJsonNode%2Ctypedesc%5BT%5D
  assert filename.len > 5 and filename[^5..^1] == ".json"
  when compileTime: {.hint: filename & " --> " & configObject.repr.}
  to((when compileTime: parseJson(static(staticRead(filename))) else: parseFile(filename)), configObject)


block:
  let configuration = getConfig("config.json", Data)
  doAssert configuration.person.name == "Nimmer"
  doAssert configuration.person.age == 25
  doAssert configuration.list == @[1, 2, 3, 4]

static:
  const configuration = getConfig("config.json", Data, compileTime = true)
  doAssert configuration.person.name == "Nimmer"
  doAssert configuration.person.age == 25
  doAssert configuration.list == @[1, 2, 3, 4]
