function [x,y,typ]=mavlinkHilState(job,arg1,arg2)
//
// mavlinkHilState.sci
//
// USAGE:
//
// input
//
//	// attitude states (rad)
//	[1] roll 
//	[2] pitch 
//	[3] yaw 
//
//	// body rates
//	[4] rollRate 
//	[5] pitchRate 
//	[6] yawRate 
//
//  // position
//	[7] lat 
//	[8] lon 
//	[9] alt 
//
//	// velocity
//	[10] vn 
//	[11] ve 
//	[12] vd 
//
//  // acceleration
//  [13] xacc
//  [14] yacc
//  [15] zacc
//
// output
//
// (option 1, recommended)
// // rc channels scaled
//  [1] ch1
//  [2] ch2
//  [3] ch3
//  [4] ch4
//  [5] ch5
//  [6] ch6
//  [7] ch7
//  [8] ch8
//
// (option 2, not recommended, more constrictive, not 
// supported by ArduPilotOne)
// // hil controls packet
//  [1] roll
//  [2] pitch
//  [3] yaw
//  [4] throttle
//  [5] mode
//  [6] nav_mode
//  [7] 0
//  [8] 0
//
// AUTHOR:
//
// Copyright (C) James Goppert 2010 <jgoppert@users.sourceforge.net>
//
// This file is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This file is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  If not, see <http://www.gnu.org/licenses/>.
//
mode(-1);
x=[];y=[];typ=[];

select job
	case 'plot' then
	 	standard_draw(arg1)
	case 'getinputs' then
	 	[x,y,typ]=standard_inputs(arg1)
	case 'getoutputs' then
	 	[x,y,typ]=standard_outputs(arg1)
	case 'getorigin' then
	 	[x,y]=standard_origin(arg1)
	case 'set' then
		x=arg1;
		graphics=arg1.graphics;exprs=graphics.exprs
		model=arg1.model;
		while %t do
			labels=['device';'baud rate'];
			[ok,device,baudRate,exprs]=..
				getvalue('Set mavlink HIL Parameters',labels,..
				list('str',-1,'vec',1),exprs);
			if ~ok then break,end
			[model,graphics,ok]=check_io(model,graphics,[15],[8],[1],[])
			if ok then
				model.ipar=[..
					length(evstr(device)),ascii(evstr(device)),0,..
					baudRate];
				graphics.exprs=exprs;
				x.graphics=graphics;
				x.model=model;
				break
			end
		end
	case 'define' then
		// set model properties
		model=scicos_model()
		model.sim=list('sci_mavlinkHilState',4)
		model.in=[15]
		model.out=[8]
		model.evtin=[1]
		model.blocktype='c'
		model.dep_ut=[%t %f]

		// jsbsim parameters
		device="""/dev/ttyUSB2""";
		baudRate=115200;
		model.ipar=[..
					length(evstr(device)),ascii(evstr(device)),0,..
					baudRate];

		// initialize strings for gui
		exprs=[strcat(device),strcat(sci2exp(baudRate))];

		// setup icon
	  	gr_i=['xstringb(orig(1),orig(2),''mavlink HIL State'',sz(1),sz(2),''fill'');']
	  	x=standard_define([5 2],model,exprs,gr_i)
	end
endfunction

// vim:ts=4:sw=4
