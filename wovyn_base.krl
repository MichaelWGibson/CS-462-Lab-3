ruleset wovyn_base {
  meta {
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "post", "type": "test",
                              "attrs": [ "temp", "baro" ] } ] }
  temperature_threshold = 80
  
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      timestamp = time:now()
      gthing = event:attrs["genericThing"]
      temp = event:attrs["genericThing"]["data"]["temperature"][0]["temperatureF"].klog("temp: ");
    }
    if gthing != null then
      send_directive("success", {"results": gthing})
    
    fired {
      raise wovyn event "new_temperature_reading"
      attributes {"timestamp": timestamp, "temp" : temp}
    }
  }
  
  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temp = event:attrs["temp"]
    }
    
    if (temp > temperature_threshold) then
    send_directive("Threshold Violation!!!", {"temp": temp})
    
    fired {
      raise wovyn event "threshold_violation"
      attributes event:attrs
    }
  }
  
  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      temp = event:attrs["temp"]
      to = "17072801566"
      from = "16784878093"
      message = "The current tempeture of " + temp + " is above the threshold of " + temperature_threshold + "!" 
    }
    twilio:send_sms(to, from, message)
  }
}