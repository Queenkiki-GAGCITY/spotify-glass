const assert=require('assert');let lastApp;const CONFIG={lyricsPlus:true};const checkLyricsPlus=()=>true;const Spicetify={Platform:{History:{location:{pathname:'/album/original'},push(path){this.location.pathname=path}}}};const window={dispatchEvent(){}};const Event=function(){};
function requestLyricsPlus() {
		if (CONFIG.lyricsPlus && checkLyricsPlus()) {
			if (Spicetify.Platform.History.location.pathname !== "/lyrics-plus") lastApp = Spicetify.Platform.History.location.pathname;
			if (lastApp !== "/lyrics-plus") {
				Spicetify.Platform.History.push("/lyrics-plus");
			}
		}
		window.dispatchEvent(new Event("fad-request"));
	}

	
requestLyricsPlus();requestLyricsPlus();assert.equal(lastApp,'/album/original');assert.equal(Spicetify.Platform.History.location.pathname,'/lyrics-plus');console.log('PASS: repeated lyrics integration preserves the original return route.');