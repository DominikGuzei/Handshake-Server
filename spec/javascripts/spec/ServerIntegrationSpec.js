	
describe("Game Integration", function() {	
	
	// domain and key for localhost in the debug modus of the server
	var key = "aewgj34jt20gj32jg2adfwey3j3hl";
	var domain = "ws://localhost:8008/";
	
	var newGameAction = "/new";
	var connectAction = "/connect/";
	
	var handshakeServerId = "server";
	var handshakeGameId = "game";
	var handshakeAddEvent = "added";
	
	describe("Connecting", function() {
    
    describe("Game", function() {
      
      it("is possible to connect", function() {
  			runs(function() {
  				this.onOpenSpy = jasmine.createSpy();
  				this.websocket = new WebSocket(domain + key + newGameAction);
  				this.websocket.onopen = this.onOpenSpy;
  			});
  			waits(50);
  			runs(function() {
  				expect(this.onOpenSpy).toHaveBeenCalled();
  				this.websocket.close();
  			});
  		});

  		it("receives a message with the game id", function() {
  			var message;
  			runs(function(){
  				this.websocket = new WebSocket(domain + key + newGameAction);
  				this.websocket.onmessage = function(event) {
  					message = event.data;
  				};
  			});
  		  waits(50);
  			runs(function() {
  				expect(message).toEqual(handshakeServerId + " " + handshakeAddEvent + " {\"id\":0}");
  				this.websocket.close();
  			});
  		});
  		
    });
    
    describe("Controller", function() {
      
      it("connects controller to game and sends an add event to both", function() {
        
        var gameMessage;
        runs(function(){
  				this.gameSocket = new WebSocket(domain + key + newGameAction);
  				this.gameSocket.onmessage = function(event) {
  					gameMessage = event.data;
  				};
  			});
  			
  			waits(50);
  			
  			var controllerMessage;
  			runs(function() {
  				this.controllerSocket = new WebSocket(domain + key + connectAction + 0);
  				this.controllerSocket.onmessage = function(event) {
  					controllerMessage = event.data;
  				};
  			});
  			
  			waits(50);
  			
  			runs(function() {
  				expect(controllerMessage).toEqual(handshakeGameId + " " + handshakeAddEvent + " {\"id\":0}");
  				expect(gameMessage).toEqual("0 " + handshakeAddEvent);
  				
  				this.controllerSocket.close();
  				this.gameSocket.close();
  			});
  			
      });
      
    });
		
	
	});
	
	describe("Wrong connecting", function() {
	  
	  it("closes connection when connecting without key", function() {
			runs(function(){
  	    this.onCloseSpy = jasmine.createSpy();
  			this.websocket = new WebSocket(domain);
  			this.websocket.onclose = this.onCloseSpy;
			});
			waits(50);
			runs(function() {
			  expect(this.onCloseSpy).toHaveBeenCalled();
			});
			
	  });
	  
	  it("closes connection when connecting with wrong key", function() {
	    runs(function(){
  	    this.onCloseSpy = jasmine.createSpy();
  			this.websocket = new WebSocket(domain + "wrongkey");
  			this.websocket.onclose = this.onCloseSpy;
			});
			waits(50);
			runs(function() {
			  expect(this.onCloseSpy).toHaveBeenCalled();
			});
	  });
	  
	  it("closes connection when connecting without action", function() {
	    runs(function(){
  	    this.onCloseSpy = jasmine.createSpy();
  			this.websocket = new WebSocket(domain + key);
  			this.websocket.onclose = this.onCloseSpy;
			});
			waits(50);
			runs(function() {
			  expect(this.onCloseSpy).toHaveBeenCalled();
			});
	  });
	  
	  it("closes connection when connecting with wrong action", function() {
	    runs(function(){
  	    this.onCloseSpy = jasmine.createSpy();
  			this.websocket = new WebSocket(domain + key + "bla");
  			this.websocket.onclose = this.onCloseSpy;
			});
			waits(50);
			runs(function() {
			  expect(this.onCloseSpy).toHaveBeenCalled();
			});
	  });
	  
	  it("closes connection when connecting controller with wrong gameId", function() {
	    runs(function(){
  	    this.onCloseSpy = jasmine.createSpy();
  			this.websocket = new WebSocket(domain + key + connectAction + 99);
  			this.websocket.onclose = this.onCloseSpy;
			});
			waits(50);
			runs(function() {
			  expect(this.onCloseSpy).toHaveBeenCalled();
			});
	  });
	  
	});
	
});
