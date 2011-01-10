module Stubs
  class Websocket
    
    def onopen(&blk)     
      @onopen = Proc.new(blk);    
    end
    
    def onclose(&blk)   
      @onclose = Proc.new(blk);   
    end
    
    def onerror(&blk)    
      @onerror = Proc.new(blk);   
    end
    
    def onmessage(&blk)
      @onmessage = Proc.new(blk); 
    end
    
    def send(message) 
    end
    
    def close_websocket 
    end
    
    def sendMessage(message)
      @onmessage.call(message)
    end
    
    def sendError(message)
      @onerror.call(message)
    end
    
    def sendClose()
      @onclose.call()
    end
  end
end
