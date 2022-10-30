
10 REM ********************************************************
11 REM *** PCODE TO 8080 TRANSLATOR -- NEEDS 8080 RUNTIME CODE*
12 REM *** TO PRODUCE A STAND-ALONE 8080 PROGRAM.           ***
13 REM *** 8080 RUNTIME CODE LOADED INTO MEMORY AT 1A00 H.  ***
15 REM *** PRODUCES A LIST OF CALLS TO THE 8080 RUNTIME CODE. *
16 REM ********************************************************
17 REM
30 DIM A$(4),B$(4),H0$(16),B0$(4)
40 S1=500\ S2=400
50 DIM T$(S1)
60 DIMD$(S2)
65 DIM E(S2)
68 DIM W$(36),Z$(88)\O2=21
70 DIM Y1(15),Y2(15),Y$(60)
75 DIM Z1(30),Z2(30)
78 H0$="0123456789ABCDEF"
82 Y$(1,32)="1A201A521A491A5F1A601ACB1A7A1A71"
86Y$(33,60)="1A861A871AD61AAE1AA31ADE1A27"
94 Z$(1,32)="1BA61C231C0F1C151C3C1C511CBE1CC7"
96 Z$(33,64)="1CD31CE91D161CED1D1D1D241D2A1D35"
98 Z$(65,88)="1D401D491D5A1D721D7C1D86"
100 W$(1,24)="1AE91AF21AF91B791D911DC4"
102 W$(33,36)="1DE7"
103 REM
105 REM
106 REM
110 M=0\FOR K= 1 TO 60 STEP 4
112 M=M+1\Y2(M)=FND(Y$(K,K+1),2)+X
113 Y1(M)=FND(Y$(K+2,K+3),2)+X\NEXT
114 M=0\FOR K=1 TO 88 STEP 4
115 Z2(M)=FND(Z$(K,K+1),2)+X
116 Z1(M)=FND(Z$(K+2,K+3),2)+X
117 M=M+1\NEXT
118 M=O2+1\ FOR K=1 TO 36 STEP 4
119 Z2(M)=FND(W$(K,K+1),2)+X
120 Z1(M)=FND(W$(K+2,K+3),2)+X
122 M=M+1\ NEXT\ GOTO 300
123 REM
125 REM
130 DEF FND(H1$,L)
135 N=0\FOR I=1 TO L
140 J=ASC(H1$(I,I))-48
145 IF J>9 THEN J=J-7
150 N=N*16+J\NEXT\RETURN N
160 FNEND
165 REM
170 DEF FNH$(L)
175 R=INT(L/16)+1\S=L-R*16+17
180 RETURN H0$(R,R)+H0$(S,S)
185 FNEND
190 REM
200 DEF FNG(O,M,N)
210 FILL P,O\FILL P+1,M
220 FILL P+2,N\RETURN P+3
230 FNEND
240 REM
250 DEF FNQ(O,M)
260 FILLP,O\FILLP+1,Y1(M)
270 FILL P+2,Y2(M)\RETURN P+3
280 FNEND
285 REM
290 REM
300 !"*** P-CODE TO 8080 TRANSLATION ***"
310 INPUT" HEX ADDRESS OF 8080 RUNTIME CODE: ",B0$
311 IF B0$=""THEN B0$="1A00"
312 X=FND(B0$,4)-FND("1A00",4)
313 INPUT" HEX ADDRESS OF TINY PASCAL PCODE: ",A$
315 IF A$=""THENA$="9800"
320 X=FND(A$,4)\X0=X
330 INPUT" HEX ADDRESS OF 8080 PROGRAM CODE: ",B$
335 IF B$=""THEN B$="9000"\P0=FND(B$,4)
340 INPUT" STACK START ADDR.(HEX):",B$
345 IF B$<>""THEN 360
350 !" DEFAULT STACK ADDRESSES USED"
355 A$="9FFF"\GOTO365
360 INPUT" STACK END ADDR.(HEX):",A$
365 K=65536-FND(A$,4)
370 J=INT(K/256)\I=K-J*256
375 P=P0+3\P=FNG(17,I,J)
380 P=FNG(205,FND(B0$(3,4),2),FND(B0$(1,2),2))
385 B0$=B$
388 REM
390 REM
400 W=1
420 J=EXAM(X)\IF J=255 THEN 470
430 X=X+4\IF J<4 THEN 420
435 IF J=5 OR J>7 THEN 420
440 T$(W,W+1)=CHR$(EXAM(X-1))+CHR$(EXAM(X-2))
450 W=W+2\GOTO 420
470 !(W-1)/2," REFERENCES"\W=W-2
472 REM
475 REM
477 REM
480 IF W<160 THEN 500
482 J=5\FOR I=7 TO W STEP 2
485 FOR K=J-4 TO J STEP 2
486 IF T$(I,I+1)=T$(K,K+1) THEN EXIT 490
488 NEXT\J=J+2\T$(J,J+1)=T$(I,I+1)
490 NEXT\ W=J
492 REM
495 REM
500 FOR I=1 TO W-2 STEP 2\A$="0"
510 FOR J=W-2 TO I STEP -2
520 IF T$(J,J+1)<=T$(J+2,J+3) THEN 550
530 B$=T$(J,J+1)\T$(J,J+1)=T$(J+2,J+3)
540 T$(J+2,J+3)=B$\A$="1"
550 NEXT\IF A$="0"THEN EXIT 600
560 NEXT
565 REM
570 REM
600 J=1\FOR I=3 TO W STEP 2
610 IF T$(I,I+1)=T$(J,J+1) THEN 630
620 J=J+2\T$(J,J+1)=T$(I,I+1)
630 NEXT\W0=J
640 T$(J+2,J+3)=CHR$(255)+CHR$(255)
660 FOR I=1 TO J STEP 2
670 D$(I,I+1)="  "\NEXT
680 !(J+1)/2," ACTUAL LABELS"
685 REM
690 REM
700 X=X0-4\K=-1\G=0
702 K1=0\L1=0
705 U=ASC(T$(2,2))\W=1\M=15
710 X=X+4\K=K+1\R0=0
711 J=INT(P/256)\I=P-J*256
712 M=M+1\IFM<=14 THEN 715
714 !\!%4I,K,"  ",FNH$(J),\M=0
715 ! FNH$(I)," ",
716 F=EXAM(X)
720 C1 =EXAM(X+2)\C2=EXAM(X+3)
725 IF K<U THEN 765
740 D$(W,W+1)=CHR$(I)+CHR$(J)
750 W=W+2\R0=1
760 U=ASC(T$(W,W))*256+ASC(T$(W+1,W+1))
765 V=0\IF F<=8 THEN 780
770 V=1\F=F-16
775 IF F>8 THEN 1700
780 ON F+1 GOTO 800,850,900,1100,1200,1500,1250,1550,1600
790 REM
800 IF C1+C2=0THEN 830
810 P=FNG(1,C1,C2)
820 P=FNQ(205,1)\GOTO 710
830 P=FNG(175,19,18)
840 P=FNG(19,18,0)-1\GOTO 710
845 REM
850 J=205\IF C1>3 THEN 890
855 IF C1=0 THEN 885
860 IF EXAM(X-4)<>0THEN 890
862 IF C1>1 THEN 870
864 J=P-5\FILL J,256-EXAM(J)
866 FILL J+1,255-EXAM(J+1)\GOTO 710
870 IF EXAM(X-1)>0THEN 890
872 L=EXAM(X-2)\IF L>3 THEN 890
874 P=P-6\N=17+C1
876 FOR I=1 TO L
878 P=FNG(J,Z1(N),Z2(N))
880 NEXT\GOTO 710
885 J=195
890 P=FNG(J,Z1(C1),Z2(C1))\GOTO 710
895 REM
900 F=2
902 IF R0 OR V THEN 925
904 IF K>K1+1 OR L<>L1 THEN 925
906 IF C1<>EXAM(X-2) OR C2<>EXAM(X-1) THEN 925
910 K1=K\IF EXAM(X-4)=2 THEN 920
915 P=FNG(19,19,0)-1\GOTO 710
920 P=FNG(205,Z1(21),Z2(21))\GOTO 710
925 J=4\L=EXAM(X+1)\IF L=255 THEN 1040
930 GOSUB 1450
940 P=FNG(1,C1,C2)
950 J=2\IF V THEN 960
955 J=0\K1=K\L1=L
960 IF L=0 THEN 1040
1030 J=J+1\ P=FNG(62,L,0)-1
1040 P=FNQ(205,F+J)\GOTO 710
1090 REM
1100 F=7\GOTO 925
1190 REM
1200 L=EXAM(X+1)\IF L>0 THEN 1225
1210 P=FNQ(205,12)
1220 GOTO 1260
1225 IF L<255 THEN 1230
1227 P=FNQ(205,14)\GOTO 710
1230 P=FNG(62,L,0)-1
1240 P=FNQ(205,13)\GOTO 1260
1250 IF C1+C2*256=K+1 THEN 710
1260 GOSUB 1300
1270 P=FNG(195,I,J)\GOTO 710
1280 REM
1290 REM
1300 A$= CHR$(C2)+CHR$(C1)
1310 I=1\J=W0
1320 N=INT((I+J)/4)*2+1
1330 IF A$=T$(N,N+1) THEN 1360
1340 IF A$>T$(N,N+1) THEN I=N+2 ELSE J=N-2
1350 IF I<=J THEN 1320
1360 IF D$(N,N+1)<>"  " THEN 1400
1370 G=G+1\E(G)=P+1
1390 J=INT(N/256)\I=N-J*256\RETURN
1400 I=ASC(D$(N,N))\J=ASC(D$(N+1,N+1))\RETURN
1440 REM
1450 C1=C1+C1\C2=C2+C2
1460 IF C1<256 THEN 1480
1470 C1=C1-256\C2=C2+1
1480 IF C2>256 THEN C2=C2-256\RETURN
1490 REM
1500 IF C1+C2=0 THEN 710
1505 GOSUB 1450\N=C1+C2*256
1510 IF N>4 AND N<65530 THEN 1530
1515 J=19\IF N<=4 THEN 1520\N=65536-N\J=27
1520 FOR I=1 TO N/2\P=FNG(J,J,0)-1
1525 NEXT\GOTO 710
1530 P=FNG(33,C1,C2)
1535 P=FNQ(205,15)\GOTO 710
1540 REM
1550 IF C1+C2*256=K+1 THEN 710
1555 P=FNG(26,27,27)
1560 FILL P,31\P=P+1
1570 GOSUB 1300\N=210
1575 IF EXAM(X+1)>0 THEN N=218
1580 P=FNG(N,I,J)\GOTO 710
1590 REM
1600 I=C1+O2+1
1605 IF C1=8 THEN 1620
1610 P=FNG(205,Z1(I),Z2(I))\GOTO 710
1620 J=EXAM(X-2)
1625 P=P-J*6-6\X1=X-J*4-2
1630 P=FNG(14,J,0)-1
1632 P=FNG(205,Z1(I),Z2(I))
1635 FOR I =1 TO J
1640 FILL P,EXAM(X1)
1645 P=P+1\X1=X1+4
1650 NEXT\GOTO 710
1700 !\!"  ",G," FORWARD REFERENCES"
1710 P1=P
1770 REM
1775 REM
1780 FOR N=1 TO G
1790 P=E(N)
1800 J=EXAM(P)+EXAM(P+1)*256
1810 FILL P,ASC(D$(J,J))
1820 FILL P+1,ASC(D$(J+1,J+1))
1830 NEXT
1840 REM
1850 IF B0$="" THEN P=P1 ELSE P=FND(B0$,4)
1860 J=INT(P/256)\I=P-J*256
1870 P=P0\P=FNG(33,I,J)
1940 !" P-CODE..",K," INSTRUCTIONS"
1950 !" 8080..",P1-P0," BYTES"
1960 !"P-CODE:8080 =",(P1-P0)/(K*4)
1970 !"* END TRANSLATION *"
2000 END
