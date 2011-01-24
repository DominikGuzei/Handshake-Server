	
describe("Game Integration", function() {	
	
	// domain and key for localhost in the debug modus of the server
	var key = "aewgj34jt20gj32jg2adfwey3j3hl";
	var domain = "ws://localhost:8008/";
	
	var newGameRoute = "/new";
	
	var handshakeServerId = "server";
	var handshakeAddEvent = "added";
	
	describe("Connecting", function() {

		it("should be possible to connect", function() {
			runs(function() {
				this.onOpenSpy = jasmine.createSpy();
				this.websocket = new WebSocket(domain + key + newGameRoute);
				this.websocket.onopen = this.onOpenSpy;
			});
			waits(200);
			runs(function() {
				expect(this.onOpenSpy).toHaveBeenCalled();
				this.websocket.close();
			});
		});
		
		it("should receive a message with the game id", function() {
			var message;
			runs(function(){
				this.websocket = new WebSocket(domain + key + newGameRoute);
				this.websocket.onmessage = function(event) {
					message = event.data;
				}
			});
		  waits(300);
			runs(function() {
				expect(message).toEqual(handshakeServerId + " " + handshakeAddEvent + " {\"id\":0}");
				//this.websocket.close();
			});
		});
	
	});
	
});
