# ylista.awk
# Sahatiedostojen yhdistely ja raportointi.
# Copyright (C) 2007, MP Soft Oy, Finland
#-----------------------------------------------------------------------
# 13-12-2007  PJM  CBD tiedoston kentän 30 lkm siirretty kenttään 5.
# 24-06-2008  PJM  Liitetty SAVA ohjelmaan.
# 09-12-2008  PJM  Rivin tunnus muotoon "<tilnum>_00".
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
BEGIN {
  FS = "\t";
  Init();
}

$1 == "Control" { Control[$2] = $3; next; }

$1 == "Files" { FileCount++; Files[FileCount] = $2; next; }

END {
  if (EXIT) exit EXIT;
  Data_Read();
  Data_Numbers();
  if (index(Control["Debug"],"1")) Data_Print();
  Data_Sort();
  Data_Join();
  if (index(Control["Debug"],"2")) Data_Print();
  Data_PrintCbd();
  Data_PrintList();
}

#-----------------------------------------------------------------------
function Init() {
  FileCount = 0;
  Rows = 0;
  Columns = 0;
}

#-----------------------------------------------------------------------
function Data_Read(  i) {
  for (i=1; i<=FileCount; i++) {
    Data_Read_File(Files[i]);
  }
}

#-----------------------------------------------------------------------
function Data_Read_File(f  ,na,a,fn) {
  print "Processing " f "...";
  na = split(f,a,"\\");
  fn = a[na];
  delete MirrorNames;
  MirrorNames["XXX"] = 0;

  while ((getline < f) > 0) {
    Data_Read_Line(f,fn);
  }
}

#-----------------------------------------------------------------------
function Data_Read_Line(f,fn  ,sep,t_a,n,i) {

  #sep = ($0 ~ /;/) ? ";" : ",";
  sep = ",";
  delete t_a;
  Columns = split($0,t_a,sep);
  
  # vanhojen CBD tiedostojen käsittely ja tietojen muotoilu
  if (length(t_a[35])==0) {
    t_a[3] = t_a[3]+0;
    t_a[4] = (length(t_a[4])==0) ? t_a[5]+0 : t_a[4]+0;
    t_a[35] = t_a[3] * t_a[4];
    t_a[3] = 1;
    t_a[4] = 1;
    t_a[5] = "";
  }

  # jos peilattu kapula niin laitetaan lukumäärät peilaamattomaan
  # kapulaan ja ei käsitellä tätä riviä.
  n = t_a[42] "";
  if (n in MirrorNames) {
    i = MirrorNames[n];
    Data[i ".35"] += t_a[35];
    Data[i ".pcs"] = Data[i ".35"];
    return;
  }

  # luetaan kapulan tiedot Data tauluun
  Rows++;
  for (i=1 ; i<=Columns ; i++) {
    Data[Rows "." i] = t_a[i];
  }

  # talletetaan peilatun kapulan tunnus
  n = Data[Rows ".42"]
  MirrorNames["-" n] = Rows;

  # huomioidaan jos ristikoiden lukumäärä on nolla
  if (Data[Rows ".4"] == 0) {
    nQFiles++;
    QFiles[nQFiles] = f;
  }

  # talletetaan debug tietoja
  Data[Rows ".pcs"] = Data[Rows ".35"];
  Data[Rows ".fil"] = f;
  Data[Rows ".fna"] = fn;

  # jos puutavaran leveys <= 123 mm, niin kulmapyöristys on 0.5 astetta
  # jos puutavaran leveys > 123 mm, niin kulmapyöristys on 0.3 astetta
  if (Data[Rows ".8"] <= 123.0) {
    if (Data[Rows ".9"] >= 895 && Data[Rows ".9"] <= 905)
      Data[Rows ".9"] = 900;
    if (Data[Rows ".12"] >= 895 && Data[Rows ".12"] <= 905)
      Data[Rows ".12"] = 900;
    if (Data[Rows ".15"] >= 895 && Data[Rows ".15"] <= 905)
      Data[Rows ".15"] = 900;
    if (Data[Rows ".18"] >= 895 && Data[Rows ".18"] <= 905)
      Data[Rows ".18"] = 900;
  } else {
    if (Data[Rows ".9"] >= 897 && Data[Rows ".9"] <= 903)
      Data[Rows ".9"] = 900;
    if (Data[Rows ".12"] >= 897 && Data[Rows ".12"] <= 903)
      Data[Rows ".12"] = 900;
    if (Data[Rows ".15"] >= 897 && Data[Rows ".15"] <= 903)
      Data[Rows ".15"] = 900;
    if (Data[Rows ".18"] >= 897 && Data[Rows ".18"] <= 903)
      Data[Rows ".18"] = 900;
  }

  # merkitään suoran pään kulma 1. tai 3. pisteisiin
  if (Data[Rows ".9"] == 0 && Data[Rows ".12"] == 900) {
    Data[Rows ".9"] = 900;
    Data[Rows ".12"] = 0;
    apu1 = Data[Rows ".10"];
    apu2 = Data[Rows ".11"];
    Data[Rows ".10"] = Data[Rows ".13"];
    Data[Rows ".11"] = Data[Rows ".14"];
    Data[Rows ".13"] = apu1;
    Data[Rows ".14"] = apu2;
  }
  if (Data[Rows ".15"] == 0 && Data[Rows ".18"] == 900) {
    Data[Rows ".15"] = 900;
    Data[Rows ".18"] = 0;
    apu1 = Data[Rows ".16"];
    apu2 = Data[Rows ".17"];
    Data[Rows ".16"] = Data[Rows ".19"];
    Data[Rows ".17"] = Data[Rows ".20"];
    Data[Rows ".19"] = apu1;
    Data[Rows ".20"] = apu2;
  }
  
  # nollataan kaikki viisteet, joiden pituus alle 1 mm
  if (Data[Rows ".10"] < 1.0) Data[Rows ".10"] = 0.0;
  if (Data[Rows ".11"] < 1.0) Data[Rows ".11"] = 0.0;
  if (Data[Rows ".13"] < 1.0) Data[Rows ".13"] = 0.0;
  if (Data[Rows ".14"] < 1.0) Data[Rows ".14"] = 0.0;
  if (Data[Rows ".16"] < 1.0) Data[Rows ".16"] = 0.0;
  if (Data[Rows ".17"] < 1.0) Data[Rows ".17"] = 0.0;
  if (Data[Rows ".19"] < 1.0) Data[Rows ".19"] = 0.0;
  if (Data[Rows ".20"] < 1.0) Data[Rows ".20"] = 0.0;
  
  # pyöristetään pituus alaspäin kokonaisluvuksi
  Data[Rows ".7"] = sprintf("%d",Data[Rows ".7"]+0.5);

  #Data_Print2(Rows);
}

#-----------------------------------------------------------------------
function Data_Numbers(  num,i,fil,t_n) {
  delete t_n;
  num = 1;
  for (i=1; i<=nQFiles; i++) {
    fil = QFiles[i];
    if (length(fil) > 0) {
      msg = sprintf("\nEnter number of trusses in '%s' <%d>: ",fil,num);
      num = Query(msg,num);
      t_n[fil] = num+0;
    }
  }
  for (i=1; i<=Rows; i++) {
    if (Data[i ".4"] == 0) {
      fil = Data[i ".fil"];
      Data[i ".4"] = t_n[fil];
      Data[i ".35"] = Data[i ".3"] * Data[i ".4"];
      Data[i ".pcs"] = Data[i ".35"];
      #printf("%d\t%s\t%d\t%d\n",i,fil,Data[i ".4"],Data[i ".35"])
    }
  }
}

#-----------------------------------------------------------------------
function Data_Sort(  i,j,pos,flag) {
  for (i=1; i<=Rows; i++) Position[i] = i;

  for (i=1; i<Rows; i++) {
    for (j=i+1; j<=Rows; j++) {
      flag = 0;
      ip = Position[i];
      jp = Position[j];
      # kapulan leveyden suhteen laskevaan järjestykseen
      if ((Data[jp ".8"]+0) > (Data[ip ".8"]+0)) {
        #print i ". (" ip ") L=" Data[ip ".8"] " < L=" Data[jp ".8"] " (" jp ")";
        flag = 1;
      } else if ((Data[jp ".8"]+0) == (Data[ip ".8"]+0)) {
        # kapulan pituuden suhteen laskevaan järjestykseen
        if ((Data[jp ".7"]+0) > (Data[ip ".7"]+0)) {
          #print jp " P=" Data[jp ".7"] " <> " ip " P=" Data[ip ".7"];
          flag = 1;
        } else if ((Data[jp ".7"]+0) == (Data[ip ".7"]+0)) {
          # kapulan nurkan viistekulman suhteen laskevaan järjestykseen
          if ((Data[jp ".9"]+0) > (Data[ip ".9"]+0)) {
            #print jp " K=" Data[jp ".9"] " <> " ip " K=" Data[ip ".9"];
            flag = 1;
          }
        }
      }
      if (flag == 1) {
        pos = Position[j];
        Position[j] = Position[i];
        Position[i] = pos;
      }
    }
  }
}

#-----------------------------------------------------------------------
function Data_Join(  i,j,pos,delta,flag,pcs,lu1,lu2,b) {
  for (i=1; i<Rows; i++) {
    for (j=i+1; j<=Rows; j++) {
      flag = 0;
      ip = Position[i];
      jp = Position[j];
      if (ip > 0 && jp > 0) {
        delta = (Data[ip ".7"]+0) - (Data[jp ".7"]+0);
        if (delta < 0) delta = -1 * delta;
        if (delta <= 1.0) {
          if (Data[ip ".8"] == Data[jp ".8"]) {
            b = Data[ip ".8"]+0;
            #printf("%s:%s | %s:%s | %f\n",Data[ip ".1"],Data[ip ".42"],Data[jp ".1"],Data[jp ".42"],delta);
            for (k=9; k<=28; k++) {
              if (k >= 9 && k <= 11) {
                Data_x[k]    = Data[jp "." k+6];
                Data_x[k+3]  = Data[jp "." k+9];
                Data_x[k+6]  = Data[jp "." k];
                Data_x[k+9]  = Data[jp "." k+3];
                Data_y[k]    = Data[jp "." k+3];
                Data_y[k+3]  = Data[jp "." k];
                Data_y[k+6]  = Data[jp "." k+9];
                Data_y[k+9]  = Data[jp "." k+6];
                Data_xy[k]   = Data[jp "." k+9];
                Data_xy[k+3] = Data[jp "." k+6];
                Data_xy[k+6] = Data[jp "." k+3];
                Data_xy[k+9] = Data[jp "." k];
              } else if (k >= 21) {
                Data_y[k]    = Data[jp "." k];
                Data_x[k]    = Data[jp "." k];
                Data_xy[k]   = Data[jp "." k];
              }
            }
            flag = 1;
            for (k=9; k<=28; k++) {
              if (k == 10 || k == 13 || k == 16 || k == 19 || k >= 21)
                if (Data[ip "." k] != Data[jp "." k]) flag = 0;
            }
            if (flag == 0) {
              flag = 1;
              for (k=9; k<=28; k++) {
                if (k == 10 || k == 13 || k == 16 || k == 19 || k >= 21)
                  if (Data[ip "." k] != Data_y[k]) flag = 0;
              }
            }
            if (flag == 0) {
              flag = 1;
              for (k=9; k<=28; k++) {
                if (k == 10 || k == 13 || k == 16 || k == 19 || k >= 21)
                  if (Data[ip "." k] != Data_x[k]) flag = 0;
              }
            }
            if (flag == 0) {
              flag = 1;
              for (k=9; k<=28; k++) {
                if (k == 10 || k == 13 || k == 16 || k == 19 || k >= 21)
                  if (Data[ip "." k] != Data_xy[k]) flag = 0;
              }
            }
            #for (k=9; k<=28; k++) {
            #  if (k == 10 || k == 13 || k == 16 || k == 19 || k >= 21)
            #    printf("%02d. %5.1f %5.1f %5.1f %5.1f %5.1f\n",k,Data[ip "." k],Data[jp "." k],Data_y[k],Data_x[k],Data_xy[k]);
            #}
          }
        }
        if (flag == 1) {
          # merkataan kapula yhdistellyksi
          #printf("%s:%s yhdistetty\n",Data[ip ".1"],Data[ip ".42"]);
          Join[ip] = ip;
          # lasketaan kapuloiden lukumäärät yhteen
          Data[ip ".35"] = Data[ip ".35"] + Data[jp ".35"];
          # valitaan suurin lujuusluokka yhdistetylle kapulalle
          lu1 = (substr(Data[ip ".29"],2)+0);
          lu2 = (substr(Data[jp ".29"],2)+0);
          if (lu2 > lu1) Data[ip ".29"] = Data[jp ".29"];
          # merkataan poistettu kapula
          Position[j] = -jp;
          Data[jp ".del"] = ip;
        }
      }
    }
  }

  j = 0;
  for (i=1; i<=Rows; i++) {
    ip = Position[i];
    if (ip > 0) {
      j++;
      Data[ip ".3"  ] = 1;
      Data[ip ".4"  ] = 1;
      Data[ip ".nam"] = Data[ip ".42"];
      if (ip in Join)
        Data[ip ".42" ] = j;
      else
        Data[ip ".42" ] = Data[ip ".1" ] "/" Data[ip ".42" ];
    }
  }
}


#-----------------------------------------------------------------------
function Data_Print(  row) {
  print "";
  for (row=1; row<=Rows; row++) {
    printf(" %2d"   ,row);
    printf(" %2d"   ,Data[row ".3"]);   #
    printf(" %3d"   ,Data[row ".4"]);   #
    printf(" %7.1f" ,Data[row ".7"]);   #
    printf(" %4d"   ,Data[row ".8"]);   #
    printf(" %4d"   ,Data[row ".9"]);   #
    printf(" %2d"   ,Data[row ".35"]);  #
    printf(" %4s"   ,Data[row ".42"]);  #
    printf(" %s"    ,Data[row ".pcs"]);  #
    printf(" %4s"   ,Data[row ".nam"]);  #
    printf(" %2d"   ,Data[row ".del"]);  #
    printf(" %s"    ,Data[row ".fna"]);  # filename
#    printf("%s"     ,Data[row ".fil"]);  # path
    printf("\n");
  }
  print "";
}

#-----------------------------------------------------------------------
function Data_Print2(row) {
    printf("%3d %2d %4d %7.1f %4d %2d %2d %4s %s %4s %2d %s\n",\
        row, \
        Data[row ".3"], \
        Data[row ".4"], \
        Data[row ".7"], \
        Data[row ".8"], \
        Data[row ".9"], \
        Data[row ".35"], \
        Data[row ".42"], \
        Data[row ".pcs"], \
        Data[row ".nam"], \
        Data[row ".del"], \
        Data[row ".fil"]);
  #print "";
}

#-----------------------------------------------------------------------
function Data_PrintCbd(  i,j,ip) {
  for (i=1; i<=Rows; i++) {
    ip = Position[i];
    if (ip > 0) {
      text = Control["OrderNo"] "_00";
      for (j=2; j<=Columns; j++) {
        text = text "," Data[ip "." j];
      }
      PrintCbd(text);
    }
  }
}

#-----------------------------------------------------------------------
function PrintCbd(text) {
  print text >> Control["Result.cbd"];
}

#-----------------------------------------------------------------------
function Data_PrintList(  i,ip,j) {
  PageHeight = 66;
  PrintedRows = 0;

  for (i=1; i<=Rows; i++) {
    n_Members = 0;
    delete Members;
    ip = Position[i];
    if (ip > 0) {
      #print Data[ip ".1"] " " Data[ip ".42"] " " Data[ip ".pcs"] " kpl 1";
      Members[++n_Members] = ip;
      for (j=1; j<=Rows; j++) {
        jp = Position[j];
        if (jp < 0) {
          jp = -1 * jp;
          if (Data[jp ".del"] == ip) {
            Members[++n_Members] = jp;
            #print Data[jp ".1"] " " Data[jp ".42"] " " Data[jp ".pcs"] " kpl 2";
          }
        }
      }
      Data_PrintMember();
    }
  }
}

#-----------------------------------------------------------------------
function Data_PrintMember(  txt,ip,n,i,a1,a2,a3,a4,p1v,p1h,p2v,p2h,p3v,p3h,p4v,p4h) {
  ip = Members[1];
  a1 = Data[ip ".9" ]; p1v = Data[ip ".10"]; p1h = Data[ip ".11"];
  a2 = Data[ip ".12"]; p2v = Data[ip ".13"]; p2h = Data[ip ".14"];
  a3 = Data[ip ".15"]; p3v = Data[ip ".16"]; p3h = Data[ip ".17"];
  a4 = Data[ip ".18"]; p4v = Data[ip ".19"]; p4h = Data[ip ".20"];

  delete L1; n_L1 = 0;
  L1[++n_L1] = sprintf("KAPULA %3d",Data[ip ".42"]);
  for (j=1; j<=n_Members; j++) {
    jp = Members[j];
    if (Data[jp ".nam"] != "")
      nam = Data[jp ".nam"];
    else
      nam = Data[jp ".42"];
    L1[++n_L1] = sprintf("%-12s  %4s  %4d kpl",Data[jp ".1"],nam,Data[jp ".pcs"]);
  }

  # vasen suora pää (90 astetta)
  if (a1 == 900)
    MemberLeft_1(ip);
  # vasen pää on kaksileikkuinen
  else if (p1v > 0.0 && p1h > 0.0 && p2v > 0.0 && p2h > 0.0)
    MemberLeft_2(ip);
  else if (a1 > a2)
    MemberLeft_3(ip);
  else
    MemberLeft_4(ip);

  MemberCenter(ip);

  # oikea suora pää (90 astetta)
  if (a3 == 900)
   MemberRight_1(ip);
  # oikea pää on kaksileikkuinen
  else if (p3v > 0.0 && p3h > 0.0 && p4v > 0.0 && p4h > 0.0)
   MemberRight_2(ip);
  else if (a3 > a4)
   MemberRight_3(ip);
  else
   MemberRight_4(ip);

  n = (n_L1 > 7) ? n_L1 : 7;
  PrintedRows = PrintedRows + n + 1;
  if (PrintedRows > PageHeight) {
    PrintedRows = n+1;
    PrintList("\f");
  }

  PrintList("");
  for (i=1; i<=n; i++) {
    txt = sprintf("%-34.34s%-13.13s%-10.10s%-13.13s",L1[i],L2[i],L3[i],L4[i]);
    PrintList(txt);
  }
}

#-----------------------------------------------------------------------
function MemberCenter(ip) {
  delete L3; n_L3 = 0;
  L3[++n_L3] = sprintf("  L %4d  ",Data[ip ".7"]);
  L3[++n_L3] = "";
  L3[++n_L3] = sprintf("%2dx%3d %3.3s",Data[ip ".41"],Data[ip ".8"],Data[ip ".29"]);
  L3[++n_L3] = "";
  L3[++n_L3] = sprintf("%4d kpl",Data[ip ".35"]);
  L3[++n_L3] = "";
  L3[++n_L3] = "";
}

#-----------------------------------------------------------------------
function MemberLeft_1(ip) {
  delete L2; n_L2 = 0;
  L2[++n_L2] = sprintf("            ");
  L2[++n_L2] = sprintf("+-----------");
  L2[++n_L2] = sprintf("|%4.1f     "    ,Data[ip ".9"]*0.1);
  L2[++n_L2] = sprintf("|           ");
  L2[++n_L2] = sprintf("|           ");
  L2[++n_L2] = sprintf("+-----------");
  L2[++n_L2] = sprintf("            ");
}

#-----------------------------------------------------------------------
function MemberLeft_2(ip) {
  delete L2; n_L2 = 0;
  L2[++n_L2] = sprintf("     %-3d    "  ,Data[ip ".10"]);
  L2[++n_L2] = sprintf("%3d +-------"   ,Data[ip ".11"]);
  L2[++n_L2] = sprintf("   / %4.1f   "  ,Data[ip ".9"]*0.1);
  L2[++n_L2] = sprintf("  +         ");
  L2[++n_L2] = sprintf("   \\ %4.1f   " ,Data[ip ".12"]*0.1);
  L2[++n_L2] = sprintf("%3d +-------"   ,Data[ip ".14"]);
  L2[++n_L2] = sprintf("     %-3d    "  ,Data[ip ".13"]);
}

#-----------------------------------------------------------------------
function MemberLeft_3(ip) {
  delete L2; n_L2 = 0;
  L2[++n_L2] = sprintf("     %-3d    "  ,Data[ip ".10"]);
  L2[++n_L2] = sprintf("%3d +-------"   ,Data[ip ".11"]);
  L2[++n_L2] = sprintf("   /%4.1f    "  ,Data[ip ".9"]*0.1);
  L2[++n_L2] = sprintf("  /         ");
  L2[++n_L2] = sprintf(" /          ");
  L2[++n_L2] = sprintf("+-----------");
  L2[++n_L2] = sprintf("            ");
}

#-----------------------------------------------------------------------
function MemberLeft_4(ip) {
  delete L2; n_L2 = 0;
  L2[++n_L2] = sprintf("            ");
  L2[++n_L2] = sprintf("+-----------");
  L2[++n_L2] = sprintf(" \\          ");
  L2[++n_L2] = sprintf("  \\         ");
  L2[++n_L2] = sprintf("   \\%4.1f    " ,Data[ip ".12"]*0.1);
  L2[++n_L2] = sprintf("%3d +-------"   ,Data[ip ".14"]);
  L2[++n_L2] = sprintf("     %-3d    "  ,Data[ip ".13"]);
}

#-----------------------------------------------------------------------
function MemberRight_1(ip) {
  delete L4; n_L4 = 0;
  L4[++n_L4] = sprintf("            ");
  L4[++n_L4] = sprintf("-----------+");
  L4[++n_L4] = sprintf("       %4.1f|"  ,Data[ip ".15"]*0.1);
  L4[++n_L4] = sprintf("           |");
  L4[++n_L4] = sprintf("           |");
  L4[++n_L4] = sprintf("-----------+");
  L4[++n_L4] = sprintf("            ");
}


#-----------------------------------------------------------------------
function MemberRight_2(ip) {
  delete L4; n_L4 = 0;
  L4[++n_L4] = sprintf("    %3d     "   ,Data[ip ".16"]);
  L4[++n_L4] = sprintf("-------+ %-3d"  ,Data[ip ".17"]);
  L4[++n_L4] = sprintf("   %4.1f \\   " ,Data[ip ".15"]*0.1);
  L4[++n_L4] = sprintf("         +  ");
  L4[++n_L4] = sprintf("   %4.1f /   "  ,Data[ip ".18"]*0.1);
  L4[++n_L4] = sprintf("-------+ %-3d"  ,Data[ip ".20"]);
  L4[++n_L4] = sprintf("    %3d     "   ,Data[ip ".19"]);
}

#-----------------------------------------------------------------------
function MemberRight_3(ip) {
  delete L4; n_L4 = 0;
  L4[++n_L4] = sprintf("    %3d     "   ,Data[ip ".16"]);
  L4[++n_L4] = sprintf("-------+ %-3d"  ,Data[ip ".17"]);
  L4[++n_L4] = sprintf("    %4.1f\\   " ,Data[ip ".15"]*0.1);
  L4[++n_L4] = sprintf("         \\  ");
  L4[++n_L4] = sprintf("          \\ ");
  L4[++n_L4] = sprintf("-----------+");
  L4[++n_L4] = sprintf("            ");
}

#-----------------------------------------------------------------------
function MemberRight_4(ip) {
  delete L4; n_L4 = 0;
  L4[++n_L4] = sprintf("            ");
  L4[++n_L4] = sprintf("-----------+");
  L4[++n_L4] = sprintf("          / ");
  L4[++n_L4] = sprintf("         /  ");
  L4[++n_L4] = sprintf("    %4.1f/   "  ,Data[ip ".18"]*0.1);
  L4[++n_L4] = sprintf("-------+ %-3d"  ,Data[ip ".20"]);
  L4[++n_L4] = sprintf("    %3d     "   ,Data[ip ".19"]);
}

#-----------------------------------------------------------------------
function PrintList(text) {
  print text >> Control["Result.txt"];
}

#-----------------------------------------------------------------------
function Query(s,d  ,a) {
  printf("%s",s);
  getline a < "/dev/stdin";
  a = (length(a)) ? a : d;
  return a;
}

#-----------------------------------------------------------------------
function Init_Desc() {
  N[1] =  "Tilausnumero";                # RCAD
  N[2] =  "Rivinumero";                  # RCAD
  N[3] =  "Kappalemäärä päällekkäin";    # RCAD
  N[4] =  "Ristikoiden määrä";           # RCAD
  N[5] =  "Montako tulee aihiosta";      # OPTIMOINTI
  N[6] =  "Monesko kappale aihiosta";    # OPTIMOINTI
  N[7] =  "Kapulan pituus (mm)";         # RCAD
  N[8] =  "Kapulan leveys (mm)";         # RCAD
  N[9] =  "Kulman1 viiste (1/10 aste)";  # RCAD
  N[10] = "Viisteen 1 pituus (mm)";      # RCAD
  N[11] = "Viisteen 1 leveys (mm)";      # RCAD
  N[12] = "Kulman 2 viiste (1/10 aste)"; # RCAD
  N[13] = "Viisteen 2 pituus (mm)";      # RCAD
  N[14] = "Viisteen 2 leveys (mm)";      # RCAD
  N[15] = "Kulman 3 viiste (1/10 aste)"; # RCAD
  N[16] = "Viisteen 3 pituus (mm)";      # RCAD
  N[17] = "Viisteen 3 leveys (mm)";      # RCAD
  N[18] = "Kulman 4 viiste (1/10 aste)"; # RCAD
  N[19] = "Viisteen 4 pituus (mm)";      # RCAD
  N[20] = "Viisteen 4 leveys (mm)";      # RCAD
  N[21] = "Loven pituus (mm)";           # RCAD
  N[22] = "Loven leveys (mm)";           # RCAD
  N[23] = "Reiän 1 X koord.";            # RCAD
  N[24] = "Reiän 1 Y koord.";            # RCAD
  N[25] = "Reiän 2 X koord.";            # RCAD
  N[26] = "Reiän 2 Y koord.";            # RCAD
  N[27] = "Reiän 3 X koord.";            # RCAD
  N[28] = "Reiän 3 Y koord.";            # RCAD
  N[29] = "Lujuusluokka";                # RCAD
  N[30] = "Mustesuihkumerkinta";         # OPTIMOINTI
  N[31] = "Mustesuihkumerkinta #1";      # OPTIMOINTI
  N[32] = "Mustesuihkumerkinta #2";      # OPTIMOINTI
  N[33] = "Mustesuihkumerkinta #3";      # RCAD
  N[34] = "Mustesuihkumerkinta #4";      # RCAD
  N[35] = "Kapuloiden kokonaismäärä";    # RCAD
  N[36] = "Pinkkausvaunun numero";       # PINKKAUS
  N[37] = "Aihion pituus (mm)";          # OPTIMOINTI
  N[38] = "Kapulan numero";              # OPTIMOINTI
  N[39] = "Aihion numero";               # OPTIMOINTI
  N[40] = "Viimeinen sahausrivi = 1";    # OPTIMOINTI
  N[41] = "Kapulan paksuus";             # RCAD
  N[42] = "Kapulan tunnus";              # RCAD
  N[43] = "Reikien halkaisija";          # RCAD
  N[44] = "Kapulan x-koord. vaunussa";   # PINKKAUS
  N[45] = "Kapulan y-koord. vaunussa";   # PINKKAUS
  N[46] = "Vapaa kenttä";                # RCAD
  N[47] = "Vapaa kenttä";                # RCAD
  N[48] = "Vapaa kenttä";                # RCAD
  N[49] = "Vapaa kenttä";                # RCAD
}



