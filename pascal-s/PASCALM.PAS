{$R+,S+}

{
  Pascal-S virtual machine
  cmdline: pascalm.exe <dat-file [>out-file]
}

program PascalM;
  const
    amax  = 32256;     { maximum address }

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

  var
    m : array [ 0 .. amax ] of integer ;

    line : array [1..24] of char;
    pc, sp, dp, j, k, n, s : integer ;
    i : integer ;
    d : integer ;
    c : char ;
    h : boolean;

  begin
    h :=true;
    pc:=0;
    while h and not eof do
      begin
        j:=1;
        while not eoln do
          begin
            read(line[j]);
            j:=j+1
          end;

        line [j]:=';';

        j:=1;
        while line[j]<>':' do
          j:=j+1;

        j:=j+1;
        while line[j]= ' ' do
          j:=j+1;

        while line[j]<>' ' do
          j:=j+1;

        while line[j]= ' ' do
          j:=j+1;

        n:=0;
        while (line[j]<>' ') and (line[j]<>';') do
          begin
            n:=10*n+(ord(line[j])-ord('0'));
            j:=j+1
          end;

        m[pc]:=n;
        pc   :=pc+1;

        if n=stop then
          h:=false;

        if line[j]<>';' then
          begin
            while line[j]= ' ' do
              j:=j+1;

            s:=1;
            if line[j]='-' then
              begin
                s:=-1;
                j:= j+1
              end;

            n:=0;
            while line[j]<>';' do
              begin
                n:=10*n+(ord(line[j])-ord('0'));
                j:=j+1
              end;

            m[pc]:=s*n;
            pc   :=pc+1
          end;

        readln
      end;

    dp:=amax;
    sp:=amax;
    pc:=0;
    h :=false;
    repeat
      i :=m[pc];
      d :=m[pc+1];
      pc:=pc+1;
      case i of
        add:
          begin
            m[sp+1]:=m[sp+1]+m[sp];
            sp:=sp+1
          end;
        neg:
          m[sp]:=-m[sp];
        mul:
          begin
            m[sp+1]:=m[sp+1]*m[sp];
            sp:=sp+1
          end;
        divd:
          begin
            m[sp+1]:=m[sp+1] div m[sp];
            sp:=sp+1
          end;
        remd:
          begin
            m[sp+1]:=m[sp+1] mod m[sp];
            sp:=sp+1
          end;
        div2:
          m[sp]:=m[sp] div 2;
        rem2:
          m[sp]:=m[sp] mod 2;
        eqli:
          begin
            m[sp+1]:=ord(m[sp+1]=m[sp]);
            sp:=sp+1
          end;
        neqi:
          begin
            m[sp+1]:=ord(m[sp+1]<>m[sp]);
            sp:=sp+1
          end;
        lssi:
          begin
            m[sp+1]:=ord(m[sp+1]<m[sp]);
            sp:=sp+1
          end;
        leqi:
          begin
            m[sp+1]:=ord(m[sp+1]<=m[sp]);
            sp:=sp+1
          end;
        gtri:
          begin
            m[sp+1]:=ord(m[sp+1]>m[sp]);
            sp:=sp+1
          end;
        geqi:
          begin
            m[sp+1]:=ord(m[sp+1]>=m[sp]);
            sp:=sp+1
          end;
        dupl:
          begin
            sp:=sp-1;
            m[sp]:=m[sp+1]
          end;
        swap:
          begin
            k:=m[sp];
            m[sp]:=m[sp+1];
            m[sp+1]:=k
          end;
        andb:
          begin
            if m[sp]=0 then
              m[sp+1]:=0;
            sp:=sp+1
          end;
        orb:
          begin
            if m[sp]=1 then
              m[sp+1]:=1;
            sp:=sp+1
          end;
        load:
          m[sp]:=m[m[sp]];
        stor:
          begin
            m[m[sp]]:=m[sp+1];
            sp:=sp+2
          end;
        hlt, stop:
          h:=true;
        wri:
          begin
            write({output,}m[sp+1]:m[sp]);
            sp:=sp+2
          end;
        wrc:
          begin
            write({output,}chr(m[sp]));
            sp:=sp+1
          end;
        wrl:
          writeln{(output)};
        rdi:
          begin
            read({input,}m[m[sp]]);
            sp:=sp+1
          end;
        rdc:
          begin
            read({input,}c);
            m[m[sp]]:=ord(c);
            sp:=sp+1
          end;
        rdl:
          readln{(input)};
        eofi:
          begin
            sp:=sp-1;
            m[sp]:=ord(eof{(input)})
          end;
        eol:
          begin
            sp:=sp-1;
            m[sp]:=ord(eoln{(input)})
          end;
        ldc:
          begin
            sp:=sp-1;
            m[sp]:=d;
            pc:=pc+1
          end;
        lda:
          begin
            sp:=sp-1;
            m[sp]:=dp+d;
            pc:=pc+1
          end;
        ldla:
          begin
            sp:=sp-1;
            m[sp]:=sp+1+d;
            pc:=pc+1
          end;
        ldl:
          begin
            sp:=sp-1;
            m[sp]:=m[sp+1+d];
            pc:=pc+1
          end;
        ldg:
          begin
            sp:=sp-1;
            m[sp]:=m[dp+d];
            pc:=pc+1
          end;
        stl:
          begin
            m[sp+d]:=m[sp];
            sp:=sp+1;
            pc:=pc+1
          end;
        stg:
          begin
            m[dp+d]:=m[sp];
            sp:=sp+1;
            pc:=pc+1
          end;
        move:
          begin
            k:=m[sp];
            j:=m[sp+1];
            sp:=sp+2;
            n:=d;
            repeat
              n:=n-1;
              m[k+n]:=m[j+n]
            until n=0;
            pc:=pc+1
          end;
        copy:
          begin
            j:=m[sp];
            n:=d;
            sp:=sp-n+1;
            repeat
              n:=n-1;
              m[sp+n]:=m[j+n]
            until n=0;
            pc:=pc+1
          end;
        addc:
          begin
            m[sp]:=m[sp]+d;
            pc:=pc+1
          end;
        mulc:
          begin
            m[sp]:=m[sp]*d;
            pc:=pc+1
          end;
        jump:
          pc:=d;
        jumpz:
          begin
            if m[sp]=0 then
              pc:=d
            else
              pc:=pc+1;
            sp:=sp+1
          end;
        call:
          begin
            sp:=sp-1;
            m[sp]:=pc+1;
            pc:=d
          end;
        adjs:
          begin
            sp:=sp+d;
            pc:=pc+1
          end;
        sets:
          begin
            sp:=sp+d;
            pc:=pc+1
          end;
        exit:
          begin
            pc:=m[sp];
            sp:=sp+d
          end
      end
    until h
  end.
