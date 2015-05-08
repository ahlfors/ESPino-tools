-- ESPino Demo
-- Based on ESPToy Startup Demo
-- This requires file 'espino.htm' to exist on the ESP8266 module. Upload the file if it doesn't exist

-- Set up GPIO pins
r=0
g=0
b=0
pin_red=4
pin_green=2
pin_but=3
pin_blue=1
gpio.mode(pin_but, gpio.INPUT, gpio.PULLUP)
pwm.setup(pin_red, 100, 512)
pwm.setup(pin_green,100,512)
pwm.setup(pin_blue,100, 0)
pwm.start(pin_red)
pwm.start(pin_green)
pwm.start(pin_blue)
tmr.delay(200000)
pwm.setduty(pin_red,1023)
pwm.setduty(pin_green,1023)
pwm.setduty(pin_blue,1023)

-- Set up WiFi
wifi.setmode(wifi.SOFTAP)
cfg={}
cfg.ssid="ESPino" .. (string.sub(wifi.ap.getmac(), 15,17))
cfg.pwd="11111111"
wifi.ap.config(cfg)

if srv then
  srv:close()
end
srv=net.createServer(net.TCP, 3)
srv:listen(80,function(conn) 
  conn:on("receive", function(conn,payload)
    local isOpen=false
    conn:on("sent", function(conn)
      if not isOpen then
        isOpen=true
        file.open(fileName, 'r')
      end
      local data=file.read(1024)
      if data then
        conn:send(data)
      else
        file.close()
        conn:close()
        conn=nil
      end
    end)
    
    if string.sub(payload, 1, 6) == 'GET / ' then
      print("request homepage")
      fileName = 'espino.htm'
      conn:send("HTTP/1.1 200 OK\r\n")
      conn:send("Content-type: text/html\r\n")
      conn:send("Connection: close\r\n\r\n")
    elseif string.sub(payload, 1, 8) == 'GET /ja ' then
      print("request ja")
      conn:send("HTTP/1.1 200 OK\r\n")
      conn:send("Content-type: application/json\r\n")
      conn:send("Connection: close\r\n\r\n")
      conn:send("{\"adc\":" .. adc.read(0) .. ",\"but\":" .. (1-gpio.read(pin_but)) .. ",\"red\":" .. r .. ",\"green\":" .. g .. ",\"blue\":" .. b .. "}")
      conn:close()
      conn=nil
    elseif string.sub(payload, 1, 8) == 'GET /cc?' then
      print("request cc")
      conn:close()
      conn=nil

      local val=string.match(payload,"r=(%d+)")
      if val then
        r=tonumber(val)
      end
      local val=string.match(payload,"g=(%d+)")
      if val then
        g=tonumber(val)
      end
      local val=string.match(payload,"b=(%d+)")
      if val then
        b=tonumber(val)
      end
      print("Heap size: " .. node.heap())          
      pwm.setduty(pin_red, 1023 - r)
      pwm.setduty(pin_green, 1023 - g)
      pwm.setduty(pin_blue, 1023 - b)
    else
      conn:close()
    end
  end) 
end)
