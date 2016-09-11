-- http://www.computercraft.info/forums2/index.php?/topic/17559-cookie-clicker/

local cookies = 0
local cookiesPerSecond = 0
local cursorClick = 1
local gameVersion = 0.5

local buildingMenu = false
local termX, termY = term.getSize()

function drawCookie() --This function draws the cookie after it sets the rest of the background white.
-- Credits to Hellkid98 for the original function
  term.setBackgroundColor(colors.white)
  term.clear()
  local cookie = {"001111100", "011111110", "121121111", "111211211", "112112111", "011211110", "001111100"}
  for a = 1, #cookie do
    for b = 1,#cookie[a] do
      local str = cookie[a]:sub( b, b )
      if str == "2" then
        term.setBackgroundColor( colors.black )
      elseif str == "1" then
        term.setBackgroundColor( colors.brown )
      elseif str == "0" then
        term.setBackgroundColor( colors.white )
      else
	    term.setBackgroundColor( colors.green )
	  end
      term.setCursorPos( 2-1+b, 2-1+a )
      term.write( " " )
    end
  end
end
function drawStats() --Draws the stats at their appropriate location(below the cookie)
  local stats = { {"Cookies: ", math.floor(cookies)}, {"CPS: ",  math.floor(cookiesPerSecond)} }
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  for i=1, #stats do
    term.setCursorPos(2,10+((i-1)))
	print(stats[i][1]..stats[i][2])
  end
end
function drawTitles() --Draws the titles at the top of the screen
  local titles = {"Cookie Clicker v"..gameVersion, "by ZeeSays"}
  for i=1, #titles do
    term.setCursorPos( (termX - titles[i]:len())/2, i)
	term.setTextColor(colors.orange)
	print(titles[i])
  end
  term.setTextColor(colors.white)
end
function drawBuildings()
  local newX =  6 + (termX/2) - (string.len("|Buildings|")/2)
  local toReturn = newX
  term.setCursorPos( newX, 4 )
  if buildingMenu then term.setTextColor(colors.green) else term.setTextColor(colors.red) end
  print("|Buildings|")
  newX = newX + string.len("|Buildings|")
  term.setCursorPos( newX, 4 )
  term.setBackgroundColor(colors.white)
  term.write("    ")
  newX = newX + string.len("    ")
  term.setCursorPos(newX, 4)
  if buildingMenu then term.setTextColor(colors.red) else term.setTextColor(colors.green) end
  print("|Upgrades|")
end
function drawScreen() --Just a mess of all the 'draw' functions
  term.setBackgroundColor(colors.white)
  term.clear()
  drawCookie()
  drawStats()
  drawTitles()
  drawBuildings()
end
function handleClick(clickX, clickY)
  if clickX > 1 and clickX < 11 and clickY > 1 and clickY < 9 then
    cookies = cookies + cursorClick
  elseif clickX > 25 and clickX < 38 and clickY == 4 then
    buildingMenu = true
  elseif clickX > 40 and clickX < 52 and clickY == 4 then
    buildingMenu = false
  end
end
function handleTimer()
  if cookiesPerSecond < 21 and cookiesPerSecond > 0.9 then
	local n = (1/cookiesPerSecond)
    os.startTimer(1/cookiesPerSecond)
	cookies = cookies + (cookiesPerSecond*n)
  elseif cookiesPerSecond > 20 then
	os.startTimer(0.05)
    cookies = cookies + (cookiesPerSecond/20)
  end
end

os.startTimer(1)

while true do
  drawScreen()
  local event, button, clickX, clickY = os.pullEvent()
  if event == "mouse_click" then
    handleClick(clickX, clickY)
  elseif event == "timer" then
    handleTimer()
  end
end