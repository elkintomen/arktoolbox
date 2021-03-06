mode(-1)

// load constants file
exec constants.sce

// load scicoslab diagram to linearize the dynamics
load arducopter2.cos

function tf = ss2cleanTf(ss)
	tf = clean(ss2tf(ss));
endfunction

// open loop statistics
function openLoopAnalysis(sys)
	if(typeof(sys)=='state-space') sys = ss2cleanTf(sys); end
	sse=1/(horner(sys,1e-10));
	if (sse>1e6) sse=%inf; end
    printf('\t\tgcf=%8.2f Hz\t\tsse=%8.2f\n',bw(tf2ss(sys),0),sse);
endfunction

// close a loop
function [sysOut,uOut] = closeLoop2(yi,ui,sys,y,u,H)
	printf('\tclosing loop: %s\n',y.str(yi)+'->'+u.str(ui));
	openLoopAnalysis(H*sys(yi,ui));
	sysOut = unityFeedback2(yi,ui,sys,H);
	uOut = createIndex(y.str(yi),u);
	[eVect,eVal] = spec(abcd(sysOut));
	eVal = diag(eVal);
	unstablePoles=find(real(eVal)>0);
	printf('\t\tunstable modes:\n');
	for i=1:size(unstablePoles,2)
		[junk,k]=sort(eVect(:,unstablePoles(i)));
		j=0; // number of valid states found
		m=1; // index 
		printf('\t\t\t');
		while 1
			if (k(m)<=size(y.str,1))		
				j = j +1;
				printf('%9s\t',y.str(k(m)));
			end
			if (j>2)
				printf('\t%8.3f + %8.3f j\n',..
					real(eVal(unstablePoles(i))),..
					imag(eVal(unstablePoles(i))));
				break;
			else
				m = m +1;
			end;
		end
	end
	poles=size(abcd(sys),1);
	printf('\t\tclbw=%f\tunstable poles=%d/%d\n',..
		bw(ss2cleanTf(sysOut),3),size(unstablePoles,2),size(abcd(sysOut),1));
endfunction


// extract blocks
disp('extracting blocks for linearization');
dynamics=scs_m.objs(1).model.rpar;
controller=scs_m.objs(299).model.rpar;
motorLag=scs_m.objs(96).model.rpar;
motorMix=scs_m.objs(209).model.rpar;
navigation=scs_m.objs(390).model.rpar;

// lineriaztion of dynamics
disp('linearizing dynamics');
// vary u to find zero initial conitions
[Xd,Ud,Yd,XPd] = steadycos2(dynamics,[],[],[],[],[1:$],[],[]);
Xd=clean(Xd,1e-5);
Ud=clean(Ud,1e-5);
quadTf = clean(ss2tf(lincos(dynamics,Xd,Ud)),1e-5);

// motor mix block
disp('linearizing motor mix block');
motorMixTf = clean(ss2tf(lincos(motorMix,[],[Ud(1);0;0;0])),1e-5);

// motor lag block
disp('linearizing motor lag block');
motorLagTf = clean(ss2tf(lincos(motorLag,zeros(4,1),Ud)),1e-5);

// find complete dynamics transfer function
disp('finding dynamics transfer function');
sys.oltf = clean(quadTf*motorLagTf*motorMixTf,1e-4);
sys.olss = minssAutoTol(tf2ss(sys.oltf),16);

// attitude loops
disp('beginning loop closures');
s = sys.olss;
s0 = ss2cleanTf(s);
[s,u] = closeLoop2(y.pD,u.SUM,s,y,u,H.pD_SUM);
s1 = ss2cleanTf(s);
[s,u] = closeLoop2(y.yawRate,u.LRFB,s,y,u,H.yawRate_LRFB);
s2 = ss2cleanTf(s);
[s,u] = closeLoop2(y.roll,u.LR,s,y,u,H.roll_LR);
s3 = ss2cleanTf(s);
[s,u] = closeLoop2(y.pitch,u.FB,s,y,u,H.pitch_FB);
s4 = ss2cleanTf(s);
[s,u] = closeLoop2(y.yaw,u.yawRate,s,y,u,H.yaw_yawRate);
s5 = ss2cleanTf(s);

sPitch = s4(y.pitch,u.pitch);

// position loops
// we can tie in pitch and roll directly since for trim we are aligned with
// North/ East frame

[s,u] = closeLoop2(y.pN,u.pitch,s,y,u,H.pN_pitch);
s6 = ss2cleanTf(s);
[s,u] = closeLoop2(y.pE,u.roll,s,y,u,H.pE_roll);
s7 = ss2cleanTf(s);

sPN = s7(y.pN,u.pN);
sPNOpen = s5(y.pN,u.pitch)*H.pN_pitch;

//Open and Closed Loops Bode Plots and RLocus
scf(1);
subplot(2,2,1); xtitle("y.pD,u.SUM"); bode(s0(y.pD,u.SUM)*H.pD_SUM)
subplot(2,2,2); xtitle("y.pD,u.pD"); bode(s1(y.pD,u.pD))
subplot(2,2,3); evans(clean(s0(y.pD,u.SUM)))
subplot(2,2,4); evans(clean(s0(y.pD,u.SUM))*H.pD_SUM)

scf(2);
subplot(2,2,1); xtitle("y.yawRate,u.LRFB"); bode(s1(y.yawRate,u.LRFB)*H.yawRate_LRFB)
subplot(2,2,2); xtitle("y.yawRate,u.yawRate"); bode(s2(y.yawRate,u.yawRate))
subplot(2,2,3); evans(clean(s1(y.yawRate,u.LRFB)))
subplot(2,2,4); evans(clean(s1(y.yawRate,u.LRFB))*H.yawRate_LRFB)

scf(3);
subplot(2,2,1); xtitle("y.roll,u.LR"); bode(s2(y.roll,u.LR)*H.roll_LR)
subplot(2,2,2); xtitle("y.roll,u.roll"); bode(s3(y.roll,u.roll))
subplot(2,2,3); evans(clean(s2(y.roll,u.LR)))
subplot(2,2,4); evans(clean(s2(y.roll,u.LR))*H.roll_LR)

scf(4);
subplot(2,2,1); xtitle("y.pitch,u.FB"); bode(s3(y.pitch,u.FB)*H.pitch_FB)
subplot(2,2,2); xtitle("y.pitch,u.pitch"); bode(s4(y.pitch,u.pitch))
subplot(2,2,3); evans(clean(s3(y.pitch,u.FB)))
subplot(2,2,4); evans(clean(s3(y.pitch,u.FB))*H.pitch_FB)

scf(5);
subplot(2,2,1); xtitle("y.yaw,u.yawRate"); bode(s4(y.yaw,u.yawRate)*H.yaw_yawRate)
subplot(2,2,2); xtitle("y.yaw,u.yaw"); bode(s5(y.yaw,u.yaw))
subplot(2,2,3); evans(clean(s4(y.yaw,u.yawRate)))
subplot(2,2,4); evans(clean(s4(y.yaw,u.yawRate))*H.yaw_yawRate)

scf(6);
subplot(2,2,1); xtitle("y.pN,u.pitch"); bode(s5(y.pN,u.pitch)*H.pN_pitch)
subplot(2,2,2); xtitle("y.pN,u.pN"); bode(s6(y.pN,u.pN))
subplot(2,2,3); evans(clean(s5(y.pN,u.pitch)))
subplot(2,2,4); evans(clean(s5(y.pN,u.pitch))*H.pN_pitch)

scf(7);
subplot(2,2,1); xtitle("y.pE,u.roll"); bode(s6(y.pE,u.roll)*H.pE_roll)
subplot(2,2,2); xtitle("y.pE,u.pE"); bode(s7(y.pE,u.pE))
subplot(2,2,3); evans(clean(s6(y.pE,u.roll)))
subplot(2,2,4); evans(clean(s6(y.pE,u.roll))*H.pE_roll)
//disp('beginning plotting');

// position north, and pitch
//f=scf(1); clf(1);
//f.figure_size=[600,600];
//set_posfig_dim(f.figure_size(1),f.figure_size(2));
//bode([sPitch*pade(PID_ATT_INTERVAL);sPN*pade(PID_POS_INTERVAL)],..
	//0.01,99,.01,["pitch";"position north"])
//xs2eps(1,'pN_pitch');

// zoh time effect on pN closed loop
//f=scf(2); clf(2);
//f.figure_size=[600,600];
//set_posfig_dim(f.figure_size(1),f.figure_size(2));
//bode([sPN*pade(4);sPN*pade(2);sPN*pade(1);sPN*pade(1/2);..
	//sPN*pade(1/4);sPN*pade(1/16)],0.01,99,.01,..
	//["1/4 Hz";"1/2 Hz";"1 Hz";"2 Hz";"4 Hz";"16 Hz"])
//xs2eps(2,'pN_closed_zoh');

// zoh time effect on pN open loop
//f=scf(3); clf(3);
//f.figure_size=[600,600];
//set_posfig_dim(f.figure_size(1),f.figure_size(2));
//bode([sPNOpen*pade(4);sPNOpen*pade(2);sPNOpen*pade(1);sPNOpen*pade(1/2);..
	//sPNOpen*pade(1/4);sPNOpen*pade(1/16)],0.01,99,.01,..
	//["1/4 Hz";"1/2 Hz";"1 Hz";"2 Hz";"4 Hz";"16 Hz"])
//xs2eps(3,'pN_open_zoh');
