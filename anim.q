//Original GL shader:
//   https://twitter.com/notargs/status/1250468645030858753
//Inspiration: 
//   http://beyondloom.com/tools/specialk.html
//
// Run:
// q -s <threads> anim.q

//You can try increase the resolution if you have stong CPU
SIZEX:160
SIZEY:120

/////////////////////
//  Browser stuff  //
/////////////////////

//port
if[not system"p";system"p 5000"]
port:system"p"

//web socket set up
ws,:0#0;.z.wo:{ws,::x};.z.wc:{ws::ws except x};.z.ws:value

//http server set up
@[get;`.z.ph0;{.z.ph0:.z.ph}];
.z.ph:{$["anim.html"~x 0;.h.hp enlist animHTML;.z.ph0 x]}
animHTML:"<script>var ws = new WebSocket('ws://localhost:",string[port],"');",
	"ws.onmessage = function(msg){document.getElementById('s').src=URL.createObjectURL(msg.data,{type:'image/bmp'});};",
	"</script><img id='s' width=",string[2*SIZEX]," height=",string[2*SIZEY],"/>";

-1 "Open http://localhost:",string[port],"/anim.html";

//////////
// ANIM //
//////////

//Procudes an w*h RGB24 BMP from an 3x(w*h) sized (r;g;b) array.
bmpFromRGB::{[w;h;rgb]
	ws:4 xbar 3+w*3;b4:{4#reverse 0x0 vs x};
	header:0x424d,b4[54+s:ws*h],0x000000003600000028000000,b4[w],b4[h],0x0100180000000000,b4[ws*h],0x130b0000130b00000000000000000000;
	header,raze ws#/:(raze')w cut flip"x"$floor reverse rgb
 }

frame:0
.z.ts:{if[count ws;neg[ws]@\:bmpFromRGB[SIZEX;SIZEY] img[]];frame+::1;}

//25 fps
\t 40

/////////////////////
//  3D Rendering   //
/////////////////////

//helper
len:{sqrt sum x*x}

//ray directions
dir::2 flip/(.5-flip raze[(til SIZEX),\:/:(til SIZEY)]%SIZEY),.5

//the object defined as a signed distance function
sdf:{
	x[2]-:frame*.04;a:.01*x 2;
	x[0 1]:((ca;sa);(neg sa:sin a;ca:cos a))wsum\:x 0 1;
	.1-len cos[x 0 1]+sin x 1 2
 }

//colors
colors:{255.999*1&(2 5 9f + sin x)%\:len x}

//iteration steps
steps:25

//parallelized f with split (input) and merge (output) functions. 
.Q.fsm:{[s;m;f;x]m f peach s[1|system"s"]x}

//split input
split:{[n;x]flip(n;0N)#/:x}
//merge resuts
merge:,'/

//everything put together
img:{
	//marching towards the object and colors
	//colors steps {x+dir*\:sdf x}/0 0 0f
	.Q.fsm[split;merge;{[d]colors steps {[d;x]x+d*\:sdf x}[d]/0 0 0f};dir]
 } 