	
describe("Game Integration", function() {	
	
	describe("Connecting", function() {
		
		var key = "jf41j2k41adfae12j4o2j1p2";
		
		it("should be possible to connect", function() {
			runs(function() {
				this.onOpenSpy = jasmine.createSpy();
				this.websocket = new WebSocket("ws://localhost:8008/" + key + "/new");
				this.websocket.onopen = this.onOpenSpy;
			});
			waits(200);
			runs(function() {
				expect(this.onOpenSpy).toHaveBeenCalled();
			});
		});
		
		it("should receive a message with the game id", function() {
			var message;
			runs(function(){
				this.websocket = new WebSocket("ws://localhost:8008/" + key + "/new");
				this.websocket.onmessage = function(event) {
					message = event.data;
				}
			});
		  waits(300);
			runs(function() {
				expect(message).toEqual("server added {\"id\":0}");
			});
		});
	
	});
	
});
