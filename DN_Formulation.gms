* Active Distribution Planning
* These should be multiplied by 8760 to account for a whole year (if they are hourly)
* Distribution Network's Income from selling energy to consumers is not modeled yet.
* LossCost has problems. it's variables and parameters are not determined yet.
* I can simply neglect Q. just a Q<=0.8P would suffice (to lessen the run-time)
* everything should be per unit, yet nothing is.

Sets
t each period /t1*t5/
N  all nodes /n1*n8/
N_ex(N) load-points /n4*n6/
N_can(N)   future load-points /n7*n8/
S(N) all substation nodes /n1*n3/
S_ex(S)  existing substation nodes /n1, n2 /
S_can(S) future substation nodes /n3 /
np(N) nodes of only load /n3*n8/
L all lines /l1*l9/
L_ex(L)  existing-Lines /l1*l3/
L_can(L)   candidate-Lines /l4*l9/
nodePars node parameters /Psmax1,Qsmax1,NIC1,Psmax2,Qsmax2,NIC2,Vmax,Vmin,Psmax,Qsmax,PsmaxR,QsmaxR,NRC/
LinePars Line parameters /fbus,tbus,R,X,PFmax,QFmax,LIC,PFRmax,QFRmax,LRC,PFImax,QFImax/

;
Parameter
number_of_nodes(t) /
t1       5
t2       5
t3       6
t4       7
t5       7 / ;


Alias(i,n)
Alias(j,n)
table node_data(n,nodePars)
$include "C:\Users\Mansour\Desktop\cheese\node_data.txt"
table Line_data(L,LinePars)
$include "C:\Users\Mansour\Desktop\cheese\Line_data.txt"
table LoadP_data(n,t)
$include "C:\Users\Mansour\Desktop\cheese\LoadP_data.txt"
table LoadQ_data(n,t)
$include "C:\Users\Mansour\Desktop\cheese\LoadQ_data.txt"
table A(L,N)
$include "C:\Users\Mansour\Desktop\cheese\Inc_matrix.txt"
;


Scalars M big number /1000/
Lf Loss factor just for test now /0.7/
LossCost_C just for test now /25/
LOLEcost just for test /150/
SubOC Subsationg operation cost /3500/
;


Variables
ObjFunc
InvCost
OprCost
LossCost
PF(L,t)
QF(L,t)
Pprod(S,t)
Qprod(S,t)
r(n,t)
V(n,t)

  ;
BINARY Variables
XI(L_can,t)
XR(L_ex,t)
Z1(S_can,t)
Z2(S_can,t)
ZR(S_ex,t)
B(i,j)
Bp(j,i)
 ;

equations
TotCost Total Cost
eq_InvCost
eq_OprCost
eq_LossCost
KCL1
KCL2
KCL3
KCL4

KVL1
KVL21
KVL22

eq_powerflow1
eq_powerflow2
eq_powerflow3
eq_powerflow4

eq_sub11
eq_sub12
eq_sub21
eq_sub22
eq_OnlySub
eq_exSub1
eq_exSub2

eq_Line_rep
eq_Line_ins
eq_OnlyRep1
eq_OnlyRep2
eq_ZOnce1
eq_ZOnce2
eq_OnlySubIns1
eq_OnlySubIns2
eq_OnlyRepSub
eq_ZROnce

*eq_Vmax
*eq_Vmin

Radiality1
Radiality2
Radiality3
Radiality4

;


TotCost.. ObjFunc =e= InvCost + OprCost + LossCost  ;

eq_InvCost..  InvCost =e= sum((S_can,t), Z1(S_can,t)*node_data(S_can,'NIC1') + Z2(S_can,t)*node_data(S_can,'NIC2'))
+sum((S_ex,t),ZR(S_ex,t)*node_data(S_ex,'NRC'))+ sum((L_ex,t),XR(L_ex,t)*Line_data(L_ex,"LRC"))
+ sum((L_can,t),XI(L_can,t)*Line_data(L_can,"LIC")) ;

eq_OprCost.. OprCost =e= sum((S_can,t),Z1(S_can,t)*node_data(S_can,'Psmax1')*SubOC + Z2(S_can,t)*node_data(S_can,'PSmax2')*SubOC)
+ sum((S_ex,t),node_data(S_ex,'Psmax')*SubOC) +  sum((np,t), r(np,t)*LOLEcost) ;

eq_LossCost.. LossCost =e= sum((L_ex,t), Lf*PF(L_ex,t)*Line_data(L_ex,'R')*LossCost_C)
+ sum((L_can,t), Lf*PF(L_can,t)*Line_data(L_can,'R')*LossCost_C) ;

*KCL:    r(n,t) is load not served.
KCL1(S,t).. sum(L$(Line_data(L,'tbus')=ord(S)),PF(L,t)) + Pprod(S,t) =e= sum(L$(Line_data(L,'fbus')=ord(S)),PF(L,t)) ;
KCL2(S,t).. sum(L$(Line_data(L,'tbus')=ord(S)),QF(L,t)) + Qprod(S,t) =e= sum(L$(Line_data(L,'fbus')=ord(S)),QF(L,t)) ;
KCL3(np,t).. sum(L$(Line_data(L,'tbus')=ord(np)),PF(L,t)) =e= sum(L$(Line_data(L,'fbus')=ord(np)),PF(L,t)) + LoadP_data(np,t) - r(np,t) ;
KCL4(np,t).. sum(L$(Line_data(L,'tbus')=ord(np)),QF(L,t)) =e= sum(L$(Line_data(L,'fbus')=ord(np)),QF(L,t)) + LoadQ_data(np,t) - r(np,t) ;


*KVL:   constraints are designed in a way to be relaxed when line is not in use.
* A /v1 is missing in KVL
KVL1(L_ex,t).. sum(n,A(L_ex,n)*V(n,t)) =e= PF(L_ex,t)*Line_data(L_ex,"R") + QF(L_ex,t)*Line_data(L_ex,"X") ;
KVL21(L_can,t).. sum(n,A(L_can,n)*V(n,t)) - PF(L_can,t)*Line_data(L_can,"R") - QF(L_can,t)*Line_data(L_can,"X") =g= (XI(L_can,t) - 1)*M  ;
KVL22(L_can,t).. sum(n,A(L_can,n)*V(n,t)) - PF(L_can,t)*Line_data(L_can,"R") - QF(L_can,t)*Line_data(L_can,"X") =l= (1 - XI(L_can,t))*M  ;

*power flow limitations
eq_powerflow1(L_ex,t).. PF(L_ex,t) =l= Line_data(L_ex,'PFmax') *(1 - XR(L_ex,t)) + Line_data(L_ex,'PFRmax')*XR(L_ex,t)  ;
eq_powerflow2(L_ex,t).. PF(L_ex,t) =g= -Line_data(L_ex,'PFmax') *(1 - XR(L_ex,t)) - Line_data(L_ex,'PFRmax')*XR(L_ex,t) ;
eq_powerflow3(L_can,t).. PF(L_can,t) =l= Line_data(L_can,'PFImax')*XI(L_can,t) ;
eq_powerflow4(L_can,t).. PF(L_can,t) =g= -Line_data(L_can,'PFImax')*XI(L_can,t) ;

*to model Substation placing. Ppmax is zero for non-substations.
eq_sub11(S_can,t).. Pprod(S_can,t) =l= Z1(S_can,t)*node_data(S_can,'Psmax1') ;
eq_sub12(S_can,t).. Qprod(S_can,t) =l= Z1(S_can,t)*node_data(S_can,'Qsmax1') ;
eq_sub21(S_can,t).. Pprod(S_can,t) =l= Z2(S_can,t)*node_data(S_can,'Psmax2') ;
eq_sub22(S_can,t).. Qprod(S_can,t) =l= Z2(S_can,t)*node_data(S_can,'Qsmax2') ;
eq_OnlySub(S_can,t).. Z1(S_can,t) + Z2(S_can,t) =l= 1 ;
*same model for existing substations replacement.
eq_exSub1(S_ex,t).. Pprod(S_ex,t) =l= (1 - ZR(S_ex,t))*node_data(S_ex,'Psmax') + ZR(S_ex,t)*node_data(S_ex,'PsmaxR')  ;
eq_exSub2(S_ex,t).. Qprod(S_ex,t) =l= (1 - ZR(S_ex,t))*node_data(S_ex,'Qsmax') + ZR(S_ex,t)*node_data(S_ex,'QsmaxR')  ;


*to ensure only one replacement or installation
eq_Line_rep(L_ex,t).. XR(L_ex,t) =g= XR(L_ex,t-1) ;
eq_Line_ins(L_can,t).. XI(L_can,t) =g= XI(L_can,t-1) ;
eq_OnlyRep1(L_ex).. sum(t,XR(L_ex,t)) =l= 1 ;
eq_OnlyRep2(L_can).. sum(t,XI(L_can,t)) =l= 1 ;

eq_ZOnce1(S_can,t).. Z1(S_can,t) =g= Z1(S_can,t-1) ;
eq_ZOnce2(S_can,t).. Z2(S_can,t) =g= Z2(S_can,t-1) ;
eq_OnlySubIns1(S_can).. sum(t,Z1(S_can,t)) =l= 1 ;
eq_OnlySubIns2(S_can).. sum(t,Z2(S_can,t)) =l= 1 ;
eq_OnlyRepSub(S_ex).. sum(t,ZR(S_ex,t)) =l= 1 ;
eq_ZROnce(S_ex,t).. ZR(S_ex,t) =g= ZR(S_ex,t-1) ;


*Node Voltage limitations
*eq_Vmax(n,t).. V(n,t) =l= Node_data(n,"Vmax") ;
*eq_Vmin(n,t).. V(n,t) =g= Node_data(n,"Vmin") ;

*mesh not allowed (N(t) is the bumber of nodes at each period):
* 1: means no mesh
* 2 means that every node has exactly one parent
* 3 means substation nodes have no parent
* 4
Radiality1(t).. card(L_ex) + sum(L_can, XI(L_can,t)) =e= sum(S_can,Z1(S_can,t) + Z2(S_can,t)) + number_of_nodes(t) - 1 ;
Radiality2(L_can,t).. sum((i,j)$((ord(i)=Line_data(L_can,'tbus')) and (ord(j) = Line_data(L_can,'fbus'))), B(i,j) + Bp(j,i) ) =e= XI(L_can,t) ;
Radiality3(i).. sum(j,B(i,j)) =e= 1 ;
Radiality4(S,j).. B(S,j) =e= 0

model DNPlanning /all/ ;
option optcr = 0.0 ;
solve DNPlanning minimizing ObjFunc using mip;


