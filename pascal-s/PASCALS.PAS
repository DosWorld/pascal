{$R+,S+}

{
  Pascal-S from Jan van de Snepscheut's book: What Computing is All About.
  with a few corrections to the printed version by Jan van de Snepscheut.
  This is based on Johnstone's version, i.e. his TurboPascal specific
  corrections have been rolled back.


  This version of Pascal-S compiler was originally fetched from
  http://hjem.get2net.dk/bnielsen/pascals5.html. I modified the
  program to get self-compiler as detailed in the last comment.
  To compile this program Turbo Pascal 4.0-7.0 or Delphi may be used.

    Command line: pascals.exe <pascals.pas >pascals.tmp
                  copy         pascals.tmp +pascals.pas pascals.dat
                  pascalm.exe <pascals.dat >pascals.out

                               Andrei V. Khokhlov, December 2002
                               www.avhohlov.narod.ru


  Jan van de Snepscheut's notes:

    line 295 (counting from 1 starting at program PascalS) is
                                    gen1(mulc, ttab[t].size); gen0(add)
    whereas the version printed in the book accidentally reads
                                    gen1(mulc, ttab[t].size)
    the present version also implements boolean negation

    the procedure funcdeclaration in the version printed in the book is
    erroneous. The first line on page 376 in the book should read
                                    if lev>1 then dx:=-1
    the last line of the procedure should read
          gen1(exit,itab[f].resultadr-dx); lev:=lev-1; dx:=odx


  To get self-compiler some language constructions are implemented and
  some other constructions are replaced with more simple constructions:

    string constant may be passed to function as char array (by value);
    forward function declarations are implemented;
    case operator with integer selector are implemented;
    eof function are implemented;

    enumerations are replaced with integer constants;
    simple records are used instead of records with cases;
    in operators are replaced with lists of simple comparisons;
    for loops are replaced with while loops;
    full object qualifications are used instead of with operators.

  Virtual machine are placed into separate file (pascalm.pas).
  Other changes in it:

    one array for code, data and stack are used;
    relative addressing of global variables are used;
    variable-length instructions are used.

  Bug fixed in arraytyp procedure:

    array [L1..H1] of array [L2..H2] of type // OK
    array [L1..H1, L2..H2] of type           // Error

  Bug fixed in funcdecaration procedure:

    procedure P;
      I:=0;                                  // OK, must be error

  Bug fixed in statement procedure:

    case N of
      C1:
        writeln('1')                         // OK, must be error (no semicolon)
      C2:
        writeln('1')
    end

  WARNING! Compiler uses nearly whole memory of virtual machine.
  If you uses 32-bit Delphi, virtual machine memory array size (amax)
  must be enlarged. This will reduce probability of stack overflow.

  Compiler source are reformatted (one line - one operator).
}

program PascalS{(input, output)};
  const
    cxmax = 12544;     { maximum code array size }
  { amax  = 16383;       maximum memory address  }

    add   =     0;     { opcodes }
    neg   =     1;
    mul   =     2;
    divd  =     3;
    remd  =     4;
    div2  =     5;
    rem2  =     6;
    eqli  =     7;
    neqi  =     8;
    lssi  =     9;
    leqi  =    10;
    gtri  =    11;
    geqi  =    12;
    dupl  =    13;
    swap  =    14;
    andb  =    15;
    orb   =    16;
    load  =    17;
    stor  =    18;
    hlt   =    19;     { terminate program }
    stop  =    20;     { end of code }
    wri   =    21;
    wrc   =    22;
    wrl   =    23;
    rdi   =    24;
    rdc   =    25;
    rdl   =    26;
    eofi  =    27;     { check eof }
    eol   =    28;
    ldc   =    29;
    lda   =    30;     { load address }
    ldla  =    31;
    ldl   =    32;
    ldg   =    33;
    stl   =    34;
    stg   =    35;
    move  =    36;
    copy  =    37;
    addc  =    38;
    mulc  =    39;
    jump  =    40;
    jumpz =    41;
    call  =    42;
    adjs  =    43;
    sets  =    44;
    exit  =    45;

{ type
    opcode = ( add, neg, mul, divd, remd, div2, rem2, eqli, neqi,
               lssi, leqi, gtri, geqi, dupl, swap, andb, orb, load,
               stor, hlt, wri, wrc, wrl, rdi, rdc, rdl, eol, ldc,
               ldla, ldl, ldg, stl, stg, move, copy, addc, mulc,
               jump, jumpz, call, adjs, sets, exit );

    instr  = record
      case op : opcode of
        add, neg, mul, divd, remd, div2, rem2, eqli, neqi, lssi, leqi,
        gtri, geqi, dupl, swap, andb, orb, load, stor, hlt, wri, wrc,
        wrl, rdi, rdc, rdl, eol:       ( );
        ldc, ldla, ldl, ldg, stl, stg, move, copy, addc, mulc, jump,
        jumpz, call, adjs, sets, exit: ( a: integer )
    end; }

  var
    code: array [ 0 .. cxmax ] of integer  { instr };
  { m   : array [ 0 .. amax  ] of integer; }

  procedure compile;
    const
      imax       = 256;      { length of identifier table }
      tmax       =  16;      { length of type table }
      lmax       =  10;      { maximum level }
      al         =   8; {10} { length of identifiers }

      ident      =   0;      { symbols }
      number     =   1;
      strconst   =   2;
      plus       =   3;
      minus      =   4;
      star       =   5;
      lbrack     =   6;
      rbrack     =   7;
      colon      =   8;
      eql        =   9;
      neq        =  10;
      lss        =  11;
      leq        =  12;
      gtr        =  13;
      geq        =  14;
      lparen     =  15;
      rparen     =  16;
      comma      =  17;
      semicolon  =  18;
      period     =  19;
      becomes    =  20;
      beginsym   =  21;
      endsym     =  22;
      ifsym      =  23;
      thensym    =  24;
      elsesym    =  25;
      whilesym   =  26;
      dosym      =  27;
      casesym    =  28;
      repeatsym  =  29;
      untilsym   =  30;
    { forsym     =   *;
      tosym      =   *;
      downtosym  =   *; }
      notsym     =  31;
      divsym     =  32;
      modsym     =  33;
      andsym     =  34;
      orsym      =  35;
      constsym   =  36;
      varsym     =  37;
      typesym    =  38;
      arraysym   =  39;
      ofsym      =  40;
      recordsym  =  41;
      progsym    =  42;
      forwardsym =  43;      { forward declaration }
      haltsym    =  44;      { halt operator }
      funcsym    =  45;
      procsym    =  46;

      konst      =   0;      { idkinds }
      varbl      =   1;
      field      =   2;
      tipe       =   3;
      funkt      =   4;

      simple     =   0;      { tpkinds }
      arrays     =   1;
      records    =   2;

      intip      =   1;      { standard types }
      booltip    =   2;
      chartip    =   3;
      stringtip  =   4;      { string }

    { fabs       =   *;        standard functions
      fsqr       =   *;
      fodd       =   *; }
      fchr       =   0;
      ford       =   1;
      fwrite     =   2;
      fwriteln   =   3;
      fread      =   4;
      freadln    =   5;
      feof       =   6;
      feoln      =   7;

    type
    { symbol = ( ident, number, strconst, plus, minus, star, lbrack,
                 rbrack, colon, eql, neq, lss, leq, gtr, geq, lparen,
                 rparen, comma, semicolon, period, becomes, beginsym,
                 endsym, ifsym, thensym, elsesym, whilesym, dosym, casesym,
                 repeatsym, untilsym, forsym, tosym, downtosym, notsym,
                 divsym, modsym, andsym, orsym, constsym, varsym, typesym,
                 arraysym, ofsym, recordsym, progsym, funcsym, procsym );

      idkind = ( konst, varbl, field, tipe, funkt );

      tpkind = ( simple, arrays, records ); }

      alfa   = { packed } array [ 1 .. al ] of char;

    var
      ch:       char;                         { last character read }
      cc:       integer;                      { character count }
      ll:       integer;                      { line length }
      lnum:     integer;                      { line number }
      line:     array [ 1 .. 81 ] of char;    { present input line }
      sym:      integer { symbol };           { last symbol read }
      id:       alfa;                         { last identifier read }
      num:      integer;                      { last number read }
      str:      array [ 1 .. 80 ] of char;    { last string read }
      slen:     integer;                      { length of last string }
      fdecl:    integer;                      { index of funcion decl }
      word:     array [ beginsym .. procsym ] of alfa;
      cx:       integer;                      { code index }
      lc:       integer;                      { last command }
      lev:      integer;                      { procedure nesting level }
      dx:       integer;                      { offset in stack }
      labeled:  boolean;                      { next instruction has label }
      namelist: array [ - 1 .. lmax ] of integer;
      ix, tx:   integer;                      { indices in tables }
      itab:     array [ 0 .. imax ] of record { identifier table }
        name:      alfa;
        link:      integer;
        tip:       integer;
      { case kind: idkind of
          konst: ( val: integer );
          varbl: ( vlevel, vadr: integer;
                   refpar: boolean );
          field: ( offset: integer );
          tipe:  ( );
          funkt: ( flevel, fadr, lastpar, resultadr: integer;
                   inside: boolean ) }
        kind:      integer {idkind};
        val:       integer;
        vlevel:    integer;
        vadr:      integer;
        refpar:    boolean;
        offset:    integer;
        flevel:    integer;
        fadr:      integer;
        lastpar:   integer;
        resultadr: integer;
        inside:    boolean
      end;
      ttab:     array [ 1 .. tmax ] of record { type table }
        size:      integer;
      { case kind: tpkind of
          simple:  ( ) ;
          arrays:  ( low, high, elemtip: integer );
          records: ( fields: integer ) }
        kind:      integer { tpkind };
        low:       integer;
        high:      integer;
        elemtip:   integer;
        fields:    integer
      end;

    function strcmp(var st1, st2: alfa): boolean;
      var
        f: boolean;
        i: integer;
      begin
        f:=true;
        i:=1;
        while f and (i<=al) do
          begin
            f:=(st2[i]=st1[i]);
            i:=i+1
          end;
        strcmp:=f
      end;

    procedure strcpy(var dst: alfa; src: alfa);
      begin
        dst:=src
      end;

    procedure error(n: integer);
      var
        i: integer;
      begin
      { for i:=1 to ll do
          write(line[i]); }
        i:=1;
        while i<=ll do
          begin
            write(line[i]);
            i:=i+1
          end;
        writeln;
      { for i:=1 to cc-2 do
          write(' ');}
        i:=1;
        while i<=cc-2 do
          begin
            write(' ');
            i:=i+1
          end;
        writeln('^');
        writeln('error ',n:1,' detected at line ',lnum:1);
        halt
      end;

    procedure getch;
      begin
        if cc=ll then
          begin
            if eof{(input)} then
              error(100);
            ll:=0;
            cc:=0;
            while  not eoln{(input)} do
              begin
                ll:=ll+1;
                read(line[ll])
              end;
            ll:=ll+1;
            line[ll]:=' ';
            readln; { read(line[ll]) }
            lnum:=lnum+1
          end;
        cc:=cc+1;
        ch:=line[cc]
      end;

    procedure getsym;
      var
        k:      integer;
        s:      integer { symbol };
        strend: boolean;
      begin
        while (ch=' ') or (ch=chr(9)) { ch in [' ',chr(9)] } do
          getch;
      { if ch in ['a'..'z','A'..'Z'] then }
        if (('a'<=ch) and (ch<='z')) or
           (('A'<=ch) and (ch<='Z')) then
          begin
            k:=0;
            repeat
              if k<>al then
                begin
                  k:=k+1;
                  id[k]:=ch
                end;
              getch
          { until not (ch in ['a'..'z','A'..'Z','0'..'9']); }
            until not ((('a'<=ch) and (ch<='z')) or
                       (('A'<=ch) and (ch<='Z')) or
                       (('0'<=ch) and (ch<='9')));
            while k<>al do
              begin
                k:=k+1;
                id[k]:=' '
              end;
            sym:=ident;
          { for s:=beginsym to procsym do
              if word[s]=id then
                sym:=s }
            s:=beginsym;
            while s<=procsym do
              begin
                if strcmp(word[s],id) { word[s]=id } then
                  sym:=s;
                s:=s+1
              end
          end
        else if ('0'<=ch) and (ch<='9') { ch in ['0'..'9'] } then
          begin
            num:=0;
            sym:=number;
            repeat
              num:=num*10+(ord(ch)-ord('0'));
              getch
            until not (('0'<=ch) and (ch<='9') { ch in ['0'..'9'] })
          end
        else if ch=':' then
          begin
            getch;
            if ch='=' then
              begin
                getch;
                sym:=becomes
              end
            else
              sym:=colon
          end
        else if ch='>' then
          begin
            getch;
            if ch='=' then
              begin
                getch;
                sym:=geq
              end
            else
              sym:=gtr
          end
        else if ch='<' then
          begin
            getch;
            if ch='=' then
              begin
                getch;
                sym:=leq
              end
            else if ch='>' then
              begin
                getch;
                sym:=neq
              end
            else
              sym:=lss
          end
        else if ch='.' then
          begin
            getch;
            if ch='.' then
              begin
                getch;
                sym:=colon
              end
            else
              sym:=period
          end
        else if ch='''' then
          begin
            slen:=0;
            strend:=false;
            sym:=strconst;
            repeat
              if cc=ll then
                error(101);
              getch;
              if ch='''' then
                begin
                  getch;
                  if ch='''' then
                    begin
                      slen:=slen+1;
                      str[slen]:=ch
                    end
                  else
                    strend:=true
                end
              else
                begin
                  slen:=slen+1;
                  str[slen]:=ch
                end
            until strend;
            if slen=0 then
              error(102)
          end
        else if ch='+' then
          begin
            getch;
            sym:=plus
          end
        else if ch='-' then
          begin
            getch;
            sym:=minus
          end
        else if ch='*' then
          begin
            getch;
            sym:=star
          end
        else if ch='(' then
          begin
            getch;
            sym:=lparen
          end
        else if ch=')' then
          begin
            getch;
            sym:=rparen
          end
        else if ch='[' then
          begin
            getch;
            sym:=lbrack
          end
        else if ch=']' then
          begin
            getch;
            sym:=rbrack
          end
        else if ch='=' then
          begin
            getch;
            sym:=eql
          end
        else if ch=',' then
          begin
            getch;
            sym:=comma
          end
        else if ch=';' then
          begin
            getch;
            sym:=semicolon
          end
        else if ch='{' then
          begin
            repeat
              getch
            until ch='}';
            getch;
            getsym
          end
        else
          error(103)
      end;

    procedure check(s: integer { symbol });
      begin
        if sym<>s then
          error(s{ord(s)})
      end;

    procedure skip(s: integer { symbol });
      begin
        check(s);
        getsym
      end;

    procedure enter(id: alfa; k: integer { idkind }; t: integer);
      var
        j: integer;
      begin
        if ix=imax then
          error(104);
        ix:=ix+1;
        itab[0].name:=id;
        j:=namelist[lev];
        while not strcmp(itab[j].name,id) { itab[j].name<>id } do
          j:=itab[j].link;
      { if j<>0 then
          error(105); }
        if j<>0 then
          begin
            if itab[j].kind<>funkt then
              error(105);
            if (code[itab[j].fadr]{.op}<>jump) or
               (code[itab[j].fadr+1]{.a}>0) then
              error(105);
            itab[j].name[1]:='$';
            code[itab[j].fadr+1]{.a}:=cx;
            fdecl:=j
          end;
      { with itab[ix] do
          begin }
            itab[ix].name:=id;
            itab[ix].link:=namelist[lev];
            itab[ix].tip :=t;
            itab[ix].kind:=k;
        { end; }
        namelist[lev]:=ix
      end;

    function position: integer;
      var
        i, j: integer;
      begin
        itab[0].name:=id;
        i:=lev;
        repeat
          j:=namelist[i];
          while not strcmp(itab[j].name,id) { itab[j].name<>id } do
            j:=itab[j].link;
          i:=i-1
        until (i<-1) or (j<>0);
        if j=0 then
          error(106);
        position:=j
      end;

    procedure gen(op, a: integer { i: instr });
      begin
        case {i.}op of
          dupl, eofi, eol, ldc, lda, ldla, ldl, ldg:
            dx:=dx-1;
        { neg, div2, rem2, swap, load, hlt, wrl, rdl,
          addc, mulc, jump, call, sets, exit:
            ; }
          add, mul, divd, remd, eqli, neqi, lssi, leqi, gtri,
          geqi, andb, orb, wrc, rdi, rdc, stl, stg, jumpz:
            dx:=dx+1;
          stor, wri, move:
            dx:=dx+2;
          copy:
            dx:=dx-{i.}a+1;
          adjs:
            dx:=dx+{i.}a
        end;

        if not (((({i.}op=addc) or ({i.}op=adjs)) and ({i.}a=0)) or
                (({i.}op=mulc) and ({i.}a=1))) then
          begin
            if labeled then
              begin
                code[cx]:=op {i};
                cx:=cx+1;
                if op>=ldc then
                  begin
                    code[cx]:=a;
                    cx:=cx+1
                  end;
                labeled:=false
              end
            else if (lc{code[cx-1].op}=ldc) and ({i.}op=add) then
              code[cx-2{1}]{.op}:=addc
            else if (lc=ldc) and ({i.}op=mul) then
              code[cx-2{1}]{.op}:=mulc
            else if (lc=ldc) and ({i.}op=neg) then
              begin
                code[cx-1]{.a}:=-code[cx-1]{.a};
                op:=lc
              end
            else if (lc=ldc) and (code[cx-1]{.a}=2) and ({i.}op=divd) then
              begin
                code[cx-2{1}]{.op}:=div2;
                cx:=cx-1
              end
            else if (lc=ldc) and (code[cx-1]{.a}=2) and ({i.}op=remd) then
              begin
                code[cx-2{1}]{.op}:=rem2;
                cx:=cx-1
              end
            else if (lc=lda{ldc}) and ({i.}op=stor) then
              code[cx-2{1}]{.op}:=stg
            else if (lc=lda{ldc}) and ({i.}op=load) then
              code[cx-2{1}]{.op}:=ldg
            else if (lc=ldla) and ({i.}op=stor) then
              code[cx-2{1}]{.op}:=stl
            else if (lc=ldla) and ({i.}op=load) then
              code[cx-2{1}]{.op}:=ldl
            else
              begin
                code[cx]:=op {i};
                cx:=cx+1;
                if op>=ldc then
                  begin
                    code[cx]:=a;
                    cx:=cx+1
                  end
              end;
            lc:=op
          end
      end;

    procedure gen0(op: integer { opcode });
    { var
        i: instr; }
      begin
      { i.op:=op; }
        gen(op, 0 {i})
      end;

    procedure gen1(op: integer { opcode }; a: integer);
    { var
        i: instr; }
      begin
      { i.op:=op;
        i.a:=a; }
        gen(op, a {i})
      end;

    function codelabel: integer;
      begin
        codelabel:=cx;
        labeled:=true
      end;

    procedure address(lv, ad: integer);
      begin
        if lv=0 then
          gen1(lda{ldc},ad)
        else if lv=lev then
          gen1(ldla,ad-dx)
        else
          begin
            gen1(ldl,-dx);
            while lv+1<>lev do
              begin
                gen0(load);
                lv:=lv+1
              end;
            gen1(addc,ad)
          end
      end;

    procedure addressvar(ref: integer);
      begin
      { with itab[ref] do
          begin }
            address(itab[ref].vlevel,itab[ref].vadr);
            if itab[ref].refpar then
              gen0(load)
        { end }
      end;

    procedure mustbe(x, y: integer);
      begin
        if x<>y then
          if (ttab[x].kind=arrays) and (ttab[y].kind=arrays) and
             (ttab[x].low=ttab[y].low) and (ttab[x].high=ttab[y].high) then
            mustbe(ttab[x].elemtip,ttab[y].elemtip)
          else
            error(107)
      end;

    procedure expression(var x: integer); forward;

    procedure selector(var t: integer; var ref: integer);
      var
        j, x: integer;
      begin
        t:=itab[ref].tip;
        getsym;
        if (sym=period) or (sym=lbrack) { sym in [period,lbrack] } then
          begin
            addressvar(ref);
            ref:=0;
            while (sym=period) or (sym=lbrack) { sym in [period,lbrack] } do
              case sym of
                period:
                  begin
                    if ttab[t].kind<>records then
                      error(108);
                    getsym;
                    check(ident);
                    j:=ttab[t].fields;
                    itab[0].name:=id;
                    while not strcmp(itab[j].name,id) { itab[j].name<>id } do
                      j:=itab[j].link;
                    if j=0 then
                      error(109);
                    gen1(addc,itab[j].offset);
                    t:=itab[j].tip;
                    getsym
                  end;
                lbrack:
                  begin
                    repeat
                      if ttab[t].kind<>arrays then
                        error(110);
                      getsym;
                      expression(x);
                      mustbe(intip,x);
                      gen1(addc,-ttab[t].low);
                      t:=ttab[t].elemtip;
                      gen1(mulc,ttab[t].size);
                      gen0(add)
                    until sym<>comma;
                    skip(rbrack)
                  end
              end
          end
      end;

    procedure varpar(var t: integer);
      var
        j: integer;
      begin
        check(ident);
        j:=position;
        selector(t,j);
        if j<>0 then
          addressvar(j)
      end;

    procedure standfct(n: integer);
      var
        x{, l}: integer;
      begin
        case n of
        { fabs:
            begin
              skip(lparen);
              expression(x);
              mustbe(intip,x);
              gen0(dupl);
              gen1(ldc,0);
              gen0(lssi);
              l:=codelabel;
              gen1(jumpz,0);
              gen0(neg);
              code[l].a:=codelabel;
              skip(rparen)
            end;
          fsqr:
            begin
              skip(lparen);
              expression(x);
              mustbe(intip,x);
              gen0(dupl);
              gen0(mul);
              skip(rparen)
            end;
          fodd:
            begin
              skip(lparen);
              expression(x);
              mustbe(intip,x);
              gen0(rem2);
              skip(rparen)
            end; }
          fchr:
            begin
              skip(lparen);
              expression(x);
              mustbe(intip,x);
              skip(rparen)
            end;
          ford:
            begin
              skip(lparen);
              expression(x);
              if x<>booltip then
                mustbe(chartip,x);
              skip(rparen)
            end;
          fwrite,fwriteln:
            begin
              if n=fwrite then
                check(lparen);
              if sym=lparen then
                begin
                  repeat
                    getsym;
                    if sym=strconst then
                      begin
                      { for x:=1 to slen do }
                        x:=1;
                        while x<=slen do
                          begin
                            gen1(ldc,ord(str[x]));
                            gen0(wrc);
                            x:=x+1
                          end;
                        getsym
                      end
                    else
                      begin
                        expression(x);
                        if sym=colon then
                          begin
                            mustbe(intip,x);
                            getsym;
                            expression(x);
                            mustbe(intip,x);
                            gen0(wri)
                          end
                        else if x=intip then
                          begin
                            gen1(ldc,8);
                            gen0(wri)
                          end
                        else if x=chartip then
                          gen0(wrc)
                        else
                          error(111)
                      end
                  until sym<>comma;
                  skip(rparen)
                end;
              if n=fwriteln then
                gen0(wrl)
            end;
          fread,freadln:
            begin
              if n=fread then
                check(lparen);
              if sym=lparen then
                begin
                  repeat
                    getsym;
                    varpar(x);
                    if x=intip then
                      gen0(rdi)
                    else if x=chartip then
                      gen0(rdc)
                    else
                      error(112)
                  until sym<>comma;
                  skip(rparen)
                end;
              if n=freadln then
                gen0(rdl)
            end;
          feof:
            gen0(eofi);
          feoln:
            gen0(eol)
        end
      end;

    procedure funcall(i: integer);
      var
        d, p, x: integer;
      begin
        getsym;
      { with itab[i] do }
          if itab[i].flevel<0 then
            standfct(itab[i].fadr)
          else
            begin
              if itab[i].tip<>0 then
                gen1(ldc,0);
              p:=i;
              d:=dx;
              if sym=lparen then
                begin
                  repeat
                    getsym;
                    if p=itab[i].lastpar then
                      error(113);
                    p:=p+1;
                    if itab[p].refpar then
                      varpar(x)
                    else
                      begin
                        expression(x);
                        if ttab[x].kind<>simple then
                          gen1(copy,ttab[x].size)
                      end;
                    if x=stringtip then
                      begin
                        if itab[p].refpar then
                          error(107);

                        if ttab[itab[p].tip].kind<>arrays then
                          error(107);

                        if ttab[itab[p].tip].elemtip<>chartip then
                          error(107);

                        if (ttab[itab[p].tip].high-
                            ttab[itab[p].tip].low)+1<>slen then
                          error(107)
                      end
                    else
                      mustbe(itab[p].tip,x)
                  until sym<>comma;
                  skip(rparen)
                end;
              if p<>itab[i].lastpar then
                error(114);
              if itab[i].flevel<>0 then
                address(itab[i].flevel,0);
              gen1(call,itab[i].fadr);
              dx:=d
            end
      end;

    procedure factor(var t: integer);
      var
        i: integer;
      begin
        if sym=ident then
          begin
            i:=position;
            t:=itab[i].tip;
            case itab[i].kind of
              konst:
                begin
                  getsym;
                  gen1(ldc,itab[i].val)
                end;
              varbl:
                begin
                  selector(t,i);
                  if i<>0 then
                    addressvar(i);
                  if ttab[t].kind=simple then
                    gen0(load)
                end;
              funkt:
                if t=0 then
                  error(115)
                else
                  funcall(i);
              tipe:
                error(116)
            end
          end
        else if sym=number then
          begin
            gen1(ldc,num);
            t:=intip;
            getsym
          end
        else if (sym=strconst) { and (slen=1) } then
          begin
          { gen1(ldc,ord(str[1])); }
            i:=slen;
            while i>=1 do
              begin
                gen1(ldc,ord(str[i]));
                i:=i-1
              end;
            t:=chartip;
            if slen<>1 then
              t:=stringtip;
            getsym
          end
        else if sym=lparen then
          begin
            getsym;
            expression(t);
            skip(rparen)
          end
        else if sym=notsym then
          begin
            getsym;
            factor(t);
            mustbe(booltip,t);
            gen0(neg);
            gen1(addc,1)
          end
        else
          error(117)
      end;

    procedure term(var x: integer);
      var
        y: integer;
      begin
        factor(x);
      { while sym in [andsym,star,divsym,modsym] do }
        while (sym=andsym) or (sym=star) or (sym=divsym) or (sym=modsym) do
          begin
            if sym=andsym then
              mustbe(booltip,x)
            else
              mustbe(intip,x);
            case sym of
              star:
                begin
                  getsym;
                  factor(y);
                  gen0(mul)
                end;
              divsym:
                begin
                  getsym;
                  factor(y);
                  gen0(divd)
                end;
              modsym:
                begin
                  getsym;
                  factor(y);
                  gen0(remd)
                end;
              andsym:
                begin
                  getsym;
                  factor(y);
                  gen0(andb)
                end
            end;
            mustbe(x,y)
          end
      end;

    procedure simplexpression(var x: integer);
      var
        y: integer;
      begin
        if sym=plus then
          begin
            getsym;
            term(x);
            mustbe(intip,x)
          end
        else if sym=minus then
          begin
            getsym;
            term(x);
            mustbe(intip,x);
            gen0(neg)
          end
        else
          term(x);
      { while sym in [orsym,plus,minus] do }
        while (sym=orsym) or (sym=plus) or (sym=minus) do
          begin
            if sym=orsym then
              mustbe(booltip,x)
            else
              mustbe(intip,x);
            case sym of
              plus:
                begin
                  getsym;
                  term(y);
                  gen0(add)
                end;
              minus:
                begin
                  getsym;
                  term(y);
                  gen0(neg);
                  gen0(add)
                end;
              orsym:
                begin
                  getsym;
                  term(y);
                  gen0(orb)
                end
            end;
            mustbe(x,y)
          end
      end;

    procedure expression(var x: integer);
      var
        op: integer { symbol };
        y:  integer;
      begin
        simplexpression(x);
      { if sym in [eql,neq,lss,leq,gtr,geq] then }
        if (sym=eql) or (sym=neq) or (sym=lss) or
           (sym=leq) or (sym=gtr) or (sym=geq) then
          begin
          { if ttab[x].kind<>simple then }
            if (x=stringtip) or (ttab[x].kind<>simple) then
              error(118);
            op:=sym;
            getsym;
            simplexpression(y);
            mustbe(x,y);
            case op of
              eql:
                gen0(eqli);
              neq:
                gen0(neqi);
              lss:
                gen0(lssi);
              leq:
                gen0(leqi);
              gtr:
                gen0(gtri);
              geq:
                gen0(geqi)
            end;
            x:=booltip
          end
      end;

    procedure statement;
      var
        l:          array [ 1 .. 48 ] of integer;
        m, n:       integer;
        i, j, t, x: integer;
      begin
        if sym=ident then
          begin
            i:=position;
          { with itab[i] do }
              case itab[i].kind of
                varbl:
                  begin
                    selector(t,i);
                    skip(becomes);
                    expression(x);
                    mustbe(t,x);
                    if i=0 then
                      gen0(swap)
                    else
                      addressvar(i);
                    if ttab[t].kind=simple then
                      gen0(stor)
                    else
                      gen1(move,ttab[t].size)
                  end;
                funkt:
                  if itab[i].tip=0 then
                    funcall(i)
                  else
                    begin
                      if  not itab[i].inside then
                        error(119);
                      getsym;
                      skip(becomes);
                      expression(x);
                      mustbe(itab[i].tip,x);
                      address(itab[i].flevel+1,itab[i].resultadr);
                      gen0(stor)
                    end;
                konst,field,tipe:
                  error(120)
              end
          end
        else if sym=ifsym then
          begin
            getsym;
            expression(t);
            mustbe(booltip,t);
            skip(thensym);
            i:=codelabel;
            gen1(jumpz,0);
            statement;
            if sym=elsesym then
              begin
                getsym;
                j:=codelabel;
                gen1(jump,0);
                code[i+1]{.a}:=codelabel;
                i:=j;
                statement
              end;
            code[i+1]{.a}:=codelabel
          end
        else if sym=casesym then
          begin
            getsym;
            expression(t);
            mustbe(intip,t);
          { skip(ofsym); }
            check(ofsym);         { 14.05.2006 }
            j:=0;
            m:=0;
            repeat
              if j<>0 then
                begin
                  m:=m+1;         { 06.01.2005 }
                  l[m]:=codelabel;
                  gen1(jump,0);
                  code[j+1]{.a}:=codelabel
                end;
              n:=m;
              repeat
              { if n<>m then }    { 14.05.2006 }
                  getsym;
                i:=position;
                if itab[i].kind<>konst then
                  error(131);
                gen0(dupl);
                gen1(ldc,itab[i].val);
                gen0(neqi);
                n:=n+1;
                l[n]:=codelabel;
                gen1(jumpz,0);
                getsym
              until sym<>comma;
              if sym<>colon then
                error(120);
              j:=codelabel;
              gen1(jump,0);
              repeat
                code[l[n]+1]{.a}:=codelabel;
                n:=n-1
              until n=m;
              getsym;
              statement;
            { m:=m+1;
              l[m]:=codelabel;
              gen1(jump,0); }
            { if sym=semicolon then
                getsym
            until sym=endsym; }
            until sym<>semicolon; { 14.05.2006 }
            code[j+1]{.a}:=codelabel;
          { repeat
              code[l[m]+1]/.a/:=codelabel;
              m:=m-1
            until m=0; }
            while m>0 do          { 14.05.2006 }
              begin
                code[l[m]+1]{.a}:=codelabel;
                m:=m-1
              end;
            gen1(adjs,1);
          { getsym }              { 14.05.2006 }
            skip(endsym)          { 14.05.2006 }
          end
        else if sym=whilesym then
          begin
            getsym;
            i:=codelabel;
            expression(t);
            mustbe(booltip,t);
            skip(dosym);
            j:=codelabel;
            gen1(jumpz,0);
            statement;
            gen1(jump,i);
            code[j+1]{.a}:=codelabel
          end
        else if sym=repeatsym then
          begin
            i:=codelabel;
            repeat
              getsym;
              statement
            until sym<>semicolon;
            skip(untilsym);
            expression(t);
            mustbe(booltip,t);
            gen1(jumpz,i)
          end
        else if sym=beginsym then
          begin
            repeat
              getsym;
              statement
            until sym<>semicolon;
            skip(endsym)
          end
        else if sym=haltsym then
          begin
            gen0(hlt);
            getsym
          end
      end;

    procedure block(l: integer); forward;

    procedure constant(var c, t: integer);
      var
        i, s: integer;
      begin
        if (sym=strconst) and (slen=1) then
          begin
            c:=ord(str[1]);
            t:=chartip
          end
        else
          begin
            if sym=plus then
              begin
                getsym;
                s:=+1
              end
            else if sym=minus then
              begin
                getsym;
                s:=-1
              end
            else
              s:=0;
            if sym=ident then
              begin
                i:=position;
                if itab[i].kind<>konst then
                  error(121);
                c:=itab[i].val;
                t:=itab[i].tip
              end
            else if sym=number then
              begin
                c:=num;
                t:=intip
              end
            else
              error(122);
            if s<>0 then
              begin
                mustbe(t,intip);
                c:=c*s
              end
          end;
        getsym
      end;

    procedure constdeclaration;
      var
        a:    alfa;
        t, c: integer;
      begin
        a:=id;
        getsym;
        skip(eql);
        constant(c,t);
        skip(semicolon);
        enter(a,konst,t);
        itab[ix].val:=c
      end;

    procedure typ(var t: integer);
      var
        i, j, sz, ft: integer;

      procedure arraytyp({var} t: integer);
        var
          x: integer;
        begin
        { with ttab[t] do
            begin }
              ttab[t].kind:=arrays;
              getsym;
              constant(ttab[t].low,x);
              mustbe(intip,x);
              skip(colon);
              constant(ttab[t].high,x);
              mustbe(intip,x);
              if ttab[t].low>ttab[t].high then
                error(123);
              if sym=comma then
              { arraytyp(ttab[t].elemtip) } { no elemtip initialization! }
                begin
                  if tx=tmax then
                    error(125);
                  tx:=tx+1;
                  ttab[t].elemtip:=tx;
                  arraytyp(ttab[t].elemtip)
                end
              else
                begin
                  skip(rbrack);
                  skip(ofsym);
                  typ(ttab[t].elemtip)
                end;
              ttab[t].size:=(ttab[t].high-ttab[t].low+1)*
                             ttab[ttab[t].elemtip].size
          { end }
        end;

      begin
        if sym=ident then
          begin
            i:=position;
            if itab[i].kind<>tipe then
              error(124);
            t:=itab[i].tip;
            getsym
          end
        else
          begin
            if tx=tmax then
              error(125);
            tx:=tx+1;
            t:=tx;
            if sym=arraysym then
              begin
                getsym;
                check(lbrack);
                arraytyp(t)
              end
            else
              begin
                skip(recordsym);
                if lev=lmax then
                  error(126);
                lev:=lev+1;
                namelist[lev]:=0;
                check(ident);
                sz:=0;
                repeat
                  enter(id,field,0);
                  i:=ix;
                  getsym;
                  while sym=comma do
                    begin
                      getsym;
                      check(ident);
                      enter(id,field,0);
                      getsym
                    end;
                  j:=ix;
                  skip(colon);
                  typ(ft);
                  repeat
                    itab[i].tip:=ft;
                    itab[i].offset:=sz;
                    sz:=sz+ttab[ft].size;
                    i:=i+1
                  until i>j;
                  if sym=semicolon then
                    getsym
                  else
                    check(endsym)
                until sym<>ident;
                ttab[t].size:=sz;
                ttab[t].kind:=records;
                ttab[t].fields:=namelist[lev];
                lev:=lev-1;
                skip(endsym)
              end
          end
      end;

    procedure typedeclaration;
      var
        a: alfa;
        t: integer;
      begin
        a:=id;
        getsym;
        skip(eql);
        typ(t);
        skip(semicolon);
        enter(a,tipe,t)
      end;

    procedure vardeclaration;
      var
        p, q, t: integer;
      begin
        enter(id,varbl,0);
        p:=ix;
        getsym;
        while sym=comma do
          begin
            getsym;
            check(ident);
            enter(id,varbl,0);
            getsym
          end;
        q:=ix;
        skip(colon);
        typ(t);
        skip(semicolon);
        repeat
        { with itab[p] do
            begin }
              itab[p].vlevel:=lev;
              dx:=dx-ttab[t].size;
              itab[p].tip:=t;
              itab[p].vadr:=dx;
              itab[p].refpar:=false;
          { end; }
          p:=p+1
        until p>q
      end;

    procedure funcdeclaration(isf: boolean);
      var
        f, p, ps, p1, p2, odx: integer;

      procedure paramlist;
        var
          r: boolean;
          t: integer;
        begin
          if sym=varsym then
            begin
              r:=true;
              getsym
            end
          else
            r:=false;
          check(ident);
          p:=ix;
          enter(id,varbl,0);
          getsym;
          while sym=comma do
            begin
              getsym;
              check(ident);
              enter(id,varbl,0);
              getsym
            end;
          skip(colon);
          check(ident);
          typ(t);
          while p<ix do
            begin
              p:=p+1;
              itab[p].tip:=t;
              itab[p].refpar:=r;
              if r then
                ps:=ps+1
              else
                ps:=ps+ttab[t].size
            end
        end;

      begin
        getsym;
        check(ident);
        fdecl:=-1; { new declaration }
        enter(id,funkt,0);
        getsym;
        f:=ix;
        itab[f].flevel:=lev;
        itab[f].fadr:=codelabel;
        gen1(jump,0);
        if lev=lmax then
          error(127);
        lev:=lev+1;
        namelist[lev]:=0;
        ps:=1;
        odx:=dx;
        if sym=lparen then
          begin
            repeat
              getsym;
              paramlist
            until sym<>semicolon;
            skip(rparen)
          end;
        if lev>1 then
          dx:=-1
        else
          dx:=0;
        itab[f].resultadr:=ps;
        p:=f;
        while p<ix do
          begin
            p:=p+1;
          { with itab[p] do
              begin }
                if itab[p].refpar then
                  ps:=ps-1
                else
                  ps:=ps-ttab[itab[p].tip].size;
                itab[p].vlevel:=lev;
                itab[p].vadr:=ps
            { end }
          end;
        if isf then
          begin
            skip(colon);
            check(ident);
            typ(itab[f].tip);
            if ttab[itab[f].tip].kind<>simple then
              error(128)
          end;
        skip(semicolon);
        itab[f].lastpar:=ix;
        if sym<>forwardsym then
          begin
            if fdecl>=0 then
              begin
                p1:=fdecl+1;
                p2:=f+1;
                while p1<=itab[fdecl].lastpar do
                  begin
                    if p2>itab[f].lastpar then
                      error(132);
                    if not strcmp(itab[p1].name,itab[p2].name) then
                      error(133);
                    if itab[p1].tip<>itab[p2].tip then
                      error(133);
                    if itab[p1].refpar<>itab[p2].refpar then
                      error(133);
                    p1:=p1+1;
                    p2:=p2+1
                  end;
                if p2<=itab[f].lastpar then
                  error(132)
              end;
          { itab[f].lastpar:=ix; }
            itab[f].inside:=true;
            block(itab[f].fadr);
            itab[f].inside:=false;
            gen1(exit,itab[f].resultadr-dx)
          end
        else
          begin
            if fdecl>=0 then
              error(105);
            getsym
          end;
        lev:=lev-1;
        dx:=odx;
        skip(semicolon)
      end;

    procedure block(l: integer);
      var
        i, d, odx, oix: integer;
      begin
        odx:=dx;
        oix:=ix;
        if sym=constsym then
          begin
            getsym;
            check(ident);
            repeat
              constdeclaration
            until sym<>ident
          end;
        if sym=typesym then
          begin
            getsym;
            check(ident);
            repeat
              typedeclaration
            until sym<>ident
          end;
        if sym=varsym then
          begin
            getsym;
            check(ident);
            repeat
              vardeclaration
            until sym<>ident
          end;
        while (sym=funcsym) or (sym=procsym) { sym in [funcsym,procsym] } do
          funcdeclaration(sym=funcsym);
        if l+1=codelabel then
          cx:=cx-1
        else
          code[l+1]{.a}:=codelabel;
        if lev=0 then
          gen1(sets,dx)
        else
          begin
            d:=dx-odx;
            dx:=odx;
            gen1(adjs,d)
          end;
        check(beginsym); { must be }
        statement;
        if lev<>0 then
          gen1(adjs,odx-dx);
        i:=oix+1;
        while i<=ix do
          begin
            if itab[i].kind=funkt then
              if (code[itab[i].fadr]{.op}=jump) and
                 (code[itab[i].fadr+1]{.a}=0) then
                error(134);
            i:=i+1
          end;
        ix:=oix
      end;

    procedure listcode;
      var
        i: integer;
        c: integer;
      begin
      { for i:=0 to cx-1 do }
        i:=0;
        while i<=cx-1 do
          begin
            write(i:5,': ');
            c:=code[i]{.op};
            case c of
              add:
                writeln('add  ',c:3);
              neg:
                writeln('neg  ',c:3);
              mul:
                writeln('mul  ',c:3);
              divd:
                writeln('divd ',c:3);
              remd:
                writeln('remd ',c:3);
              div2:
                writeln('div2 ',c:3);
              rem2:
                writeln('rem2 ',c:3);
              eqli:
                writeln('eqli ',c:3);
              neqi:
                writeln('neqi ',c:3);
              lssi:
                writeln('lssi ',c:3);
              leqi:
                writeln('leqi ',c:3);
              gtri:
                writeln('gtri ',c:3);
              geqi:
                writeln('geqi ',c:3);
              dupl:
                writeln('dupl ',c:3);
              swap:
                writeln('swap ',c:3);
              andb:
                writeln('andb ',c:3);
              orb:
                writeln('orb  ',c:3);
              load:
                writeln('load ',c:3);
              stor:
                writeln('stor ',c:3);
              hlt:
                writeln('hlt  ',c:3);
              stop:
                writeln('stop ',c:3);
              wri:
                writeln('wri  ',c:3);
              wrc:
                writeln('wrc  ',c:3);
              wrl:
                writeln('wrl  ',c:3);
              rdi:
                writeln('rdi  ',c:3);
              rdc:
                writeln('rdc  ',c:3);
              rdl:
                writeln('rdl  ',c:3);
              eofi:
                writeln('eofi ',c:3);
              eol:
                writeln('eol  ',c:3);
              ldc:
                writeln('ldc  ',c:3,code[i+1]{.a}:7);
              lda:
                writeln('lda  ',c:3,code[i+1]{.a}:7);
              ldla:
                writeln('ldla ',c:3,code[i+1]{.a}:7);
              ldl:
                writeln('ldl  ',c:3,code[i+1]{.a}:7);
              ldg:
                writeln('ldg  ',c:3,code[i+1]{.a}:7);
              stl:
                writeln('stl  ',c:3,code[i+1]{.a}:7);
              stg:
                writeln('stg  ',c:3,code[i+1]{.a}:7);
              move:
                writeln('move ',c:3,code[i+1]{.a}:7);
              copy:
                writeln('copy ',c:3,code[i+1]{.a}:7);
              addc:
                writeln('addc ',c:3,code[i+1]{.a}:7);
              mulc:
                writeln('mulc ',c:3,code[i+1]{.a}:7);
              jump:
                writeln('jump ',c:3,code[i+1]{.a}:7);
              jumpz:
                writeln('jumpz',c:3,code[i+1]{.a}:7);
              call:
                writeln('call ',c:3,code[i+1]{.a}:7);
              adjs:
                writeln('adjs ',c:3,code[i+1]{.a}:7);
              sets:
                writeln('sets ',c:3,code[i+1]{.a}:7);
              exit:
                writeln('exit ',c:3,code[i+1]{.a}:7)
            end;
            if code[i]>=ldc then
              i:=i+2
            else
              i:=i+1
          end
      end;

    begin { compile }
      strcpy(word[beginsym],  'begin   ');
      strcpy(word[endsym],    'end     ');
      strcpy(word[ifsym],     'if      ');
      strcpy(word[thensym],   'then    ');
      strcpy(word[elsesym],   'else    ');
      strcpy(word[whilesym],  'while   ');
      strcpy(word[dosym],     'do      ');
      strcpy(word[casesym],   'case    ');
      strcpy(word[repeatsym], 'repeat  ');
      strcpy(word[untilsym],  'until   ');
    { strcpy(word[forsym],    'for     ');
      strcpy(word[tosym],     'to      ');
      strcpy(word[downtosym], 'downto  '); }
      strcpy(word[notsym],    'not     ');
      strcpy(word[divsym],    'div     ');
      strcpy(word[modsym],    'mod     ');
      strcpy(word[andsym],    'and     ');
      strcpy(word[orsym],     'or      ');
      strcpy(word[constsym],  'const   ');
      strcpy(word[varsym],    'var     ');
      strcpy(word[typesym],   'type    ');
      strcpy(word[arraysym],  'array   ');
      strcpy(word[ofsym],     'of      ');
      strcpy(word[recordsym], 'record  ');
      strcpy(word[progsym],   'program ');
      strcpy(word[forwardsym],'forward ');
      strcpy(word[haltsym],   'halt    ');
      strcpy(word[funcsym],   'function');
      strcpy(word[procsym],   'procedur');

      ttab[intip]    .size:=1;
      ttab[intip]    .kind:=simple;

      ttab[chartip]  .size:=1;
      ttab[chartip]  .kind:=simple;

      ttab[booltip]  .size:=1;
      ttab[booltip]  .kind:=simple;

      ttab[stringtip].size:=0;
      ttab[stringtip].kind:=simple;

      tx:=4; {3}

      namelist[-1]:=0;
      lev:=-1;
      ix := 0;

      enter('false   ',konst,booltip);
      itab[ix].val   :=ord(false);

      enter('true    ',konst,booltip);
      itab[ix].val   :=ord(true);

    { enter('maxint  ',konst,intip);
      itab[ix].val   :=32767; }

      enter('integer ',tipe,intip);
      enter('char    ',tipe,chartip);
      enter('boolean ',tipe,booltip);

    { enter('abs     ',funkt,intip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fabs;
      itab[ix].inside:=false;

      enter('sqr     ',funkt,intip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fsqr;
      itab[ix].inside:=false;

      enter('odd     ',funkt,booltip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fodd;
      itab[ix].inside:=false; }

      enter('chr     ',funkt,chartip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fchr;
      itab[ix].inside:=false;

      enter('ord     ',funkt,intip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=ford;
      itab[ix].inside:=false;

      enter('write   ',funkt,0);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fwrite;

      enter('writeln ',funkt,0);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fwriteln;

      enter('read    ',funkt,0);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=fread;

      enter('readln  ',funkt,0);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=freadln;

      enter('eof     ',funkt,booltip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=feof;
      itab[ix].inside:=false;

      enter('eoln    ',funkt,booltip);
      itab[ix].flevel:=-1;
      itab[ix].fadr  :=feoln;
      itab[ix].inside:=false;

      namelist[0]:=0;
      lev:=0;

      lnum:=0;
      cc  :=0;
      ll  :=0;

      getch;
      getsym;
      labeled:=true;
      cx:= 0;
      lc:=-1;
      dx:= 1; { amax+1; }
      skip(progsym);
      skip(ident);
    { check(lparen);
      repeat
        getsym;
        check(ident);
        if (id<>'input     ') and (id<>'output    ') then
          error(129);
        getsym
      until sym<>comma;
      skip(rparen); }
      skip(semicolon);
      gen1(jump,0);
      block(0);
      gen0(stop);
      check(period);
      listcode
    end;

  begin
    compile
  end.
