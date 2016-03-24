kpse.set_program_name "luatex"
-- Regression testing for tex4ht biblatex support
--
--
--
local function prepare(filename)
  for _,ext in ipairs {"aux", "log", "dvi", "html", "bbl"} do
    os.remove(string.format("%s.%s", filename, ext))
  end
end

local function compile(filename)
  print("Compile ".. filename)
  -- os.execute("make4ht -e biblatex.mk4 " .. filename .. "fn-in")
  local compilation = io.popen("make4ht -e biblatex.mk4 " .. filename .. " fn-in", "r")
  local result = compilation:read "*all"
  compilation:close()
  -- print(result)
end

local function compile_errors(filename)
  local logfile = io.open(filename .. ".log", "r")
  local log = logfile:read "*all"
  logfile:close()
  local errno = 0
  for match in log:gmatch "<to be read again>" do
    errno = errno + 1
  end
  for match in log:gmatch "Undefined control sequence" do
    errno = errno + 1
  end
  return errno
end

local function file_exists(filename)
  local f = io.open(filename, "r")
  if f~=nil then 
    f:close()
    return true
  end
  return false
end

-- exectute test suite
local function run(filename, message, testfn)
  -- each test suite has caption
  local tests = {caption = message}
  local function test(message, expected, result)
    local equivalence = expected == result
    table.insert(tests, {equivalence = equivalence, expected = expected, result = result, message = message})
  end
  prepare(filename)
  compile(filename)
  local par = {}
  par.filename = filename
  test("Compile errors", 0, compile_errors(filename))
  test("DVI file exists", true, file_exists(filename .. ".dvi"))
  local htmlfile = filename .. ".html"
  test("HTML file exists", true, file_exists(htmlfile))
  if file_exists(htmlfile) then
    -- run test suite passed as argument
    local f = io.open(htmlfile, "r")
    par.document = f:read("*all")
    testfn(test, par)
  end
  return tests
end

local function printtests(tests)
  local caption = tests.caption or ""
  local errors = {}
  for k,v in ipairs(tests) do
    if v.equivalence ~= true then
      table.insert(errors,v)
    end
  end
  local errno = #errors
  local testno = #tests
  print(string.format("Test suite %s: executed %i, failed %i", caption, testno, errno))
  if errno > 0 then
    print "====================================="
    for _, v in ipairs(errors) do
      print(string.format("%s: %s expected, got %s", v.message, v.expected, v.result))
    end
    print "====================================="
  end
end

printtests(run("01-introduction", "Basic author-year style", 
  function(test, par)
    local document = par.document
    test("Document is string", true, type(document) == "string")
    test("Document is not empty", true, assert(string.len(document) > 0))
    -- test("pokus", true, false)
    test("Is html", true, document:find("<html") > -1)
  end)
)


