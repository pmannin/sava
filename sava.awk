# sahaus.awk
# Copyright (C) 2008, MP Soft Oy, Finland
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
BEGIN {
  FS = "\t";
  Init();
}

$1 == "Data" { Data[$2] = $3; next; }

$1 == "Files" { Files[$2] = $3; nFiles++; next; }

$1 == "Control" { Control[$2] = $3; nControl++; next; }

END {
  Process();
}

#-----------------------------------------------------------------------
function Init() {
  # kenttien lukum‰‰r‰ CBD tiedostossa
  Data["KenttaLkm"] = 49;
  Data["RiviLkm"] = 0;

  # VAUNUN PƒƒMITAT
  Data["VAUNU_PITUUS" ] = 4000; # Vaunun pituus (4000, 5000, 6000)
  Data["VAUNU_LEVEYS" ] = 1020; # Vaunun leveys
  Data["VAUNU_YLITYS" ] = 300;  # Kuormausalueen ylitys vaunun alkup‰‰ss‰
  # VAUNUN KAISTOJEN MITAT
  Data["KAISTA_REUNA" ] = 97.5; # Reunakaistan 1. pinon minimi x-paikka (110 - 25/2)
  Data["KAISTA_MIN_X" ] = 82.5; # Reunan kaistan leveyden mimimi (110 - 25/2 - 15)
  Data["KAISTA_LISA"  ] = 10.0; #
  Data["KAISTA_VALI_X"] = 35.0; # Kaistojen v‰li (leveyssuunta)
  # KUORMAUSALUE
  Data["KAISTA_C3_Y"  ] = 2500; # C3 sahattavien kapuloiden y-koordinaatti
  Data["KAISTA_VALI_Y"] = 150;  # kapuloiden v‰li kaistassa (pituussuunta)
  Data["SISA_OSUUS_4M"] = 0.7;  # kapulasta oltava 4 m k‰rrin sis‰puolella (0,7 -- 70%)
  Data["SISA_MINIMI"  ] = 300;  # pituus, jota lyhemm‰t kokonaan vaunun sis‰ll‰
  Data["TILA_MIN_Y"   ] = 1000; # kapulan viem‰n tilan minimipituus, kun kapula ei vaunun p‰‰ss‰

  nIN = 0;   # sis‰‰n luetun CBD tiedoston kapuloiden lkm
  nOUT = 0;  # CBD tiedoston nippujen lkm
  nKAI = 0;  # kaistojen lkm
  nKAR = 0;  # k‰rryjen lkm
  
  PinoLkmMax[ 72] = 8; # kapulan leveyden suhteen pinon kapuloiden max lkm
  PinoLkmMax[ 98] = 10;
  PinoLkmMax[123] = 12;

  XmlListFile = ENVIRON["TEMP"] "\\SaVa_xml.txt";
  print "">XmlListFile;
}

#-----------------------------------------------------------------------
function Process(  i) {
  printf("\n");
  printf("SAHAUS - SEPAn sahaustiedostojen ohjaus\n");
  printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
  printf("Copyright (C) 2008, MP Soft Oy, Finland\n\n");
  nKAR = Data["CbdCar"]-1; # viimeisin k‰rryn numero
  for (i=1 ; i<=nFiles ; i++) {
    Read_CBD(i);
    Join_CBD();
    Update_CBD();
    Sort_CBD();
    Loop_CBD();
  }
  Write_PAR();
}

#-----------------------------------------------------------------------
function Read_CBD(j  ,f,w,nw,s,i,nw1,w1,t,nw2,w2,f2,b_f2,nfie,lkm) {
  f = Files[j];
  nw = split(f,w,"\\");
  s = w[nw];
  nw = split(s,w,".")
  s = w[1];
  Data["CbdNimi"] = s;
  #printf("Tiedosto %s (%s)...\n",f,s);
  printf("Ristikko %s...\n",s);

  delete CT;
  delete CT_Saw;
  delete CT_Group;
  delete CT_Del;
  if (j in Control) {
    s = Control[j]; # ohjausdata, erotin puolipiste ";"
    if (Data["CbdDebug"] ~ "O") printf("    Ohjaus: %s\n",s);
    nw = split(s,w,";");
    for (i=1; i<=nw; i++) {
      if (w[i] != "") {
        s = w[i];
        # <optio>=<arvo>
        nw1 = split(s,w1,"=");
        t = w1[1];
        s = w1[2];
        nw2 = split(s,w2,"|");
        # kapulan ohjausdata, erotin pipe "|"
        if (nw2 == 3) {
          if (s == "||") {
            CT_Del[t] = s;
          } else {
            CT_Saw[t] = w2[1];
            CT_Group[t] = w2[2];
            if (length(w2[3]) > 0) {
              if (w2[3] != "-") CT_Join[t] = w2[3];
            }
          }
        # ristikon ohjausdataa
        } else {
          CT[t] = s;
        }
      }
    }
  }
  
  # ohjaustiedon j‰ljitys
  if (Data["CbdDebug"] ~ "O") {
    # sekalaiset optiot
    for (t in CT) printf("\tCT[%s] = '%s'\n",t,CT[t]);
    # kapulan sahalinja (1 | 2)
    for (t in CT_Saw) printf("\tCT_Saw[%s] = '%s'\n",t,CT_Saw[t]);
    # kapulan vaunuryhm‰ (1 | 2)
    for (t in CT_Group) printf("\tCT_Group[%s] = '%s'\n",t,CT_Group[t]);
    # poistettavat kapulat
    for (t in CT_Del) printf("\tCT_Del[%s] = '%s'\n",t,CT_Del[t]);
    # liitett‰v‰t kapulat
    for (t in CT_Join) printf("\tCT_Join[%s] = '%s'\n",t,CT_Join[t]);
  }

  # vaunun pituus
  Data["VAUNU_PITUUS"] = CT["Vaunu"]+0;

  delete IN;
  delete TIN;
  f2 = Data["CbdSaha3"] "\\" Data["CbdNimi"] "_C0.cbd";
  b_f2 = 0;
  FS = ",";
  while ((getline < f) > 0) {
    # poistettavat kapulat
    if ($(42) in CT_Del) {  # 42 = kapulan tunnus
      print $0 > f2;
      b_f2 = 1;
      continue;
    }
    # kapulan tietojen luku IN tauluun
    nIN++; nfie = NF;
    for (i=1; i<=nfie; i++) {
      IN[nIN "." i] = $(i);
    }
    # kapulan uudet kent‰t IN tauluun
    if (nfie < Data["KenttaLkm"]) {
      for (i=nfie+1; i<=Data["KenttaLkm"]; i++) {
        IN[nIN "." i] = "";
      }
    }
    # tunnus talteen
    TIN[$(42)] = nIN;
    # vanhojen tiedostojen korjaus:
    # 1. jaa tiedoston nimi tilausnumeroksi ja tilausriviksi
    if (IN[nIN ".2"] == "") {
      s = IN[nIN ".1"];
      nw = split(s,w,"_");
      if (nw == 2) {
        IN[nIN ".1"] = w[1];  # 1 - tilausnumero
        IN[nIN ".2"] = w[2];  # 2 - tilausnumeron rivi
      }
    }
    # 2. ristikoiden lukum‰‰r‰: CT["Lkm"] tai kentt‰ 5 kentt‰‰n 4
    if (nfie < Data["KenttaLkm"]) {
      #printf("nIN=%s,3=%s,4=%s,5=%s,35=%s\n",nIN,IN[nIN ".3"],IN[nIN ".4"],IN[nIN ".5"],IN[nIN ".35"]);
      lkm = IN[nIN ".3"]+0;
      # yhdistetyill‰ ristikoilla lukum‰‰r‰ on kent‰ss‰ 35
      if ((IN[nIN ".35"]+0) > 0) {
        lkm = IN[nIN ".35"]+0;
      }
      IN[nIN ".4"] = ("Lkm" in CT) ? (CT["Lkm"]+0) : IN[nIN ".5"];
      IN[nIN ".5"] = 0;
      # 35 - kapuloiden kokonaislukum‰‰r‰
      IN[nIN ".35"] = IN[nIN ".4"] * lkm;
      #printf("==>35=%d\n",IN[nIN ".35"])
    }
    # 3. kapulan leima
    if (IN[nIN ".42"] ~ "NR$") {
      IN[nIN ".46"] = CT["Leima"];
    }
  }
  close(f);
  if (b_f2 == 1) close(f2);

}

#-----------------------------------------------------------------------
# Kapuloiden yhdist‰minen (vain jos kaikki kriteerit t‰yttyv‰t).
#-----------------------------------------------------------------------
function Join_CBD(  t1,t2,i1,i2,p1,p2,k) {
  for (t1 in CT_Join) {
    t2 = CT_Join[t1];
    i1 = TIN[t1];
    i2 = TIN[t2];
    # kapuloiden tulee olla paarteita
    if (t1 !~ /[0-9][AY]$/ || t2 !~ /[0-9][AY]$/) {
      print "Kapuloiden " t1 " ja " t2 " tulee olla paarteita.";
      continue;
    }
    # kapuloiden pit‰‰ olla saman levyisi‰
    if (IN[i1 ".8"] != IN[i2 ".8"]) {
      print "Kapuloiden " t1 " ja " t2 " tulee olla saman leveyiset.";
      continue;
    }
    # kapuloita pit‰‰ olla sama lukum‰‰r‰
    if (IN[i1 ".35"] != IN[i2 ".35"]) {
      print "Kapuloiden " t1 " ja " t2 " luku tulee olla sama.";
      continue;
    }
    # kapulan 1 ei-suoraleikkuinen p‰‰
    p1 = ((IN[i1 ".9" ] == 900 && IN[i1 ".12"] == 0) || \
          (IN[i1 ".12"] == 900 && IN[i1 ".9" ] == 0)) ? 2 : 1;
    # kapulan 2 ei-suoraleikkuinen p‰‰
    p2 = ((IN[i2 ".9" ] == 900 && IN[i2 ".12"] == 0) || \
          (IN[i2 ".12"] == 900 && IN[i2 ".9" ] == 0)) ? 2 : 1;
    # siirret‰‰n kapulan 1 ei-suoraleikkuinen p‰‰ yhdisten kapulan 1. p‰‰h‰n
    # siirret‰‰n kapulan 2 ei-suoraleikkuinen p‰‰ yhdisten kapulan 2. p‰‰h‰n
    for (k=9; k<=14; k++) {
      IN[i1 "." k    ] = (p1 == 1) ? IN[i1 "." k] : IN[i1 "." (k+6)];
      IN[i1 "." (k+6)] = (p2 == 1) ? IN[i2 "." k] : IN[i2 "." (k+6)];
    }
    # pituudet yhteen
    IN[i1 ".7"] =  IN[i1 ".7"] + IN[i2 ".7"];
    # isompi lujuuluokka
    IN[i1 ".29"] = (IN[i2 ".29"] > IN[i1 ".29"]) ? IN[i2 ".29"] : IN[i1 ".29"];
    # poistetaan liitetty kapula asettamalla kapulam‰‰r‰ nollaksi
    IN[i2 ".35"] = 0;
  }
}

#-----------------------------------------------------------------------
# Kapuloiden jakaminen pinoihin.
#-----------------------------------------------------------------------
function Update_CBD(  j,pk,w,pink,rest,k,i) {
  delete OUT;
  nOUT = 0;
  for (j=1; j<=nIN; j++) {
    # pinon korkeus
    pk = CT["Pino"];
    w = int(IN[j ".8"]);
    if (w in PinoLkmMax)
      if (PinoLkmMax[w] < pk)
        pk = PinoLkmMax[w];
    # pinojen lukum‰‰r‰ sek‰ viimeisen pinon kapulam‰‰r‰
    pink = int(IN[j ".35"]/pk);
    rest = IN[j ".35"]%pk;
    if (rest > 0) pink++;
    # rivien monistus
    for (k=1; k<=pink; k++) {
      nOUT++;
      #print nOUT " " nIN " " pink " " rest;
      for (i=1; i<=Data["KenttaLkm"]; i++) {
        OUT[nOUT "." i] = IN[j "." i];
      }
      OUT[nOUT ".35"] = (k == pink && rest != 0) ? rest : pk;
    }
  }
}

#-----------------------------------------------------------------------
# Kapuloiden (pinojen) lajittelu 1. leveyden ja 2. pituuden mukaan.
#-----------------------------------------------------------------------
function Sort_CBD(  i,j,i1,j1,pit1,lev1,pit2,lev2,apu) {
  # alusta lajittelutaulu
  for (i=1; i<=nOUT; i++) {
    LAJ[i] = i;
  }
  # lajittele: 1. leveys (8), 2. pituus (7)
  for (i=1; i<nOUT; i++) {
    for (j=i+1; j<=nOUT; j++) {
      i1 = LAJ[i];
      j1 = LAJ[j];
      pit1 = OUT[i1 ".7"]; lev1 = OUT[i1 ".8"];
      pit2 = OUT[j1 ".7"]; lev2 = OUT[j1 ".8"];
      if ((lev2 > lev1) || (lev2 == lev1 && pit2 > pit1)) {
        apu = LAJ[i1];
        LAJ[i1] = LAJ[j1];
        LAJ[j1] = apu;
      }
    }
  }
}

#-----------------------------------------------------------------------
# Pinoiksi jaettujen lajiteltujen kapuloiden jako sahalinjalle ja
# vaunuun.
#-----------------------------------------------------------------------
function Loop_CBD(  saw1,grp1,j1,j,tun,lkm,sah,ryh,num,maxgrp) {
  nCAR = 0; delete CAR;

  maxgrp = (Data["CbdGroups"]+0);
  for (saw1=1; saw1<=3; saw1++) {
    delete SAW;
    for (grp1=1; grp1<=maxgrp; grp1++) {
      if (Data["CbdDebug"] ~ "P") printf("    Pinot: saha=%d ryhma=%d\n",saw1,grp1);
      delete GRP; nGRP = 0;
      for (j1=1; j1<=nOUT; j1++) {
        j = LAJ[j1];
        # kapulan tunnus ja lukum‰‰r‰
        tun = OUT[j ".42"];  # 42 - kapulan tunnus
        lkm = OUT[j ".35"];  # 35 - kapuloiden kokonaisulukum‰‰r‰ ristikossa
        # kapulan sahalinja (1 tai 2)
        sah = (tun ~ /^[0-9]+[AY]$/) ? "C3" : "H";
        if (tun in CT_Saw) sah = CT_Saw[tun];
        if ("Saha" in CT) sah = CT["Saha"];
        if (sah == "C3")
          sah = 1;
        else if (sah == "C4")
          sah = 2;
        else  # (sah == "H")
          sah = 3;
        # kapulan vaunuryhm‰
        ryh = (tun in CT_Group) ? CT_Group[tun] : 1;
        # lis‰t‰‰n kapula vaunuryhm‰‰n ja sahaukseen
        if (sah == saw1 && ryh == grp1) {
          nGRP++;
          GRP[nGRP] = j;
          SAW[sah] = SAW[sah]+1;
          num = SAW[sah];
          SAW[sah "." num] = j;
          if (Data["CbdDebug"] ~ "P")
            printf("\t%2d. (%2d) kapula=%-4s lkm=%-2d\n",nGRP,j,tun,lkm);
        }
      }
      if (nGRP > 0) {
        nKAI = 0; delete KAI;
        Band_CBD(saw1,grp1);
        Car_CBD(saw1,grp1);
     }
    }
    Write_CBD(saw1);
  }
}

#-----------------------------------------------------------------------
function Band_CBD(saw1,grp1  ,ypis,j1,j,pit,lev,tun,pit_alue,pit_sisa,
                             pit_ulko,vapaa,kaista,k,v,f,kid,lkm) {

  if (Data["CbdDebug"] ~ "K") printf("    Kaistotus: saha=%d ryhma=%d\n",saw1,grp1);
  
  ypis = 0;
  for (j1=1; j1<=nGRP; j1++) {
    j = GRP[j1];
    pit = OUT[j ".7" ]; # kapulan pituus L
    lev = OUT[j ".8" ]; # kapulan leveys B
    tun = OUT[j ".42"]; # kapulan tunnus

    # jos pituus alle minimitilan niin k‰ytet‰‰n minimitilavarausta (1000)
    pit_alue = (pit < 1000) ? 1000 : pit;
    pit_sisa = pit_alue;

    # kapulasta on oltava 70% vaunun sis‰ll‰, jos vaunun pituus on 4 m
    if (Data["VAUNU_PITUUS"] == 4000) {
      pit_sisa = Data["SISA_OSUUS_4M"]*pit_alue;
    }
    pit_ulko = pit_alue - pit_sisa;

    #printf("pit=%d sisa=%d ulko=%d alue=%d\n",pit,pit_sisa,pit_ulko,pit_alue);

    # haetaan ensimm‰inen kaista, johon kapulan sis‰pituus mahtuu
    vapaa = 0
    kaista = 0;
    for (k=1; k<=nKAI; k++) {
      v = KAI[k ".vap"] - Data["KAISTA_VALI_Y"] - pit_sisa;
      if (v  > 0) {
        if (vapaa == 0 || vapaa > v) {
          vapaa = KAI[k ".vap"];
          kaista = k;
          #printf("kaista=%d vapaa=%d pit_sisa=%d\n",kaista,vapaa,pit_sisa);
        }
      }
    }

    # tehd‰‰n uusi kaista jos kapula ei mahtunut aikaisempiin kaistoihin
    if (kaista == 0) {
      nKAI++;
      kaista = nKAI;
      vapaa = Data["VAUNU_PITUUS"];
      KAI[kaista ".vap"] = vapaa;
      KAI[kaista ".lev"] = lev;
      KAI[kaista ".lkm"] = 0;
      ypis = 0;
    }

    # Kapulan y-suuntainen sijoittelu vaunu˙n:
    # 1. Jos C3 paarresaha niin kapulan y-piste vaunun keskelle.
    # 2. Kapulan kuormauspiste y-suunnassa sijaitsee pituuden puoliv‰liss‰.
    # 3. Jos kapulan pituus < 300 niin kapulan pit‰‰ sijaita kokonaan vaunulla.
    # 4. Jos kapulan pituus < 1000 niin kapulan tilantarve on 1000.
    # 5. Kapula sijaitsee tilantarpeensa keskell‰.
    # 6. 30% kapulasta, mutta max 500,  voi sijaita vaunun ulkopuolella
    # 7. Kapulapinojen v‰linen et‰isyys vaunulla on 100.

    # C3 linjan sahaus: y-piste kaistan puoliv‰liin
    if (saw1 == 1) {
      ypis = Data["KAISTA_C3_Y"];
      vapaa = 0;
    # uuden kaistan alku
    } else if (ypis == 0) {
      if (pit_ulko > Data["VAUNU_YLITYS"]) {
        ypis = pit_alue/2 - Data["VAUNU_YLITYS"];
        vapaa = Data["VAUNU_PITUUS"] + Data["VAUNU_YLITYS"] - pit_alue;
        f = 3;
      # pituus >= 1000 ja ulkopituus on alle alkuvaran (VAUNU_YLITYS)
      } else {
        ypis = pit_alue/2 - pit_ulko;
        vapaa = Data["VAUNU_PITUUS"] + pit_ulko - pit_alue;
        f = 4;
      }
    } else {
      ypis = Data["VAUNU_PITUUS"] - vapaa + Data["KAISTA_VALI_Y"] + pit_alue/2;
      vapaa = vapaa - Data["KAISTA_VALI_Y"] - pit_alue;
      f = 5;
    }

    # kaistan j‰ljell‰ oleva vapaa tila
    KAI[kaista ".vap"] = vapaa;

    # nipun numeron talletus kaistalle
    kid = KAI[kaista ".lkm"] + 1;
    KAI[kaista ".lkm"] = kid;
    KAI[kaista "." kid] = j;

    # nipun Y-koordinaatti vaunulla
    OUT[j ".45"] = sprintf("%.1f",ypis);

    if (Data["CbdDebug"] ~ "K") {
      lkm = OUT[j ".35"]; # kapuloiden luku pinossa
      printf("\t%2d.%d %3d x %-4d y=%-4d f=%d vapaa=%-5d kapula=%-4s lkm=%d\n",
             kaista,kid,lev,pit,ypis,f,vapaa,tun,lkm);
    }
  }
}

#-----------------------------------------------------------------------
function Car_CBD(saw1,grp1  ,k_x,xpis,k,k1,k2,p_lev1,p_lev2,
                 k_lev1,k_lev2,k_lev,f,i,j,tun,lev,pit,lkm,id,v) {

  if (Data["CbdDebug"] ~ "V") printf("    Vaunutus: saha=%d ryhma=%d\n",saw1,grp1);

  # uusi vaunu
  Car_CBD_Add();
  k_x = 0;   # kaistan x-piste (kaistan vasemmassa reunassa)
  xpis = 0;  # pinon latauspisteen x-arvo, joka sijaitse pinon oikeassa reunassa
  k1 = 1;    # alkup‰‰n kaistan indeksi
  k2 = nKAI; # loppup‰‰n kaistan indeksi

  # kaistojen l‰pik‰ynti
  while (k1 <= k2) {
    # alku- ja loppup‰‰n pinojen leveys (pinon kapuloiden max leveys)
    p_lev1 = int(KAI[k1 ".lev"]);
    k_lev1 = (p_lev1%25 == 0) ? p_lev1 : (p_lev1-p_lev1%25)+25;
    p_lev2 = int(KAI[k2 ".lev"]);
    k_lev2 = (p_lev2%25 == 0) ? p_lev2 : (p_lev2-p_lev2%25)+25;
    # Vaunulle asetettavan kaistan valinta:
    # - (1) alussa vaunun oikeaan reunaan alkup‰‰n kaista
    if (k_x == 0) {
      k = k1;
      p_lev = p_lev1;
      k1++; v = "(1) alussa vaunun oikeaan reunaan alkup‰‰n kaista";
    # - (2) uusi vaunu jos alkup‰‰n kaistan pino ei mahdu nykyiseen vaunuun
    } else if (k_x + k_lev1 + 15 > Data["VAUNU_LEVEYS"]) {
      k_x = 0;
      Car_CBD_Add();
      k = k1;
      p_lev = p_lev1;
      k1++; v = "(2) uusi vaunu jos alkup‰‰n kaistan pino ei mahdu nykyiseen vaunuun";
    # - (3) jos alku- ja loppup‰‰n kaistat eiv‰t en‰‰ mahdu niin laitetaan alkup‰‰n kaista
    } else if (k_x + k_lev2 + Data["KAISTA_VALI_X"] + k_lev1 + 15 > Data["VAUNU_LEVEYS"]) {
      k = k1;
      p_lev = p_lev1;
      k1++; v = "(3) jos alku- ja loppup‰‰n kaistat eiv‰t en‰‰ mahdu niin laitetaan alkup‰‰n kaista";
    # - (4) muutoin valitaan kaistalistan lopusta kaista
    } else {
      k = k2;
      p_lev = p_lev2;
      k2--; v = "(4) muutoin valitaan kaistalistan lopusta kaista";
    }
    if (Data["CbdDebug"] ~ "V") {
      printf("k=%d (k1=%d,k2=%d): %s\n",k,k1,k2,v);
    }

    # pino laitetaan alussa kaistan oikeaan reunaan
    if (k_x == 0) {
      # pinolle tarvittava kaistan leveys
      p_lev = p_lev + 15; # pinon leveys + reunav‰li
      k_lev = (p_lev%25 == 0) ? p_lev : (p_lev-p_lev%25)+25;
      # pinon leveys on alle reunakaistan minimileveyden
      if (p_lev <= Data["KAISTA_REUNA"]) {
        xpis = Data["KAISTA_REUNA"];
        k_x = Data["KAISTA_REUNA"] + Data["KAISTA_VALI_X"];
        f = 1;
      # pinon leveys on yli reunakaistan minimileveyden
      } else {
        #print "k_lev=" k_lev " p_lev=" p_lev;
        xpis = k_lev + Data["KAISTA_LISA"] - 0.5*Data["KAISTA_VALI_X"];
        k_x = xpis + Data["KAISTA_VALI_X"];
        f = 2;
      }
    # ei alussa olevat pinot kaistan vasempaan reunaan
    } else {
      # pinolle tarvittava kaistan leveys
      k_lev = (p_lev%25 == 0) ? p_lev : (p_lev-p_lev%25)+25;
      xpis = k_x + p_lev;
      k_x = k_x + k_lev + Data["KAISTA_VALI_X"];
      f = 3;
    }
    #
    # kaistan nipuille vaunun numero ja x-piste
    for (i=1; i<=KAI[k ".lkm"]; i++) {
      j = KAI[k "." i];
      OUT[j ".36"] = nKAR;
      OUT[j ".44"] = sprintf("%.1f",xpis);
      if (Data["CbdDebug"] ~ "V") {
        tun = OUT[j ".42"]; # kapulan tunnus
        lev = OUT[j ".8" ]; # kapulan leveys B
        pit = OUT[j ".7" ]; # kapulan pituus L
        lkm = OUT[j ".35"]; # kapuloiden m‰‰r‰ pinossa
        id = sprintf("%d.%d.%d",nKAR,k,i);
        printf("\t%-8s f=%d x=%-6.1f %3d x %4d (%2d) kapula=%-4s lkm=%d\n",id,f,xpis,lev,pit,j,tun,lkm);
      }
    }
  }
}

#-----------------------------------------------------------------------
function Car_CBD_Add() {
  nKAR++;                       # vaunun numero
  if (nKAR > 999) nKAR = 100;   # vaunun numero v‰lill‰ 100-999
  nGEO++;                       # vaunujen lukum‰‰r‰ PDF kuvaa varten
  GEO[nGEO ".car"] = nKAR;      # PDF kuvan vaunun numero
}

#-----------------------------------------------------------------------
function Write_CBD(saw  ,t,f,b_f,c,d,xsiz) {
  if (saw == 0) {
    return;
  } else if (saw == 1) {
    t = "C3";
    d = Data["CbdSaha1"];
  } else if (saw == 2) {
    t = "C4";
    d = Data["CbdSaha2"];
  } else {
    t = "H";
    d = Data["BvxSaha"];
  }
  f = d "\\" Data["CbdNimi"] "_" t ".cbd";

  # kirjoita CBD tiedostot
  if (saw == 1) {
    b_f = Write_CBD_C3(saw,f);
  } else {
    b_f = Write_CBD_C4(saw,f);
  }

  # kirjoita XML lista
  if (b_f == 1 && saw == 3) {
    printf("%s\n",f) >>XmlListFile;
    close(XmlListFile);
  }

  # n‰yt‰ CBD tiedostot
  if ((Data["CbdDebug"] ~ "C") && b_f == 1) {
    c = "notepad.exe " f;
    system(c);
    close(c);
  }

  # tee PDF tiedosto
  if ((Data["CbdPdfMake"] == "TRUE") && b_f == 1) {
    f = d "\\" Data["CbdNimi"] "_" t ".pdf";
    xsiz = Data["VAUNU_PITUUS"] + 2000;
    Write_PDF_Begin(f,xsiz,0,595,841);
    Write_PDF_Graph(saw);
    Write_PDF_End();
    close(f);
    if (Data["CbdPdfShow"] == "TRUE") {
      c = "CMD /C \"" f "\"";
      system(c);
      close(c);
    }
  }
}

#-----------------------------------------------------------------------
function Write_CBD_C3(saw,f  ,lkm,v2,l35,j2,j1,j,v1,s,i) {
  b_f = 0;
  lkm = SAW[saw];
  if (lkm == 0) return b_f;
  v2 = "";
  l35 = 0;
  j2 = SAW[saw "." 1];;
  for (j1=1; j1<=lkm; j1++) {
    j = SAW[saw "." j1];
    # nykyisen rivin vertailurivi ei sis‰ll‰ kapulan lukum‰‰r‰‰
    v1 = OUT[j ".1"];
    for (i=2; i<=43; i++) {
      if (i != 35) v1 = v1 "," OUT[j "." i];
    }
    # jos per‰kk‰iset rivit samoja niin summaa lukum‰‰r‰t
    if (j1 == 1 || v1 == v2) {
      l35 = l35 + OUT[j "." 35];
    }
    # jos per‰kk‰iset rivit eroavat niin tulosta edellinen rivi
    if (j1 > 1 && v1 != v2) {
      s = OUT[j2 ".1"];
      for (i=2; i<=Data["KenttaLkm"]; i++) {
        if (i == 5 || i == 35) {
          s = s "," l35;
        } else {
          s = s "," OUT[j2 "." i];
        }
      }
      print s > f;
      j2 = j;
      l35 = OUT[j "." 35];
      b_f = 1;
    }
    #printf("\nj1=%d\tl35=%d\nv1=%s\nv2=%s\n",j1,l35,v1,v2);
    # talletetaan nykyisen rivin vertailu ja positio
    v2 = v1;
  }
  # tulosta viimeinen rivi
  if (lkm > 0) {
    s = OUT[j2 ".1"];
    for (i=2; i<=Data["KenttaLkm"]; i++) {
      if (i == 5 || i == 35) {
        s = s "," l35;
      } else {
        s = s "," OUT[j2 "." i];
      }
    }
    print s > f;
    # sulja tulostiedosto
    close(f);
  }
  # b_f = 1 jos tiedostoon on kirjoitettu
  return b_f;
}

#-----------------------------------------------------------------------
function Write_CBD_C4(saw,f  ,lkm,j1,j,s,c) {
  b_f = 0;
  lkm = SAW[saw];
  for (j1=1; j1<=lkm; j1++) {
    j = SAW[saw "." j1];
    s = OUT[j ".1"];
    c = OUT[j ".36"] "";
    CarData[c] = CarData[c] + OUT[j ".35"];
    for (i=2; i<=Data["KenttaLkm"]; i++) {
      s = s "," OUT[j "." i];
    }
    print s > f;
    b_f = 1;
  }
  close(f);
  return b_f;
}

#-----------------------------------------------------------------------
function Write_PAR(  f,car) {
  nKAR++;
  if (nKAR > 999) nKAR = 100;
  f = ENVIRON["TEMP"] "\\SaVa.par";
  printf("Data\t%s\t%d\n","CbdCar",nKAR) >f;
  close(f);

  f = ENVIRON["TEMP"] "\\CarData.par";
  for (car in CarData) {
    printf("CarData\t%s\t%d\n",car,CarData[car]) >>f;
  }
  close(f);

  f = ENVIRON["TEMP"] "\\SaVa.log";
  printf("SAHAUS - SEPAn sahaustiedostojen ohjaus\n") >f;
  close(f);
}

#-----------------------------------------------------------------------
function Write_PDF_Graph(saw  ,pox,poy,vle,vpi,vay,vox,voy,j1,j,vau,y,
                              tun,lev,pit,lkm,kxp,kyp,kox,koy,ktx) {
  pox = 0;
  poy = PDF["SizeY"];

  vle = Data["VAUNU_LEVEYS"];
  vpi = Data["VAUNU_PITUUS"];
  vay = -Data["VAUNU_YLITYS"];
  vox = pox+1200;  # vaunun origon (vasen yl‰nurkka) x-koordinaatti
  voy = poy-400;   # vaunun origon (vasen yl‰nurkka) y-koordinaatti
  delete VOY;

  Write_PDF_Text(Data["CbdNimi"], 5, 5, 24);
  for (j1=1; j1<=SAW[saw]; j1++) {
    # vaunun piirto
    j = SAW[saw "." j1];
    vau = OUT[j ".36"] " (" vpi ")"; # kapulan vaunun tunnus + pituus
    if (vau in VOY) {
      # nykyinen vaunu
      voy = VOY[vau];
    } else {
      # uusi vaunu
      voy = (j1 == 1)? voy : voy - vle - 200;
      Write_PDF_Dash(0.3,3,2);
      Write_PDF_Box(vox,voy,vpi,-vle); # ulkoreuna
      Write_PDF_Box(vox,voy,vay,-vle); # ylitys alkup‰‰ss‰
      Write_PDF_Dash(0.3,2,500/PDF["Scale"]);
      for (y=110; y<=1020-110; y=y+25) {
        Write_PDF_Line(vox,voy-y,vox+vpi,voy-y); # rei‰t
      }
      Write_PDF_Text(vau,vox,voy+20,16);
      VOY[vau] = voy;
    }
    tun = OUT[j ".42"]; # kapulan tunnus
    lev = OUT[j ".8" ]; # kapulan leveys B
    pit = OUT[j ".7" ]; # kapulan pituus L
    lkm = OUT[j ".35"]; # kapuloiden m‰‰r‰ pinossa
    kxp = OUT[j ".44"]; # kapulan keskipisteen x-koordinaatti vaunussa
    kyp = OUT[j ".45"]; # kapulan keskipisteen y-koordinaatti vaunussa
    # kapulan vasen etunurkka
    kox = vox+kyp-pit/2;
    koy = voy-kxp;
    # kapulan p‰‰lle kirjoitettava teksti
    ktx = sprintf("%s %dx%d (%d)",tun,lev,pit,lkm);
    # kapulan piirto
    Write_PDF_Solid(0.5);
    Write_PDF_Box(kox,koy,pit,lev);
    if (pit < Data["TILA_MIN_Y"]) {
      Write_PDF_Dash(0.5,2,2);
      Write_PDF_Box(kox-0.5*(Data["TILA_MIN_Y"]-pit),koy,Data["TILA_MIN_Y"],lev);
    }
    Write_PDF_Dash(0.3,2,1);
    Write_PDF_Line(kox+0.3*pit,koy,kox+0.3*pit,koy+lev);
    Write_PDF_Line(kox+0.7*pit,koy,kox+0.7*pit,koy+lev);
    Write_PDF_Text(ktx,kox,koy+9,7);
  }

  vau = OUT[j ".36"];
}

#-----------------------------------------------------------------------
function Write_PDF_Begin(path,xsiz,ysiz,xpap,ypap  ,sca) {
  PDF["Path"] = path;
  xpap = (xpap == 0) ? 595 : xpap;
  ypap = (ypap == 0) ? 841 : ypap;
  sca = (xsiz/xpap > ysiz/ypap) ? xsiz/xpap : ysiz/ypap;
  xsiz = (xsiz == 0) ? sca*xpap : xsiz;
  ysiz = (ysiz == 0) ? sca*ypap : ysiz;
  PDF["Scale"] = sca;
  PDF["SizeX"] = xsiz;
  PDF["SizeY"] = ysiz;
  #printf("%d x %d, %d x %d, sca=%f\n",xsiz,ysiz,xpap,ypap,sca);
  Print_PDF("%PDF-1. 4");
  Print_PDF("1 0 obj");
  Print_PDF("  << /Type /Catalog");
  Print_PDF("    /Outlines 2 0 R");
  Print_PDF("    /Pages 3 0 R");
  Print_PDF("  >>");
  Print_PDF("endobj");
  Print_PDF("2 0 obj");
  Print_PDF("  << /Type /Outlines");
  Print_PDF("    /Count 0");
  Print_PDF("  >>");
  Print_PDF("endobj");
  Print_PDF("3 0 obj");
  Print_PDF("  << /Type /Pages");
  Print_PDF("    /Kids [ 4 0 R ]");
  Print_PDF("    /Count 1");
  Print_PDF("  >>");
  Print_PDF("endobj");
  Print_PDF("4 0 obj");
  Print_PDF("  << /Type /Page");
  Print_PDF("    /Parent 3 0 R");
  Print_PDF("    /MediaBox [ 0 0 " xpap " " ypap " ]");
  Print_PDF("    /Contents 5 0 R");
  Print_PDF("    /Resources << /ProcSet 6 0 R >>");
  Print_PDF("  >>");
  Print_PDF("endobj");
  Print_PDF("5 0 obj");
  Print_PDF("  << /Length 883 >>");
  Print_PDF("stream");
}

#-----------------------------------------------------------------------
function Write_PDF_Box(x,y,w,h) {
  Write_PDF_DrawLine(x  ,y  ,"m");
  Write_PDF_DrawLine(x  ,y+h,"l");
  Write_PDF_DrawLine(x+w,y+h,"l");
  Write_PDF_DrawLine(x+w,y  ,"l");
  Write_PDF_DrawLine(x  ,y  ,"l");
  Write_PDF_EndLine();
}

#-----------------------------------------------------------------------
function Write_PDF_Line(x1,y1,x2,y2) {
  Write_PDF_DrawLine(x1,y1,"m");
  Write_PDF_DrawLine(x2,y2,"l");
  Write_PDF_EndLine();
}

#-----------------------------------------------------------------------
function Write_PDF_Dash(wid,on,off) {
  Print_PDF(wid " w");                  # Set line width
  Print_PDF("[ " on " " off " ] 0 d");  # Set dash pattern units
}

#-----------------------------------------------------------------------
function Write_PDF_Solid(wid) {
  wid = (wid == 0) ? 1 : wid;
  Print_PDF("[ ] 0 d"); # Reset dash pattern to a solid line
  Print_PDF(wid " w");  # Line width
}

#-----------------------------------------------------------------------
function Write_PDF_DrawLine(x,y,m) {
  x = x / PDF["Scale"];
  y = y / PDF["Scale"];
  Print_PDF("  " x " " y " " m);
}

#-----------------------------------------------------------------------
function Write_PDF_EndLine() {
  Print_PDF("  S");
}

#-----------------------------------------------------------------------
function Write_PDF_Text(txt,x,y,hei) {
  hei = (hei == 0) ? 10 : hei;
  x = x / PDF["Scale"];
  y = y / PDF["Scale"];
  Print_PDF("  BT");
  Print_PDF("    /F1 " hei " Tf");
  Print_PDF("    " x " " y " Td");
  Print_PDF("    ( " txt " ) Tj");
  Print_PDF("  ET");
}

#-----------------------------------------------------------------------
function Write_PDF_End() {
  Print_PDF("endstream");
  Print_PDF("endobj");
  Print_PDF("6 0 obj");
  Print_PDF("[ /PDF /Text ]");
  Print_PDF("endobj");
  Print_PDF("7 0 obj");
  Print_PDF("  << /Type /Font");
  Print_PDF("    /Subtype /Type1");
  Print_PDF("    /Name /F1");
  Print_PDF("    /BaseFont /Helvetica");
  Print_PDF("    /Encoding /MacRomanEncoding");
  Print_PDF("  >>");
  Print_PDF("endobj");
  Print_PDF("xref");
  Print_PDF("0 8");
  Print_PDF("0000000000 65535 f");
  Print_PDF("0000000009 00000 n");
  Print_PDF("0000000074 00000 n");
  Print_PDF("0000000120 00000 n");
  Print_PDF("0000000179 00000 n");
  Print_PDF("0000000364 00000 n");
  Print_PDF("0000000466 00000 n");
  Print_PDF("0000000496 00000 n");
  Print_PDF("trailer");
  Print_PDF("<< /Size 8");
  Print_PDF("  /Root 1 0 R");
  Print_PDF(">>");
  Print_PDF("startxref");
  Print_PDF("625");
  Print_PDF("%%EOF");
}

#-----------------------------------------------------------------------
function Print_PDF(s) {
  print s >PDF["Path"];
}

